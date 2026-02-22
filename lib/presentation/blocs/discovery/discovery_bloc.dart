// lib/presentation/blocs/discovery/discovery_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart' as usecases;
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import 'dart:async';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';

@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryProfiles _getDiscoveryProfiles;
  final LikeProfile _likeProfile;
  final DislikeProfile _dislikeProfile;
  final SuperLikeProfile _superLikeProfile;
  final RewindSwipe _rewindSwipe;
  final usecases.UpdateFilters _updateFilters;
  final GetDailyLikeLimit _getDailyLikeLimit;
  final PremiumRepository? _premiumRepository;

  List<DiscoveryProfile> _profiles = [];
  int _currentIndex = 0;
  DailyLikeLimit? _dailyLimit;
  StreamSubscription<String>? _revokeSubscription;

  DiscoveryLoaded? _safePreviousState() {
    final currentState = state;
    if (currentState is ProfileSwiping) return currentState.previousState;
    if (currentState is DiscoveryLoaded) return currentState;
    if (currentState is DailyLimitReached) return currentState.previousState;
    return null;
  }

  String _mapFailureToMessage(String prefix, Failure? failure) {
    final rawMessage = failure?.message ?? 'Unknown';
    final lower = rawMessage.toLowerCase();
    if (lower.contains('429') || lower.contains('too many requests')) {
      return 'Trop de requêtes. Patiente quelques secondes puis réessaie.';
    }
    return '$prefix: $rawMessage';
  }

  DiscoveryBloc({
    required GetDiscoveryProfiles getDiscoveryProfiles,
    required LikeProfile likeProfile,
    required DislikeProfile dislikeProfile,
    required SuperLikeProfile superLikeProfile,
    required RewindSwipe rewindSwipe,
    required usecases.UpdateFilters updateFilters,
    required GetDailyLikeLimit getDailyLikeLimit,
    PremiumRepository? premiumRepository,
  })  : _getDiscoveryProfiles = getDiscoveryProfiles,
        _likeProfile = likeProfile,
        _dislikeProfile = dislikeProfile,
        _superLikeProfile = superLikeProfile,
        _rewindSwipe = rewindSwipe,
        _updateFilters = updateFilters,
        _getDailyLikeLimit = getDailyLikeLimit,
        _premiumRepository = premiumRepository,
        super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadDiscoveryProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<RewindLastSwipe>(_onRewindLastSwipe);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadDailyLimit>(_onLoadDailyLimit);
    on<LoadMoreProfiles>(_onLoadMoreProfiles);

    // Écouter les notifications de révocation d'interactions
    _revokeSubscription =
        AppEvents().onInteractionRevoked.listen((profileId) async {
      print('🔔 DiscoveryBloc: Reçu notification révocation profil $profileId');

      // Attendre un peu pour que le backend traite la révocation
      print('⏳ DiscoveryBloc: Attente de 500ms avant rechargement...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Recharger les profils avec forceRefresh pour ignorer le cache
      print('🔄 DiscoveryBloc: Rechargement forcé des profils');
      add(const LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
    });
  }

  @override
  Future<void> close() {
    _revokeSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadDiscoveryProfiles(
    LoadDiscoveryProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    print(
        '🔄 DEBUG DiscoveryBloc: _onLoadDiscoveryProfiles - limit: ${event.limit}');
    emit(DiscoveryLoading());
    print('🔄 DEBUG DiscoveryBloc: DiscoveryLoading émis');

    try {
      print(
          '🔄 DEBUG DiscoveryBloc: Appel _getDiscoveryProfiles use case (forceRefresh: ${event.forceRefresh})');
      // Charger les profils en premier (priorité)
      final params = event.forceRefresh
          ? GetDiscoveryProfilesParams.forceRefresh(limit: event.limit)
          : GetDiscoveryProfilesParams.initial(limit: event.limit);
      final result = await _getDiscoveryProfiles(params);

      result.fold(
        (failure) {
          print(
              '❌ DEBUG DiscoveryBloc: Échec récupération profils: ${failure.message}');
          emit(DiscoveryError(message: failure.message));
        },
        (profiles) async {
          print('✅ DEBUG DiscoveryBloc: Profils récupérés: ${profiles.length}');
          _profiles = profiles;
          _currentIndex = 0;

          // Émettre immédiatement l'état chargé avec les profils
          _emitLoaded(emit);

          // Charger la limite quotidienne en arrière-plan (non bloquant)
          _loadDailyLimitInBackground();
        },
      );
    } catch (e) {
      print('❌ DEBUG DiscoveryBloc: Exception lors du chargement: $e');
      emit(DiscoveryError(message: 'Erreur réseau: $e'));
    }
  }

  Future<void> _loadDailyLimitInBackground() async {
    try {
      final limitEither = await _getDailyLikeLimit();
      _dailyLimit = limitEither.fold((l) => null, (r) => r);

      // Mettre à jour l'état si on est toujours en mode chargé
      if (state is DiscoveryLoaded) {
        add(LoadDailyLimit());
      }
    } catch (e) {
      // Ignorer les erreurs de limite quotidienne pour ne pas bloquer l'UI
      print('Erreur chargement limite quotidienne: $e');
    }
  }

  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<DiscoveryState> emit,
  ) async {
    print(
        '👉 DEBUG DiscoveryBloc: _onSwipeProfile - direction: ${event.direction}');

    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      print('❌ DEBUG DiscoveryBloc: Pas de profil à swiper');
      return;
    }

    final currentProfile = _profiles[_currentIndex];
    print(
        '👉 DEBUG DiscoveryBloc: Swiping profil: ${currentProfile.id} (${currentProfile.displayName})');

    if (event.direction == SwipeDirection.right &&
        _dailyLimit != null &&
        _dailyLimit!.hasReachedLimit) {
      emit(DailyLimitReached(
        previousState: state as DiscoveryLoaded,
        limitInfo: _dailyLimit!,
      ));
      return;
    }

    emit(ProfileSwiping(
      previousState: state as DiscoveryLoaded,
      profile: currentProfile,
      direction: event.direction,
    ));

    final SwipeResult result;

    switch (event.direction) {
      case SwipeDirection.right:
        print('👉 DEBUG DiscoveryBloc: Like profil ${currentProfile.id}');
        final params = LikeProfileParams(profileId: currentProfile.id);
        final either = await _likeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          print('❌ DEBUG DiscoveryBloc: Like failed - ${failure?.toString()}');
          emit(DiscoveryError(
            message: _mapFailureToMessage('Erreur like', failure),
            previousState: _safePreviousState(),
          ));
          return;
        }
        print('✅ DEBUG DiscoveryBloc: Like réussi pour ${currentProfile.id}');
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.left:
        print('👈 DEBUG DiscoveryBloc: Dislike profil ${currentProfile.id}');
        final params = DislikeProfileParams(profileId: currentProfile.id);
        final either = await _dislikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold(
              (l) => l, (r) => const ServerFailure(message: 'Unknown'));
          print(
              '❌ DEBUG DiscoveryBloc: Dislike failed - ${failure.toString()}');
          emit(DiscoveryError(
            message: _mapFailureToMessage('Erreur dislike', failure),
            previousState: _safePreviousState(),
          ));
          return;
        }
        print(
            '✅ DEBUG DiscoveryBloc: Dislike réussi pour ${currentProfile.id}');
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.up:
        // Vérification optionnelle du quota de super likes
        if (_premiumRepository != null) {
          final subscriptionResult =
              await _premiumRepository.getCurrentSubscription();
          await subscriptionResult.fold(
            (failure) {
              // Log l'erreur mais continue (le backend fera la vraie vérification)
              print(
                  '⚠️ DEBUG: Could not check subscription: ${failure.message}');
            },
            (subscription) async {
              if (subscription == null) {
                print('⚠️ DEBUG: No active subscription found');
                emit(DiscoveryError(
                    message:
                        'Vous devez avoir un abonnement actif pour envoyer des Super Likes',
                    previousState: _safePreviousState()));
                return;
              }

              if (!subscription.isActive) {
                print(
                    '⚠️ DEBUG: Subscription is not active: ${subscription.status}');
                emit(DiscoveryError(
                    message:
                        'Votre abonnement n\'est plus actif. Veuillez renouveler votre abonnement.',
                    previousState: _safePreviousState()));
                return;
              }

              final usage = subscription.featuresUsage;
              if (usage != null && usage.superLikesRemaining <= 0) {
                print('⚠️ DEBUG: No super likes remaining');
                emit(DiscoveryError(
                    message:
                        'Vous avez utilisé tous vos Super Likes aujourd\'hui. Ils seront réinitialisés demain.',
                    previousState: _safePreviousState()));
                return;
              }

              print(
                  '✅ DEBUG: Super likes available: ${usage?.superLikesRemaining ?? "unknown"}');
            },
          );

          // Si emit a été appelé (erreur), sortir
          if (state is DiscoveryError) {
            return;
          }
        }

        final params = SuperLikeProfileParams(profileId: currentProfile.id);
        final either = await _superLikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          print(
              '❌ DEBUG DiscoveryBloc: SuperLike failed - ${failure?.toString()}');

          // Message d'erreur plus explicite basé sur le type de failure
          String errorMessage =
              _mapFailureToMessage('Erreur super like', failure);
          if (failure is ServerFailure) {
            if (failure.message.contains('no_active_subscription')) {
              errorMessage =
                  'Vous devez avoir un abonnement actif pour utiliser les Super Likes. '
                  'Veuillez vérifier votre abonnement dans les paramètres.';
            } else if (failure.message.contains('no_super_likes_remaining')) {
              errorMessage =
                  'Vous n\'avez plus de Super Likes disponibles aujourd\'hui. '
                  'Ils seront réinitialisés demain.';
            } else if (failure.message.contains('429') ||
                failure.message.toLowerCase().contains('too many requests')) {
              errorMessage =
                  'Trop de requêtes. Patiente quelques secondes puis réessaie.';
            }
          }

          emit(DiscoveryError(
            message: errorMessage,
            previousState: _safePreviousState(),
          ));
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      default:
        return;
    }

    if (result.isMatch) {
      emit(MatchFound(
        matchedProfile: currentProfile,
        matchId: result.matchId!,
      ));

      await Future.delayed(const Duration(seconds: 3));
    }

    // ✅ IMPORTANT: Retirer le profil immédiatement de la liste pour l'UI
    // Cela évite de reswiper le même profil et de créer des doublons
    _profiles.removeAt(_currentIndex);
    print(
        '🗑️ DEBUG DiscoveryBloc: Profil ${currentProfile.id} retiré de la liste. Reste ${_profiles.length} profils.');

    // Charger plus de profils si on est près de la fin (SANS changer _currentIndex)
    if (_profiles.length <= 2 && _profiles.isNotEmpty) {
      print(
          '📥 DEBUG DiscoveryBloc: Liste faible (${_profiles.length} profils), chargement de plus...');
      _loadMoreProfiles();
    }

    // Mettre à jour la limite quotidienne avec les valeurs du backend
    print(
        '🔍 DEBUG DiscoveryBloc: result.remainingLikes = ${result.remainingLikes}, _dailyLimit = $_dailyLimit');
    if (result.remainingLikes != null) {
      if (_dailyLimit != null) {
        _dailyLimit = _dailyLimit!.copyWith(
          remainingLikes: result.remainingLikes!,
        );
        print(
            '✅ DEBUG DiscoveryBloc: Compteur de likes mis à jour: ${_dailyLimit!.remainingLikes}/${_dailyLimit!.totalLikes}');
      } else {
        print(
            '⚠️ DEBUG DiscoveryBloc: _dailyLimit est null, impossible de mettre à jour le compteur');
      }
    } else {
      print(
          '⚠️ DEBUG DiscoveryBloc: result.remainingLikes est null, le compteur ne sera pas mis à jour');
    }

    _emitLoaded(emit);
  }

  Future<void> _onRewindLastSwipe(
    RewindLastSwipe event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (_currentIndex > 0) {
      final either = await _rewindSwipe(NoParams());
      if (either.isLeft()) {
        final msg = either
            .swap()
            .getOrElse(() => const ServerFailure(message: 'Erreur rewind'))
            .message;
        emit(DiscoveryError(message: msg));
        return;
      }
      _currentIndex--;
      _emitLoaded(emit);
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      print('🔄 DEBUG DiscoveryBloc: Mise à jour des filtres');
      print('   - Âge: ${event.filters.minAge} - ${event.filters.maxAge}');
      print('   - Distance: ${event.filters.maxDistance} km');
      print('   - Genre: ${event.filters.gender}');

      final params = usecases.UpdateFiltersParams(filters: event.filters);
      final either = await _updateFilters(params);
      either.fold(
        (failure) {
          print(
              '❌ DEBUG DiscoveryBloc: Échec mise à jour filtres: ${failure.message}');
          emit(DiscoveryError(message: failure.message));
        },
        (_) {
          print(
              '✅ DEBUG DiscoveryBloc: Filtres mis à jour, rechargement des profils...');
          add(const LoadDiscoveryProfiles());
        },
      );
    } catch (e) {
      print('❌ DEBUG DiscoveryBloc: Exception mise à jour filtres: $e');
      emit(DiscoveryError(message: 'Erreur mise à jour filters'));
    }
  }

  Future<void> _onLoadDailyLimit(
    LoadDailyLimit event,
    Emitter<DiscoveryState> emit,
  ) async {
    final either = await _getDailyLikeLimit();
    _dailyLimit = either.fold((l) => null, (r) => r);
    if (state is DiscoveryLoaded && _dailyLimit != null) {
      _emitLoaded(emit);
    }
  }

  void _emitLoaded(Emitter<DiscoveryState> emit) {
    print(
        '🔄 DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: $_currentIndex, _profiles.length: ${_profiles.length}');

    if (_currentIndex >= _profiles.length) {
      print('ℹ️ DEBUG DiscoveryBloc: NoMoreProfiles émis');
      emit(NoMoreProfiles());
      return;
    }

    print(
        '✅ DEBUG DiscoveryBloc: DiscoveryLoaded émis avec profil: ${_profiles[_currentIndex].displayName}');
    emit(DiscoveryLoaded(
      currentProfile: _profiles[_currentIndex],
      nextProfiles: _profiles.sublist(
        _currentIndex + 1,
        (_currentIndex + 3).clamp(0, _profiles.length),
      ),
      canRewind: _currentIndex > 0,
      dailyLimit: _dailyLimit,
    ));
  }

  Future<void> _onLoadMoreProfiles(
    LoadMoreProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Si limit = 0, c'est juste pour déclencher une mise à jour de l'état
    if (event.limit == 0) {
      if (state is DiscoveryLoaded) {
        _emitLoaded(emit);
      }
      return;
    }

    // Émettre l'état de chargement
    if (state is DiscoveryLoaded) {
      emit(DiscoveryLoadingMore(currentState: state as DiscoveryLoaded));
    }

    try {
      final params = GetDiscoveryProfilesParams(
        limit: event.limit,
        lastProfileId: _profiles.isNotEmpty ? _profiles.last.id : null,
      );
      final result = await _getDiscoveryProfiles(params);
      result.fold(
        (failure) {
          print(
              'Erreur chargement profils supplémentaires: ${failure.message}');
          // Revenir à l'état précédent en cas d'erreur
          if (state is DiscoveryLoadingMore) {
            emit((state as DiscoveryLoadingMore).currentState);
          }
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            _profiles.addAll(newProfilesList);
          }
          // Émettre l'état chargé mis à jour
          _emitLoaded(emit);
        },
      );
    } catch (e) {
      print('Erreur chargement profils supplémentaires: $e');
      // Revenir à l'état précédent en cas d'erreur
      if (state is DiscoveryLoadingMore) {
        emit((state as DiscoveryLoadingMore).currentState);
      }
    }
  }

  Future<void> _loadMoreProfiles() async {
    try {
      final params = GetDiscoveryProfilesParams(
        limit: 20,
        lastProfileId: _profiles.isNotEmpty ? _profiles.last.id : null,
      );
      final result = await _getDiscoveryProfiles(params);
      result.fold(
        (failure) {
          print(
              'Erreur chargement profils supplémentaires: ${failure.message}');
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            // ✅ Éviter les doublons : vérifier que les nouveaux profils ne sont pas déjà dans la liste
            final existingIds = _profiles.map((p) => p.id).toSet();
            final uniqueNewProfiles =
                newProfilesList.where((p) => !existingIds.contains(p.id));

            _profiles.addAll(uniqueNewProfiles);
            print(
                '📥 DEBUG DiscoveryBloc: ${newProfilesList.length} nouveaux profils chargés, ${uniqueNewProfiles.length} ajoutés (${existingIds.length} doublons ignorés). Total: ${_profiles.length}');

            // Émettre un nouvel état si on est toujours en mode chargé
            if (state is DiscoveryLoaded) {
              add(LoadMoreProfiles(
                  limit: 0)); // Événement factice pour déclencher l'émission
            }
          }
        },
      );
    } catch (e) {
      print('Erreur chargement profils supplémentaires: $e');
    }
  }
}

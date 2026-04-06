// lib/presentation/blocs/discovery/discovery_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart' as usecases;
import 'package:hivmeet/domain/usecases/match/get_search_filters.dart';
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import 'dart:async';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';

const bool _enableVerboseLogs = false;

void _debugLog(Object? message) {
  if (_enableVerboseLogs) {
    debugPrint(message?.toString());
  }
}

@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryProfiles _getDiscoveryProfiles;
  final LikeProfile _likeProfile;
  final DislikeProfile _dislikeProfile;
  final SuperLikeProfile _superLikeProfile;
  final RewindSwipe _rewindSwipe;
  final usecases.UpdateFilters _updateFilters;
  final GetSearchFilters _getSearchFilters;
  final GetDailyLikeLimit _getDailyLikeLimit;
  final PremiumRepository? _premiumRepository;

  List<DiscoveryProfile> _profiles = [];
  final Set<String> _swipedProfileIds = {};
  int _currentIndex = 0;
  DailyLikeLimit? _dailyLimit;
  StreamSubscription<String>? _revokeSubscription;
  Timer? _rateLimitTimer;

  DiscoveryLoaded? _safePreviousState() {
    final currentState = state;
    if (currentState is ProfileSwiping) return currentState.previousState;
    if (currentState is DiscoveryLoaded) return currentState;
    if (currentState is DailyLimitReached) return currentState.previousState;
    if (currentState is DiscoveryError) return currentState.previousState;
    return null;
  }

  String _mapFailureToMessage(String prefix, Failure? failure) {
    final rawMessage = failure?.message ?? 'Unknown';
    final lower = rawMessage.toLowerCase();
    if (lower.contains('429') || lower.contains('too many requests')) {
      return 'Trop de requetes. Patiente quelques secondes puis reessaie.';
    }
    return '$prefix: $rawMessage';
  }

  bool _isRateLimitFailure(Failure? failure) {
    final lower = failure?.message.toLowerCase() ?? '';
    return lower.contains('429') || lower.contains('too many requests');
  }

  /// Émet une erreur transitoire avec retour automatique après [seconds] secondes
  /// si [autoDissmiss] est vrai (typiquement pour les erreurs 429).
  void _emitSwipeError(
    Emitter<DiscoveryState> emit,
    String message, {
    bool autoDismiss = false,
  }) {
    emit(DiscoveryError(
      message: message,
      previousState: _safePreviousState(),
    ));
    if (autoDismiss) {
      _rateLimitTimer?.cancel();
      _rateLimitTimer = Timer(const Duration(seconds: 5), () {
        add(const DismissError());
      });
    }
  }

  DiscoveryBloc({
    required GetDiscoveryProfiles getDiscoveryProfiles,
    required LikeProfile likeProfile,
    required DislikeProfile dislikeProfile,
    required SuperLikeProfile superLikeProfile,
    required RewindSwipe rewindSwipe,
    required usecases.UpdateFilters updateFilters,
    required GetSearchFilters getSearchFilters,
    required GetDailyLikeLimit getDailyLikeLimit,
    PremiumRepository? premiumRepository,
  })  : _getDiscoveryProfiles = getDiscoveryProfiles,
        _likeProfile = likeProfile,
        _dislikeProfile = dislikeProfile,
        _superLikeProfile = superLikeProfile,
        _rewindSwipe = rewindSwipe,
        _updateFilters = updateFilters,
        _getSearchFilters = getSearchFilters,
        _getDailyLikeLimit = getDailyLikeLimit,
        _premiumRepository = premiumRepository,
        super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadDiscoveryProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<RewindLastSwipe>(_onRewindLastSwipe);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadDailyLimit>(_onLoadDailyLimit);
    on<LoadMoreProfiles>(_onLoadMoreProfiles);
    on<DismissError>(_onDismissError);

    // Ã‰couter les notifications de rÃ©vocation d'interactions
    _revokeSubscription =
        AppEvents().onInteractionRevoked.listen((profileId) async {
      _debugLog(
          'ðŸ”” DiscoveryBloc: ReÃ§u notification rÃ©vocation profil $profileId');

      // Attendre un peu pour que le backend traite la rÃ©vocation
      _debugLog('â³ DiscoveryBloc: Attente de 500ms avant rechargement...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Recharger les profils avec forceRefresh pour ignorer le cache
      _debugLog('ðŸ”„ DiscoveryBloc: Rechargement forcÃ© des profils');
      add(const LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
    });
  }

  @override
  Future<void> close() {
    _revokeSubscription?.cancel();
    _rateLimitTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadDiscoveryProfiles(
    LoadDiscoveryProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    _debugLog(
        'ðŸ”„ DEBUG DiscoveryBloc: _onLoadDiscoveryProfiles - limit: ${event.limit}');
    emit(DiscoveryLoading());
    _debugLog('ðŸ”„ DEBUG DiscoveryBloc: DiscoveryLoading Ã©mis');

    try {
      _debugLog(
          'ðŸ”„ DEBUG DiscoveryBloc: Appel _getDiscoveryProfiles use case (forceRefresh: ${event.forceRefresh})');
      // Charger les profils en premier (prioritÃ©)
      final params = event.forceRefresh
          ? GetDiscoveryProfilesParams.forceRefresh(limit: event.limit)
          : GetDiscoveryProfilesParams.initial(limit: event.limit);
      final result = await _getDiscoveryProfiles(params);

      result.fold(
        (failure) {
          _debugLog(
              'âŒ DEBUG DiscoveryBloc: Ã‰chec rÃ©cupÃ©ration profils: ${failure.message}');
          emit(DiscoveryError(message: failure.message));
        },
        (profiles) async {
          _debugLog(
              'âœ… DEBUG DiscoveryBloc: Profils rÃ©cupÃ©rÃ©s: ${profiles.length}');
          _profiles = profiles;
          _currentIndex = 0;

          // Ã‰mettre immÃ©diatement l'Ã©tat chargÃ© avec les profils
          _emitLoaded(emit);

          // Note: _dailyLimit est mis à jour directement depuis les réponses
          // de swipe (result.remainingLikes). Pas d'appel API séparé nécessaire.
        },
      );
    } catch (e) {
      _debugLog('âŒ DEBUG DiscoveryBloc: Exception lors du chargement: $e');
      emit(DiscoveryError(message: 'Erreur reseau: $e'));
    }
  }

  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<DiscoveryState> emit,
  ) async {
    _debugLog(
        'ðŸ‘‰ DEBUG DiscoveryBloc: _onSwipeProfile - direction: ${event.direction}');

    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      _debugLog('âŒ DEBUG DiscoveryBloc: Pas de profil Ã  swiper');
      return;
    }

    final currentProfile = _profiles[_currentIndex];
    _debugLog(
        'ðŸ‘‰ DEBUG DiscoveryBloc: Swiping profil: ${currentProfile.id} (${currentProfile.displayName})');

    if (event.direction == SwipeDirection.right &&
        _dailyLimit != null &&
        _dailyLimit!.hasReachedLimit) {
      final previousLoadedState = _safePreviousState();
      if (previousLoadedState == null) return;
      emit(DailyLimitReached(
        previousState: previousLoadedState,
        limitInfo: _dailyLimit!,
      ));
      return;
    }

    final previousLoadedState = _safePreviousState();
    if (previousLoadedState == null) return;

    emit(ProfileSwiping(
      previousState: previousLoadedState,
      profile: currentProfile,
      direction: event.direction,
    ));

    final SwipeResult result;

    switch (event.direction) {
      case SwipeDirection.right:
        _debugLog('ðŸ‘‰ DEBUG DiscoveryBloc: Like profil ${currentProfile.id}');
        final params = LikeProfileParams(profileId: currentProfile.id);
        final either = await _likeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          _debugLog(
              'âŒ DEBUG DiscoveryBloc: Like failed - ${failure?.toString()}');
          _emitSwipeError(
            emit,
            _mapFailureToMessage('Erreur like', failure),
            autoDismiss: _isRateLimitFailure(failure),
          );
          return;
        }
        _debugLog(
            'âœ… DEBUG DiscoveryBloc: Like rÃ©ussi pour ${currentProfile.id}');
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.left:
        _debugLog(
            'ðŸ‘ˆ DEBUG DiscoveryBloc: Dislike profil ${currentProfile.id}');
        final params = DislikeProfileParams(profileId: currentProfile.id);
        final either = await _dislikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold(
              (l) => l, (r) => const ServerFailure(message: 'Unknown'));
          _debugLog(
              'âŒ DEBUG DiscoveryBloc: Dislike failed - ${failure.toString()}');
          _emitSwipeError(
            emit,
            _mapFailureToMessage('Erreur dislike', failure),
            autoDismiss: _isRateLimitFailure(failure),
          );
          return;
        }
        _debugLog(
            'âœ… DEBUG DiscoveryBloc: Dislike rÃ©ussi pour ${currentProfile.id}');
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.up:
        // VÃ©rification optionnelle du quota de super likes
        if (_premiumRepository != null) {
          final subscriptionResult =
              await _premiumRepository.getCurrentSubscription();
          await subscriptionResult.fold(
            (failure) {
              // Log l'erreur mais continue (le backend fera la vraie vÃ©rification)
              _debugLog(
                  'âš ï¸ DEBUG: Could not check subscription: ${failure.message}');
            },
            (subscription) async {
              if (subscription == null) {
                _debugLog('âš ï¸ DEBUG: No active subscription found');
                emit(DiscoveryError(
                    message:
                        'Vous devez avoir un abonnement actif pour envoyer des Super Likes',
                    previousState: _safePreviousState()));
                return;
              }

              if (!subscription.isActive) {
                _debugLog(
                    'âš ï¸ DEBUG: Subscription is not active: ${subscription.status}');
                emit(DiscoveryError(
                    message:
                        'Votre abonnement n\'est plus actif. Veuillez renouveler votre abonnement.',
                    previousState: _safePreviousState()));
                return;
              }

              final usage = subscription.featuresUsage;
              if (usage != null && usage.superLikesRemaining <= 0) {
                _debugLog('âš ï¸ DEBUG: No super likes remaining');
                emit(DiscoveryError(
                    message:
                        'Vous avez utilisÃ© tous vos Super Likes aujourd\'hui. Ils seront rÃ©initialisÃ©s demain.',
                    previousState: _safePreviousState()));
                return;
              }

              _debugLog(
                  'âœ… DEBUG: Super likes available: ${usage?.superLikesRemaining ?? "unknown"}');
            },
          );

          // Si emit a Ã©tÃ© appelÃ© (erreur), sortir
          if (state is DiscoveryError) {
            return;
          }
        }

        final params = SuperLikeProfileParams(profileId: currentProfile.id);
        final either = await _superLikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          _debugLog(
              'âŒ DEBUG DiscoveryBloc: SuperLike failed - ${failure?.toString()}');

          // Message d'erreur plus explicite basÃ© sur le type de failure
          String errorMessage =
              _mapFailureToMessage('Erreur super like', failure);
          if (failure is ServerFailure) {
            if (failure.message.contains('no_active_subscription')) {
              errorMessage =
                  'Vous devez avoir un abonnement actif pour utiliser les Super Likes. '
                  'Veuillez vÃ©rifier votre abonnement dans les paramÃ¨tres.';
            } else if (failure.message.contains('no_super_likes_remaining')) {
              errorMessage =
                  'Vous n\'avez plus de Super Likes disponibles aujourd\'hui. '
                  'Ils seront rÃ©initialisÃ©s demain.';
            } else if (failure.message.contains('429') ||
                failure.message.toLowerCase().contains('too many requests')) {
              errorMessage =
                  'Trop de requÃªtes. Patiente quelques secondes puis rÃ©essaie.';
            }
          }

          final isSuperLikeRateLimit = failure is ServerFailure &&
              (failure.message.contains('429') ||
                  failure.message.toLowerCase().contains('too many requests'));
          _emitSwipeError(emit, errorMessage,
              autoDismiss: isSuperLikeRateLimit);
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

    // Swipe réussi : annuler le timer de rate-limit éventuel
    _rateLimitTimer?.cancel();
    _rateLimitTimer = null;

    // âœ… IMPORTANT: Retirer le profil immÃ©diatement de la liste pour l'UI
    // Cela Ã©vite de reswiper le mÃªme profil et de crÃ©er des doublons
    _swipedProfileIds.add(currentProfile.id);
    _profiles.removeAt(_currentIndex);
    _debugLog(
        'ðŸ—‘ï¸ DEBUG DiscoveryBloc: Profil ${currentProfile.id} retirÃ© de la liste. Reste ${_profiles.length} profils.');

    // Charger plus de profils si on est prÃ¨s de la fin (SANS changer _currentIndex)
    if (_profiles.length <= 2 && _profiles.isNotEmpty) {
      _debugLog(
          'ðŸ“¥ DEBUG DiscoveryBloc: Liste faible (${_profiles.length} profils), chargement de plus...');
      _loadMoreProfiles();
    }

    // Mettre à jour la limite quotidienne avec les valeurs du backend
    _debugLog(
        'DEBUG DiscoveryBloc: result.remainingLikes = ${result.remainingLikes}, _dailyLimit = $_dailyLimit');

    if (_dailyLimit != null) {
      // Valider la valeur retournée par le backend (doit être entre 0 et 10 pour le tier gratuit)
      final bool isValidValue = result.remainingLikes != null &&
          result.remainingLikes! >= 0 &&
          result.remainingLikes! <= 10;

      if (isValidValue) {
        // Valeur valide du backend → utiliser cette valeur
        _dailyLimit = _dailyLimit!.copyWith(
          remainingLikes: result.remainingLikes!,
        );
        _debugLog(
            'DEBUG DiscoveryBloc: Compteur mis à jour depuis backend: ${_dailyLimit!.remainingLikes}/${_dailyLimit!.totalLikes}');
      } else {
        // Valeur invalide ou null du backend → décrémenter localement
        final int newRemaining =
            (_dailyLimit!.remainingLikes - 1).clamp(0, _dailyLimit!.totalLikes);
        _dailyLimit = _dailyLimit!.copyWith(
          remainingLikes: newRemaining,
        );
        _debugLog(
            'DEBUG DiscoveryBloc: Compteur décrémenté localement: ${_dailyLimit!.remainingLikes}/${_dailyLimit!.totalLikes}');
      }
    } else {
      // Première initialisation de _dailyLimit
      // Ne créer _dailyLimit QUE pour les utilisateurs gratuits.
      // Pour les premium, le backend retourne remainingLikes = null ou -1 → on laisse _dailyLimit = null,
      // ce qui empêche l'affichage du compteur dans l'UI (condition: if (state.dailyLimit != null)).
      if (result.remainingLikes != null && result.remainingLikes! >= 0) {
        final int initialRemaining =
            result.remainingLikes! <= 10 ? result.remainingLikes! : 10;

        _dailyLimit = DailyLikeLimit(
          remainingLikes: initialRemaining,
          totalLikes: 10,
          resetAt: DateTime.now().add(const Duration(hours: 24)),
        );
        _debugLog(
            'DEBUG DiscoveryBloc: _dailyLimit initialisé (utilisateur gratuit): ${_dailyLimit!.remainingLikes}/${_dailyLimit!.totalLikes}');
      } else {
        // Utilisateur premium (remainingLikes null ou négatif) → pas de compteur
        _debugLog(
            'DEBUG DiscoveryBloc: Utilisateur premium détecté (remainingLikes=${result.remainingLikes}), compteur désactivé');
      }
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
      _debugLog('ðŸ”„ DEBUG DiscoveryBloc: Mise Ã  jour des filtres');
      _debugLog('   - Ã‚ge: ${event.filters.minAge} - ${event.filters.maxAge}');
      _debugLog('   - Distance: ${event.filters.maxDistance} km');
      _debugLog('   - Genres: ${event.filters.genders}');

      final params = usecases.UpdateFiltersParams(filters: event.filters);
      final either = await _updateFilters(params);
      either.fold(
        (failure) {
          _debugLog(
              'âŒ DEBUG DiscoveryBloc: Ã‰chec mise Ã  jour filtres: ${failure.message}');
          emit(DiscoveryError(message: failure.message));
        },
        (_) {
          _debugLog(
              'âœ… DEBUG DiscoveryBloc: Filtres mis Ã  jour, rechargement des profils...');
          add(const LoadDiscoveryProfiles());
        },
      );
    } catch (e) {
      _debugLog('âŒ DEBUG DiscoveryBloc: Exception mise Ã  jour filtres: $e');
      emit(DiscoveryError(message: 'Erreur mise a jour filters'));
    }
  }

  Future<SearchPreferences> getCurrentSearchFilters() async {
    final result = await _getSearchFilters(NoParams());
    return result.fold(
      (_) => const SearchPreferences(
        minAge: 18,
        maxAge: 99,
        maxDistance: 25,
        interestedIn: <String>[],
        relationshipTypes: <String>[],
        showVerifiedOnly: false,
        showOnlineOnly: false,
      ),
      (filters) => filters,
    );
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
    _debugLog(
        'ðŸ”„ DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: $_currentIndex, _profiles.length: ${_profiles.length}');

    if (_currentIndex >= _profiles.length) {
      _debugLog('â„¹ï¸ DEBUG DiscoveryBloc: NoMoreProfiles Ã©mis');
      emit(NoMoreProfiles());
      return;
    }

    _debugLog(
        'âœ… DEBUG DiscoveryBloc: DiscoveryLoaded Ã©mis avec profil: ${_profiles[_currentIndex].displayName}');
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
    // Si limit = 0, c'est juste pour dÃ©clencher une mise Ã  jour de l'Ã©tat
    if (event.limit == 0) {
      if (state is DiscoveryLoaded) {
        _emitLoaded(emit);
      }
      return;
    }

    // Ã‰mettre l'Ã©tat de chargement
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
          _debugLog(
              'Erreur chargement profils supplÃ©mentaires: ${failure.message}');
          // Revenir Ã  l'Ã©tat prÃ©cÃ©dent en cas d'erreur
          if (state is DiscoveryLoadingMore) {
            emit((state as DiscoveryLoadingMore).currentState);
          }
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            _profiles.addAll(newProfilesList);
          }
          // Ã‰mettre l'Ã©tat chargÃ© mis Ã  jour
          _emitLoaded(emit);
        },
      );
    } catch (e) {
      _debugLog('Erreur chargement profils supplÃ©mentaires: $e');
      // Revenir Ã  l'Ã©tat prÃ©cÃ©dent en cas d'erreur
      if (state is DiscoveryLoadingMore) {
        emit((state as DiscoveryLoadingMore).currentState);
      }
    }
  }

  Future<void> _onDismissError(
    DismissError event,
    Emitter<DiscoveryState> emit,
  ) async {
    _rateLimitTimer?.cancel();
    _rateLimitTimer = null;
    final currentState = state;
    if (currentState is DiscoveryError && currentState.previousState != null) {
      _debugLog(
          'DEBUG DiscoveryBloc: Dismissing error, returning to loaded state');
      emit(currentState.previousState!);
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
          _debugLog(
              'Erreur chargement profils supplÃ©mentaires: ${failure.message}');
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            // âœ… Ã‰viter les doublons : exclure les profils dÃ©jÃ  prÃ©sents ET ceux dÃ©jÃ  swipÃ©s dans cette session
            final existingIds = _profiles.map((p) => p.id).toSet();
            final uniqueNewProfiles = newProfilesList.where((p) =>
                !existingIds.contains(p.id) &&
                !_swipedProfileIds.contains(p.id));

            _profiles.addAll(uniqueNewProfiles);
            _debugLog(
                'ðŸ“¥ DEBUG DiscoveryBloc: ${newProfilesList.length} nouveaux profils chargÃ©s, ${uniqueNewProfiles.length} ajoutÃ©s (${existingIds.length} doublons ignorÃ©s). Total: ${_profiles.length}');

            // Ã‰mettre un nouvel Ã©tat si on est toujours en mode chargÃ©
            if (state is DiscoveryLoaded) {
              add(LoadMoreProfiles(
                  limit:
                      0)); // Ã‰vÃ©nement factice pour dÃ©clencher l'Ã©mission
            }
          }
        },
      );
    } catch (e) {
      _debugLog('Erreur chargement profils supplÃ©mentaires: $e');
    }
  }
}

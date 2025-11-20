// lib/presentation/blocs/discovery/discovery_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart';
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import 'dart:async';
import 'package:hivmeet/core/error/failures.dart';

@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryProfiles _getDiscoveryProfiles;
  final LikeProfile _likeProfile;
  final DislikeProfile _dislikeProfile;
  final SuperLikeProfile _superLikeProfile;
  final RewindSwipe _rewindSwipe;
  final UpdateFilters _updateFilters;
  final GetDailyLikeLimit _getDailyLikeLimit;

  List<DiscoveryProfile> _profiles = [];
  int _currentIndex = 0;
  DailyLikeLimit? _dailyLimit;

  DiscoveryBloc({
    required GetDiscoveryProfiles getDiscoveryProfiles,
    required LikeProfile likeProfile,
    required DislikeProfile dislikeProfile,
    required SuperLikeProfile superLikeProfile,
    required RewindSwipe rewindSwipe,
    required UpdateFilters updateFilters,
    required GetDailyLikeLimit getDailyLikeLimit,
  })  : _getDiscoveryProfiles = getDiscoveryProfiles,
        _likeProfile = likeProfile,
        _dislikeProfile = dislikeProfile,
        _superLikeProfile = superLikeProfile,
        _rewindSwipe = rewindSwipe,
        _updateFilters = updateFilters,
        _getDailyLikeLimit = getDailyLikeLimit,
        super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadDiscoveryProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<RewindLastSwipe>(_onRewindLastSwipe);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadDailyLimit>(_onLoadDailyLimit);
    on<LoadMoreProfiles>(_onLoadMoreProfiles);
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
          '🔄 DEBUG DiscoveryBloc: Appel _getDiscoveryProfiles use case');
      // Charger les profils en premier (priorité)
      final params = GetDiscoveryProfilesParams.initial(limit: event.limit);
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
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) return;

    final currentProfile = _profiles[_currentIndex];

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
        final params = LikeProfileParams(profileId: currentProfile.id);
        final either = await _likeProfile(params);
        if (either.isLeft()) {
          emit(DiscoveryError(message: 'Erreur like'));
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.left:
        final params = DislikeProfileParams(profileId: currentProfile.id);
        final either = await _dislikeProfile(params);
        if (either.isLeft()) {
          emit(DiscoveryError(message: 'Erreur dislike'));
          return;
        }
        result = const SwipeResult(isMatch: false);
        break;
      case SwipeDirection.up:
        final params = SuperLikeProfileParams(profileId: currentProfile.id);
        final either = await _superLikeProfile(params);
        if (either.isLeft()) {
          emit(DiscoveryError(message: 'Erreur super like'));
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

    _currentIndex++;

    if (_currentIndex >= _profiles.length - 2) {
      _loadMoreProfiles();
    }

    // Mettre à jour la limite quotidienne (si disponible via backend)
    if (event.direction == SwipeDirection.right) {
      final limitEither = await _getDailyLikeLimit();
      _dailyLimit = limitEither.fold((l) => _dailyLimit, (r) => r);
    }

    _emitLoaded(emit);
  }

  Future<void> _onRewindLastSwipe(
    RewindLastSwipe event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (_currentIndex > 0) {
      final either = await _rewindSwipe();
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
      final params = UpdateFiltersParams(filters: event.filters);
      final either = await _updateFilters(params);
      either.fold(
        (failure) => emit(DiscoveryError(message: failure.message)),
        (_) => add(const LoadDiscoveryProfiles()),
      );
    } catch (_) {
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
            _profiles.addAll(newProfilesList);
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

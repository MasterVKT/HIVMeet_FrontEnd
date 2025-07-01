// lib/presentation/blocs/discovery/discovery_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final MatchRepository _matchRepository;

  List<DiscoveryProfile> _profiles = [];
  int _currentIndex = 0;
  DailyLikeLimit? _dailyLimit;

  DiscoveryBloc({
    required MatchRepository matchRepository,
  })  : _matchRepository = matchRepository,
        super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadDiscoveryProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<RewindLastSwipe>(_onRewindLastSwipe);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadDailyLimit>(_onLoadDailyLimit);
  }

  Future<void> _onLoadDiscoveryProfiles(
    LoadDiscoveryProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());

    final profilesResult = await _matchRepository.getDiscoveryProfiles(
      limit: event.limit,
    );

    final limitResult = await _matchRepository.getDailyLikeLimit();

    profilesResult.fold(
      (failure) => emit(DiscoveryError(message: failure.message)),
      (profiles) {
        _profiles = profiles;
        _currentIndex = 0;

        limitResult.fold(
          (failure) => _dailyLimit = null,
          (limit) => _dailyLimit = limit,
        );

        _emitLoaded(emit);
      },
    );
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

    final Either<Failure, SwipeResult> result;

    switch (event.direction) {
      case SwipeDirection.right:
        result = await _matchRepository.likeProfile(currentProfile.id);
        break;
      case SwipeDirection.left:
        final dislikeResult =
            await _matchRepository.dislikeProfile(currentProfile.id);
        result = dislikeResult.fold(
          (failure) => Left(failure),
          (_) => const Right(SwipeResult(isMatch: false)),
        );
        break;
      case SwipeDirection.up:
        result = await _matchRepository.superLikeProfile(currentProfile.id);
        break;
      default:
        return;
    }

    result.fold(
      (failure) {
        emit(DiscoveryError(
          message: failure.message,
          previousState: state as DiscoveryLoaded,
        ));
      },
      (swipeResult) async {
        if (swipeResult.isMatch) {
          emit(MatchFound(
            matchedProfile: currentProfile,
            matchId: swipeResult.matchId!,
          ));

          await Future.delayed(const Duration(seconds: 3));
        }

        _currentIndex++;

        if (_currentIndex >= _profiles.length - 2) {
          _loadMoreProfiles();
        }

        // Update daily limit
        if (event.direction == SwipeDirection.right) {
          final limitResult = await _matchRepository.getDailyLikeLimit();
          limitResult.fold(
            (_) => {},
            (limit) => _dailyLimit = limit,
          );
        }

        _emitLoaded(emit);
      },
    );
  }

  Future<void> _onRewindLastSwipe(
    RewindLastSwipe event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (_currentIndex > 0) {
      final result = await _matchRepository.rewindLastSwipe();

      result.fold(
        (failure) => emit(DiscoveryError(
          message: failure.message,
          previousState: state as DiscoveryLoaded,
        )),
        (_) {
          _currentIndex--;
          _emitLoaded(emit);
        },
      );
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<DiscoveryState> emit,
  ) async {
    final result = await _matchRepository.updateSearchFilters(event.filters);

    result.fold(
      (failure) => emit(DiscoveryError(message: failure.message)),
      (_) {
        add(LoadDiscoveryProfiles());
      },
    );
  }

  Future<void> _onLoadDailyLimit(
    LoadDailyLimit event,
    Emitter<DiscoveryState> emit,
  ) async {
    final result = await _matchRepository.getDailyLikeLimit();

    result.fold(
      (_) => {},
      (limit) {
        _dailyLimit = limit;
        if (state is DiscoveryLoaded) {
          _emitLoaded(emit);
        }
      },
    );
  }

  void _emitLoaded(Emitter<DiscoveryState> emit) {
    if (_currentIndex >= _profiles.length) {
      emit(NoMoreProfiles());
      return;
    }

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

  Future<void> _loadMoreProfiles() async {
    final lastId = _profiles.isNotEmpty ? _profiles.last.id : null;
    final result = await _matchRepository.getDiscoveryProfiles(
      lastProfileId: lastId,
    );

    result.fold(
      (_) => {},
      (newProfiles) => _profiles.addAll(newProfiles),
    );
  }
}

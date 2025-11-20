// lib/presentation/blocs/discovery/discovery_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';

abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

class DiscoveryInitial extends DiscoveryState {}

class DiscoveryLoading extends DiscoveryState {}

class DiscoveryLoadingMore extends DiscoveryState {
  final DiscoveryLoaded currentState;

  const DiscoveryLoadingMore({required this.currentState});

  @override
  List<Object> get props => [currentState];
}

class DiscoveryLoaded extends DiscoveryState {
  final DiscoveryProfile currentProfile;
  final List<DiscoveryProfile> nextProfiles;
  final bool canRewind;
  final DailyLikeLimit? dailyLimit;

  const DiscoveryLoaded({
    required this.currentProfile,
    required this.nextProfiles,
    required this.canRewind,
    this.dailyLimit,
  });

  @override
  List<Object?> get props =>
      [currentProfile, nextProfiles, canRewind, dailyLimit];
}

class ProfileSwiping extends DiscoveryState {
  final DiscoveryLoaded previousState;
  final DiscoveryProfile profile;
  final SwipeDirection direction;

  const ProfileSwiping({
    required this.previousState,
    required this.profile,
    required this.direction,
  });

  @override
  List<Object> get props => [previousState, profile, direction];
}

class MatchFound extends DiscoveryState {
  final DiscoveryProfile matchedProfile;
  final String matchId;

  const MatchFound({
    required this.matchedProfile,
    required this.matchId,
  });

  @override
  List<Object> get props => [matchedProfile, matchId];
}

class NoMoreProfiles extends DiscoveryState {}

class DailyLimitReached extends DiscoveryState {
  final DiscoveryLoaded previousState;
  final DailyLikeLimit limitInfo;

  const DailyLimitReached({
    required this.previousState,
    required this.limitInfo,
  });

  @override
  List<Object> get props => [previousState, limitInfo];
}

class DiscoveryError extends DiscoveryState {
  final String message;
  final DiscoveryLoaded? previousState;

  const DiscoveryError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

// lib/presentation/blocs/matches/matches_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';

abstract class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object?> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final List<Match> matches;
  final bool hasMore;
  final bool isLoadingMore;
  final int newMatchesCount;
  final int likesReceivedCount;

  const MatchesLoaded({
    required this.matches,
    required this.hasMore,
    this.isLoadingMore = false,
    this.newMatchesCount = 0,
    this.likesReceivedCount = 0,
  });

  MatchesLoaded copyWith({
    List<Match>? matches,
    bool? hasMore,
    bool? isLoadingMore,
    int? newMatchesCount,
    int? likesReceivedCount,
  }) {
    return MatchesLoaded(
      matches: matches ?? this.matches,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      newMatchesCount: newMatchesCount ?? this.newMatchesCount,
      likesReceivedCount: likesReceivedCount ?? this.likesReceivedCount,
    );
  }

  @override
  List<Object?> get props => [
        matches,
        hasMore,
        isLoadingMore,
        newMatchesCount,
        likesReceivedCount,
      ];
}

class LikesReceivedLoading extends MatchesState {}

class LikesReceivedLoaded extends MatchesState {
  final List<DiscoveryProfile> profiles;
  final bool hasMore;

  const LikesReceivedLoaded({
    required this.profiles,
    required this.hasMore,
  });

  @override
  List<Object> get props => [profiles, hasMore];
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError({required this.message});

  @override
  List<Object> get props => [message];
}
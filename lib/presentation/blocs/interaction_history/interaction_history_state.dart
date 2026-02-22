// lib/presentation/blocs/interaction_history/interaction_history_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';

abstract class InteractionHistoryState extends Equatable {
  const InteractionHistoryState();

  @override
  List<Object?> get props => [];
}

class InteractionHistoryInitial extends InteractionHistoryState {}

// ===== LIKES STATES =====

class LikesLoading extends InteractionHistoryState {}

class LikesLoaded extends InteractionHistoryState {
  final List<InteractionHistory> likes;
  final bool hasMore;
  final bool isLoadingMore;
  final bool includeMatched;

  const LikesLoaded({
    required this.likes,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.includeMatched = false,
  });

  LikesLoaded copyWith({
    List<InteractionHistory>? likes,
    bool? hasMore,
    bool? isLoadingMore,
    bool? includeMatched,
  }) {
    return LikesLoaded(
      likes: likes ?? this.likes,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      includeMatched: includeMatched ?? this.includeMatched,
    );
  }

  @override
  List<Object?> get props => [likes, hasMore, isLoadingMore, includeMatched];
}

// ===== PASSES STATES =====

class PassesLoading extends InteractionHistoryState {}

class PassesLoaded extends InteractionHistoryState {
  final List<InteractionHistory> passes;
  final bool hasMore;
  final bool isLoadingMore;

  const PassesLoaded({
    required this.passes,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PassesLoaded copyWith({
    List<InteractionHistory>? passes,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PassesLoaded(
      passes: passes ?? this.passes,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [passes, hasMore, isLoadingMore];
}

// ===== STATS STATES =====

class StatsLoading extends InteractionHistoryState {}

class StatsLoaded extends InteractionHistoryState {
  final InteractionStats stats;

  const StatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

// ===== ERROR STATE =====

class InteractionHistoryError extends InteractionHistoryState {
  final String message;

  const InteractionHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

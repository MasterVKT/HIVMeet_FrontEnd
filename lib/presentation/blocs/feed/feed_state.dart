// lib/presentation/blocs/feed/feed_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/resource.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<FeedPost> posts;
  final bool hasMore;
  final bool isLoadingMore;

  const FeedLoaded({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  FeedLoaded copyWith({
    List<FeedPost>? posts,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [posts, hasMore, isLoadingMore];
}

class FeedError extends FeedState {
  final String message;

  const FeedError({required this.message});

  @override
  List<Object> get props => [message];
}

// lib/presentation/blocs/feed/feed_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'feed_event.dart';
import 'feed_state.dart';

@injectable
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final ResourceRepository _resourceRepository;
  int _currentPage = 1;

  FeedBloc({
    required ResourceRepository resourceRepository,
  })  : _resourceRepository = resourceRepository,
        super(FeedInitial()) {
    on<LoadFeedPosts>(_onLoadFeedPosts);
    on<LoadMoreFeedPosts>(_onLoadMoreFeedPosts);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);
    on<SharePost>(_onSharePost);
    on<TogglePostLike>(_onTogglePostLike);
    on<ReportPost>(_onReportPost);
  }

  Future<void> _onLoadFeedPosts(
    LoadFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = 1;
    } else {
      emit(FeedLoading());
    }

    final result = await _resourceRepository.getFeedPosts(page: _currentPage);

    result.fold(
      (failure) => emit(FeedError(message: failure.message)),
      (posts) => emit(FeedLoaded(
        posts: posts,
        hasMore: posts.length >= 20,
      )),
    );
  }

  Future<void> _onLoadMoreFeedPosts(
    LoadMoreFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is FeedLoaded && !currentState.isLoadingMore) {
      emit(currentState.copyWith(isLoadingMore: true));

      _currentPage++;
      final result = await _resourceRepository.getFeedPosts(page: _currentPage);

      result.fold(
        (failure) => emit(FeedError(message: failure.message)),
        (newPosts) => emit(FeedLoaded(
          posts: [...currentState.posts, ...newPosts],
          hasMore: newPosts.length >= 20,
          isLoadingMore: false,
        )),
      );
    }
  }

  Future<void> _onLikePost(
    LikePost event,
    Emitter<FeedState> emit,
  ) async {
    await _resourceRepository.likePost(event.postId);
    // Refresh the current posts to reflect the like
    add(const LoadFeedPosts(refresh: true));
  }

  Future<void> _onUnlikePost(
    UnlikePost event,
    Emitter<FeedState> emit,
  ) async {
    await _resourceRepository.unlikePost(event.postId);
    // Refresh the current posts to reflect the unlike
    add(const LoadFeedPosts(refresh: true));
  }

  Future<void> _onSharePost(
    SharePost event,
    Emitter<FeedState> emit,
  ) async {
    // TODO: Implement share functionality
    // This could involve opening native share sheet or copying link
  }

  Future<void> _onTogglePostLike(
    TogglePostLike event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final postIndex =
          currentState.posts.indexWhere((p) => p.id == event.postId);
      if (postIndex != -1) {
        final post = currentState.posts[postIndex];
        if (post.isLikedByCurrentUser) {
          await _resourceRepository.unlikePost(event.postId);
        } else {
          await _resourceRepository.likePost(event.postId);
        }
        // Refresh to get updated like status
        add(const LoadFeedPosts(refresh: true));
      }
    }
  }

  Future<void> _onReportPost(
    ReportPost event,
    Emitter<FeedState> emit,
  ) async {
    await _resourceRepository.reportPost(
      postId: event.postId,
      reason: event.reason,
    );
    // Could show a success message or refresh the posts
  }
}

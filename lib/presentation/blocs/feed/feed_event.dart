// lib/presentation/blocs/feed/feed_event.dart

import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeedPosts extends FeedEvent {
  final bool refresh;

  const LoadFeedPosts({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}

class LoadMoreFeedPosts extends FeedEvent {}

class LikePost extends FeedEvent {
  final String postId;

  const LikePost({required this.postId});

  @override
  List<Object> get props => [postId];
}

class UnlikePost extends FeedEvent {
  final String postId;

  const UnlikePost({required this.postId});

  @override
  List<Object> get props => [postId];
}

class SharePost extends FeedEvent {
  final String postId;

  const SharePost({required this.postId});

  @override
  List<Object> get props => [postId];
}

class TogglePostLike extends FeedEvent {
  final String postId;

  const TogglePostLike({required this.postId});

  @override
  List<Object> get props => [postId];
}

class ReportPost extends FeedEvent {
  final String postId;
  final String reason;

  const ReportPost({required this.postId, required this.reason});

  @override
  List<Object> get props => [postId, reason];
}

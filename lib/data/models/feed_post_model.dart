import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/resource.dart';

part 'feed_post_model.g.dart';

@JsonSerializable()
class FeedPostModel {
  final String id;
  @JsonKey(name: 'author_id')
  final String authorId;
  @JsonKey(name: 'author_name')
  final String authorName;
  @JsonKey(name: 'author_photo_url')
  final String authorPhotoUrl;
  final String content;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final List<String> tags;
  @JsonKey(
      name: 'created_at',
      fromJson: _fromDateTimeString,
      toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(name: 'like_count')
  final int likeCount;
  @JsonKey(name: 'comment_count')
  final int commentCount;
  @JsonKey(name: 'is_liked_by_current_user')
  final bool isLikedByCurrentUser;
  @JsonKey(name: 'allow_comments')
  final bool allowComments;
  @JsonKey(fromJson: _fromStatusString, toJson: _toStatusString)
  final PostStatus status;

  const FeedPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    this.imageUrl,
    required this.tags,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByCurrentUser,
    required this.allowComments,
    required this.status,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) =>
      _$FeedPostModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeedPostModelToJson(this);

  factory FeedPostModel.fromEntity(FeedPost post) {
    return FeedPostModel(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorPhotoUrl: post.authorPhotoUrl,
      content: post.content,
      imageUrl: post.imageUrl,
      tags: post.tags,
      createdAt: post.createdAt,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isLikedByCurrentUser: post.isLikedByCurrentUser,
      allowComments: post.allowComments,
      status: post.status,
    );
  }

  FeedPost toEntity() {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      imageUrl: imageUrl,
      tags: tags,
      createdAt: createdAt,
      likeCount: likeCount,
      commentCount: commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser,
      allowComments: allowComments,
      status: status,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  static String _toDateTimeString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static PostStatus _fromStatusString(String status) {
    switch (status) {
      case 'published':
        return PostStatus.published;
      case 'pending_moderation':
        return PostStatus.pending_moderation;
      case 'rejected':
        return PostStatus.rejected;
      default:
        return PostStatus.pending_moderation;
    }
  }

  static String _toStatusString(PostStatus status) {
    switch (status) {
      case PostStatus.published:
        return 'published';
      case PostStatus.pending_moderation:
        return 'pending_moderation';
      case PostStatus.rejected:
        return 'rejected';
    }
  }
}

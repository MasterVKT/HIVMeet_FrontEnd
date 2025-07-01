import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/resource.dart';

part 'post_comment_model.g.dart';

@JsonSerializable()
class PostCommentModel {
  final String id;
  @JsonKey(name: 'post_id')
  final String postId;
  @JsonKey(name: 'author_id')
  final String authorId;
  @JsonKey(name: 'author_name')
  final String authorName;
  @JsonKey(name: 'author_photo_url')
  final String authorPhotoUrl;
  final String content;
  @JsonKey(
      name: 'created_at',
      fromJson: _fromDateTimeString,
      toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(name: 'is_own_comment')
  final bool isOwnComment;

  const PostCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.isOwnComment,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) =>
      _$PostCommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostCommentModelToJson(this);

  factory PostCommentModel.fromEntity(PostComment comment) {
    return PostCommentModel(
      id: comment.id,
      postId: comment.postId,
      authorId: comment.authorId,
      authorName: comment.authorName,
      authorPhotoUrl: comment.authorPhotoUrl,
      content: comment.content,
      createdAt: comment.createdAt,
      isOwnComment: comment.isOwnComment,
    );
  }

  PostComment toEntity() {
    return PostComment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      createdAt: createdAt,
      isOwnComment: isOwnComment,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  static String _toDateTimeString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostCommentModel _$PostCommentModelFromJson(Map<String, dynamic> json) =>
    PostCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorPhotoUrl: json['author_photo_url'] as String,
      content: json['content'] as String,
      createdAt:
          PostCommentModel._fromDateTimeString(json['created_at'] as String),
      isOwnComment: json['is_own_comment'] as bool,
    );

Map<String, dynamic> _$PostCommentModelToJson(PostCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post_id': instance.postId,
      'author_id': instance.authorId,
      'author_name': instance.authorName,
      'author_photo_url': instance.authorPhotoUrl,
      'content': instance.content,
      'created_at': PostCommentModel._toDateTimeString(instance.createdAt),
      'is_own_comment': instance.isOwnComment,
    };

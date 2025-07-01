// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedPostModel _$FeedPostModelFromJson(Map<String, dynamic> json) =>
    FeedPostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorPhotoUrl: json['author_photo_url'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt:
          FeedPostModel._fromDateTimeString(json['created_at'] as String),
      likeCount: (json['like_count'] as num).toInt(),
      commentCount: (json['comment_count'] as num).toInt(),
      isLikedByCurrentUser: json['is_liked_by_current_user'] as bool,
      allowComments: json['allow_comments'] as bool,
      status: FeedPostModel._fromStatusString(json['status'] as String),
    );

Map<String, dynamic> _$FeedPostModelToJson(FeedPostModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'author_name': instance.authorName,
      'author_photo_url': instance.authorPhotoUrl,
      'content': instance.content,
      'image_url': instance.imageUrl,
      'tags': instance.tags,
      'created_at': FeedPostModel._toDateTimeString(instance.createdAt),
      'like_count': instance.likeCount,
      'comment_count': instance.commentCount,
      'is_liked_by_current_user': instance.isLikedByCurrentUser,
      'allow_comments': instance.allowComments,
      'status': FeedPostModel._toStatusString(instance.status),
    };

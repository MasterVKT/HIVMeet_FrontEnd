// lib/domain/entities/resource.dart

import 'package:equatable/equatable.dart';

class Resource extends Equatable {
  final String id;
  final String title;
  final ResourceType type;
  final String categoryId;
  final String categoryName;
  final List<String> tags;
  final String? thumbnailUrl;
  final DateTime publicationDate;
  final DateTime? lastUpdatedAt;
  final String? authorName;
  final bool isPremium;
  final bool isVerifiedExpert;
  final String language;
  final String content;
  final String? externalLink;
  final int viewCount;
  final bool isFavorite;
  final int? estimatedReadTimeMinutes;
  final List<RelatedResource>? relatedResources;

  const Resource({
    required this.id,
    required this.title,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    this.thumbnailUrl,
    required this.publicationDate,
    this.lastUpdatedAt,
    this.authorName,
    required this.isPremium,
    required this.isVerifiedExpert,
    required this.language,
    required this.content,
    this.externalLink,
    required this.viewCount,
    required this.isFavorite,
    this.estimatedReadTimeMinutes,
    this.relatedResources,
  });

  Resource copyWith({
    bool? isFavorite,
    int? viewCount,
  }) {
    return Resource(
      id: id,
      title: title,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags,
      thumbnailUrl: thumbnailUrl,
      publicationDate: publicationDate,
      lastUpdatedAt: lastUpdatedAt,
      authorName: authorName,
      isPremium: isPremium,
      isVerifiedExpert: isVerifiedExpert,
      language: language,
      content: content,
      externalLink: externalLink,
      viewCount: viewCount ?? this.viewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      estimatedReadTimeMinutes: estimatedReadTimeMinutes,
      relatedResources: relatedResources,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        categoryId,
        categoryName,
        tags,
        thumbnailUrl,
        publicationDate,
        lastUpdatedAt,
        authorName,
        isPremium,
        isVerifiedExpert,
        language,
        content,
        externalLink,
        viewCount,
        isFavorite,
        estimatedReadTimeMinutes,
        relatedResources,
      ];
}

enum ResourceType { article, video, link, contact }

class ResourceCategory extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int resourceCount;
  final bool isPremiumOnly;

  const ResourceCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.resourceCount,
    required this.isPremiumOnly,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        resourceCount,
        isPremiumOnly,
      ];
}

class RelatedResource extends Equatable {
  final String id;
  final String title;
  final String? thumbnailUrl;

  const RelatedResource({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [id, title, thumbnailUrl];
}

// Feed models
class FeedPost extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final String? imageUrl;
  final List<String> tags;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final bool allowComments;
  final PostStatus status;

  const FeedPost({
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

  FeedPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      imageUrl: imageUrl,
      tags: tags,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      allowComments: allowComments,
      status: status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorPhotoUrl,
        content,
        imageUrl,
        tags,
        createdAt,
        likeCount,
        commentCount,
        isLikedByCurrentUser,
        allowComments,
        status,
      ];
}

enum PostStatus { pending_moderation, published, rejected }

class PostComment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final DateTime createdAt;
  final bool isOwnComment;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.isOwnComment,
  });

  @override
  List<Object> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorPhotoUrl,
        content,
        createdAt,
        isOwnComment,
      ];
}
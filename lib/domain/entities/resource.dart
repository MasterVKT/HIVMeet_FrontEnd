// lib/domain/entities/resource.dart

import 'package:equatable/equatable.dart';

class Resource extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final String type; // article, video, etc.
  final String url;
  final bool isPremium;
  final bool isFavorite;
  final List<String> tags;
  final String categoryName;
  final int? estimatedReadTimeMinutes;
  final String? authorName;
  final DateTime publicationDate;
  final bool isVerifiedExpert;
  final String? thumbnailUrl;
  final String? externalLink;
  final List<RelatedResource>? relatedResources;
  final String categoryId;
  final DateTime? lastUpdatedAt;
  final String language;
  final int viewCount;

  const Resource({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.type,
    required this.url,
    this.isPremium = false,
    this.isFavorite = false,
    this.tags = const [],
    required this.categoryName,
    this.estimatedReadTimeMinutes,
    this.authorName,
    required this.publicationDate,
    this.isVerifiedExpert = false,
    this.thumbnailUrl,
    this.externalLink,
    this.relatedResources,
    required this.categoryId,
    this.lastUpdatedAt,
    required this.language,
    required this.viewCount,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      type: json['type'],
      url: json['url'],
      isPremium: json['is_premium'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      categoryName: json['category_name'] ?? '',
      estimatedReadTimeMinutes: json['estimated_read_time_minutes'],
      authorName: json['author_name'],
      publicationDate:
          DateTime.parse(json['publication_date'] ?? DateTime.now().toString()),
      isVerifiedExpert: json['is_verified_expert'] ?? false,
      thumbnailUrl: json['thumbnail_url'],
      externalLink: json['external_link'],
      relatedResources: (json['related_resources'] as List?)
          ?.map((e) => RelatedResource.fromJson(e))
          .toList(),
      categoryId: json['category_id'] ?? '',
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'])
          : null,
      language: json['language'] ?? 'en',
      viewCount: json['view_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'type': type,
      'url': url,
      'is_premium': isPremium,
      'is_favorite': isFavorite,
      'tags': tags,
      'category_name': categoryName,
      'estimated_read_time_minutes': estimatedReadTimeMinutes,
      'author_name': authorName,
      'publication_date': publicationDate.toIso8601String(),
      'is_verified_expert': isVerifiedExpert,
      'thumbnail_url': thumbnailUrl,
      'external_link': externalLink,
      'related_resources': relatedResources?.map((e) => e.toJson()).toList(),
      'category_id': categoryId,
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
      'language': language,
      'view_count': viewCount,
    };
  }

  Resource copyWith({
    bool? isFavorite,
    String? categoryId,
    DateTime? lastUpdatedAt,
    String? language,
    int? viewCount,
    // Ajouter d'autres champs si nécessaire
  }) {
    return Resource(
      id: id,
      title: title,
      content: content,
      category: category,
      type: type,
      url: url,
      isPremium: isPremium,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags,
      categoryName: categoryName,
      estimatedReadTimeMinutes: estimatedReadTimeMinutes,
      authorName: authorName,
      publicationDate: publicationDate,
      isVerifiedExpert: isVerifiedExpert,
      thumbnailUrl: thumbnailUrl,
      externalLink: externalLink,
      relatedResources: relatedResources,
      categoryId: categoryId ?? this.categoryId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      language: language ?? this.language,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        type,
        url,
        isPremium,
        isFavorite,
        tags,
        categoryName,
        estimatedReadTimeMinutes,
        authorName,
        publicationDate,
        isVerifiedExpert,
        thumbnailUrl,
        externalLink,
        relatedResources,
        categoryId,
        lastUpdatedAt,
        language,
        viewCount,
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

  factory RelatedResource.fromJson(Map<String, dynamic> json) {
    return RelatedResource(
      id: json['id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail_url': thumbnailUrl,
    };
  }

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

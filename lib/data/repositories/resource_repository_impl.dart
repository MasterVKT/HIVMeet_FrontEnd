// lib/data/repositories/resource_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/resources_api.dart';
import 'package:hivmeet/data/models/resource_model.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

@LazySingleton(as: ResourceRepository)
class ResourceRepositoryImpl implements ResourceRepository {
  final ResourcesApi _resourcesApi;

  const ResourceRepositoryImpl(this._resourcesApi);

  @override
  Future<Either<Failure, List<Resource>>> getResources({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    List<String>? tags,
    String? searchQuery,
    String? language,
    ResourceType? type,
  }) async {
    try {
      final response = await _resourcesApi.getResources(
        page: page,
        pageSize: pageSize,
        categoryId: categoryId,
        tags: tags,
        searchQuery: searchQuery,
        language: language,
        type: type?.name,
      );

      final resources = (response.data!['data'] as List)
          .map((json) => _mapJsonToResource(json))
          .toList();

      return Right(resources);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Resource>> getResourceDetail(String resourceId) async {
    try {
      final response = await _resourcesApi.getResource(resourceId);
      final resource = _mapJsonToResource(response.data!);
      return Right(resource);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Resource>>> getFavorites({
    int page = 1,
    int pageSize = 20,
    ResourceType? type,
  }) async {
    try {
      final response = await _resourcesApi.getFavorites(
        page: page,
        pageSize: pageSize,
        type: type?.name,
      );

      final resources = (response.data!['data'] as List)
          .map((json) => _mapJsonToResource(json))
          .toList();

      return Right(resources);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FeedPost>>> getFeedPosts({
    int page = 1,
    int pageSize = 20,
    String? categoryFilter,
  }) async {
    try {
      final response = await _resourcesApi.getFeedPosts(
        page: page,
        pageSize: pageSize,
        categoryFilter: categoryFilter,
      );

      final posts = (response.data!['data'] as List)
          .map((json) => _mapJsonToFeedPost(json))
          .toList();

      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FeedPost>> createPost({
    required String content,
    String? imageUrl,
    List<String> tags = const [],
    bool allowComments = true,
  }) async {
    try {
      final response = await _resourcesApi.createPost(
        content: content,
        imageUrl: imageUrl,
        tags: tags,
        allowComments: allowComments,
      );

      final post = _mapJsonToFeedPost(response.data!);
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PostComment>>> getPostComments({
    required String postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _resourcesApi.getPostComments(
        postId: postId,
        page: page,
        pageSize: pageSize,
      );

      final comments = (response.data!['data'] as List)
          .map((json) => _mapJsonToPostComment(json))
          .toList();

      return Right(comments);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostComment>> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final response = await _resourcesApi.addComment(
        postId: postId,
        content: content,
      );

      final comment = _mapJsonToPostComment(response.data!);
      return Right(comment);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ResourceCategory>>> getCategories() async {
    try {
      final response = await _resourcesApi.getCategories();
      final categories = (response.data!['categories'] as List)
          .map((json) => _mapJsonToResourceCategory(json))
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String resourceId) async {
    try {
      await _resourcesApi.markArticleAsRead(articleId: resourceId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addToFavorites(String resourceId) async {
    try {
      await _resourcesApi.addToFavorites(resourceId: resourceId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromFavorites(String resourceId) async {
    try {
      await _resourcesApi.removeFromFavorites(resourceId: resourceId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Resource>>> getRecentlyViewed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response =
          await _resourcesApi.getRecentlyViewed(page: page, limit: limit);
      final resources = (response.data!['resources'] as List)
          .map((json) => ResourceModel.fromJson(json).toEntity())
          .toList();
      return Right(resources);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    try {
      await _resourcesApi.likeFeedPost(postId: postId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    try {
      await _resourcesApi.unlikeFeedPost(postId: postId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      // TODO: Implémenter l'API de signalement
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Méthodes helper pour le mapping
  Resource _mapJsonToResource(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ResourceType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ResourceType.article,
      ),
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnail_url'] as String?,
      publicationDate: DateTime.parse(json['publication_date'] as String),
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : null,
      authorName: json['author_name'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      isVerifiedExpert: json['is_verified_expert'] as bool? ?? false,
      language: json['language'] as String,
      content: json['content'] as String,
      externalLink: json['external_link'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      estimatedReadTimeMinutes: json['estimated_read_time_minutes'] as int?,
    );
  }

  FeedPost _mapJsonToFeedPost(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorPhotoUrl: json['author_photo_url'] as String? ?? '',
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLikedByCurrentUser: json['is_liked_by_current_user'] as bool? ?? false,
      allowComments: json['allow_comments'] as bool? ?? true,
      status: PostStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PostStatus.published,
      ),
    );
  }

  PostComment _mapJsonToPostComment(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorPhotoUrl: json['author_photo_url'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOwnComment: json['is_own_comment'] as bool? ?? false,
    );
  }

  ResourceCategory _mapJsonToResourceCategory(Map<String, dynamic> json) {
    return ResourceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      resourceCount: json['resource_count'] as int? ?? 0,
      isPremiumOnly: json['is_premium_only'] as bool? ?? false,
    );
  }
}

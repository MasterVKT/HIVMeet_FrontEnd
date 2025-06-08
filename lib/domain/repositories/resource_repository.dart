// lib/domain/repositories/resource_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/resource.dart';

abstract class ResourceRepository {
  // Categories
  Future<Either<Failure, List<ResourceCategory>>> getCategories();
  
  // Resources
  Future<Either<Failure, List<Resource>>> getResources({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    List<String>? tags,
    String? searchQuery,
    String? language,
    ResourceType? type,
  });
  
  Future<Either<Failure, Resource>> getResourceDetail(String resourceId);
  
  // Favorites
  Future<Either<Failure, void>> addToFavorites(String resourceId);
  Future<Either<Failure, void>> removeFromFavorites(String resourceId);
  Future<Either<Failure, List<Resource>>> getFavorites({
    int page = 1,
    int pageSize = 20,
    ResourceType? type,
  });
  
  // Feed
  Future<Either<Failure, List<FeedPost>>> getFeedPosts({
    int page = 1,
    int pageSize = 20,
    String? categoryFilter,
  });
  
  Future<Either<Failure, FeedPost>> createPost({
    required String content,
    String? imageUrl,
    List<String> tags = const [],
    bool allowComments = true,
  });
  
  Future<Either<Failure, void>> likePost(String postId);
  Future<Either<Failure, void>> unlikePost(String postId);
  
  Future<Either<Failure, List<PostComment>>> getPostComments({
    required String postId,
    int page = 1,
    int pageSize = 20,
  });
  
  Future<Either<Failure, PostComment>> addComment({
    required String postId,
    required String content,
  });
  
  Future<Either<Failure, void>> reportPost({
    required String postId,
    required String reason,
  });
}
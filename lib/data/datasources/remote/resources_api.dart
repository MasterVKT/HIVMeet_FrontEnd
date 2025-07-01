import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';

@injectable
class ResourcesApi {
  final ApiClient _apiClient;

  const ResourcesApi(this._apiClient);

  /// Liste des ressources avec filtres
  /// GET /resources
  Future<Response<Map<String, dynamic>>> getResources({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    List<String>? tags,
    String? searchQuery,
    String? language,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': pageSize,
    };

    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
    if (searchQuery != null) queryParams['search'] = searchQuery;
    if (language != null) queryParams['language'] = language;
    if (type != null) queryParams['type'] = type;

    return await _apiClient.get('/resources', queryParameters: queryParams);
  }

  /// Détail d'une ressource
  /// GET /resources/{id}
  Future<Response<Map<String, dynamic>>> getResource(String resourceId) async {
    return await _apiClient.get('/resources/$resourceId');
  }

  /// Liste des catégories
  /// GET /resources/categories
  Future<Response<Map<String, dynamic>>> getCategories() async {
    return await _apiClient.get('/resources/categories');
  }

  /// Marquer un article comme lu (analytics)
  /// POST /resources/{article_id}/read
  Future<Response<Map<String, dynamic>>> markArticleAsRead({
    required String articleId,
    int? readingTimeSeconds,
  }) async {
    final data = <String, dynamic>{};

    if (readingTimeSeconds != null) {
      data['reading_time_seconds'] = readingTimeSeconds;
    }

    return await _apiClient.post('/resources/$articleId/read', data: data);
  }

  /// Ajouter aux favoris
  /// POST /resources/{resource_id}/favorite
  Future<Response<Map<String, dynamic>>> addToFavorites({
    required String resourceId,
  }) async {
    return await _apiClient.post('/resources/$resourceId/favorite');
  }

  /// Supprimer des favoris
  /// DELETE /resources/{resource_id}/favorite
  Future<Response<Map<String, dynamic>>> removeFromFavorites({
    required String resourceId,
  }) async {
    return await _apiClient.delete('/resources/$resourceId/favorite');
  }

  /// Liste des favoris
  /// GET /resources/favorites
  Future<Response<Map<String, dynamic>>> getFavorites({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': pageSize,
    };

    if (type != null) queryParams['type'] = type;

    return await _apiClient.get('/resources/favorites',
        queryParameters: queryParams);
  }

  /// Ressources récemment consultées
  /// GET /resources/recently-viewed
  Future<Response<Map<String, dynamic>>> getRecentlyViewed({
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiClient.get('/resources/recently-viewed', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  /// Liste des posts du feed
  /// GET /feed/posts
  Future<Response<Map<String, dynamic>>> getFeedPosts({
    int page = 1,
    int pageSize = 20,
    String? categoryFilter,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': pageSize,
    };

    if (categoryFilter != null) queryParams['category'] = categoryFilter;

    return await _apiClient.get('/feed/posts', queryParameters: queryParams);
  }

  /// Créer un post dans le feed (alias)
  /// POST /feed/posts
  Future<Response<Map<String, dynamic>>> createFeedPost({
    required String content,
    List<String>? tags,
    String? imageUrl,
  }) async {
    return await createPost(
      content: content,
      imageUrl: imageUrl,
      tags: tags ?? [],
      allowComments: true,
    );
  }

  /// Créer un post dans le feed
  /// POST /feed/posts
  Future<Response<Map<String, dynamic>>> createPost({
    required String content,
    String? imageUrl,
    List<String> tags = const [],
    bool allowComments = true,
  }) async {
    final data = <String, dynamic>{
      'content': content,
      'allow_comments': allowComments,
    };

    if (imageUrl != null) data['image_url'] = imageUrl;
    if (tags.isNotEmpty) data['tags'] = tags;

    return await _apiClient.post('/feed/posts', data: data);
  }

  /// Liker un post
  /// POST /feed/posts/{post_id}/like
  Future<Response<Map<String, dynamic>>> likeFeedPost({
    required String postId,
  }) async {
    return await _apiClient.post('/feed/posts/$postId/like');
  }

  /// Supprimer le like d'un post
  /// DELETE /feed/posts/{post_id}/like
  Future<Response<Map<String, dynamic>>> unlikeFeedPost({
    required String postId,
  }) async {
    return await _apiClient.delete('/feed/posts/$postId/like');
  }

  /// Commentaires d'un post
  /// GET /feed/posts/{post_id}/comments
  Future<Response<Map<String, dynamic>>> getPostComments({
    required String postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient
        .get('/feed/posts/$postId/comments', queryParameters: {
      'page': page,
      'limit': pageSize,
    });
  }

  /// Ajouter un commentaire
  /// POST /feed/posts/{post_id}/comments
  Future<Response<Map<String, dynamic>>> addComment({
    required String postId,
    required String content,
  }) async {
    return await _apiClient.post('/feed/posts/$postId/comments', data: {
      'content': content,
    });
  }

  /// Signaler un post
  /// POST /feed/posts/{post_id}/report
  Future<Response<Map<String, dynamic>>> reportFeedPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final data = <String, dynamic>{
      'reason': reason,
    };

    if (details != null) {
      data['details'] = details;
    }

    return await _apiClient.post('/feed/posts/$postId/report', data: data);
  }
}

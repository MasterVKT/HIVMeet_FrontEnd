// lib/data/datasources/remote/resources_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class ResourcesApi {
  final ApiClient _apiClient;

  ResourcesApi(this._apiClient);

  /// Récupérer les ressources
  /// GET /api/v1/content/resources
  Future<Response<Map<String, dynamic>>> getResources({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
    String? language,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (language != null) queryParams['language'] = language;

    return await _apiClient.get('/api/v1/content/resources',
        queryParameters: queryParams);
  }

  /// Récupérer une ressource par ID
  /// GET /api/v1/content/resources/{resource_id}
  Future<Response<Map<String, dynamic>>> getResource(String resourceId) async {
    return await _apiClient.get('/api/v1/content/resources/$resourceId');
  }

  /// Récupérer les catégories de ressources
  /// GET /api/v1/content/resource-categories
  Future<Response<Map<String, dynamic>>> getResourceCategories() async {
    return await _apiClient.get('/api/v1/content/resource-categories');
  }

  /// Marquer une ressource comme favorite
  /// POST /api/v1/content/resources/{resource_id}/favorite
  Future<Response<Map<String, dynamic>>> favoriteResource(
      String resourceId) async {
    return await _apiClient
        .post('/api/v1/content/resources/$resourceId/favorite');
  }

  /// Récupérer les ressources favorites
  /// GET /api/v1/content/favorites
  Future<Response<Map<String, dynamic>>> getFavoriteResources({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient.get('/api/v1/content/favorites', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Récupérer les posts du feed
  /// GET /api/v1/feed/posts
  Future<Response<Map<String, dynamic>>> getFeedPosts({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    return await _apiClient.get('/api/v1/feed/posts',
        queryParameters: queryParams);
  }

  /// Créer un post
  /// POST /api/v1/feed/posts
  Future<Response<Map<String, dynamic>>> createPost({
    required String content,
    String? imageUrl,
    List<String>? tags,
  }) async {
    Map<String, dynamic> data = {
      'content': content,
    };

    if (imageUrl != null) data['image_url'] = imageUrl;
    if (tags != null) data['tags'] = tags;

    return await _apiClient.post('/api/v1/feed/posts', data: data);
  }

  /// Liker un post
  /// POST /api/v1/feed/posts/{post_id}/like
  Future<Response<Map<String, dynamic>>> likePost(String postId) async {
    return await _apiClient.post('/api/v1/feed/posts/$postId/like');
  }

  /// Récupérer les commentaires d'un post
  /// GET /api/v1/feed/posts/{post_id}/comments
  Future<Response<Map<String, dynamic>>> getPostComments(
    String postId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient
        .get('/api/v1/feed/posts/$postId/comments', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Commenter un post
  /// POST /api/v1/feed/posts/{post_id}/comments
  Future<Response<Map<String, dynamic>>> commentPost(
    String postId, {
    required String content,
  }) async {
    return await _apiClient.post('/api/v1/feed/posts/$postId/comments', data: {
      'content': content,
    });
  }

  /// Signaler un post
  /// POST /api/v1/feed/posts/{post_id}/report
  Future<Response<Map<String, dynamic>>> reportPost(
    String postId, {
    required String reason,
    String? description,
  }) async {
    return await _apiClient.post('/api/v1/feed/posts/$postId/report', data: {
      'reason': reason,
      if (description != null) 'description': description,
    });
  }

  /// Ajouter un commentaire à un post
  /// POST /api/v1/feed/posts/{post_id}/comments
  Future<Response<Map<String, dynamic>>> addComment(
    String postId, {
    required String content,
  }) async {
    return await _apiClient.post('/api/v1/feed/posts/$postId/comments', data: {
      'content': content,
    });
  }

  /// Récupérer les catégories de ressources
  /// GET /api/v1/content/categories
  Future<Response<Map<String, dynamic>>> getCategories() async {
    return await _apiClient.get('/api/v1/content/categories');
  }

  /// Marquer un article comme lu
  /// POST /api/v1/content/resources/{resource_id}/read
  Future<Response<Map<String, dynamic>>> markArticleAsRead(
      String resourceId) async {
    return await _apiClient.post('/api/v1/content/resources/$resourceId/read');
  }

  /// Ajouter aux favoris
  /// POST /api/v1/content/resources/{resource_id}/favorite
  Future<Response<Map<String, dynamic>>> addToFavorites(
      String resourceId) async {
    return await _apiClient
        .post('/api/v1/content/resources/$resourceId/favorite');
  }

  /// Retirer des favoris
  /// DELETE /api/v1/content/resources/{resource_id}/favorite
  Future<Response<Map<String, dynamic>>> removeFromFavorites(
      String resourceId) async {
    return await _apiClient
        .delete('/api/v1/content/resources/$resourceId/favorite');
  }

  /// Récupérer les ressources récemment vues
  /// GET /api/v1/content/recently-viewed
  Future<Response<Map<String, dynamic>>> getRecentlyViewed({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient
        .get('/api/v1/content/recently-viewed', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Liker un post du feed
  /// POST /api/v1/feed/posts/{post_id}/like
  Future<Response<Map<String, dynamic>>> likeFeedPost(String postId) async {
    return await _apiClient.post('/api/v1/feed/posts/$postId/like');
  }

  /// Ne plus liker un post du feed
  /// DELETE /api/v1/feed/posts/{post_id}/like
  Future<Response<Map<String, dynamic>>> unlikeFeedPost(String postId) async {
    return await _apiClient.delete('/api/v1/feed/posts/$postId/like');
  }

  /// Liker une ressource
  /// POST /api/v1/content/resources/{resource_id}/like
  Future<Response<Map<String, dynamic>>> likeResource(String resourceId) async {
    return await _apiClient.post('/api/v1/content/resources/$resourceId/like');
  }

  /// Bookmarker une ressource
  /// POST /api/v1/content/resources/{resource_id}/bookmark
  Future<Response<Map<String, dynamic>>> bookmarkResource(
      String resourceId) async {
    return await _apiClient
        .post('/api/v1/content/resources/$resourceId/bookmark');
  }

  /// Partager une ressource
  /// POST /api/v1/content/resources/{resource_id}/share
  Future<Response<Map<String, dynamic>>> shareResource(
    String resourceId, {
    required String platform,
    String? recipientId,
  }) async {
    Map<String, dynamic> data = {
      'platform': platform,
    };
    if (recipientId != null) data['recipient_id'] = recipientId;

    return await _apiClient.post('/api/v1/content/resources/$resourceId/share',
        data: data);
  }

  /// Récupérer les statistiques de lecture
  /// GET /api/v1/content/reading-stats
  Future<Response<Map<String, dynamic>>> getReadingStats() async {
    return await _apiClient.get('/api/v1/content/reading-stats');
  }

  /// Rechercher du contenu
  /// GET /api/v1/content/search
  Future<Response<Map<String, dynamic>>> searchContent({
    required String query,
    String? categoryId,
    String? language,
    int page = 1,
    int perPage = 20,
    String sort = 'relevance',
  }) async {
    Map<String, dynamic> queryParams = {
      'q': query,
      'page': page,
      'per_page': perPage,
      'sort': sort,
    };

    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (language != null) queryParams['language'] = language;

    return await _apiClient.get('/api/v1/content/search',
        queryParameters: queryParams);
  }
}

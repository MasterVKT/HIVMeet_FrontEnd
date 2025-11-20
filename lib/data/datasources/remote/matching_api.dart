// lib/data/datasources/remote/matching_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class MatchingApi {
  final ApiClient _apiClient;

  MatchingApi(this._apiClient);

  /// Récupérer les profils de découverte
  /// GET /api/v1/discovery/profiles
  Future<Response<Map<String, dynamic>>> getDiscoveryProfiles({
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (filters != null) {
      queryParams.addAll(filters);
    }

    return await _apiClient.get('/api/v1/discovery/profiles',
        queryParameters: queryParams);
  }

  /// Mettre à jour les préférences de recherche
  /// PUT /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> updateSearchPreferences({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? relationshipTypes,
    List<String>? interests,
    bool? verifiedOnly,
  }) async {
    Map<String, dynamic> data = {};

    if (minAge != null) data['search_preferences'] = {'min_age': minAge};
    if (maxAge != null) {
      data['search_preferences'] = {
        ...?data['search_preferences'],
        'max_age': maxAge
      };
    }
    if (maxDistance != null) {
      data['search_preferences'] = {
        ...?data['search_preferences'],
        'max_distance': maxDistance
      };
    }
    if (relationshipTypes != null) {
      data['search_preferences'] = {
        ...?data['search_preferences'],
        'relationship_types': relationshipTypes
      };
    }
    if (interests != null) {
      data['search_preferences'] = {
        ...?data['search_preferences'],
        'interests': interests
      };
    }
    if (verifiedOnly != null) {
      data['search_preferences'] = {
        ...?data['search_preferences'],
        'verified_only': verifiedOnly
      };
    }

    return await _apiClient.put('/api/v1/user-profiles/me/', data: data);
  }

  /// Liker un profil
  /// POST /api/v1/discovery/interactions/like
  Future<Response<Map<String, dynamic>>> likeProfile({
    required String profileId,
    String? message,
  }) async {
    return await _apiClient.post('/api/v1/discovery/interactions/like', data: {
      'profile_id': profileId,
      if (message != null) 'message': message,
    });
  }

  /// Disliker un profil
  /// POST /api/v1/discovery/interactions/dislike
  Future<Response<Map<String, dynamic>>> dislikeProfile({
    required String profileId,
    String? reason,
  }) async {
    return await _apiClient
        .post('/api/v1/discovery/interactions/dislike', data: {
      'profile_id': profileId,
      if (reason != null) 'reason': reason,
    });
  }

  /// Super liker un profil
  /// POST /api/v1/discovery/interactions/superlike
  Future<Response<Map<String, dynamic>>> superLikeProfile({
    required String profileId,
    String? message,
  }) async {
    return await _apiClient
        .post('/api/v1/discovery/interactions/superlike', data: {
      'profile_id': profileId,
      if (message != null) 'message': message,
    });
  }

  /// Annuler le dernier swipe
  /// POST /api/v1/discovery/interactions/rewind
  Future<Response<Map<String, dynamic>>> rewindLastSwipe() async {
    return await _apiClient.post('/api/v1/discovery/interactions/rewind');
  }

  /// Récupérer les profils qui m'ont liké
  /// GET /api/v1/discovery/interactions/liked-me
  Future<Response<Map<String, dynamic>>> getLikedMeProfiles({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient
        .get('/api/v1/discovery/interactions/liked-me', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Récupérer les matches
  /// GET /api/v1/matches/
  Future<Response<Map<String, dynamic>>> getMatches({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient.get('/api/v1/matches/', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Récupérer les likes reçus
  /// GET /api/v1/user-profiles/likes-received/
  Future<Response<Map<String, dynamic>>> getLikesReceived({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient
        .get('/api/v1/user-profiles/likes-received/', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
  }

  /// Récupérer le statut premium
  /// GET /api/v1/user-profiles/premium-status/
  Future<Response<Map<String, dynamic>>> getPremiumStatus() async {
    return await _apiClient.get('/api/v1/user-profiles/premium-status/');
  }

  /// Récupérer le profil actuel
  /// GET /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> getCurrentProfile() async {
    return await _apiClient.get('/api/v1/user-profiles/me/');
  }

  /// Activer le boost
  /// POST /api/v1/discovery/boost/activate
  Future<Response<Map<String, dynamic>>> activateBoost() async {
    return await _apiClient.post('/api/v1/discovery/boost/activate');
  }

  /// Récupérer le statut du boost
  /// GET /api/v1/discovery/boost/status
  Future<Response<Map<String, dynamic>>> getBoostStatus() async {
    return await _apiClient.get('/api/v1/discovery/boost/status');
  }

  /// Mettre à jour les filtres de découverte
  /// PUT /api/v1/discovery/filters
  Future<Response<Map<String, dynamic>>> updateDiscoveryFilters({
    int? ageMin,
    int? ageMax,
    int? distanceMaxKm,
    List<String>? genders,
    List<String>? relationshipTypes,
    bool? verifiedOnly,
    bool? onlineOnly,
  }) async {
    Map<String, dynamic> data = {};

    if (ageMin != null) data['age_min'] = ageMin;
    if (ageMax != null) data['age_max'] = ageMax;
    if (distanceMaxKm != null) data['distance_max_km'] = distanceMaxKm;
    if (genders != null) data['genders'] = genders;
    if (relationshipTypes != null) {
      data['relationship_types'] = relationshipTypes;
    }
    if (verifiedOnly != null) data['verified_only'] = verifiedOnly;
    if (onlineOnly != null) data['online_only'] = onlineOnly;

    return await _apiClient.put('/api/v1/discovery/filters', data: data);
  }
}

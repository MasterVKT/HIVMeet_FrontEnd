import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';

@injectable
class MatchingApi {
  final ApiClient _apiClient;

  const MatchingApi(this._apiClient);

  /// Profils à découvrir
  /// GET /discovery/
  Future<Response<Map<String, dynamic>>> getDiscoveryProfiles({
    int page = 1,
    int perPage = 10,
    double? latitude,
    double? longitude,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (latitude != null) queryParams['latitude'] = latitude;
    if (longitude != null) queryParams['longitude'] = longitude;

    return await _apiClient.get('/discovery/', queryParameters: queryParams);
  }

  /// Configuration des filtres de découverte
  /// POST /discovery/filters
  Future<Response<Map<String, dynamic>>> updateDiscoveryFilters({
    required int ageMin,
    required int ageMax,
    required int distanceMaxKm,
    required List<String> genders,
    required List<String> relationshipTypes,
    List<String>? interests,
    bool? verifiedOnly,
    bool? onlineOnly,
  }) async {
    final data = {
      'age_min': ageMin,
      'age_max': ageMax,
      'distance_max_km': distanceMaxKm,
      'genders': genders,
      'relationship_types': relationshipTypes,
    };

    if (interests != null) data['interests'] = interests;
    if (verifiedOnly != null) data['verified_only'] = verifiedOnly;
    if (onlineOnly != null) data['online_only'] = onlineOnly;

    return await _apiClient.post('/discovery/filters', data: data);
  }

  /// Envoyer un like ou dislike
  /// POST /matches/
  Future<Response<Map<String, dynamic>>> sendLike({
    required String targetProfileId,
    required String action, // "like" ou "dislike"
    String likeType = "regular", // "regular" ou "super"
  }) async {
    final data = {
      'target_profile_id': targetProfileId,
      'action': action,
      'like_type': likeType,
    };

    return await _apiClient.post('/matches/', data: data);
  }

  /// Liste des matches
  /// GET /matches/
  Future<Response<Map<String, dynamic>>> getMatches({
    int page = 1,
    int perPage = 20,
    String filter = "all", // "all|new|active"
  }) async {
    return await _apiClient.get('/matches/', queryParameters: {
      'page': page,
      'per_page': perPage,
      'filter': filter,
    });
  }

  /// Super Like
  /// POST /matches/super-like
  Future<Response<Map<String, dynamic>>> sendSuperLike({
    required String targetProfileId,
  }) async {
    final data = {
      'target_profile_id': targetProfileId,
    };

    return await _apiClient.post('/matches/super-like', data: data);
  }

  /// Rewind (Annuler le dernier swipe)
  /// POST /matches/rewind
  Future<Response<Map<String, dynamic>>> rewindLastSwipe() async {
    return await _apiClient.post('/matches/rewind');
  }

  /// Voir qui m'a liké (Premium)
  /// GET /matches/who-liked-me
  Future<Response<Map<String, dynamic>>> getWhoLikedMe({
    int page = 1,
    int perPage = 20,
  }) async {
    return await _apiClient.get('/matches/who-liked-me', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
  }

  /// Rejeter (dislike) un profil
  /// POST /likes/dislike
  Future<Response<Map<String, dynamic>>> sendDislike({
    required String targetProfileId,
    String? reason,
  }) async {
    final data = <String, dynamic>{
      'target_profile_id': targetProfileId,
    };

    if (reason != null) {
      data['reason'] = reason;
    }

    return await _apiClient.post('/likes/dislike', data: data);
  }

  /// Récupérer les likes reçus
  /// GET /likes/received
  Future<Response<Map<String, dynamic>>> getLikesReceived({
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiClient.get('/likes/received', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  /// Récupérer le nombre de likes reçus
  /// GET /likes/received/count
  Future<Response<Map<String, dynamic>>> getLikesReceivedCount() async {
    return await _apiClient.get('/likes/received/count');
  }

  /// Récupérer le statut du boost
  /// GET /matches/boost/status
  Future<Response<Map<String, dynamic>>> getBoostStatus() async {
    return await _apiClient.get('/matches/boost/status');
  }

  /// Mettre à jour les filtres de recherche
  /// PUT /discovery/filters
  Future<Response<Map<String, dynamic>>> updateFilters({
    required int ageMin,
    required int ageMax,
    required int distanceMaxKm,
    required List<String> genders,
    required List<String> relationshipTypes,
  }) async {
    final data = {
      'age_min': ageMin,
      'age_max': ageMax,
      'distance_max_km': distanceMaxKm,
      'genders': genders,
      'relationship_types': relationshipTypes,
    };

    return await _apiClient.put('/discovery/filters', data: data);
  }

  /// Récupérer les filtres actuels
  /// GET /discovery/filters
  Future<Response<Map<String, dynamic>>> getFilters() async {
    return await _apiClient.get('/discovery/filters');
  }

  /// Récupérer la limite quotidienne de likes
  /// GET /likes/daily-limit
  Future<Response<Map<String, dynamic>>> getDailyLikeLimit() async {
    return await _apiClient.get('/likes/daily-limit');
  }

  /// Activer un boost avec durée
  /// POST /matches/boost
  Future<Response<Map<String, dynamic>>> activateBoost(
      {required String duration}) async {
    final data = {
      'duration': duration,
    };
    return await _apiClient.post('/matches/boost', data: data);
  }
}

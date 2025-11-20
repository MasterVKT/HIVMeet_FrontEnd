// lib/data/datasources/remote/profile_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class ProfileApi {
  final ApiClient _apiClient;

  ProfileApi(this._apiClient);

  /// Récupérer un profil par ID
  /// GET /api/v1/user-profiles/{user_id}/
  Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
    return await _apiClient.get('/api/v1/user-profiles/$profileId/');
  }

  /// Récupérer le profil actuel
  /// GET /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> getCurrentProfile() async {
    return await _apiClient.get('/api/v1/user-profiles/me/');
  }

  /// Mettre à jour le profil actuel
  /// PUT /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> updateProfile(
      Map<String, dynamic> profileData) async {
    return await _apiClient.put('/api/v1/user-profiles/me/', data: profileData);
  }

  /// Ajouter une photo au profil
  /// POST /api/v1/user-profiles/me/photos/
  Future<Response<Map<String, dynamic>>> addPhoto(
    String photoPath, {
    bool isMain = false,
    int? order,
  }) async {
    FormData formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoPath),
      'is_main': isMain,
      if (order != null) 'order': order,
    });

    return await _apiClient.post('/api/v1/user-profiles/me/photos/',
        data: formData);
  }

  /// Supprimer une photo du profil
  /// DELETE /api/v1/user-profiles/me/photos/{photo_id}/
  Future<Response<Map<String, dynamic>>> deletePhoto(String photoId) async {
    return await _apiClient.delete('/api/v1/user-profiles/me/photos/$photoId/');
  }

  /// Définir une photo comme principale
  /// PUT /api/v1/user-profiles/me/photos/{photo_id}/set-main/
  Future<Response<Map<String, dynamic>>> setMainPhoto(String photoId) async {
    return await _apiClient
        .put('/api/v1/user-profiles/me/photos/$photoId/set-main/');
  }

  /// Mettre à jour la localisation du profil
  /// PUT /api/v1/user-profiles/me/ (inclut la localisation)
  Future<Response<Map<String, dynamic>>> updateLocation({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    return await _apiClient.put('/api/v1/user-profiles/me/', data: {
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
      }
    });
  }

  /// Récupérer le statut de vérification
  /// GET /api/v1/user-profiles/me/verification/
  Future<Response<Map<String, dynamic>>> getVerificationStatus() async {
    return await _apiClient.get('/api/v1/user-profiles/me/verification/');
  }

  /// Générer une URL d'upload pour la vérification
  /// POST /api/v1/user-profiles/me/verification/generate-upload-url/
  Future<Response<Map<String, dynamic>>> generateVerificationUploadUrl(
      String documentType) async {
    return await _apiClient.post(
        '/api/v1/user-profiles/me/verification/generate-upload-url/',
        data: {'document_type': documentType});
  }

  /// Soumettre des documents de vérification
  /// POST /api/v1/user-profiles/me/verification/submit-documents/
  Future<Response<Map<String, dynamic>>> submitVerificationDocuments({
    required String frontDocumentUrl,
    required String backDocumentUrl,
    String? selfieUrl,
  }) async {
    return await _apiClient
        .post('/api/v1/user-profiles/me/verification/submit-documents/', data: {
      'front_document_url': frontDocumentUrl,
      'back_document_url': backDocumentUrl,
      if (selfieUrl != null) 'selfie_url': selfieUrl,
    });
  }

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
  /// PUT /api/v1/user-profiles/me/ (mise à jour uniquement)
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

  /// Mettre à jour les paramètres de confidentialité
  /// PUT /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> updatePrivacySettings({
    bool? showAge,
    bool? showDistance,
    bool? showOnlineStatus,
    bool? allowMessagesFromNonMatches,
  }) async {
    Map<String, dynamic> data = {};

    if (showAge != null) data['privacy_settings'] = {'show_age': showAge};
    if (showDistance != null) {
      data['privacy_settings'] = {
        ...?data['privacy_settings'],
        'show_distance': showDistance
      };
    }
    if (showOnlineStatus != null) {
      data['privacy_settings'] = {
        ...?data['privacy_settings'],
        'show_online_status': showOnlineStatus
      };
    }
    if (allowMessagesFromNonMatches != null) {
      data['privacy_settings'] = {
        ...?data['privacy_settings'],
        'allow_messages_from_non_matches': allowMessagesFromNonMatches
      };
    }

    return await _apiClient.put('/api/v1/user-profiles/me/', data: data);
  }

  /// Récupérer les profils de découverte avec filtres
  /// GET /api/v1/discovery/profiles
  Future<Response<Map<String, dynamic>>> getDiscoveryProfilesWithFilters({
    int page = 1,
    int pageSize = 20,
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? relationshipTypes,
    List<String>? interests,
    bool? verifiedOnly,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (minAge != null) queryParams['min_age'] = minAge;
    if (maxAge != null) queryParams['max_age'] = maxAge;
    if (maxDistance != null) queryParams['max_distance'] = maxDistance;
    if (relationshipTypes != null) {
      queryParams['relationship_types'] = relationshipTypes.join(',');
    }
    if (interests != null) {
      queryParams['interests'] = interests.join(',');
    }
    if (verifiedOnly != null) queryParams['verified_only'] = verifiedOnly;

    return await _apiClient.get('/api/v1/discovery/profiles',
        queryParameters: queryParams);
  }

  // - deleteProfile() - DELETE /api/v1/user-profiles/me/ n'existe pas
  // - reportProfile() - POST /api/v1/user-profiles/{user_id}/report/ n'existe pas
  // - updatePhoto() - PUT /api/v1/user-profiles/me/photos/{photo_id}/ n'existe pas
}

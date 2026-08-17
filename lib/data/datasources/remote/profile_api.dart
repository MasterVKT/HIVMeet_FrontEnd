// lib/data/datasources/remote/profile_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class ProfileApi {
  final ApiClient _apiClient;

  ProfileApi(this._apiClient);

  /// Récupérer un profil par ID
  /// GET /api/v1/user-profiles/{user_id}/
  Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
    return await _apiClient.get('/user-profiles/$profileId/');
  }

  /// Récupérer le profil actuel
  /// GET /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> getCurrentProfile() async {
    return await _apiClient.get('/user-profiles/me/');
  }

  /// Mettre à jour le profil actuel
  /// PATCH /api/v1/user-profiles/me/
  Future<Response<Map<String, dynamic>>> updateProfile(
      Map<String, dynamic> profileData) async {
    return await _apiClient.patch('/user-profiles/me/', data: profileData);
  }

  /// Ajouter une photo au profil
  /// POST /api/v1/user-profiles/me/photos/
  Future<Response<Map<String, dynamic>>> addPhoto(
    String photoPath, {
    bool isMain = false,
    String? caption,
  }) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photoPath),
      'is_main': isMain,
      if (caption != null) 'caption': caption,
    });

    return await _apiClient.post('/user-profiles/me/photos/', data: formData);
  }

  /// Supprimer une photo du profil
  /// DELETE /api/v1/user-profiles/me/photos/{photo_id}/
  Future<Response<Map<String, dynamic>>> deletePhoto(String photoId) async {
    return await _apiClient.delete('/user-profiles/me/photos/$photoId/');
  }

  /// Définir une photo comme principale
  /// PUT /api/v1/user-profiles/me/photos/{photo_id}/set-main/
  Future<Response<Map<String, dynamic>>> setMainPhoto(String photoId) async {
    return await _apiClient.put('/user-profiles/me/photos/$photoId/set-main/');
  }

  /// Mettre à jour la localisation du profil
  /// PUT /api/v1/user-profiles/me/ (inclut la localisation)
  Future<Response<Map<String, dynamic>>> updateLocation({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    return await _apiClient.patch('/user-profiles/me/', data: {
      'latitude': latitude,
      'longitude': longitude,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    });
  }

  /// Récupérer le statut de vérification
  /// GET /api/v1/user-profiles/me/verification/
  Future<Response<Map<String, dynamic>>> getVerificationStatus() async {
    return await _apiClient.get('/user-profiles/me/verification/');
  }

  /// Générer une URL d'upload pour la vérification
  /// POST /api/v1/user-profiles/me/verification/generate-upload-url/
  Future<Response<Map<String, dynamic>>> generateVerificationUploadUrl({
    required String documentType,
    required String fileType,
    required int fileSize,
  }) async {
    return await _apiClient
        .post('/user-profiles/me/verification/generate-upload-url/', data: {
      'document_type': documentType,
      'file_type': fileType,
      'file_size': fileSize,
    });
  }

  /// Envoyer le fichier vers l'URL Firebase signÃ©e.
  Future<Response<dynamic>> uploadFileToSignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String fileType,
  }) async {
    final dio = Dio();
    return await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {'Content-Type': fileType},
        contentType: fileType,
      ),
    );
  }

  /// Soumettre des documents de vérification
  /// POST /api/v1/user-profiles/me/verification/submit-documents/
  Future<Response<Map<String, dynamic>>> submitVerificationDocuments({
    required List<Map<String, dynamic>> documents,
    required String selfieCodeUsed,
  }) async {
    return await _apiClient
        .post('/user-profiles/me/verification/submit-documents/', data: {
      'documents': documents,
      'selfie_code_used': selfieCodeUsed,
    });
  }

  /// GET /api/v1/user-profiles/premium-status/
  Future<Response<Map<String, dynamic>>> getPremiumStatus() async {
    return await _apiClient.get('/user-profiles/premium-status/');
  }

  Future<Response<Map<String, dynamic>>> getLikesReceived(
      {int page = 1}) async {
    return await _apiClient.get(
      '/user-profiles/likes-received/',
      queryParameters: {'page': page},
    );
  }

  Future<Response<Map<String, dynamic>>> getSuperLikesReceived({
    int page = 1,
  }) async {
    return await _apiClient.get(
      '/user-profiles/super-likes-received/',
      queryParameters: {'page': page},
    );
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

    return await _apiClient.get('/discovery/profiles',
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

    if (minAge != null) data['age_min_preference'] = minAge;
    if (maxAge != null) data['age_max_preference'] = maxAge;
    if (maxDistance != null) data['distance_max_km'] = maxDistance;
    if (relationshipTypes != null) {
      data['relationship_types_sought'] = relationshipTypes;
    }
    if (interests != null) data['interests'] = interests;

    return await _apiClient.patch('/user-profiles/me/', data: data);
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

    if (showDistance != null) data['hide_exact_location'] = !showDistance;
    if (showOnlineStatus != null) {
      data['show_online_status'] = showOnlineStatus;
    }

    return await _apiClient.patch('/user-profiles/me/', data: data);
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

    return await _apiClient.get('/discovery/profiles',
        queryParameters: queryParams);
  }

  // - deleteProfile() - DELETE /api/v1/user-profiles/me/ n'existe pas
  // - reportProfile() - POST /api/v1/user-profiles/{user_id}/report/ n'existe pas
  // - updatePhoto() - PUT /api/v1/user-profiles/me/photos/{photo_id}/ n'existe pas
}

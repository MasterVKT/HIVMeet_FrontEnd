import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';

@injectable
class ProfileApi {
  final ApiClient _apiClient;

  const ProfileApi(this._apiClient);

  /// Récupérer un profil par ID
  /// GET /profiles/{id}
  Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
    return await _apiClient.get('/profiles/$profileId');
  }

  /// Mettre à jour le profil actuel
  /// PUT /profiles/me
  Future<Response<Map<String, dynamic>>> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    return await _apiClient.put('/profiles/me', data: profileData);
  }

  /// Supprimer le profil actuel
  /// DELETE /profiles/me
  Future<Response<Map<String, dynamic>>> deleteProfile() async {
    return await _apiClient.delete('/profiles/me');
  }

  /// Télécharger une photo de profil
  /// POST /profiles/me/photos
  Future<Response<Map<String, dynamic>>> uploadPhoto({
    required String filePath,
    int? order,
  }) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      if (order != null) 'order': order,
    });

    return await _apiClient.post('/profiles/me/photos', data: formData);
  }

  /// Supprimer une photo de profil
  /// DELETE /profiles/me/photos/{photoId}
  Future<Response<Map<String, dynamic>>> deletePhoto(String photoId) async {
    return await _apiClient.delete('/profiles/me/photos/$photoId');
  }

  /// Mettre à jour la localisation
  /// PUT /profiles/me/location
  Future<Response<Map<String, dynamic>>> updateLocation(
    double latitude,
    double longitude,
  ) async {
    return await _apiClient.put('/profiles/me/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Mettre à jour les paramètres de confidentialité
  /// PUT /profiles/me/privacy
  Future<Response<Map<String, dynamic>>> updatePrivacySettings({
    required Map<String, dynamic> settings,
  }) async {
    return await _apiClient.put('/profiles/me/privacy', data: settings);
  }

  /// Soumettre des documents de vérification
  /// POST /verification/submit
  Future<Response<Map<String, dynamic>>> submitVerification({
    required List<String> documents,
  }) async {
    final formData = FormData();

    for (int i = 0; i < documents.length; i++) {
      formData.files.add(MapEntry(
        'documents',
        await MultipartFile.fromFile(documents[i]),
      ));
    }

    return await _apiClient.post('/verification/submit', data: formData);
  }

  /// Récupérer le statut de vérification
  /// GET /verification/status
  Future<Response<Map<String, dynamic>>> getVerificationStatus() async {
    return await _apiClient.get('/verification/status');
  }

  /// Récupérer les profils à proximité
  /// GET /discovery/nearby
  Future<Response<Map<String, dynamic>>> getNearbyProfiles({
    required double latitude,
    required double longitude,
    double radius = 50.0,
    int? minAge,
    int? maxAge,
    String? gender,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'page': page,
      'limit': limit,
    };

    if (minAge != null) queryParams['min_age'] = minAge;
    if (maxAge != null) queryParams['max_age'] = maxAge;
    if (gender != null) queryParams['gender'] = gender;

    return await _apiClient.get('/discovery/nearby',
        queryParameters: queryParams);
  }

  /// Signaler un profil
  /// POST /profiles/{profileId}/report
  Future<Response<Map<String, dynamic>>> reportProfile({
    required String profileId,
    required String reason,
    String? details,
  }) async {
    final data = <String, dynamic>{
      'reason': reason,
    };

    if (details != null) {
      data['details'] = details;
    }

    return await _apiClient.post('/profiles/$profileId/report', data: data);
  }

  /// Bloquer un profil
  /// POST /profiles/{profileId}/block
  Future<Response<Map<String, dynamic>>> blockProfile(String profileId) async {
    return await _apiClient.post('/profiles/$profileId/block');
  }

  /// Débloquer un profil
  /// DELETE /profiles/{profileId}/block
  Future<Response<Map<String, dynamic>>> unblockProfile(
      String profileId) async {
    return await _apiClient.delete('/profiles/$profileId/block');
  }

  /// Récupérer la liste des profils bloqués
  /// GET /profiles/blocked
  Future<Response<Map<String, dynamic>>> getBlockedProfiles() async {
    return await _apiClient.get('/profiles/blocked');
  }

  /// Récupérer le profil actuel
  /// GET /profiles/me
  Future<Response<Map<String, dynamic>>> getCurrentProfile() async {
    return await _apiClient.get('/profiles/me');
  }

  /// Mettre à jour l'ordre des photos
  /// PUT /profiles/me/photos/order
  Future<Response<Map<String, dynamic>>> reorderPhotos({
    required List<String> photoIds,
  }) async {
    return await _apiClient.put('/profiles/me/photos/order', data: {
      'photo_ids': photoIds,
    });
  }

  /// Récupérer les statistiques du profil
  /// GET /profiles/me/stats
  Future<Response<Map<String, dynamic>>> getProfileStats() async {
    return await _apiClient.get('/profiles/me/stats');
  }

  /// Création/Mise à jour du profil
  /// POST /user-profiles/ (création) ou PUT /user-profiles/me (mise à jour)
  Future<Response<Map<String, dynamic>>> createOrUpdateProfile({
    required String bio,
    required String gender,
    required Map<String, dynamic> location,
    required List<String> interests,
    required List<String> relationshipTypesought,
    required Map<String, dynamic> searchPreferences,
    required Map<String, dynamic> visibilitySettings,
  }) async {
    final data = {
      'bio': bio,
      'gender': gender,
      'location': location,
      'interests': interests,
      'relationship_types_sought': relationshipTypesought,
      'search_preferences': searchPreferences,
      'visibility_settings': visibilitySettings,
    };

    return await _apiClient.post('/user-profiles/', data: data);
  }

  // Supprimé pour éviter duplication - utiliser updateProfile avec Map<String, dynamic>

  /// Récupération d'un profil par ID
  /// GET /user-profiles/{profile_id}
  Future<Response<Map<String, dynamic>>> getProfileById(
      String profileId) async {
    return await _apiClient.get('/user-profiles/$profileId');
  }

  // Supprimé pour éviter duplication - utiliser uploadPhoto avec filePath

  /// Mise à jour d'une photo
  /// PUT /user-profiles/photos/{photo_id}
  Future<Response<Map<String, dynamic>>> updatePhoto({
    required String photoId,
    String? caption,
    bool? isMain,
    int? order,
  }) async {
    final data = <String, dynamic>{};
    if (caption != null) data['caption'] = caption;
    if (isMain != null) data['is_main'] = isMain;
    if (order != null) data['order'] = order;

    return await _apiClient.put('/user-profiles/photos/$photoId', data: data);
  }

  /// Demande de vérification
  /// POST /user-profiles/verification/request
  Future<Response<Map<String, dynamic>>> requestVerification() async {
    return await _apiClient.post('/user-profiles/verification/request');
  }

  /// Upload de documents de vérification
  /// POST /user-profiles/verification/upload
  Future<Response<Map<String, dynamic>>> uploadVerificationDocument({
    required String documentType, // "id_document|medical_document|selfie"
    required String filePath,
    required String verificationId,
  }) async {
    final formData = FormData.fromMap({
      'document_type': documentType,
      'file': await MultipartFile.fromFile(filePath),
      'verification_id': verificationId,
    });

    return await _apiClient.post(
      '/user-profiles/verification/upload',
      data: formData,
    );
  }

  /// Mise à jour des préférences de recherche
  /// PUT /user-profiles/search-preferences
  Future<Response<Map<String, dynamic>>> updateSearchPreferences({
    required int ageMin,
    required int ageMax,
    required int distanceMaxKm,
    required List<String> gendersSought,
    required List<String> relationshipTypes,
  }) async {
    final data = {
      'age_min': ageMin,
      'age_max': ageMax,
      'distance_max_km': distanceMaxKm,
      'genders_sought': gendersSought,
      'relationship_types': relationshipTypes,
    };

    return await _apiClient.put('/user-profiles/search-preferences',
        data: data);
  }

  /// Paramètres de visibilité
  /// PUT /user-profiles/visibility-settings
  Future<Response<Map<String, dynamic>>> updateVisibilitySettings({
    required bool isHidden,
    required bool showOnlineStatus,
    required bool allowProfileInDiscovery,
    required bool hideExactLocation,
  }) async {
    final data = {
      'is_hidden': isHidden,
      'show_online_status': showOnlineStatus,
      'allow_profile_in_discovery': allowProfileInDiscovery,
      'hide_exact_location': hideExactLocation,
    };

    return await _apiClient.put('/user-profiles/visibility-settings',
        data: data);
  }

  /// Profils suggérés
  /// GET /user-profiles/suggestions
  Future<Response<Map<String, dynamic>>> getSuggestedProfiles({
    int page = 1,
    int perPage = 20,
  }) async {
    return await _apiClient.get('/user-profiles/suggestions', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
  }

  /// Recherche avancée
  /// GET /user-profiles/search
  Future<Response<Map<String, dynamic>>> searchProfiles({
    int? ageMin,
    int? ageMax,
    int? distanceMax,
    String? interests,
    String? relationshipType,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (ageMin != null) queryParams['age_min'] = ageMin;
    if (ageMax != null) queryParams['age_max'] = ageMax;
    if (distanceMax != null) queryParams['distance_max'] = distanceMax;
    if (interests != null) queryParams['interests'] = interests;
    if (relationshipType != null) {
      queryParams['relationship_type'] = relationshipType;
    }

    return await _apiClient.get('/user-profiles/search',
        queryParameters: queryParams);
  }

  /// Statistiques du profil
  /// GET /user-profiles/statistics
  Future<Response<Map<String, dynamic>>> getProfileStatistics() async {
    return await _apiClient.get('/user-profiles/statistics');
  }
}

// lib/data/datasources/remote/settings_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class SettingsApi {
  final ApiClient _apiClient;

  SettingsApi(this._apiClient);

  /// Récupérer les préférences de notification
  /// GET /api/v1/user-settings/notification-preferences
  Future<Response<Map<String, dynamic>>> getNotificationPreferences() async {
    return await _apiClient.get('/user-settings/notification-preferences');
  }

  /// Mettre à jour les préférences de notification
  /// PUT /api/v1/user-settings/notification-preferences
  Future<Response<Map<String, dynamic>>> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    return await _apiClient.put('/user-settings/notification-preferences',
        data: preferences);
  }

  /// Récupérer les préférences de confidentialité
  /// GET /api/v1/user-settings/privacy-preferences
  Future<Response<Map<String, dynamic>>> getPrivacyPreferences() async {
    return await _apiClient.get('/user-settings/privacy-preferences');
  }

  /// Mettre à jour les préférences de confidentialité
  /// PUT /api/v1/user-settings/privacy-preferences
  Future<Response<Map<String, dynamic>>> updatePrivacyPreferences(
      Map<String, dynamic> preferences) async {
    return await _apiClient.put(
      '/user-settings/privacy-preferences',
      data: preferences,
    );
  }

  /// Récupérer la liste des utilisateurs bloqués
  /// GET /api/v1/user-settings/blocks
  Future<Response<Map<String, dynamic>>> getBlockedUsers() async {
    return await _apiClient.get('/user-settings/blocks');
  }

  /// Bloquer un utilisateur
  /// POST /api/v1/user-settings/blocks/{user_id}
  Future<Response<Map<String, dynamic>>> blockUser(String userId) async {
    return await _apiClient.post('/user-settings/blocks/$userId');
  }

  /// DÃ©bloquer un utilisateur
  /// DELETE /api/v1/user-settings/blocks/{user_id}
  Future<Response<dynamic>> unblockUser(String userId) async {
    return await _apiClient.delete('/user-settings/blocks/$userId');
  }

  /// Demander la suppression du compte
  /// POST /api/v1/user-settings/delete-account
  Future<Response<Map<String, dynamic>>> requestAccountDeletion({
    String? reason,
    String? feedback,
  }) async {
    final data = <String, dynamic>{
      if (reason != null) 'reason': reason,
      if (feedback != null) 'feedback': feedback,
    };
    return await _apiClient.post(
      '/user-settings/delete-account',
      data: data.isEmpty ? null : data,
    );
  }

  /// Exporter les données utilisateur
  /// GET /api/v1/user-settings/export-data
  Future<Response<Map<String, dynamic>>> exportUserData() async {
    return await _apiClient.get('/user-settings/export-data');
  }
}

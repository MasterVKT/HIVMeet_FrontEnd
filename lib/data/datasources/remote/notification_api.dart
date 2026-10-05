import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';

/// Service REST pour les notifications.
///
/// Communique avec les endpoints backend `/api/v1/notifications/` :
/// - GET    /notifications/              — liste paginée
/// - GET    /notifications/unread-count/ — compteur non-lus
/// - PUT    /notifications/<id>/read/   — marquer comme lu
/// - PUT    /notifications/read-all/     — tout marquer comme lu
/// - DELETE /notifications/<id>/delete/ — supprimer une notification
/// - DELETE /notifications/delete-all/   — supprimer toutes les notifications
class NotificationApi {
  final ApiClient _apiClient;
  static final RegExp _canonicalNotificationId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  NotificationApi(this._apiClient);

  /// GET /api/v1/notifications/
  /// Récupère la liste paginée des notifications.
  /// [unreadOnly] filtre pour ne retourner que les non-lues.
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      'notifications/',
      queryParameters: unreadOnly ? {'unread': 'true'} : null,
    );

    final data = response.data;
    if (data == null) return [];

    // La réponse peut être paginée (results) ou une liste simple
    List<dynamic> results;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      return [];
    }

    return results
        .map((e) => AppNotification.fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/notifications/unread-count/
  /// Retourne le nombre de notifications non lues.
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('notifications/unread-count/');
    final data = response.data as Map<String, dynamic>?;
    return data?['unread_count'] as int? ?? 0;
  }

  /// PUT /api/v1/notifications/<id>/read/
  /// Marque une notification comme lue côté backend.
  Future<void> markAsRead(String notificationId) async {
    // Les anciennes versions stockaient des identifiants synthétiques. Ils
    // n'ont jamais correspondu à une ressource REST.
    if (!_canonicalNotificationId.hasMatch(notificationId)) return;
    await _apiClient.put('notifications/$notificationId/read/');
  }

  /// PUT /api/v1/notifications/read-all/
  /// Marque toutes les notifications comme lues côté backend.
  Future<int> markAllAsRead() async {
    final response = await _apiClient.put('notifications/read-all/');
    final data = response.data as Map<String, dynamic>?;
    return data?['marked_read'] as int? ?? 0;
  }

  /// DELETE /api/v1/notifications/<id>/delete/
  /// Supprime une notification côté backend.
  Future<void> deleteNotification(String notificationId) async {
    if (!_canonicalNotificationId.hasMatch(notificationId)) return;
    await _apiClient.delete('notifications/$notificationId/delete/');
  }

  /// DELETE /api/v1/notifications/delete-all/
  /// Supprime toutes les notifications côté backend.
  Future<int> deleteAllNotifications() async {
    final response = await _apiClient.delete('notifications/delete-all/');
    final data = response.data as Map<String, dynamic>?;
    return data?['deleted_count'] as int? ?? 0;
  }
}

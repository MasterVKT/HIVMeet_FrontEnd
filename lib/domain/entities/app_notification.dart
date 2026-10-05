import 'package:equatable/equatable.dart';

enum AppNotificationType {
  newMatch,
  newMessage,
  messageRead,
  like,
  superLike,
  subscriptionExpiring,
  reportResolved,
  system,
}

class AppNotification extends Equatable {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    AppNotificationType parsedType;
    try {
      parsedType = AppNotificationType.values.byName(json['type'] as String);
    } catch (_) {
      parsedType = AppNotificationType.system;
    }
    return AppNotification(
      id: json['id'] as String,
      type: parsedType,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Factory pour parser les réponses du backend (snake_case).
  /// Le backend DRF retourne `created_at` au lieu de `createdAt`
  /// et `is_read` au lieu de `isRead`.
  factory AppNotification.fromBackendJson(Map<String, dynamic> json) {
    final parsedType = _typeFromBackend(json['type'] as String?);
    return AppNotification(
      id: json['id'] as String,
      type: parsedType,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, data, createdAt, isRead];

  /// Mappe le `type` snake_case renvoyé par le backend (`new_match`,
  /// `super_like`, `new_message`, ...) vers [AppNotificationType].
  ///
  /// Ne pas utiliser `AppNotificationType.values.byName(...)` ici : les noms
  /// d'enum Dart sont en camelCase (`newMatch`, `superLike`) alors que le
  /// backend envoie du snake_case — seul `'like'` correspondait par
  /// coïncidence, si bien que toute notification `new_match`/`super_like`/
  /// `new_message` rechargée depuis `GET /notifications/` retombait
  /// silencieusement sur `system` et disparaissait des compteurs qui
  /// filtrent par type (ex. badge Matches).
  static AppNotificationType _typeFromBackend(String? type) {
    switch (type) {
      case 'new_match':
        return AppNotificationType.newMatch;
      case 'new_message':
        return AppNotificationType.newMessage;
      case 'message_read':
        return AppNotificationType.messageRead;
      case 'like':
        return AppNotificationType.like;
      case 'super_like':
        return AppNotificationType.superLike;
      case 'subscription_expiring':
        return AppNotificationType.subscriptionExpiring;
      case 'report_resolved':
        return AppNotificationType.reportResolved;
      default:
        return AppNotificationType.system;
    }
  }
}

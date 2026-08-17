import 'package:equatable/equatable.dart';

enum AppNotificationType {
  newMatch,
  newMessage,
  like,
  superLike,
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

  @override
  List<Object?> get props => [id, type, title, body, data, createdAt, isRead];
}

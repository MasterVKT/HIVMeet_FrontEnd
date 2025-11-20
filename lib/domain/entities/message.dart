// lib/domain/entities/message.dart

import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice, system }

enum MessageStatus { sending, sent, delivered, read, failed }

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;
  final String? mediaUrl;
  final Map<String, String> reactions;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = false,
    this.mediaUrl,
    this.reactions = const {},
    required this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.${json['type'] as String}'),
      createdAt: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool,
      isDelivered: json['is_delivered'] as bool,
      mediaUrl: json['mediaUrl'] as String?,
      reactions: (json['reactions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      status: MessageStatus.values.firstWhere(
          (e) => e.toString() == 'MessageStatus.${json['status'] as String}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_delivered': isDelivered,
      'mediaUrl': mediaUrl,
      'reactions': reactions,
      'status': status.toString().split('.').last,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        type,
        createdAt,
        isRead,
        isDelivered,
        mediaUrl,
        reactions,
        status
      ];
}

class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      participantIds: (json['participant_ids'] as List).cast<String>(),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_ids': participantIds,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, participantIds, lastMessage, unreadCount, updatedAt];
}

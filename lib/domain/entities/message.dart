// lib/domain/entities/message.dart

import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, String> reactions;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.createdAt,
    required this.isRead,
    this.reactions = const {},
    required this.status,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? type,
    String? mediaUrl,
    DateTime? createdAt,
    bool? isRead,
    Map<String, String>? reactions,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        type,
        mediaUrl,
        createdAt,
        isRead,
        reactions,
        status,
      ];
}

enum MessageType { text, image, video, audio }

enum MessageStatus { sending, sent, delivered, read, failed }

class Conversation extends Equatable {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.createdAt,
    this.lastActivityAt,
  });

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessage,
        unreadCounts,
        createdAt,
        lastActivityAt,
      ];
}
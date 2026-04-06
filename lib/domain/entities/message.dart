// lib/domain/entities/message.dart

import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, voice, system, callLog }

enum MessageStatus { sending, sent, delivered, read, failed }

class ParticipantPresence extends Equatable {
  final String userId;
  final bool isOnline;
  final DateTime? lastActive;
  final bool isTyping;

  const ParticipantPresence({
    required this.userId,
    required this.isOnline,
    this.lastActive,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, isOnline, lastActive, isTyping];
}

class MediaUploadTarget extends Equatable {
  final String uploadUrl;
  final String filePathOnStorage;
  final String contentType;
  final int expiresInSeconds;

  const MediaUploadTarget({
    required this.uploadUrl,
    required this.filePathOnStorage,
    required this.contentType,
    required this.expiresInSeconds,
  });

  @override
  List<Object?> get props => [
        uploadUrl,
        filePathOnStorage,
        contentType,
        expiresInSeconds,
      ];
}

class ConversationMessagesPage extends Equatable {
  final List<Message> messages;
  final bool hasMore;
  final bool showPremiumPrompt;

  const ConversationMessagesPage({
    required this.messages,
    required this.hasMore,
    required this.showPremiumPrompt,
  });

  @override
  List<Object?> get props => [messages, hasMore, showPremiumPrompt];
}

class Message extends Equatable {
  final String id;
  final String? clientMessageId;
  final String conversationId;
  final String senderId;
  final bool isMine;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? readAtByRecipient;
  final bool isRead;
  final bool isDelivered;
  final bool isSending;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaThumbnailUrl;
  final Map<String, String> reactions;
  final MessageStatus status;

  const Message({
    required this.id,
    this.clientMessageId,
    required this.conversationId,
    required this.senderId,
    this.isMine = false,
    required this.content,
    required this.type,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.readAtByRecipient,
    this.isRead = false,
    this.isDelivered = false,
    this.isSending = false,
    this.mediaUrl,
    this.mediaType,
    this.mediaThumbnailUrl,
    this.reactions = const {},
    required this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['message_type'] ?? 'text') as String;
    final createdAtSource =
        (json['created_at'] ?? json['sent_at'] ?? json['timestamp']) as String?;

    return Message(
      id: (json['id'] ?? json['message_id']) as String,
      clientMessageId: json['client_message_id'] as String?,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      isMine: json['is_mine'] as bool? ?? false,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.$rawType',
          orElse: () =>
              rawType == 'audio' ? MessageType.audio : MessageType.text),
      createdAt: createdAtSource != null
          ? DateTime.parse(createdAtSource)
          : DateTime.fromMillisecondsSinceEpoch(0),
      sentAt: _dateTimeOrNull(json['sent_at'] as String?),
      deliveredAt: _dateTimeOrNull(json['delivered_at'] as String?),
      readAt: _dateTimeOrNull(json['read_at'] as String?),
      readAtByRecipient:
          _dateTimeOrNull(json['read_at_by_recipient'] as String?),
      isRead: (json['is_read'] as bool?) ??
          ((json['read_at'] ?? json['read_at_by_recipient']) != null),
      isDelivered:
          (json['is_delivered'] as bool?) ?? (json['delivered_at'] != null),
      isSending: json['is_sending'] as bool? ?? false,
      mediaUrl: (json['mediaUrl'] ?? json['media_url']) as String?,
      mediaType: json['media_type'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
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
      'message_id': id,
      'client_message_id': clientMessageId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'is_mine': isMine,
      'content': content,
      'type': type.toString().split('.').last,
      'message_type': type.toString().split('.').last,
      'timestamp': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'read_at_by_recipient': readAtByRecipient?.toIso8601String(),
      'is_read': isRead,
      'is_delivered': isDelivered,
      'is_sending': isSending,
      'mediaUrl': mediaUrl,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'media_thumbnail_url': mediaThumbnailUrl,
      'reactions': reactions,
      'status': status.toString().split('.').last,
    };
  }

  static DateTime? _dateTimeOrNull(String? value) {
    return value == null || value.isEmpty ? null : DateTime.parse(value);
  }

  /// Crée une copie de ce message avec les champs optionnels remplacés
  Message copyWith({
    String? id,
    String? clientMessageId,
    String? conversationId,
    String? senderId,
    bool? isMine,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? readAtByRecipient,
    bool? isRead,
    bool? isDelivered,
    bool? isSending,
    String? mediaUrl,
    String? mediaType,
    String? mediaThumbnailUrl,
    Map<String, String>? reactions,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      isMine: isMine ?? this.isMine,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      readAtByRecipient: readAtByRecipient ?? this.readAtByRecipient,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isSending: isSending ?? this.isSending,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientMessageId,
        conversationId,
        senderId,
        isMine,
        content,
        type,
        createdAt,
        sentAt,
        deliveredAt,
        readAt,
        readAtByRecipient,
        isRead,
        isDelivered,
        isSending,
        mediaUrl,
        mediaType,
        mediaThumbnailUrl,
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
  final DateTime? lastActivityAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.lastActivityAt,
  });

  static DateTime? _dateTimeOrNull(String? value) {
    return value == null || value.isEmpty ? null : DateTime.parse(value);
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      participantIds: (json['participant_ids'] as List).cast<String>(),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount:
          (json['unread_count'] ?? json['unread_count_for_me'] ?? 0) as int,
      updatedAt: DateTime.parse(
        (json['updated_at'] ??
            json['last_message_at'] ??
            json['last_activity_at']) as String,
      ),
      lastActivityAt: _dateTimeOrNull(json['last_activity_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_ids': participantIds,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, participantIds, lastMessage, unreadCount, updatedAt, lastActivityAt];
}

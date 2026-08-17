// lib/domain/entities/message.dart

import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, voice, system, callLog }

enum MessageStatus { sending, sent, delivered, read, failed }

/// Filtre de conversations accepté par l'API.
///
/// Garder la conversion HTTP ici évite de propager des chaînes libres entre la
/// présentation, le domaine et la datasource.
enum ConversationFilter {
  all,
  unread,
  archived;

  String get apiValue => switch (this) {
        ConversationFilter.all => 'all',
        ConversationFilter.unread => 'unread',
        ConversationFilter.archived => 'archived',
      };
}

/// Résultat autoritatif du marquage comme lu retourné par le backend.
class MarkAsReadResult extends Equatable {
  final int messagesMarked;
  final int unreadCountForMe;
  final DateTime? readAt;

  const MarkAsReadResult({
    required this.messagesMarked,
    required this.unreadCountForMe,
    this.readAt,
  });

  @override
  List<Object?> get props => [messagesMarked, unreadCountForMe, readAt];
}

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

/// Page de résultats pour `getConversations`.
///
/// [hasMore] est dérivé du champ DRF `next` (page-based pagination réelle
/// côté backend), pas d'une heuristique sur la taille de la liste.
class ConversationListPage extends Equatable {
  final List<Conversation> conversations;
  final bool hasMore;

  const ConversationListPage({
    required this.conversations,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [conversations, hasMore];
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
      content: (json['content'] ?? json['content_preview'] ?? '') as String,
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
        (e) => e.toString() == 'MessageStatus.${json['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
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
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final bool isOnline;
  final DateTime? lastActive;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.isOnline = false,
    this.lastActive,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.lastActivityAt,
  });

  static DateTime? _dateTimeOrNull(String? value) {
    return value == null || value.isEmpty ? null : DateTime.parse(value);
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final otherUser = json['other_user'] is Map<String, dynamic>
        ? json['other_user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final otherUserId = otherUser['user_id'] as String?;
    final participantIds = json['participant_ids'] is List
        ? (json['participant_ids'] as List).whereType<String>().toList()
        : otherUserId == null || otherUserId.isEmpty
            ? const <String>[]
            : <String>[otherUserId];

    return Conversation(
      id: (json['conversation_id'] ?? json['id']) as String,
      participantIds: participantIds,
      otherUserId: otherUserId,
      otherUserName: otherUser['display_name'] as String?,
      otherUserPhotoUrl: otherUser['main_photo_url'] as String?,
      isOnline: otherUser['is_online'] as bool? ?? false,
      lastActive: _dateTimeOrNull(otherUser['last_active'] as String?),
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
      'conversation_id': id,
      'participant_ids': participantIds,
      'other_user': {
        'user_id': otherUserId,
        'display_name': otherUserName,
        'main_photo_url': otherUserPhotoUrl,
        'is_online': isOnline,
        'last_active': lastActive?.toIso8601String(),
      },
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'unread_count_for_me': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
    };
  }

  /// Crée une copie de cette conversation avec les champs optionnels remplacés.
  ///
  /// Toujours utiliser cette méthode pour les mises à jour partielles (ex:
  /// marquer comme lu) plutôt que de reconstruire l'entité manuellement —
  /// reconstruire à la main a déjà causé la perte silencieuse de
  /// otherUserName/otherUserPhotoUrl/isOnline/lastActive par le passé.
  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    Object? otherUserId = _conversationUnset,
    Object? otherUserName = _conversationUnset,
    Object? otherUserPhotoUrl = _conversationUnset,
    bool? isOnline,
    Object? lastActive = _conversationUnset,
    Object? lastMessage = _conversationUnset,
    int? unreadCount,
    DateTime? updatedAt,
    Object? lastActivityAt = _conversationUnset,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      otherUserId: identical(otherUserId, _conversationUnset)
          ? this.otherUserId
          : otherUserId as String?,
      otherUserName: identical(otherUserName, _conversationUnset)
          ? this.otherUserName
          : otherUserName as String?,
      otherUserPhotoUrl: identical(otherUserPhotoUrl, _conversationUnset)
          ? this.otherUserPhotoUrl
          : otherUserPhotoUrl as String?,
      isOnline: isOnline ?? this.isOnline,
      lastActive: identical(lastActive, _conversationUnset)
          ? this.lastActive
          : lastActive as DateTime?,
      lastMessage: identical(lastMessage, _conversationUnset)
          ? this.lastMessage
          : lastMessage as Message?,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: identical(lastActivityAt, _conversationUnset)
          ? this.lastActivityAt
          : lastActivityAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        otherUserId,
        otherUserName,
        otherUserPhotoUrl,
        isOnline,
        lastActive,
        lastMessage,
        unreadCount,
        updatedAt,
        lastActivityAt,
      ];
}

const Object _conversationUnset = Object();

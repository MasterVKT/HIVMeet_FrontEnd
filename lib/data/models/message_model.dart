import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/message.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;
  @JsonKey(name: 'client_message_id')
  final String? clientMessageId;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'is_mine')
  final bool isMine;
  final String content;
  @JsonKey(
    name: 'message_type',
    fromJson: _messageTypeFromString,
    toJson: _messageTypeToString,
  )
  final MessageType type;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'media_type')
  final String? mediaType;
  @JsonKey(name: 'media_thumbnail_url')
  final String? mediaThumbnailUrl;
  @JsonKey(name: 'created_at', fromJson: _fromDateTimeString, toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(name: 'sent_at', fromJson: _fromDateTimeStringNullable, toJson: _toDateTimeStringNullable)
  final DateTime? sentAt;
  @JsonKey(name: 'delivered_at', fromJson: _fromDateTimeStringNullable, toJson: _toDateTimeStringNullable)
  final DateTime? deliveredAt;
  @JsonKey(name: 'read_at', fromJson: _fromDateTimeStringNullable, toJson: _toDateTimeStringNullable)
  final DateTime? readAt;
  @JsonKey(name: 'read_at_by_recipient', fromJson: _fromDateTimeStringNullable, toJson: _toDateTimeStringNullable)
  final DateTime? readAtByRecipient;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'is_delivered')
  final bool isDelivered;
  @JsonKey(name: 'is_sending')
  final bool isSending;
  @JsonKey(name: 'reactions')
  final Map<String, String> reactions;
  @JsonKey(
    name: 'status',
    fromJson: _messageStatusFromString,
    toJson: _messageStatusToString,
  )
  final MessageStatus status;

  const MessageModel({
    required this.id,
    this.clientMessageId,
    required this.conversationId,
    required this.senderId,
    this.isMine = false,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.mediaType,
    this.mediaThumbnailUrl,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.readAtByRecipient,
    required this.isRead,
    this.isDelivered = false,
    this.isSending = false,
    this.reactions = const {},
    required this.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      clientMessageId: message.clientMessageId,
      conversationId: message.conversationId,
      senderId: message.senderId,
      isMine: message.isMine,
      content: message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
      mediaType: message.mediaType,
      mediaThumbnailUrl: message.mediaThumbnailUrl,
      createdAt: message.createdAt,
      sentAt: message.sentAt,
      deliveredAt: message.deliveredAt,
      readAt: message.readAt,
      readAtByRecipient: message.readAtByRecipient,
      isRead: message.isRead,
      isDelivered: message.isDelivered,
      isSending: message.isSending,
      reactions: message.reactions,
      status: message.status,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      senderId: senderId,
      isMine: isMine,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaThumbnailUrl: mediaThumbnailUrl,
      createdAt: createdAt,
      sentAt: sentAt,
      deliveredAt: deliveredAt,
      readAt: readAt,
      readAtByRecipient: readAtByRecipient,
      isRead: isRead,
      isDelivered: isDelivered,
      isSending: isSending,
      reactions: reactions,
      status: status,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) => DateTime.parse(dateTimeString);

  static String _toDateTimeString(DateTime dateTime) => dateTime.toIso8601String();

  static DateTime? _fromDateTimeStringNullable(String? dateTimeString) {
    return dateTimeString == null || dateTimeString.isEmpty ? null : DateTime.parse(dateTimeString);
  }

  static String? _toDateTimeStringNullable(DateTime? dateTime) => dateTime?.toIso8601String();

  static MessageType _messageTypeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'voice':
        return MessageType.voice;
      case 'call_log':
        return MessageType.callLog;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
        return 'audio';
      case MessageType.voice:
        return 'voice';
      case MessageType.callLog:
        return 'call_log';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageStatus _messageStatusFromString(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }
}

@JsonSerializable()
class ConversationModel {
  final String id;
  final List<String> participants;
  @JsonKey(name: 'last_message')
  final MessageModel? lastMessage;
  @JsonKey(name: 'unread_counts')
  final Map<String, int> unreadCounts;
  @JsonKey(name: 'created_at', fromJson: _fromDateTimeString, toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(name: 'last_activity_at', fromJson: _fromDateTimeStringNullable, toJson: _toDateTimeStringNullable)
  final DateTime? lastActivityAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      participants: conversation.participantIds,
      lastMessage: conversation.lastMessage != null ? MessageModel.fromEntity(conversation.lastMessage!) : null,
      unreadCounts: <String, int>{'current_user': conversation.unreadCount},
      createdAt: conversation.updatedAt,
      lastActivityAt: conversation.lastActivityAt,
    );
  }

  Conversation toEntity() {
    return Conversation(
      id: id,
      participantIds: participants,
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCounts.values.fold<int>(0, (sum, count) => sum + count),
      updatedAt: lastActivityAt ?? createdAt,
      lastActivityAt: lastActivityAt,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) => DateTime.parse(dateTimeString);

  static String _toDateTimeString(DateTime dateTime) => dateTime.toIso8601String();

  static DateTime? _fromDateTimeStringNullable(String? dateTimeString) {
    return dateTimeString == null || dateTimeString.isEmpty ? null : DateTime.parse(dateTimeString);
  }

  static String? _toDateTimeStringNullable(DateTime? dateTime) => dateTime?.toIso8601String();
}

import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/message.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(
      name: 'message_type',
      fromJson: _messageTypeFromString,
      toJson: _messageTypeToString)
  final MessageType type;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(
      name: 'created_at',
      fromJson: _fromDateTimeString,
      toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'reactions')
  final Map<String, String> reactions;
  @JsonKey(
      name: 'status',
      fromJson: _messageStatusFromString,
      toJson: _messageStatusToString)
  final MessageStatus status;

  const MessageModel({
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

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
      createdAt: message.createdAt,
      isRead: message.isRead,
      reactions: message.reactions,
      status: message.status,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      createdAt: createdAt,
      isRead: isRead,
      reactions: reactions,
      status: status,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  static String _toDateTimeString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static MessageType _messageTypeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
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
      case MessageType.voice:
        return 'voice';
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
  @JsonKey(
      name: 'created_at',
      fromJson: _fromDateTimeString,
      toJson: _toDateTimeString)
  final DateTime createdAt;
  @JsonKey(
      name: 'last_activity_at',
      fromJson: _fromDateTimeStringNullable,
      toJson: _toDateTimeStringNullable)
  final DateTime? lastActivityAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      participants: conversation.participantIds,
      lastMessage: conversation.lastMessage != null
          ? MessageModel.fromEntity(conversation.lastMessage!)
          : null,
      unreadCounts: {
        'current_user': conversation.unreadCount
      }, // Mapper int vers Map
      createdAt: conversation.updatedAt, // Mapper updatedAt vers createdAt
      lastActivityAt: conversation.updatedAt, // Mapper depuis updatedAt
    );
  }

  Conversation toEntity() {
    return Conversation(
      id: id,
      participantIds: participants,
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCounts.values.fold(0, (a, b) => a + b),
      updatedAt: lastActivityAt ?? createdAt,
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  static String _toDateTimeString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static DateTime? _fromDateTimeStringNullable(String? dateTimeString) {
    return dateTimeString != null ? DateTime.parse(dateTimeString) : null;
  }

  static String? _toDateTimeStringNullable(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

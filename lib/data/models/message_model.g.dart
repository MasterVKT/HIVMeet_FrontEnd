// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: MessageModel._messageTypeFromString(json['message_type'] as String),
      mediaUrl: json['media_url'] as String?,
      createdAt: MessageModel._fromDateTimeString(json['created_at'] as String),
      isRead: json['is_read'] as bool,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      status: MessageModel._messageStatusFromString(json['status'] as String),
    );

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'message_type': MessageModel._messageTypeToString(instance.type),
      'media_url': instance.mediaUrl,
      'created_at': MessageModel._toDateTimeString(instance.createdAt),
      'is_read': instance.isRead,
      'reactions': instance.reactions,
      'status': MessageModel._messageStatusToString(instance.status),
    };

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    ConversationModel(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['last_message'] == null
          ? null
          : MessageModel.fromJson(json['last_message'] as Map<String, dynamic>),
      unreadCounts: Map<String, int>.from(json['unread_counts'] as Map),
      createdAt:
          ConversationModel._fromDateTimeString(json['created_at'] as String),
      lastActivityAt: ConversationModel._fromDateTimeStringNullable(
          json['last_activity_at'] as String?),
    );

Map<String, dynamic> _$ConversationModelToJson(ConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'last_message': instance.lastMessage,
      'unread_counts': instance.unreadCounts,
      'created_at': ConversationModel._toDateTimeString(instance.createdAt),
      'last_activity_at':
          ConversationModel._toDateTimeStringNullable(instance.lastActivityAt),
    };

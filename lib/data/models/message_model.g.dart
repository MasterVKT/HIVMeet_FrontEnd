// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
      id: json['id'] as String,
      clientMessageId: json['client_message_id'] as String?,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      isMine: json['is_mine'] as bool? ?? false,
      content: json['content'] as String,
      type: MessageModel._messageTypeFromString(json['message_type'] as String),
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      createdAt: MessageModel._fromDateTimeString(json['created_at'] as String),
      sentAt:
          MessageModel._fromDateTimeStringNullable(json['sent_at'] as String?),
      deliveredAt: MessageModel._fromDateTimeStringNullable(
          json['delivered_at'] as String?),
      readAt:
          MessageModel._fromDateTimeStringNullable(json['read_at'] as String?),
      readAtByRecipient: MessageModel._fromDateTimeStringNullable(
          json['read_at_by_recipient'] as String?),
      isRead: json['is_read'] as bool,
      isDelivered: json['is_delivered'] as bool? ?? false,
      isSending: json['is_sending'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      status: MessageModel._messageStatusFromString(json['status'] as String),
    );

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_message_id': instance.clientMessageId,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'is_mine': instance.isMine,
      'content': instance.content,
      'message_type': MessageModel._messageTypeToString(instance.type),
      'media_url': instance.mediaUrl,
      'media_type': instance.mediaType,
      'media_thumbnail_url': instance.mediaThumbnailUrl,
      'created_at': MessageModel._toDateTimeString(instance.createdAt),
      'sent_at': MessageModel._toDateTimeStringNullable(instance.sentAt),
      'delivered_at':
          MessageModel._toDateTimeStringNullable(instance.deliveredAt),
      'read_at': MessageModel._toDateTimeStringNullable(instance.readAt),
      'read_at_by_recipient':
          MessageModel._toDateTimeStringNullable(instance.readAtByRecipient),
      'is_read': instance.isRead,
      'is_delivered': instance.isDelivered,
      'is_sending': instance.isSending,
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

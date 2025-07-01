// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActivityAt: json['last_activity_at'] == null
          ? null
          : DateTime.parse(json['last_activity_at'] as String),
    );

Map<String, dynamic> _$ConversationModelToJson(ConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'last_message': instance.lastMessage,
      'unread_counts': instance.unreadCounts,
      'created_at': instance.createdAt.toIso8601String(),
      'last_activity_at': instance.lastActivityAt?.toIso8601String(),
    };

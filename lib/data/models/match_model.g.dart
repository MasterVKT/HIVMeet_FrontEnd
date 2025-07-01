// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
      id: json['id'] as String,
      profile: ProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      matchedAt: DateTime.parse(json['matched_at'] as String),
      lastMessage: json['last_message'] == null
          ? null
          : MessageModel.fromJson(json['last_message'] as Map<String, dynamic>),
      isNew: json['is_new'] as bool? ?? false,
      unreadCounts: (json['unread_counts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profile': instance.profile,
      'matched_at': instance.matchedAt.toIso8601String(),
      'last_message': instance.lastMessage,
      'is_new': instance.isNew,
      'unread_counts': instance.unreadCounts,
    };

SwipeActionModel _$SwipeActionModelFromJson(Map<String, dynamic> json) =>
    SwipeActionModel(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      type: json['type'] as String,
      createdAt:
          SwipeActionModel._timestampToDateTime(json['createdAt'] as Timestamp),
    );

Map<String, dynamic> _$SwipeActionModelToJson(SwipeActionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'type': instance.type,
      'createdAt': SwipeActionModel._dateTimeToTimestamp(instance.createdAt),
    };

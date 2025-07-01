// lib/data/models/match_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/data/models/profile_model.dart';
import 'package:hivmeet/data/models/message_model.dart';

part 'match_model.g.dart';

@JsonSerializable()
class MatchModel {
  final String id;
  final ProfileModel profile;
  @JsonKey(name: 'matched_at')
  final DateTime matchedAt;
  @JsonKey(name: 'last_message')
  final MessageModel? lastMessage;
  @JsonKey(name: 'is_new')
  final bool isNew;
  @JsonKey(name: 'unread_counts')
  final Map<String, int> unreadCounts;

  const MatchModel({
    required this.id,
    required this.profile,
    required this.matchedAt,
    this.lastMessage,
    this.isNew = false,
    this.unreadCounts = const {},
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$MatchModelToJson(this);

  Match toEntity() {
    return Match(
      id: id,
      profile: profile.toEntity(),
      matchedAt: matchedAt,
      lastMessage: lastMessage?.toEntity(),
      isNew: isNew,
      unreadCounts: unreadCounts,
    );
  }

  static MatchModel fromEntity(Match match) {
    return MatchModel(
      id: match.id,
      profile: ProfileModel.fromEntity(match.profile),
      matchedAt: match.matchedAt,
      lastMessage: match.lastMessage != null
          ? MessageModel.fromEntity(match.lastMessage!)
          : null,
      isNew: match.isNew,
      unreadCounts: match.unreadCounts,
    );
  }
}

@JsonSerializable()
class SwipeActionModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String type;
  @JsonKey(
      toJson: SwipeActionModel._dateTimeToTimestamp,
      fromJson: SwipeActionModel._timestampToDateTime)
  final DateTime createdAt;

  SwipeActionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.createdAt,
  });

  factory SwipeActionModel.fromJson(Map<String, dynamic> json) =>
      _$SwipeActionModelFromJson(json);
  Map<String, dynamic> toJson() => _$SwipeActionModelToJson(this);

  SwipeAction toEntity() {
    return SwipeAction(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: _parseSwipeType(type),
      createdAt: createdAt,
    );
  }

  static Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static DateTime _timestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  static SwipeType _parseSwipeType(String type) {
    switch (type) {
      case 'like':
        return SwipeType.like;
      case 'superLike':
        return SwipeType.superLike;
      case 'dislike':
        return SwipeType.dislike;
      default:
        return SwipeType.dislike;
    }
  }
}

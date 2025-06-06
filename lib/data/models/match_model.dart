// lib/data/models/match_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/match.dart';

part 'match_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MatchModel {
  final String id;
  final List<String> users;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime createdAt;
  final String status;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final Map<String, bool> isNew;

  MatchModel({
    required this.id,
    required this.users,
    required this.createdAt,
    required this.status,
    this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageSenderId,
    required this.unreadCounts,
    required this.isNew,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Match toEntity(String currentUserId) {
    final matchedUserId = users.firstWhere((id) => id != currentUserId);
    return Match(
      id: id,
      currentUserId: currentUserId,
      matchedUserId: matchedUserId,
      createdAt: createdAt,
      status: _parseMatchStatus(status),
      lastMessageAt: lastMessageAt,
      lastMessageContent: lastMessageContent,
      lastMessageSenderId: lastMessageSenderId,
      unreadCounts: unreadCounts,
      isNew: isNew[currentUserId] ?? false,
    );
  }

  static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  static DateTime? _timestampToDateTime(Timestamp? timestamp) {
    return timestamp?.toDate();
  }

  static MatchStatus _parseMatchStatus(String status) {
    switch (status) {
      case 'active':
        return MatchStatus.active;
      case 'pending':
        return MatchStatus.pending;
      case 'expired':
        return MatchStatus.expired;
      case 'deleted':
        return MatchStatus.deleted;
      default:
        return MatchStatus.active;
    }
  }
}

@JsonSerializable()
class SwipeActionModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String type;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime createdAt;

  SwipeActionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.createdAt,
  });

  factory SwipeActionModel.fromJson(Map<String, dynamic> json) => _$SwipeActionModelFromJson(json);
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
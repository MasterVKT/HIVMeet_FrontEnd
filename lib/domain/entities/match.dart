// lib/domain/entities/match.dart

import 'package:equatable/equatable.dart';

class Match extends Equatable {
  final String id;
  final String currentUserId;
  final String matchedUserId;
  final DateTime createdAt;
  final MatchStatus status;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final bool isNew;

  const Match({
    required this.id,
    required this.currentUserId,
    required this.matchedUserId,
    required this.createdAt,
    required this.status,
    this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageSenderId,
    required this.unreadCounts,
    required this.isNew,
  });

  int get unreadCount => unreadCounts[currentUserId] ?? 0;
  bool get hasUnreadMessages => unreadCount > 0;
  bool get isActive => status == MatchStatus.active;
  
  Match copyWith({
    String? id,
    String? currentUserId,
    String? matchedUserId,
    DateTime? createdAt,
    MatchStatus? status,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    bool? isNew,
  }) {
    return Match(
      id: id ?? this.id,
      currentUserId: currentUserId ?? this.currentUserId,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  List<Object?> get props => [
        id,
        currentUserId,
        matchedUserId,
        createdAt,
        status,
        lastMessageAt,
        lastMessageContent,
        lastMessageSenderId,
        unreadCounts,
        isNew,
      ];
}

enum MatchStatus {
  active,
  pending,
  expired,
  deleted,
}

class DiscoveryProfile extends Equatable {
  final String id;
  final String displayName;
  final int age;
  final String mainPhotoUrl;
  final List<String> otherPhotosUrls;
  final String bio;
  final String city;
  final String country;
  final double? distance;
  final List<String> interests;
  final String relationshipType;
  final bool isVerified;
  final bool isPremium;
  final DateTime lastActive;
  final double compatibilityScore;

  const DiscoveryProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.mainPhotoUrl,
    required this.otherPhotosUrls,
    required this.bio,
    required this.city,
    required this.country,
    this.distance,
    required this.interests,
    required this.relationshipType,
    required this.isVerified,
    required this.isPremium,
    required this.lastActive,
    required this.compatibilityScore,
  });

  bool get isOnline {
    return DateTime.now().difference(lastActive).inMinutes < 10;
  }

  List<String> get allPhotos => [mainPhotoUrl, ...otherPhotosUrls];

  @override
  List<Object?> get props => [
        id,
        displayName,
        age,
        mainPhotoUrl,
        otherPhotosUrls,
        bio,
        city,
        country,
        distance,
        interests,
        relationshipType,
        isVerified,
        isPremium,
        lastActive,
        compatibilityScore,
      ];
}

class SwipeAction extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final SwipeType type;
  final DateTime createdAt;

  const SwipeAction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, fromUserId, toUserId, type, createdAt];
}

enum SwipeType {
  like,
  superLike,
  dislike,
}

class DailyLikeLimit extends Equatable {
  final int used;
  final int limit;
  final DateTime resetAt;

  const DailyLikeLimit({
    required this.used,
    required this.limit,
    required this.resetAt,
  });

  int get remaining => limit - used;
  bool get hasReachedLimit => used >= limit;
  bool get shouldReset => DateTime.now().isAfter(resetAt);

  @override
  List<Object> get props => [used, limit, resetAt];
}
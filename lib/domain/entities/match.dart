// lib/domain/entities/match.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/message.dart';

class Match extends Equatable {
  final String id;
  final Profile profile;
  final DateTime matchedAt;
  final Message? lastMessage;
  final bool isNew;
  final Map<String, int> unreadCounts;

  const Match({
    required this.id,
    required this.profile,
    required this.matchedAt,
    this.lastMessage,
    this.isNew = false,
    this.unreadCounts = const {},
  });

  int get unreadCount => unreadCounts.values.fold(0, (a, b) => a + b);
  bool get hasUnreadMessages => unreadCount > 0;
  bool get isActive => true;

  // Propriétés de compatibilité pour résoudre les erreurs
  String? get lastMessageContent => lastMessage?.content;
  DateTime? get lastMessageAt => lastMessage?.createdAt;

  Match copyWith({
    String? id,
    Profile? profile,
    DateTime? matchedAt,
    Message? lastMessage,
    bool? isNew,
    Map<String, int>? unreadCounts,
  }) {
    return Match(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      matchedAt: matchedAt ?? this.matchedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      isNew: isNew ?? this.isNew,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profile,
        matchedAt,
        lastMessage,
        isNew,
        unreadCounts,
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

enum SwipeDirection {
  left,
  right,
  up,
  down,
}

class DailyLikeLimit extends Equatable {
  final int remainingLikes;
  final int totalLikes;
  final DateTime resetAt;

  const DailyLikeLimit({
    required this.remainingLikes,
    required this.totalLikes,
    required this.resetAt,
  });

  bool get hasReachedLimit => remainingLikes <= 0;

  // Propriétés de compatibilité pour résoudre les erreurs
  int get remaining => remainingLikes;
  int get limit => totalLikes;

  @override
  List<Object> get props => [remainingLikes, totalLikes, resetAt];
}

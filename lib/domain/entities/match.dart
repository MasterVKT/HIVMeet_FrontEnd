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

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    return DiscoveryProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      age: json['age'] as int,
      mainPhotoUrl: json['main_photo_url'] as String,
      otherPhotosUrls: (json['other_photos_urls'] as List).cast<String>(),
      bio: json['bio'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      distance: (json['distance'] as num?)?.toDouble(),
      interests: (json['interests'] as List).cast<String>(),
      relationshipType: json['relationship_type'] as String,
      isVerified: json['is_verified'] as bool,
      isPremium: json['is_premium'] as bool,
      lastActive: DateTime.parse(json['last_active'] as String),
      compatibilityScore: (json['compatibility_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'age': age,
      'main_photo_url': mainPhotoUrl,
      'other_photos_urls': otherPhotosUrls,
      'bio': bio,
      'city': city,
      'country': country,
      'distance': distance,
      'interests': interests,
      'relationship_type': relationshipType,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'last_active': lastActive.toIso8601String(),
      'compatibility_score': compatibilityScore,
    };
  }

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

  factory DailyLikeLimit.fromJson(Map<String, dynamic> json) {
    return DailyLikeLimit(
      remainingLikes: json['remaining_likes'] as int,
      totalLikes: json['total_likes'] as int,
      resetAt: DateTime.parse(json['reset_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'remaining_likes': remainingLikes,
      'total_likes': totalLikes,
      'reset_at': resetAt.toIso8601String(),
    };
  }

  bool get hasReachedLimit => remainingLikes <= 0;

  // Propriétés de compatibilité pour résoudre les erreurs
  int get remaining => remainingLikes;
  int get limit => totalLikes;

  @override
  List<Object> get props => [remainingLikes, totalLikes, resetAt];
}

class SwipeResult extends Equatable {
  final bool isMatch;
  final String? matchId;
  final Profile? matchedProfile;

  const SwipeResult({
    required this.isMatch,
    this.matchId,
    this.matchedProfile,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      isMatch: json['is_match'] as bool,
      matchId: json['match_id'] as String?,
      matchedProfile:
          null, // TODO: Implémenter la sérialisation Profile si nécessaire
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_match': isMatch,
      'match_id': matchId,
      // matched_profile omis car Profile n'a pas de toJson()
    };
  }

  @override
  List<Object?> get props => [isMatch, matchId, matchedProfile];
}

class BoostStatus extends Equatable {
  final bool isActive;
  final DateTime? endsAt;
  final int boostsRemaining;
  final DateTime? activatedAt;

  const BoostStatus({
    required this.isActive,
    this.endsAt,
    required this.boostsRemaining,
    this.activatedAt,
  });

  factory BoostStatus.fromJson(Map<String, dynamic> json) {
    return BoostStatus(
      isActive: json['is_active'] as bool,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      boostsRemaining: json['boosts_remaining'] as int,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'ends_at': endsAt?.toIso8601String(),
      'boosts_remaining': boostsRemaining,
      'activated_at': activatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [isActive, endsAt, boostsRemaining, activatedAt];
}

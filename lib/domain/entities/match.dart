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
  final List<String> relationshipTypesSought;
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
    this.relationshipTypesSought = const [],
    required this.relationshipType,
    required this.isVerified,
    required this.isPremium,
    required this.lastActive,
    required this.compatibilityScore,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    // Gérer les deux formats de photos : main_photo_url/other_photos_urls OU photos[]
    String mainPhotoUrl = '';
    List<String> otherPhotosUrls = [];

    // Priorité : main_photo_url / other_photos_urls (ancien format)
    if (json.containsKey('main_photo_url')) {
      final mainPhoto = json['main_photo_url'];
      if (mainPhoto != null && mainPhoto is String && mainPhoto.isNotEmpty) {
        mainPhotoUrl = mainPhoto;
      }
    }
    if (json.containsKey('other_photos_urls')) {
      final otherPhotos = json['other_photos_urls'];
      if (otherPhotos != null && otherPhotos is List) {
        otherPhotosUrls = otherPhotos.map((e) => e.toString()).toList();
      }
    }

    // Fallback : photos[] (nouveau format backend)
    if (mainPhotoUrl.isEmpty && json.containsKey('photos')) {
      final photos = json['photos'];
      if (photos != null && photos is List && photos.isNotEmpty) {
        final photosList = photos.map((e) => e.toString()).toList();
        mainPhotoUrl = photosList.first;
        if (photosList.length > 1) {
          otherPhotosUrls = photosList.sublist(1);
        }
      }
    }

    // Extraire l'ID
    String id = '';
    if (json.containsKey('user_id') && json['user_id'] != null) {
      id = json['user_id'].toString();
    } else if (json.containsKey('id') && json['id'] != null) {
      id = json['id'].toString();
    }

    // Extraire le display_name
    String displayName = '';
    if (json.containsKey('display_name') && json['display_name'] != null) {
      displayName = json['display_name'].toString();
    }

    // Extraire les interests
    List<String> interests = [];
    if (json.containsKey('interests') && json['interests'] is List) {
      interests = (json['interests'] as List).map((e) => e.toString()).toList();
    }

    // Extraire les relationship types
    List<String> relationshipTypesSought = [];
    String relationshipType = 'long_term';
    if (json.containsKey('relationship_types_sought') &&
        json['relationship_types_sought'] is List) {
      final types = json['relationship_types_sought'] as List;
      relationshipTypesSought = types.map((e) => e.toString()).toList();
      if (types.isNotEmpty) {
        relationshipType = types.first.toString();
      }
    } else if (json.containsKey('relationship_type') &&
        json['relationship_type'] != null) {
      relationshipType = json['relationship_type'].toString();
    }

    return DiscoveryProfile(
      id: id,
      displayName: displayName,
      age: json['age'] as int,
      mainPhotoUrl: mainPhotoUrl,
      otherPhotosUrls: otherPhotosUrls,
      bio: json['bio']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? 'FR',
      distance: (json['distance_km'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      interests: interests,
      relationshipTypesSought: relationshipTypesSought,
      relationshipType: relationshipType,
      isVerified: json['is_verified'] == true,
      isPremium: json['is_premium'] == true,
      lastActive: json.containsKey('last_active') && json['last_active'] != null
          ? DateTime.parse(json['last_active'].toString())
          : DateTime.now(),
      compatibilityScore:
          (json['compatibility_score'] as num?)?.toDouble() ?? 0.0,
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
      'relationship_types_sought': relationshipTypesSought,
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

  List<String> get allPhotos {
    // Filtrer les URLs vides et ajouter un placeholder si aucune photo
    final photos = [mainPhotoUrl, ...otherPhotosUrls]
        .where((url) => url.isNotEmpty)
        .toList();

    // Si aucune photo, retourner une liste avec un placeholder
    if (photos.isEmpty) {
      return ['placeholder'];
    }

    return photos;
  }

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
        relationshipTypesSought,
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

  DailyLikeLimit copyWith({
    int? remainingLikes,
    int? totalLikes,
    DateTime? resetAt,
  }) {
    return DailyLikeLimit(
      remainingLikes: remainingLikes ?? this.remainingLikes,
      totalLikes: totalLikes ?? this.totalLikes,
      resetAt: resetAt ?? this.resetAt,
    );
  }

  @override
  List<Object> get props => [remainingLikes, totalLikes, resetAt];
}

class SwipeResult extends Equatable {
  final bool isMatch;
  final String? matchId;
  final Profile? matchedProfile;
  final int? remainingLikes;
  final int? remainingSuperLikes;

  const SwipeResult({
    required this.isMatch,
    this.matchId,
    this.matchedProfile,
    this.remainingLikes,
    this.remainingSuperLikes,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      isMatch: json['is_match'] as bool,
      matchId: json['match_id'] as String?,
      matchedProfile:
          null, // TODO: Implémenter la sérialisation Profile si nécessaire
      remainingLikes: json['remaining_likes'] as int?,
      remainingSuperLikes: json['remaining_super_likes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_match': isMatch,
      'match_id': matchId,
      // matched_profile omis car Profile n'a pas de toJson()
      if (remainingLikes != null) 'remaining_likes': remainingLikes,
      if (remainingSuperLikes != null)
        'remaining_super_likes': remainingSuperLikes,
    };
  }

  @override
  List<Object?> get props =>
      [isMatch, matchId, matchedProfile, remainingLikes, remainingSuperLikes];
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

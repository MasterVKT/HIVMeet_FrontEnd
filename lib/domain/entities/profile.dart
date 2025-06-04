// lib/domain/entities/profile.dart

import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class Profile extends Equatable {
  final String id;
  final String userId;
  final String displayName;
  final DateTime birthDate;
  final String bio;
  final Location location;
  final String city;
  final String country;
  final List<String> interests;
  final String relationshipType;
  final PhotoCollection photos;
  final SearchPreferences searchPreferences;
  final DateTime lastActive;
  final bool isHidden;
  final VerificationStatus verificationStatus;
  final PrivacySettings privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.birthDate,
    required this.bio,
    required this.location,
    required this.city,
    required this.country,
    required this.interests,
    required this.relationshipType,
    required this.photos,
    required this.searchPreferences,
    required this.lastActive,
    required this.isHidden,
    required this.verificationStatus,
    required this.privacySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  // Propriétés calculées
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get isOnline {
    final difference = DateTime.now().difference(lastActive);
    return difference.inMinutes < 10;
  }

  String get displayLocation {
    return privacySettings.showExactLocation ? city : country;
  }

  String get mainPhotoUrl => photos.main;
  bool get hasMultiplePhotos => photos.others.isNotEmpty;

  Profile copyWith({
    String? id,
    String? userId,
    String? displayName,
    DateTime? birthDate,
    String? bio,
    Location? location,
    String? city,
    String? country,
    List<String>? interests,
    String? relationshipType,
    PhotoCollection? photos,
    SearchPreferences? searchPreferences,
    DateTime? lastActive,
    bool? isHidden,
    VerificationStatus? verificationStatus,
    PrivacySettings? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      city: city ?? this.city,
      country: country ?? this.country,
      interests: interests ?? this.interests,
      relationshipType: relationshipType ?? this.relationshipType,
      photos: photos ?? this.photos,
      searchPreferences: searchPreferences ?? this.searchPreferences,
      lastActive: lastActive ?? this.lastActive,
      isHidden: isHidden ?? this.isHidden,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
        id,
        userId,
        displayName,
        birthDate,
        bio,
        location,
        city,
        country,
        interests,
        relationshipType,
        photos,
        searchPreferences,
        lastActive,
        isHidden,
        verificationStatus,
        privacySettings,
        createdAt,
        updatedAt,
      ];
}

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String geohash;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.geohash,
  });

  double distanceFrom(Location other) {
    // Formule de Haversine pour calculer la distance
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);
    
    final double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(latitude)) * 
      math.cos(_toRadians(other.latitude)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  @override
  List<Object> get props => [latitude, longitude, geohash];
}

class PhotoCollection extends Equatable {
  final String main;
  final List<String> others;
  final List<String> private;

  const PhotoCollection({
    required this.main,
    this.others = const [],
    this.private = const [],
  });

  int get totalCount => 1 + others.length + private.length;
  bool get hasPrivatePhotos => private.isNotEmpty;

  List<String> get allPublicPhotos => [main, ...others];

  @override
  List<Object> get props => [main, others, private];
}

class SearchPreferences extends Equatable {
  final AgeRange ageRange;
  final int maxDistanceKm;
  final String relationshipType;
  final List<String> gendersSought;

  const SearchPreferences({
    required this.ageRange,
    required this.maxDistanceKm,
    required this.relationshipType,
    required this.gendersSought,
  });

  SearchPreferences copyWith({
    AgeRange? ageRange,
    int? maxDistanceKm,
    String? relationshipType,
    List<String>? gendersSought,
  }) {
    return SearchPreferences(
      ageRange: ageRange ?? this.ageRange,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      relationshipType: relationshipType ?? this.relationshipType,
      gendersSought: gendersSought ?? this.gendersSought,
    );
  }

  @override
  List<Object> get props => [ageRange, maxDistanceKm, relationshipType, gendersSought];
}

class AgeRange extends Equatable {
  final int min;
  final int max;

  const AgeRange({
    required this.min,
    required this.max,
  }) : assert(min >= 18 && max <= 99 && min <= max);

  @override
  List<Object> get props => [min, max];
}

class VerificationStatus extends Equatable {
  final String status; // not_started, pending_id, pending_medical, pending_selfie, pending_review, verified, rejected, expired
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final Map<String, DocumentStatus> documents;

  const VerificationStatus({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.expiresAt,
    required this.documents,
  });

  bool get isPending => status.contains('pending');
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired' || (expiresAt?.isBefore(DateTime.now()) ?? false);

  @override
  List<Object?> get props => [
        status,
        submittedAt,
        reviewedAt,
        rejectionReason,
        expiresAt,
        documents,
      ];
}

class DocumentStatus extends Equatable {
  final String type; // identity_document, medical_document, selfie_with_code
  final String status; // pending, uploaded, approved, rejected

  const DocumentStatus({
    required this.type,
    required this.status,
  });

  @override
  List<Object> get props => [type, status];
}

class PrivacySettings extends Equatable {
  final String profileVisibility; // visible_to_all, visible_to_matches_only, incognito
  final bool showOnlineStatus;
  final bool showDistance;
  final bool showExactLocation;
  final bool profileDiscoverable;

  const PrivacySettings({
    this.profileVisibility = 'visible_to_all',
    this.showOnlineStatus = true,
    this.showDistance = true,
    this.showExactLocation = false,
    this.profileDiscoverable = true,
  });

  PrivacySettings copyWith({
    String? profileVisibility,
    bool? showOnlineStatus,
    bool? showDistance,
    bool? showExactLocation,
    bool? profileDiscoverable,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showDistance: showDistance ?? this.showDistance,
      showExactLocation: showExactLocation ?? this.showExactLocation,
      profileDiscoverable: profileDiscoverable ?? this.profileDiscoverable,
    );
  }

  @override
  List<Object> get props => [
        profileVisibility,
        showOnlineStatus,
        showDistance,
        showExactLocation,
        profileDiscoverable,
      ];
}

// Enums
class RelationshipType {
  static const String friendship = 'friendship';
  static const String longTerm = 'long_term_relationship';
  static const String shortTerm = 'short_term_relationship';
  static const String casualDating = 'casual_dating';
  static const String networking = 'networking';
  
  static const List<String> all = [
    friendship,
    longTerm,
    shortTerm,
    casualDating,
    networking,
  ];
}

class Gender {
  static const String male = 'male';
  static const String female = 'female';
  static const String nonBinary = 'non_binary';
  static const String transMale = 'trans_male';
  static const String transFemale = 'trans_female';
  static const String other = 'other';
  static const String preferNotToSay = 'prefer_not_to_say';
  
  static const List<String> all = [
    male,
    female,
    nonBinary,
    transMale,
    transFemale,
    other,
    preferNotToSay,
  ];
}

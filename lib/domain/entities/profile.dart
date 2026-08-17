// lib/domain/entities/profile.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'dart:math' as math;

class Profile extends Equatable {
  final String id;
  final String userId;
  final String displayName;
  final ProfileUserSummary? user;
  final DateTime birthDate;
  final String bio;
  final String gender;
  final Location location;
  final String city;
  final String country;
  final List<String> interests;
  final String relationshipType;
  final List<String> relationshipTypesSought;
  final PhotoCollection photos;
  final List<ProfilePhoto> photoItems;
  final SearchPreferences searchPreferences;
  final DateTime lastActive;
  final bool isHidden;
  final VerificationStatus verificationStatus;
  final PrivacySettings privacySettings;
  final PremiumProfileStatus? premiumStatus;
  final double? distanceFromMeKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.user,
    required this.birthDate,
    required this.bio,
    this.gender = '',
    required this.location,
    required this.city,
    required this.country,
    required this.interests,
    required this.relationshipType,
    this.relationshipTypesSought = const [],
    required this.photos,
    this.photoItems = const [],
    required this.searchPreferences,
    required this.lastActive,
    required this.isHidden,
    required this.verificationStatus,
    required this.privacySettings,
    this.premiumStatus,
    this.distanceFromMeKm,
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
  bool get hasMultiplePhotos =>
      photoItems.length > 1 || photos.others.isNotEmpty;
  int get photoCount =>
      photoItems.isNotEmpty ? photoItems.length : photos.totalCount;

  Profile copyWith({
    String? id,
    String? userId,
    String? displayName,
    ProfileUserSummary? user,
    DateTime? birthDate,
    String? bio,
    String? gender,
    Location? location,
    String? city,
    String? country,
    List<String>? interests,
    String? relationshipType,
    List<String>? relationshipTypesSought,
    PhotoCollection? photos,
    List<ProfilePhoto>? photoItems,
    SearchPreferences? searchPreferences,
    DateTime? lastActive,
    bool? isHidden,
    VerificationStatus? verificationStatus,
    PrivacySettings? privacySettings,
    PremiumProfileStatus? premiumStatus,
    double? distanceFromMeKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      user: user ?? this.user,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      city: city ?? this.city,
      country: country ?? this.country,
      interests: interests ?? this.interests,
      relationshipType: relationshipType ?? this.relationshipType,
      relationshipTypesSought:
          relationshipTypesSought ?? this.relationshipTypesSought,
      photos: photos ?? this.photos,
      photoItems: photoItems ?? this.photoItems,
      searchPreferences: searchPreferences ?? this.searchPreferences,
      lastActive: lastActive ?? this.lastActive,
      isHidden: isHidden ?? this.isHidden,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      privacySettings: privacySettings ?? this.privacySettings,
      premiumStatus: premiumStatus ?? this.premiumStatus,
      distanceFromMeKm: distanceFromMeKm ?? this.distanceFromMeKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        user,
        birthDate,
        bio,
        gender,
        location,
        city,
        country,
        interests,
        relationshipType,
        relationshipTypesSought,
        photos,
        photoItems,
        searchPreferences,
        lastActive,
        isHidden,
        verificationStatus,
        privacySettings,
        premiumStatus,
        distanceFromMeKm,
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

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

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

  int get totalCount => (main.isEmpty ? 0 : 1) + others.length + private.length;
  bool get hasPrivatePhotos => private.isNotEmpty;

  List<String> get allPublicPhotos => [
        if (main.isNotEmpty) main,
        ...others,
      ];

  @override
  List<Object> get props => [main, others, private];
}

class SearchPreferences extends Equatable {
  final int minAge;
  final int maxAge;
  final double maxDistance;
  final List<String> interestedIn;
  final List<String> relationshipTypes;
  final bool showVerifiedOnly;
  final bool showOnlineOnly;

  const SearchPreferences({
    required this.minAge,
    required this.maxAge,
    required this.maxDistance,
    required this.interestedIn,
    required this.relationshipTypes,
    this.showVerifiedOnly = false,
    this.showOnlineOnly = false,
  });

  // Propriétés de compatibilité pour résoudre les erreurs
  AgeRange get ageRange => AgeRange(min: minAge, max: maxAge);
  double get maxDistanceKm => maxDistance;
  String get relationshipType =>
      relationshipTypes.isNotEmpty ? relationshipTypes.first : '';
  List<String> get gendersSought => interestedIn;

  Map<String, dynamic> toJson() {
    return {
      'min_age': minAge,
      'max_age': maxAge,
      'max_distance': maxDistance,
      'interested_in': interestedIn,
      'relationship_types': relationshipTypes,
      'show_verified_only': showVerifiedOnly,
      'show_online_only': showOnlineOnly,
    };
  }

  SearchPreferences copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interestedIn,
    List<String>? relationshipTypes,
    bool? showVerifiedOnly,
    bool? showOnlineOnly,
  }) {
    return SearchPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      interestedIn: interestedIn ?? this.interestedIn,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      showOnlineOnly: showOnlineOnly ?? this.showOnlineOnly,
    );
  }

  @override
  List<Object> get props => [
        minAge,
        maxAge,
        maxDistance,
        interestedIn,
        relationshipTypes,
        showVerifiedOnly,
        showOnlineOnly,
      ];
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
  final String
      status; // not_started, pending_id, pending_medical, pending_selfie, pending_review, verified, rejected, expired
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final String? verificationCode;
  final Map<String, DocumentStatus> documents;

  const VerificationStatus({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.expiresAt,
    this.verificationCode,
    required this.documents,
  });

  bool get isPending => status.contains('pending');
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isExpired =>
      status == 'expired' || (expiresAt?.isBefore(DateTime.now()) ?? false);

  @override
  List<Object?> get props => [
        status,
        submittedAt,
        reviewedAt,
        rejectionReason,
        expiresAt,
        verificationCode,
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
  final String
      profileVisibility; // visible_to_all, visible_to_matches_only, incognito
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
  static const String longTerm = 'long_term';
  static const String shortTerm = 'short_term';
  static const String casualDating = 'casual';

  static const List<String> all = [
    friendship,
    longTerm,
    shortTerm,
    casualDating,
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

  // Options pour le filtre de recherche (3 options simplifiées)
  static const String all = 'all'; // Tout le monde

  // Liste des trois options de genre
  static const List<String> allOptions = [
    male,
    female,
    nonBinary,
    transMale,
    transFemale,
    other,
    preferNotToSay,
  ];

  // Labels français pour l'affichage
  static const Map<String, String> labelsFr = {
    male: 'Homme',
    female: 'Femme',
    nonBinary: 'Non-binaire',
    transMale: 'Homme trans',
    transFemale: 'Femme trans',
    other: 'Autre',
    preferNotToSay: 'Préfère ne pas dire',
  };

  // Labels anglais pour l'affichage
  static const Map<String, String> labelsEn = {
    male: 'Man',
    female: 'Woman',
    nonBinary: 'Non-binary',
    transMale: 'Trans man',
    transFemale: 'Trans woman',
    other: 'Other',
    preferNotToSay: 'Prefer not to say',
  };

  // Méthode utilitaire pour obtenir le label selon la locale
  static String getLabel(String gender, {String? locale}) {
    final effectiveLocale =
        locale ?? LocalizationService.instance.currentLocale;
    if (effectiveLocale == 'en') {
      return labelsEn[gender] ?? gender;
    }
    return labelsFr[gender] ?? gender;
  }
}

class ProfileUserSummary extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final DateTime? birthDate;
  final int? age;
  final bool isVerified;
  final bool isPremium;
  final String verificationStatus;
  final bool profileComplete;
  final DateTime? lastActive;
  final DateTime? dateJoined;

  const ProfileUserSummary({
    required this.id,
    this.email = '',
    required this.displayName,
    this.birthDate,
    this.age,
    this.isVerified = false,
    this.isPremium = false,
    this.verificationStatus = 'not_started',
    this.profileComplete = false,
    this.lastActive,
    this.dateJoined,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        birthDate,
        age,
        isVerified,
        isPremium,
        verificationStatus,
        profileComplete,
        lastActive,
        dateJoined,
      ];
}

class ProfilePhoto extends Equatable {
  final String id;
  final String photoUrl;
  final String thumbnailUrl;
  final bool isMain;
  final String caption;
  final int order;
  final DateTime? uploadedAt;

  const ProfilePhoto({
    required this.id,
    required this.photoUrl,
    this.thumbnailUrl = '',
    this.isMain = false,
    this.caption = '',
    this.order = 0,
    this.uploadedAt,
  });

  @override
  List<Object?> get props =>
      [id, photoUrl, thumbnailUrl, isMain, caption, order, uploadedAt];
}

class PremiumProfileStatus extends Equatable {
  final bool isPremium;
  final String? subscriptionType;
  final DateTime? premiumUntil;
  final Map<String, bool> features;
  final Map<String, PremiumUsageQuota> usage;

  const PremiumProfileStatus({
    required this.isPremium,
    this.subscriptionType,
    this.premiumUntil,
    this.features = const {},
    this.usage = const {},
  });

  bool get canSeeLikers => features['can_see_likers'] ?? false;

  @override
  List<Object?> get props =>
      [isPremium, subscriptionType, premiumUntil, features, usage];
}

class PremiumUsageQuota extends Equatable {
  final int total;
  final int remaining;
  final int used;
  final DateTime? resetAt;

  const PremiumUsageQuota({
    this.total = 0,
    this.remaining = 0,
    this.used = 0,
    this.resetAt,
  });

  @override
  List<Object?> get props => [total, remaining, used, resetAt];
}

class VerificationDetails extends Equatable {
  final String id;
  final String status;
  final String rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? expiresAt;
  final String? verificationCode;
  final List<VerificationDocumentRequirement> requiredDocuments;

  const VerificationDetails({
    required this.id,
    required this.status,
    this.rejectionReason = '',
    this.submittedAt,
    this.reviewedAt,
    this.expiresAt,
    this.verificationCode,
    this.requiredDocuments = const [],
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status.contains('pending');

  @override
  List<Object?> get props => [
        id,
        status,
        rejectionReason,
        submittedAt,
        reviewedAt,
        expiresAt,
        verificationCode,
        requiredDocuments,
      ];
}

class VerificationDocumentRequirement extends Equatable {
  final String type;
  final String status;
  final String name;

  const VerificationDocumentRequirement({
    required this.type,
    required this.status,
    required this.name,
  });

  @override
  List<Object> get props => [type, status, name];
}

class VerificationUploadResult extends Equatable {
  final String uploadUrl;
  final String filePathOnStorage;

  const VerificationUploadResult({
    required this.uploadUrl,
    required this.filePathOnStorage,
  });

  @override
  List<Object> get props => [uploadUrl, filePathOnStorage];
}

class VerificationSubmissionDocument extends Equatable {
  final String documentType;
  final String filePathOnStorage;

  const VerificationSubmissionDocument({
    required this.documentType,
    required this.filePathOnStorage,
  });

  Map<String, dynamic> toJson() => {
        'document_type': documentType,
        'file_path_on_storage': filePathOnStorage,
      };

  @override
  List<Object> get props => [documentType, filePathOnStorage];
}

class PrivacyPreferences extends Equatable {
  final String profileVisibility;
  final bool showOnlineStatus;
  final bool showDistance;
  final bool profileDiscoverable;

  const PrivacyPreferences({
    this.profileVisibility = 'visible_to_all',
    this.showOnlineStatus = true,
    this.showDistance = true,
    this.profileDiscoverable = true,
  });

  Map<String, dynamic> toJson() => {
        'profile_visibility': profileVisibility,
        'show_online_status': showOnlineStatus,
        'show_distance': showDistance,
        'profile_discoverable': profileDiscoverable,
      };

  PrivacyPreferences copyWith({
    String? profileVisibility,
    bool? showOnlineStatus,
    bool? showDistance,
    bool? profileDiscoverable,
  }) {
    return PrivacyPreferences(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showDistance: showDistance ?? this.showDistance,
      profileDiscoverable: profileDiscoverable ?? this.profileDiscoverable,
    );
  }

  @override
  List<Object> get props =>
      [profileVisibility, showOnlineStatus, showDistance, profileDiscoverable];
}

class NotificationPreferences extends Equatable {
  final bool newMatchNotifications;
  final bool newMessageNotifications;
  final bool profileLikeNotifications;
  final bool appUpdateNotifications;
  final bool promotionalNotifications;
  final Map<String, dynamic> doNotDisturbSettings;

  const NotificationPreferences({
    this.newMatchNotifications = true,
    this.newMessageNotifications = true,
    this.profileLikeNotifications = false,
    this.appUpdateNotifications = true,
    this.promotionalNotifications = false,
    this.doNotDisturbSettings = const {
      'enabled': false,
      'start_time_utc': '22:00',
      'end_time_utc': '07:00',
    },
  });

  Map<String, dynamic> toJson() => {
        'new_match_notifications': newMatchNotifications,
        'new_message_notifications': newMessageNotifications,
        'profile_like_notifications': profileLikeNotifications,
        'app_update_notifications': appUpdateNotifications,
        'promotional_notifications': promotionalNotifications,
        'do_not_disturb_settings': doNotDisturbSettings,
      };

  NotificationPreferences copyWith({
    bool? newMatchNotifications,
    bool? newMessageNotifications,
    bool? profileLikeNotifications,
    bool? appUpdateNotifications,
    bool? promotionalNotifications,
    Map<String, dynamic>? doNotDisturbSettings,
  }) {
    return NotificationPreferences(
      newMatchNotifications:
          newMatchNotifications ?? this.newMatchNotifications,
      newMessageNotifications:
          newMessageNotifications ?? this.newMessageNotifications,
      profileLikeNotifications:
          profileLikeNotifications ?? this.profileLikeNotifications,
      appUpdateNotifications:
          appUpdateNotifications ?? this.appUpdateNotifications,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
      doNotDisturbSettings: doNotDisturbSettings ?? this.doNotDisturbSettings,
    );
  }

  @override
  List<Object?> get props => [
        newMatchNotifications,
        newMessageNotifications,
        profileLikeNotifications,
        appUpdateNotifications,
        promotionalNotifications,
        doNotDisturbSettings,
      ];
}

class BlockedUser extends Equatable {
  final String userId;
  final String displayName;
  final String? profilePhotoUrl;

  const BlockedUser({
    required this.userId,
    required this.displayName,
    this.profilePhotoUrl,
  });

  @override
  List<Object?> get props => [userId, displayName, profilePhotoUrl];
}

/// Résultat d'une demande RGPD (export ou suppression de compte).
class DataRequestResult extends Equatable {
  final String requestId;
  final String message;
  final DateTime? requestedAt;
  final String status;

  const DataRequestResult({
    required this.requestId,
    required this.message,
    this.requestedAt,
    this.status = 'pending',
  });

  @override
  List<Object?> get props => [requestId, message, requestedAt, status];
}

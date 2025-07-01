// lib/data/models/profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/profile.dart';

part 'profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProfileModel {
  final String id;
  final String userId;
  final String displayName;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime birthDate;
  final String bio;
  final LocationModel location;
  final String city;
  final String country;
  final List<String> interests;
  final String relationshipType;
  final PhotoCollectionModel photos;
  final SearchPreferencesModel searchPreferences;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime lastActive;
  final bool isHidden;
  final VerificationStatusModel verificationStatus;
  final PrivacySettingsModel privacySettings;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime createdAt;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime updatedAt;

  ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      birthDate: profile.birthDate,
      bio: profile.bio,
      location: LocationModel.fromEntity(profile.location),
      city: profile.city,
      country: profile.country,
      interests: profile.interests,
      relationshipType: profile.relationshipType,
      photos: PhotoCollectionModel.fromEntity(profile.photos),
      searchPreferences:
          SearchPreferencesModel.fromEntity(profile.searchPreferences),
      lastActive: profile.lastActive,
      isHidden: profile.isHidden,
      verificationStatus:
          VerificationStatusModel.fromEntity(profile.verificationStatus),
      privacySettings: PrivacySettingsModel.fromEntity(profile.privacySettings),
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Profile toEntity() {
    return Profile(
      id: id,
      userId: userId,
      displayName: displayName,
      birthDate: birthDate,
      bio: bio,
      location: location.toEntity(),
      city: city,
      country: country,
      interests: interests,
      relationshipType: relationshipType,
      photos: photos.toEntity(),
      searchPreferences: searchPreferences.toEntity(),
      lastActive: lastActive,
      isHidden: isHidden,
      verificationStatus: verificationStatus.toEntity(),
      privacySettings: privacySettings.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  static DateTime _timestampToDateTimeNonNull(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now(); // fallback
  }

  static DateTime? _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }
}

@JsonSerializable()
class LocationModel {
  final double latitude;
  final double longitude;
  final String geohash;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.geohash,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
  Map<String, dynamic> toJson() => _$LocationModelToJson(this);

  factory LocationModel.fromEntity(Location location) {
    return LocationModel(
      latitude: location.latitude,
      longitude: location.longitude,
      geohash: location.geohash,
    );
  }

  Location toEntity() {
    return Location(
      latitude: latitude,
      longitude: longitude,
      geohash: geohash,
    );
  }
}

@JsonSerializable()
class PhotoCollectionModel {
  final String main;
  final List<String> others;
  final List<String> private;

  PhotoCollectionModel({
    required this.main,
    this.others = const [],
    this.private = const [],
  });

  factory PhotoCollectionModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoCollectionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoCollectionModelToJson(this);

  factory PhotoCollectionModel.fromEntity(PhotoCollection photos) {
    return PhotoCollectionModel(
      main: photos.main,
      others: photos.others,
      private: photos.private,
    );
  }

  PhotoCollection toEntity() {
    return PhotoCollection(
      main: main,
      others: others,
      private: private,
    );
  }
}

@JsonSerializable()
class SearchPreferencesModel {
  final int minAge;
  final int maxAge;
  final double maxDistance;
  final List<String> interestedIn;
  final List<String> relationshipTypes;
  final bool showVerifiedOnly;
  final bool showOnlineOnly;

  SearchPreferencesModel({
    required this.minAge,
    required this.maxAge,
    required this.maxDistance,
    required this.interestedIn,
    required this.relationshipTypes,
    this.showVerifiedOnly = false,
    this.showOnlineOnly = false,
  });

  factory SearchPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$SearchPreferencesModelFromJson(json);
  Map<String, dynamic> toJson() => _$SearchPreferencesModelToJson(this);

  factory SearchPreferencesModel.fromEntity(SearchPreferences prefs) {
    return SearchPreferencesModel(
      minAge: prefs.minAge,
      maxAge: prefs.maxAge,
      maxDistance: prefs.maxDistance,
      interestedIn: prefs.interestedIn,
      relationshipTypes: prefs.relationshipTypes,
      showVerifiedOnly: prefs.showVerifiedOnly,
      showOnlineOnly: prefs.showOnlineOnly,
    );
  }

  SearchPreferences toEntity() {
    return SearchPreferences(
      minAge: minAge,
      maxAge: maxAge,
      maxDistance: maxDistance,
      interestedIn: interestedIn,
      relationshipTypes: relationshipTypes,
      showVerifiedOnly: showVerifiedOnly,
      showOnlineOnly: showOnlineOnly,
    );
  }
}

@JsonSerializable()
class VerificationStatusModel {
  final String status;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime? submittedAt;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime? reviewedAt;
  final String? rejectionReason;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime? expiresAt;
  final Map<String, DocumentStatusModel> documents;

  VerificationStatusModel({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.expiresAt,
    required this.documents,
  });

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) =>
      _$VerificationStatusModelFromJson(json);
  Map<String, dynamic> toJson() => _$VerificationStatusModelToJson(this);

  factory VerificationStatusModel.fromEntity(VerificationStatus status) {
    return VerificationStatusModel(
      status: status.status,
      submittedAt: status.submittedAt,
      reviewedAt: status.reviewedAt,
      rejectionReason: status.rejectionReason,
      expiresAt: status.expiresAt,
      documents: status.documents.map(
        (key, value) => MapEntry(key, DocumentStatusModel.fromEntity(value)),
      ),
    );
  }

  VerificationStatus toEntity() {
    return VerificationStatus(
      status: status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      expiresAt: expiresAt,
      documents: documents.map(
        (key, value) => MapEntry(key, value.toEntity()),
      ),
    );
  }

  static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  static DateTime? _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }
}

@JsonSerializable()
class DocumentStatusModel {
  final String type;
  final String status;

  DocumentStatusModel({
    required this.type,
    required this.status,
  });

  factory DocumentStatusModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentStatusModelFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentStatusModelToJson(this);

  factory DocumentStatusModel.fromEntity(DocumentStatus status) {
    return DocumentStatusModel(
      type: status.type,
      status: status.status,
    );
  }

  DocumentStatus toEntity() {
    return DocumentStatus(
      type: type,
      status: status,
    );
  }
}

@JsonSerializable()
class PrivacySettingsModel {
  final String profileVisibility;
  final bool showOnlineStatus;
  final bool showDistance;
  final bool showExactLocation;
  final bool profileDiscoverable;

  PrivacySettingsModel({
    this.profileVisibility = 'visible_to_all',
    this.showOnlineStatus = true,
    this.showDistance = true,
    this.showExactLocation = false,
    this.profileDiscoverable = true,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacySettingsModelToJson(this);

  factory PrivacySettingsModel.fromEntity(PrivacySettings settings) {
    return PrivacySettingsModel(
      profileVisibility: settings.profileVisibility,
      showOnlineStatus: settings.showOnlineStatus,
      showDistance: settings.showDistance,
      showExactLocation: settings.showExactLocation,
      profileDiscoverable: settings.profileDiscoverable,
    );
  }

  PrivacySettings toEntity() {
    return PrivacySettings(
      profileVisibility: profileVisibility,
      showOnlineStatus: showOnlineStatus,
      showDistance: showDistance,
      showExactLocation: showExactLocation,
      profileDiscoverable: profileDiscoverable,
    );
  }
}

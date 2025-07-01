// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      birthDate: ProfileModel._timestampToDateTimeNonNull(json['birthDate']),
      bio: json['bio'] as String,
      location:
          LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      city: json['city'] as String,
      country: json['country'] as String,
      interests:
          (json['interests'] as List<dynamic>).map((e) => e as String).toList(),
      relationshipType: json['relationshipType'] as String,
      photos:
          PhotoCollectionModel.fromJson(json['photos'] as Map<String, dynamic>),
      searchPreferences: SearchPreferencesModel.fromJson(
          json['searchPreferences'] as Map<String, dynamic>),
      lastActive: ProfileModel._timestampToDateTimeNonNull(json['lastActive']),
      isHidden: json['isHidden'] as bool,
      verificationStatus: VerificationStatusModel.fromJson(
          json['verificationStatus'] as Map<String, dynamic>),
      privacySettings: PrivacySettingsModel.fromJson(
          json['privacySettings'] as Map<String, dynamic>),
      createdAt: ProfileModel._timestampToDateTimeNonNull(json['createdAt']),
      updatedAt: ProfileModel._timestampToDateTimeNonNull(json['updatedAt']),
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'displayName': instance.displayName,
      'birthDate': ProfileModel._dateTimeToTimestamp(instance.birthDate),
      'bio': instance.bio,
      'location': instance.location.toJson(),
      'city': instance.city,
      'country': instance.country,
      'interests': instance.interests,
      'relationshipType': instance.relationshipType,
      'photos': instance.photos.toJson(),
      'searchPreferences': instance.searchPreferences.toJson(),
      'lastActive': ProfileModel._dateTimeToTimestamp(instance.lastActive),
      'isHidden': instance.isHidden,
      'verificationStatus': instance.verificationStatus.toJson(),
      'privacySettings': instance.privacySettings.toJson(),
      'createdAt': ProfileModel._dateTimeToTimestamp(instance.createdAt),
      'updatedAt': ProfileModel._dateTimeToTimestamp(instance.updatedAt),
    };

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geohash: json['geohash'] as String,
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geohash': instance.geohash,
    };

PhotoCollectionModel _$PhotoCollectionModelFromJson(
        Map<String, dynamic> json) =>
    PhotoCollectionModel(
      main: json['main'] as String,
      others: (json['others'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      private: (json['private'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PhotoCollectionModelToJson(
        PhotoCollectionModel instance) =>
    <String, dynamic>{
      'main': instance.main,
      'others': instance.others,
      'private': instance.private,
    };

SearchPreferencesModel _$SearchPreferencesModelFromJson(
        Map<String, dynamic> json) =>
    SearchPreferencesModel(
      minAge: (json['minAge'] as num).toInt(),
      maxAge: (json['maxAge'] as num).toInt(),
      maxDistance: (json['maxDistance'] as num).toDouble(),
      interestedIn: (json['interestedIn'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      relationshipTypes: (json['relationshipTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      showVerifiedOnly: json['showVerifiedOnly'] as bool? ?? false,
      showOnlineOnly: json['showOnlineOnly'] as bool? ?? false,
    );

Map<String, dynamic> _$SearchPreferencesModelToJson(
        SearchPreferencesModel instance) =>
    <String, dynamic>{
      'minAge': instance.minAge,
      'maxAge': instance.maxAge,
      'maxDistance': instance.maxDistance,
      'interestedIn': instance.interestedIn,
      'relationshipTypes': instance.relationshipTypes,
      'showVerifiedOnly': instance.showVerifiedOnly,
      'showOnlineOnly': instance.showOnlineOnly,
    };

VerificationStatusModel _$VerificationStatusModelFromJson(
        Map<String, dynamic> json) =>
    VerificationStatusModel(
      status: json['status'] as String,
      submittedAt:
          VerificationStatusModel._timestampToDateTime(json['submittedAt']),
      reviewedAt:
          VerificationStatusModel._timestampToDateTime(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      expiresAt:
          VerificationStatusModel._timestampToDateTime(json['expiresAt']),
      documents: (json['documents'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, DocumentStatusModel.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$VerificationStatusModelToJson(
        VerificationStatusModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'submittedAt':
          VerificationStatusModel._dateTimeToTimestamp(instance.submittedAt),
      'reviewedAt':
          VerificationStatusModel._dateTimeToTimestamp(instance.reviewedAt),
      'rejectionReason': instance.rejectionReason,
      'expiresAt':
          VerificationStatusModel._dateTimeToTimestamp(instance.expiresAt),
      'documents': instance.documents,
    };

DocumentStatusModel _$DocumentStatusModelFromJson(Map<String, dynamic> json) =>
    DocumentStatusModel(
      type: json['type'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$DocumentStatusModelToJson(
        DocumentStatusModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'status': instance.status,
    };

PrivacySettingsModel _$PrivacySettingsModelFromJson(
        Map<String, dynamic> json) =>
    PrivacySettingsModel(
      profileVisibility:
          json['profileVisibility'] as String? ?? 'visible_to_all',
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      showDistance: json['showDistance'] as bool? ?? true,
      showExactLocation: json['showExactLocation'] as bool? ?? false,
      profileDiscoverable: json['profileDiscoverable'] as bool? ?? true,
    );

Map<String, dynamic> _$PrivacySettingsModelToJson(
        PrivacySettingsModel instance) =>
    <String, dynamic>{
      'profileVisibility': instance.profileVisibility,
      'showOnlineStatus': instance.showOnlineStatus,
      'showDistance': instance.showDistance,
      'showExactLocation': instance.showExactLocation,
      'profileDiscoverable': instance.profileDiscoverable,
    };

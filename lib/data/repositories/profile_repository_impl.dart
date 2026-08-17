import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/config/app_config.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/data/datasources/remote/profile_api.dart';
import 'package:hivmeet/data/datasources/remote/settings_api.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _profileApi;
  final SettingsApi _settingsApi;
  final AuthApi _authApi;

  ProfileRepositoryImpl(this._profileApi, this._settingsApi, this._authApi);

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final response = await _profileApi.getProfile(userId);
      return Right(
          _mapJsonToProfile(response.data ?? {}, fallbackUserId: userId));
    } catch (e) {
      return Left(
          _failureFromException(e, 'Erreur lors du chargement du profil'));
    }
  }

  @override
  Future<Either<Failure, Profile>> getCurrentUserProfile() async {
    try {
      final response = await _profileApi.getCurrentProfile();
      return Right(_mapJsonToProfile(response.data ?? {}));
    } catch (e) {
      return Left(
          _failureFromException(e, 'Erreur lors du chargement du profil'));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    List<String>? interests,
    String? relationshipType,
    List<String>? relationshipTypesSought,
    SearchPreferences? searchPreferences,
    PrivacySettings? privacySettings,
  }) async {
    final data = <String, dynamic>{
      if (bio != null) 'bio': bio,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (interests != null) 'interests': interests,
      if (relationshipTypesSought != null)
        'relationship_types_sought': relationshipTypesSought,
      if (relationshipType != null)
        'relationship_types_sought': [relationshipType],
      if (searchPreferences != null) ...{
        'age_min_preference': searchPreferences.minAge,
        'age_max_preference': searchPreferences.maxAge,
        'distance_max_km': searchPreferences.maxDistance.round(),
        'genders_sought': searchPreferences.interestedIn,
        'relationship_types_sought': searchPreferences.relationshipTypes,
      },
      if (privacySettings != null) ...{
        'hide_exact_location': !privacySettings.showDistance,
        'is_hidden': privacySettings.profileVisibility == 'hidden',
        'show_online_status': privacySettings.showOnlineStatus,
        'allow_profile_in_discovery': privacySettings.profileDiscoverable,
      },
    };
    return updateProfileFields(data);
  }

  @override
  Future<Either<Failure, Profile>> updateProfileFields(
      Map<String, dynamic> fields) async {
    try {
      await _profileApi.updateProfile(fields);
      final refreshed = await _profileApi.getCurrentProfile();
      return Right(_mapJsonToProfile(refreshed.data ?? {}));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors de la mise à jour'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required File photo,
    required bool isMain,
    bool isPrivate = false,
    String? caption,
  }) async {
    final result = await uploadProfilePhotoDetails(
      photo: photo,
      isMain: isMain,
      caption: caption,
    );
    return result.map((photo) => photo.photoUrl);
  }

  @override
  Future<Either<Failure, ProfilePhoto>> uploadProfilePhotoDetails({
    required File photo,
    required bool isMain,
    String? caption,
  }) async {
    try {
      final response = await _profileApi.addPhoto(
        photo.path,
        isMain: isMain,
        caption: caption,
      );
      return Right(_mapPhoto(response.data ?? {}));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors de l’upload'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String photoUrl) async {
    return deleteProfilePhotoById(_extractPhotoId(photoUrl));
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhotoById(String photoId) async {
    try {
      await _profileApi.deletePhoto(photoId);
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors de la suppression'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainPhoto(String photoUrl) async {
    return setMainPhotoById(_extractPhotoId(photoUrl));
  }

  @override
  Future<Either<Failure, void>> setMainPhotoById(String photoId) async {
    try {
      await _profileApi.setMainPhoto(photoId);
      return const Right(null);
    } catch (e) {
      return Left(
        _failureFromException(e, 'Erreur lors de la définition de la photo'),
      );
    }
  }

  @override
  Future<Either<Failure, VerificationStatus>> getVerificationStatus() async {
    final result = await getVerificationDetails();
    return result.map((details) {
      return VerificationStatus(
        status: details.status,
        submittedAt: details.submittedAt,
        reviewedAt: details.reviewedAt,
        rejectionReason: details.rejectionReason,
        expiresAt: details.expiresAt,
        verificationCode: details.verificationCode,
        documents: {
          for (final doc in details.requiredDocuments)
            doc.type: DocumentStatus(type: doc.type, status: doc.status),
        },
      );
    });
  }

  @override
  Future<Either<Failure, VerificationDetails>> getVerificationDetails() async {
    try {
      final response = await _profileApi.getVerificationStatus();
      return Right(_mapVerificationDetails(response.data ?? {}));
    } catch (e) {
      return Left(
          _failureFromException(e, 'Erreur lors du statut de vérification'));
    }
  }

  @override
  Future<Either<Failure, VerificationUploadResult>>
      generateVerificationUploadUrl({
    required String documentType,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final response = await _profileApi.generateVerificationUploadUrl(
        documentType: documentType,
        fileType: fileType,
        fileSize: fileSize,
      );
      final data = response.data ?? {};
      return Right(VerificationUploadResult(
        uploadUrl: data['upload_url'] as String? ?? '',
        filePathOnStorage: data['file_path_on_storage'] as String? ?? '',
      ));
    } catch (e) {
      return Left(_failureFromException(
          e, 'Erreur lors de la préparation du document'));
    }
  }

  @override
  Future<Either<Failure, void>> uploadFileToSignedUrl({
    required String uploadUrl,
    required File file,
    required String fileType,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      await _profileApi.uploadFileToSignedUrl(
        uploadUrl: uploadUrl,
        bytes: bytes,
        fileType: fileType,
      );
      return const Right(null);
    } catch (e) {
      return Left(
          _failureFromException(e, 'Erreur lors de l’envoi du document'));
    }
  }

  @override
  Future<Either<Failure, void>> submitVerificationDocumentPaths({
    required List<VerificationSubmissionDocument> documents,
    required String selfieCode,
  }) async {
    try {
      await _profileApi.submitVerificationDocuments(
        documents: documents.map((doc) => doc.toJson()).toList(),
        selfieCodeUsed: selfieCode,
      );
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors de la soumission'));
    }
  }

  @override
  Future<Either<Failure, void>> submitVerificationDocuments({
    required File identityDocument,
    required File medicalDocument,
    required File selfieWithCode,
    required String verificationCode,
  }) async {
    final files = {
      'identity_document': identityDocument,
      'medical_document': medicalDocument,
      'selfie_with_code': selfieWithCode,
    };
    final documents = <VerificationSubmissionDocument>[];

    for (final entry in files.entries) {
      final fileType = _mimeTypeForFile(entry.value);
      final signedUrl = await generateVerificationUploadUrl(
        documentType: entry.key,
        fileType: fileType,
        fileSize: await entry.value.length(),
      );
      final signed = signedUrl.fold((failure) => null, (value) => value);
      if (signed == null) {
        return Left(signedUrl
            .swap()
            .getOrElse(() => const ServerFailure(message: 'Erreur document')));
      }

      final uploadResult = await uploadFileToSignedUrl(
        uploadUrl: signed.uploadUrl,
        file: entry.value,
        fileType: fileType,
      );
      if (uploadResult.isLeft()) {
        return uploadResult;
      }
      documents.add(VerificationSubmissionDocument(
        documentType: entry.key,
        filePathOnStorage: signed.filePathOnStorage,
      ));
    }

    return submitVerificationDocumentPaths(
      documents: documents,
      selfieCode: verificationCode,
    );
  }

  @override
  Future<Either<Failure, PremiumProfileStatus>>
      getPremiumProfileStatus() async {
    try {
      final response = await _profileApi.getPremiumStatus();
      return Right(_mapPremiumStatus(response.data ?? {}));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors du statut premium'));
    }
  }

  @override
  Future<Either<Failure, PrivacyPreferences>> getPrivacyPreferences() async {
    try {
      final response = await _settingsApi.getPrivacyPreferences();
      return Right(_mapPrivacyPreferences(response.data ?? {}));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors des préférences'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePrivacyPreferences(
      PrivacyPreferences preferences) async {
    try {
      await _settingsApi.updatePrivacyPreferences(preferences.toJson());
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors des préférences'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>>
      getNotificationPreferences() async {
    try {
      final response = await _settingsApi.getNotificationPreferences();
      return Right(_mapNotificationPreferences(response.data ?? {}));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors des notifications'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>>
      updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      final response = await _settingsApi
          .updateNotificationPreferences(preferences.toJson());
      return Right(
          _mapNotificationPreferences(response.data ?? preferences.toJson()));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors des notifications'));
    }
  }

  @override
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers() async {
    try {
      final response = await _settingsApi.getBlockedUsers();
      final results = response.data?['results'];
      return Right((results is List)
          ? results
              .whereType<Map<String, dynamic>>()
              .map(_mapBlockedUser)
              .toList()
          : const []);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors des blocages'));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    try {
      await _settingsApi.blockUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors du blocage'));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    try {
      await _settingsApi.unblockUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors du déblocage'));
    }
  }

  @override
  Future<Either<Failure, DataRequestResult>> requestDataExport() async {
    try {
      final response = await _settingsApi.exportUserData();
      final data = response.data ?? {};
      return Right(DataRequestResult(
        requestId: data['request_id']?.toString() ?? '',
        message: data['message'] as String? ??
            'Votre demande d’export a été enregistrée.',
        requestedAt: _parseDateTime(data['requested_at']),
        status: data['status'] as String? ?? 'pending',
      ));
    } catch (e) {
      return Left(
          _failureFromException(e, 'Erreur lors de la demande d’export'));
    }
  }

  @override
  Future<Either<Failure, DataRequestResult>> requestAccountDeletion() async {
    try {
      final response = await _settingsApi.requestAccountDeletion();
      final data = response.data ?? {};
      return Right(DataRequestResult(
        requestId: data['request_id']?.toString() ?? '',
        message: data['message'] as String? ??
            'Votre demande de suppression a été enregistrée.',
        requestedAt: _parseDateTime(data['requested_at']),
        status: data['status'] as String? ?? 'pending',
      ));
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors de la demande'));
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.tryParse(value.toString())?.toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    final result = await updateProfile(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
    );
    return result.fold(Left.new, (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> toggleProfileVisibility(bool isHidden) async {
    final privacy = await getPrivacyPreferences();
    return privacy.fold(
      Left.new,
      (prefs) => updatePrivacyPreferences(prefs.copyWith(
        profileVisibility: isHidden ? 'hidden' : 'visible_to_all',
        profileDiscoverable: !isHidden,
      )),
    );
  }

  @override
  Future<Either<Failure, Profile>> createProfile({
    required String userId,
    required String displayName,
    required DateTime birthDate,
    required String bio,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    required List<String> interests,
    required String relationshipType,
    required SearchPreferences searchPreferences,
    required File mainPhoto,
  }) async {
    final updated = await updateProfile(
      bio: bio,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      interests: interests,
      relationshipType: relationshipType,
      searchPreferences: searchPreferences,
    );
    if (updated.isLeft()) return updated;
    await uploadProfilePhoto(photo: mainPhoto, isMain: true);
    return getCurrentUserProfile();
  }

  @override
  Stream<Profile?> watchCurrentUserProfile() async* {
    final result = await getCurrentUserProfile();
    yield result.fold((_) => null, (profile) => profile);
  }

  @override
  Future<Either<Failure, void>> reorderPhotos(List<String> photoUrls) async {
    return const Left(ServerFailure(
      message: 'La réorganisation des photos n’est pas disponible.',
    ));
  }

  @override
  Future<Either<Failure, List<Profile>>> getRecommendedProfiles({
    int limit = 20,
    Profile? lastProfile,
  }) async {
    return const Left(ServerFailure(
      message: 'Utilisez la découverte pour les profils recommandés.',
    ));
  }

  @override
  Future<Either<Failure, List<Profile>>> searchProfiles({
    AgeRange? ageRange,
    int? maxDistance,
    String? relationshipType,
    List<String>? genders,
    bool verifiedOnly = false,
    int limit = 20,
  }) async {
    return const Left(ServerFailure(
      message: 'La recherche directe de profils n’est pas exposée par l’API.',
    ));
  }

  @override
  Future<Either<Failure, void>> reportProfile({
    required String userId,
    required String reason,
    String? details,
    List<String>? screenshotUrls,
  }) async {
    return reportUser(
      userId: userId,
      reason: reason,
      description: details,
    );
  }

  @override
  Future<Either<Failure, void>> reportUser({
    required String userId,
    required String reason,
    String? description,
  }) async {
    try {
      await _authApi.reportUser(
        reportedUserId: userId,
        reason: reason,
        description: description,
      );
      return const Right(null);
    } catch (e) {
      return Left(_failureFromException(e, 'Erreur lors du signalement'));
    }
  }

  Profile _mapJsonToProfile(
    Map<String, dynamic> json, {
    String? fallbackUserId,
  }) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final user = userJson != null ? _mapUserSummary(userJson) : null;
    final photos = (json['photos'] is List)
        ? (json['photos'] as List)
            .whereType<Map<String, dynamic>>()
            .map(_mapPhoto)
            .toList()
        : <ProfilePhoto>[];
    final mainPhoto = photos.cast<ProfilePhoto?>().firstWhere(
          (photo) => photo?.isMain == true,
          orElse: () => photos.isNotEmpty ? photos.first : null,
        );
    final otherPhotos = photos
        .where((photo) => photo.id != mainPhoto?.id)
        .map((photo) => photo.photoUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    final lat = _toDouble(json['latitude']);
    final lng = _toDouble(json['longitude']);
    final relationshipTypes = _stringList(json['relationship_types_sought']);
    final searchPreferences = SearchPreferences(
      minAge: _toInt(json['age_min_preference']) ?? 18,
      maxAge: _toInt(json['age_max_preference']) ?? 50,
      maxDistance: (_toDouble(json['distance_max_km']) ?? 50).toDouble(),
      interestedIn: _stringList(json['genders_sought']),
      relationshipTypes: relationshipTypes,
    );
    final privacySettings = PrivacySettings(
      profileVisibility: (json['allow_profile_in_discovery'] as bool? ?? true)
          ? 'visible_to_all'
          : 'hidden',
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      showDistance: !(json['hide_exact_location'] as bool? ?? false),
      showExactLocation: !(json['hide_exact_location'] as bool? ?? false),
      profileDiscoverable: json['allow_profile_in_discovery'] as bool? ?? true,
    );
    final age = _toInt(json['age']) ?? user?.age;
    final birthDate = user?.birthDate ??
        _parseDate(json['birth_date']) ??
        DateTime.now().subtract(Duration(days: (age ?? 25) * 365));

    return Profile(
      id: json['id'] as String? ?? '',
      userId: user?.id ?? json['user_id'] as String? ?? fallbackUserId ?? '',
      displayName: user?.displayName ?? json['display_name'] as String? ?? '',
      user: user,
      birthDate: birthDate,
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      location: Location(
        latitude: lat ?? 0,
        longitude: lng ?? 0,
        geohash: json['geohash'] as String? ?? '',
      ),
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      interests: _stringList(json['interests']),
      relationshipType:
          relationshipTypes.isNotEmpty ? relationshipTypes.first : '',
      relationshipTypesSought: relationshipTypes,
      photos: PhotoCollection(
        main: mainPhoto?.photoUrl ?? '',
        others: otherPhotos,
      ),
      photoItems: photos,
      searchPreferences: searchPreferences,
      lastActive:
          user?.lastActive ?? _parseDate(json['last_active']) ?? DateTime.now(),
      isHidden: json['is_hidden'] as bool? ?? false,
      verificationStatus: VerificationStatus(
        status: user?.verificationStatus ??
            json['verification_status'] as String? ??
            'not_started',
        documents: const {},
      ),
      privacySettings: privacySettings,
      premiumStatus: json['premium_limits'] is Map<String, dynamic>
          ? _mapPremiumLimits(json['premium_limits'] as Map<String, dynamic>)
          : null,
      distanceFromMeKm: _toDouble(json['distance_from_me_km']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  ProfileUserSummary _mapUserSummary(Map<String, dynamic> json) {
    return ProfileUserSummary(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      birthDate: _parseDate(json['birth_date']),
      age: _toInt(json['age']),
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      verificationStatus:
          json['verification_status'] as String? ?? 'not_started',
      profileComplete: json['profile_complete'] as bool? ?? false,
      lastActive: _parseDate(json['last_active']),
      dateJoined: _parseDate(json['date_joined']),
    );
  }

  ProfilePhoto _mapPhoto(Map<String, dynamic> json) {
    final photoUrlRaw =
        json['photo_url'] as String? ?? json['url'] as String? ?? '';
    final thumbnailUrlRaw = json['thumbnail_url'] as String? ?? '';

    // Convertir les URLs relatives en URLs absolues
    final photoUrl = photoUrlRaw.isEmpty || photoUrlRaw.startsWith('http')
        ? photoUrlRaw
        : '${AppConfig.apiBaseUrl}/$photoUrlRaw';
    final thumbnailUrl =
        thumbnailUrlRaw.isEmpty || thumbnailUrlRaw.startsWith('http')
            ? thumbnailUrlRaw
            : '${AppConfig.apiBaseUrl}/$thumbnailUrlRaw';

    return ProfilePhoto(
      id: json['id'] as String? ?? json['photo_id'] as String? ?? '',
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      isMain: json['is_main'] as bool? ?? false,
      caption: json['caption'] as String? ?? '',
      order: _toInt(json['order']) ?? 0,
      uploadedAt: _parseDate(json['uploaded_at']),
    );
  }

  PremiumProfileStatus _mapPremiumStatus(Map<String, dynamic> json) {
    return PremiumProfileStatus(
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionType: json['subscription_type'] as String?,
      premiumUntil: _parseDate(json['premium_until']),
      features: _boolMap(json['features']),
      usage: _usageMap(json['usage']),
    );
  }

  PremiumProfileStatus _mapPremiumLimits(Map<String, dynamic> json) {
    final limits = json['limits'] is Map<String, dynamic>
        ? json['limits'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return PremiumProfileStatus(
      isPremium: json['is_premium'] as bool? ?? false,
      features: _boolMap(limits['features']),
      usage: _usageMap(limits),
    );
  }

  VerificationDetails _mapVerificationDetails(Map<String, dynamic> json) {
    final docs = json['required_documents'];
    return VerificationDetails(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
      rejectionReason: json['rejection_reason'] as String? ?? '',
      submittedAt: _parseDate(json['submitted_at']),
      reviewedAt: _parseDate(json['reviewed_at']),
      expiresAt: _parseDate(json['expires_at']),
      verificationCode: json['verification_code'] as String?,
      requiredDocuments: docs is List
          ? docs
              .whereType<Map<String, dynamic>>()
              .map((doc) => VerificationDocumentRequirement(
                    type: doc['type'] as String? ?? '',
                    status: doc['status'] as String? ?? 'pending',
                    name: doc['name'] as String? ?? '',
                  ))
              .toList()
          : const [],
    );
  }

  PrivacyPreferences _mapPrivacyPreferences(Map<String, dynamic> json) {
    return PrivacyPreferences(
      profileVisibility:
          json['profile_visibility'] as String? ?? 'visible_to_all',
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      showDistance: json['show_distance'] as bool? ?? true,
      profileDiscoverable: json['profile_discoverable'] as bool? ?? true,
    );
  }

  NotificationPreferences _mapNotificationPreferences(
      Map<String, dynamic> json) {
    return NotificationPreferences(
      newMatchNotifications: json['new_match_notifications'] as bool? ?? true,
      newMessageNotifications:
          json['new_message_notifications'] as bool? ?? true,
      profileLikeNotifications:
          json['profile_like_notifications'] as bool? ?? false,
      appUpdateNotifications: json['app_update_notifications'] as bool? ?? true,
      promotionalNotifications:
          json['promotional_notifications'] as bool? ?? false,
      doNotDisturbSettings:
          json['do_not_disturb_settings'] is Map<String, dynamic>
              ? json['do_not_disturb_settings'] as Map<String, dynamic>
              : const {
                  'enabled': false,
                  'start_time_utc': '22:00',
                  'end_time_utc': '07:00',
                },
    );
  }

  BlockedUser _mapBlockedUser(Map<String, dynamic> json) {
    final photoUrlRaw = json['profile_photo_url'] as String?;
    final profilePhotoUrl = photoUrlRaw == null ||
            photoUrlRaw.isEmpty ||
            photoUrlRaw.startsWith('http')
        ? photoUrlRaw
        : '${AppConfig.apiBaseUrl}/$photoUrlRaw';

    return BlockedUser(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      profilePhotoUrl: profilePhotoUrl,
    );
  }

  Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map<String, dynamic>) return const {};
    return value.map((key, raw) => MapEntry(key, raw == true));
  }

  Map<String, PremiumUsageQuota> _usageMap(dynamic value) {
    if (value is! Map<String, dynamic>) return const {};
    final result = <String, PremiumUsageQuota>{};
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is Map<String, dynamic>) {
        result[entry.key] = PremiumUsageQuota(
          total: _toInt(raw['total']) ?? 0,
          remaining: _toInt(raw['remaining']) ?? 0,
          used: _toInt(raw['used']) ?? 0,
          resetAt: _parseDate(raw['reset_at'] ?? raw['reset_date']),
        );
      }
    }
    return result;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _mimeTypeForFile(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.pdf')) return 'application/pdf';
    if (path.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Failure _failureFromException(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      String? message;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ??
            data['detail'] as String? ??
            data['error'] as String?;
      }
      final status = error.response?.statusCode;
      if (status == 403 && data is Map<String, dynamic>) {
        final code = data['error'] as String?;
        if (code == 'premium_required') {
          return const PremiumRequiredFailure();
        }
      }
      return ServerFailure(message: message ?? error.message ?? fallback);
    }
    return ServerFailure(message: fallback);
  }

  String _extractPhotoId(String photoUrl) {
    if (!photoUrl.contains('/')) return photoUrl;
    final uri = Uri.tryParse(photoUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : photoUrl.split('/').last;
    return lastSegment.split('.').first;
  }
}

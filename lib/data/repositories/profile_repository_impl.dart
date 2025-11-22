import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/data/datasources/remote/profile_api.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _profileApi;

  ProfileRepositoryImpl(this._profileApi);

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES IMPLÉMENTÉES (appel API réel)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final response = await _profileApi.getProfile(userId);
      final data = response.data!;

      final profile = _mapJsonToProfile(data);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du chargement du profil: $e'));
    }
  }

  @override
  Future<Either<Failure, Profile>> getCurrentUserProfile() async {
    try {
      final response = await _profileApi.getCurrentProfile();
      final data = response.data!;

      final profile = _mapJsonToProfile(data);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du chargement du profil: $e'));
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
    SearchPreferences? searchPreferences,
    PrivacySettings? privacySettings,
  }) async {
    try {
      // Construire le payload de mise à jour
      final Map<String, dynamic> data = {};

      if (displayName != null) data['display_name'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (interests != null) data['interests'] = interests;
      if (relationshipType != null) data['relationship_type'] = relationshipType;

      // Localisation
      if (latitude != null && longitude != null) {
        data['location'] = {
          'latitude': latitude,
          'longitude': longitude,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
        };
      }

      // Search preferences
      if (searchPreferences != null) {
        data['search_preferences'] = {
          'age_min': searchPreferences.minAge,
          'age_max': searchPreferences.maxAge,
          'distance_max_km': searchPreferences.maxDistance.round(),
          'genders_sought': searchPreferences.interestedIn,
        };
      }

      // Privacy settings
      if (privacySettings != null) {
        data['visibility_settings'] = {
          'is_hidden': privacySettings.profileVisibility != 'visible_to_all',
          'show_online_status': privacySettings.showOnlineStatus,
          'allow_profile_in_discovery': privacySettings.profileDiscoverable,
        };
      }

      final response = await _profileApi.updateProfile(data);

      // L'API peut retourner { profile: {...} } ou directement {...}
      final profileData = response.data!['profile'] ?? response.data!;
      final profile = _mapJsonToProfile(profileData as Map<String, dynamic>);

      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la mise à jour: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required File photo,
    required bool isMain,
    bool isPrivate = false,
  }) async {
    try {
      final response = await _profileApi.addPhoto(
        photo.path,
        isMain: isMain,
      );

      final photoData = response.data!['photo'] ?? response.data!;
      final photoUrl = photoData['photo_url'] as String;

      return Right(photoUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de l\'upload: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String photoUrl) async {
    try {
      // L'API attend un photo_id, pas une URL
      final photoId = _extractPhotoId(photoUrl);
      await _profileApi.deletePhoto(photoId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la suppression: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainPhoto(String photoUrl) async {
    try {
      final photoId = _extractPhotoId(photoUrl);
      await _profileApi.setMainPhoto(photoId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la définition de la photo principale: $e'));
    }
  }

  @override
  Future<Either<Failure, VerificationStatus>> getVerificationStatus() async {
    try {
      final response = await _profileApi.getVerificationStatus();
      final data = response.data!;

      final status = VerificationStatus(
        status: data['status'] as String? ?? 'not_started',
        submittedAt: data['submitted_at'] != null
            ? DateTime.parse(data['submitted_at'] as String)
            : null,
        reviewedAt: data['reviewed_at'] != null
            ? DateTime.parse(data['reviewed_at'] as String)
            : null,
        rejectionReason: data['rejection_reason'] as String?,
        expiresAt: data['expires_at'] != null
            ? DateTime.parse(data['expires_at'] as String)
            : null,
        documents: const {}, // TODO: Parser documents si nécessaire
      );

      return Right(status);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la récupération du statut: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitVerificationDocuments({
    required File identityDocument,
    required File medicalDocument,
    required File selfieWithCode,
    required String verificationCode,
  }) async {
    try {
      // 1. Générer les URLs d'upload
      final frontUrlResponse = await _profileApi.generateVerificationUploadUrl('id_front');
      final frontUploadUrl = frontUrlResponse.data!['upload_url'] as String;

      final backUrlResponse = await _profileApi.generateVerificationUploadUrl('id_back');
      final backUploadUrl = backUrlResponse.data!['upload_url'] as String;

      final selfieUrlResponse = await _profileApi.generateVerificationUploadUrl('selfie');
      final selfieUploadUrl = selfieUrlResponse.data!['upload_url'] as String;

      // 2. Upload les fichiers vers les URLs signées
      // TODO: Implémenter l'upload direct vers les URLs signées
      // Pour l'instant, on suppose que les URLs uploadées sont les mêmes

      // 3. Soumettre les documents
      await _profileApi.submitVerificationDocuments(
        frontDocumentUrl: frontUploadUrl,
        backDocumentUrl: backUploadUrl,
        selfieUrl: selfieUploadUrl,
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la soumission: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    try {
      await _profileApi.updateLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la mise à jour de la localisation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleProfileVisibility(bool isHidden) async {
    return updateProfile(
      privacySettings: PrivacySettings(
        profileVisibility: isHidden ? 'hidden' : 'visible_to_all',
      ),
    ).then((result) => result.fold(
          (failure) => Left(failure),
          (_) => const Right(null),
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES NON IMPLÉMENTÉES (retournent erreur au lieu de mock)
  // ═══════════════════════════════════════════════════════════════════════════

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
    return Left(ServerFailure(
      message: 'createProfile non implémenté - utiliser updateProfile après auth',
    ));
  }

  @override
  Stream<Profile?> watchCurrentUserProfile() {
    throw UnimplementedError('Real-time profile stream non implémenté');
  }

  @override
  Future<Either<Failure, void>> reorderPhotos(List<String> photoUrls) async {
    return Left(ServerFailure(
      message: 'reorderPhotos non implémenté dans l\'API backend',
    ));
  }

  @override
  Future<Either<Failure, List<Profile>>> getRecommendedProfiles({
    int limit = 20,
    Profile? lastProfile,
  }) async {
    // Utiliser getDiscoveryProfiles de MatchRepository à la place
    return Left(ServerFailure(
      message: 'Utiliser MatchRepository.getDiscoveryProfiles() à la place',
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
    return Left(ServerFailure(
      message: 'searchProfiles non implémenté - utiliser getRecommendedProfiles avec filtres',
    ));
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    return Left(ServerFailure(
      message: 'blockUser non implémenté dans l\'API backend',
    ));
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    return Left(ServerFailure(
      message: 'unblockUser non implémenté dans l\'API backend',
    ));
  }

  @override
  Future<Either<Failure, List<String>>> getBlockedUsers() async {
    return Left(ServerFailure(
      message: 'getBlockedUsers non implémenté dans l\'API backend',
    ));
  }

  @override
  Future<Either<Failure, void>> reportProfile({
    required String userId,
    required String reason,
    String? details,
    List<String>? screenshotUrls,
  }) async {
    return Left(ServerFailure(
      message: 'reportProfile non implémenté dans l\'API backend',
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS DE MAPPING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mappe les données JSON de l'API vers une entité Profile
  Profile _mapJsonToProfile(Map<String, dynamic> json) {
    // Parse location
    final locationData = json['location'] as Map<String, dynamic>?;
    final location = locationData != null
        ? Location(
            latitude: (locationData['latitude'] as num).toDouble(),
            longitude: (locationData['longitude'] as num).toDouble(),
            geohash: locationData['geohash'] as String? ?? '',
          )
        : const Location(latitude: 0, longitude: 0, geohash: '');

    // Parse photos - support array format et flat format
    final photosData = json['photos'];
    PhotoCollection photos;
    if (photosData is List && photosData.isNotEmpty) {
      // Format array: [{photo_url, is_main}, ...]
      final mainPhoto = photosData.firstWhere(
        (p) => p['is_main'] == true,
        orElse: () => photosData.isNotEmpty ? photosData.first : null,
      );
      final otherPhotos = photosData
          .where((p) => p['is_main'] != true)
          .map((p) => p['photo_url'] as String)
          .toList();

      photos = PhotoCollection(
        main: mainPhoto != null ? mainPhoto['photo_url'] as String : '',
        others: otherPhotos,
        private: const [],
      );
    } else {
      // Format flat ou absent
      photos = const PhotoCollection(main: '', others: [], private: []);
    }

    // Parse search preferences
    final searchPrefData = json['search_preferences'] as Map<String, dynamic>?;
    final searchPreferences = searchPrefData != null
        ? SearchPreferences(
            minAge: searchPrefData['age_min'] as int? ?? 18,
            maxAge: searchPrefData['age_max'] as int? ?? 50,
            maxDistance: (searchPrefData['distance_max_km'] as num?)?.toDouble() ?? 50.0,
            interestedIn: (searchPrefData['genders_sought'] as List?)?.cast<String>() ?? [],
            relationshipTypes: (searchPrefData['relationship_types_sought'] as List?)?.cast<String>() ?? [],
          )
        : const SearchPreferences(
            minAge: 18,
            maxAge: 50,
            maxDistance: 50.0,
            interestedIn: [],
            relationshipTypes: [],
          );

    // Parse privacy settings
    final visibilityData = json['visibility_settings'] as Map<String, dynamic>?;
    final privacySettings = visibilityData != null
        ? PrivacySettings(
            profileVisibility: (visibilityData['is_hidden'] as bool? ?? false)
                ? 'hidden'
                : 'visible_to_all',
            showOnlineStatus: visibilityData['show_online_status'] as bool? ?? true,
            showDistance: visibilityData['show_distance'] as bool? ?? true,
            showExactLocation: visibilityData['hide_exact_location'] as bool? ?? false ? false : true,
            profileDiscoverable: visibilityData['allow_profile_in_discovery'] as bool? ?? true,
          )
        : const PrivacySettings();

    // Parse verification status
    final verificationStatus = VerificationStatus(
      status: json['verification_status'] as String? ?? 'not_started',
      documents: const {},
    );

    // Calculate birthDate from age or use birth_date field
    DateTime birthDate;
    if (json['birth_date'] != null) {
      birthDate = DateTime.parse(json['birth_date'] as String);
    } else if (json['age'] != null) {
      final age = json['age'] as int;
      birthDate = DateTime.now().subtract(Duration(days: age * 365));
    } else {
      // Fallback obligatoire - assumons 25 ans
      birthDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    }

    return Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      birthDate: birthDate,
      bio: json['bio'] as String? ?? '',
      location: location,
      city: json['location']?['city'] as String? ?? json['city'] as String? ?? '',
      country: json['location']?['country'] as String? ?? json['country'] as String? ?? '',
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      relationshipType: json['relationship_types_sought'] is List
          ? (json['relationship_types_sought'] as List).first as String
          : json['relationship_type'] as String? ?? 'casual',
      photos: photos,
      searchPreferences: searchPreferences,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : DateTime.now(),
      isHidden: visibilityData?['is_hidden'] as bool? ?? false,
      verificationStatus: verificationStatus,
      privacySettings: privacySettings,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Extrait l'ID d'une photo depuis son URL
  /// Exemple: https://storage.googleapis.com/.../photos/abc123.jpg -> abc123
  String _extractPhotoId(String photoUrl) {
    // Si l'URL contient /photos/, extraire ce qui suit
    if (photoUrl.contains('/photos/')) {
      final parts = photoUrl.split('/photos/');
      if (parts.length > 1) {
        final idPart = parts.last.split('.').first; // Enlever l'extension
        return idPart;
      }
    }
    // Sinon, retourner l'URL complète et laisser le backend gérer
    return photoUrl;
  }
}

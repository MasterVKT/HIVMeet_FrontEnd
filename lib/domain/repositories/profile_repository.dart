// lib/domain/repositories/profile_repository.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class ProfileRepository {
  /// Crée un nouveau profil pour l'utilisateur
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
  });

  /// Récupère le profil d'un utilisateur par son ID
  Future<Either<Failure, Profile>> getProfile(String userId);

  /// Récupère le profil de l'utilisateur connecté
  Future<Either<Failure, Profile>> getCurrentUserProfile();

  /// Met à jour le profil de l'utilisateur
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
  });

  /// Mise Ã  jour avancÃ©e alignÃ©e sur le serializer backend plat.
  Future<Either<Failure, Profile>> updateProfileFields(
      Map<String, dynamic> fields);

  /// Stream du profil de l'utilisateur connecté
  Stream<Profile?> watchCurrentUserProfile();

  /// Upload une photo de profil
  Future<Either<Failure, String>> uploadProfilePhoto({
    required File photo,
    required bool isMain,
    bool isPrivate = false,
    String? caption,
  });

  Future<Either<Failure, ProfilePhoto>> uploadProfilePhotoDetails({
    required File photo,
    required bool isMain,
    String? caption,
  });

  /// Supprime une photo de profil
  Future<Either<Failure, void>> deleteProfilePhoto(String photoUrl);
  Future<Either<Failure, void>> deleteProfilePhotoById(String photoId);

  /// Définit une photo comme photo principale
  Future<Either<Failure, void>> setMainPhoto(String photoUrl);
  Future<Either<Failure, void>> setMainPhotoById(String photoId);

  /// Réorganise l'ordre des photos
  Future<Either<Failure, void>> reorderPhotos(List<String> photoUrls);

  /// Soumet les documents pour la vérification
  Future<Either<Failure, void>> submitVerificationDocuments({
    required File identityDocument,
    required File medicalDocument,
    required File selfieWithCode,
    required String verificationCode,
  });

  /// Récupère le statut de vérification
  Future<Either<Failure, VerificationStatus>> getVerificationStatus();
  Future<Either<Failure, VerificationDetails>> getVerificationDetails();
  Future<Either<Failure, VerificationUploadResult>>
      generateVerificationUploadUrl({
    required String documentType,
    required String fileType,
    required int fileSize,
  });
  Future<Either<Failure, void>> uploadFileToSignedUrl({
    required String uploadUrl,
    required File file,
    required String fileType,
  });
  Future<Either<Failure, void>> submitVerificationDocumentPaths({
    required List<VerificationSubmissionDocument> documents,
    required String selfieCode,
  });

  Future<Either<Failure, PremiumProfileStatus>> getPremiumProfileStatus();

  Future<Either<Failure, PrivacyPreferences>> getPrivacyPreferences();
  Future<Either<Failure, void>> updatePrivacyPreferences(
      PrivacyPreferences preferences);

  Future<Either<Failure, NotificationPreferences>> getNotificationPreferences();
  Future<Either<Failure, NotificationPreferences>>
      updateNotificationPreferences(NotificationPreferences preferences);

  /// Met à jour la localisation de l'utilisateur
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  });

  /// Cache/montre le profil dans la découverte
  Future<Either<Failure, void>> toggleProfileVisibility(bool isHidden);

  /// Récupère des profils recommandés pour l'utilisateur
  Future<Either<Failure, List<Profile>>> getRecommendedProfiles({
    int limit = 20,
    Profile? lastProfile,
  });

  /// Recherche des profils avec des filtres
  Future<Either<Failure, List<Profile>>> searchProfiles({
    AgeRange? ageRange,
    int? maxDistance,
    String? relationshipType,
    List<String>? genders,
    bool verifiedOnly = false,
    int limit = 20,
  });

  /// Bloque un utilisateur
  Future<Either<Failure, void>> blockUser(String userId);

  /// Débloque un utilisateur
  Future<Either<Failure, void>> unblockUser(String userId);

  /// Récupère la liste des utilisateurs bloqués
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers();

  Future<Either<Failure, DataRequestResult>> requestDataExport();
  Future<Either<Failure, DataRequestResult>> requestAccountDeletion();

  /// Signale un profil
  Future<Either<Failure, void>> reportProfile({
    required String userId,
    required String reason,
    String? details,
    List<String>? screenshotUrls,
  });

  /// Signale un utilisateur via l'API de moderation.
  Future<Either<Failure, void>> reportUser({
    required String userId,
    required String reason,
    String? description,
  });
}

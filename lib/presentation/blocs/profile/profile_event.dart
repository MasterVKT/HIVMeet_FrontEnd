// lib/presentation/blocs/profile/profile_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour charger le profil
class LoadProfile extends ProfileEvent {}

class LoadProfileSection extends ProfileEvent {}

/// Événement pour créer le profil lors de l'onboarding
class CreateProfile extends ProfileEvent {
  final File mainPhoto;
  final String bio;
  final List<String> interests;
  final String relationshipType;
  final List<String> relationshipTypesSought;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final int minAge;
  final int maxAge;
  final double maxDistance;
  final List<String> interestedIn;

  const CreateProfile({
    required this.mainPhoto,
    required this.bio,
    required this.interests,
    required this.relationshipType,
    required this.relationshipTypesSought,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.minAge,
    required this.maxAge,
    required this.maxDistance,
    required this.interestedIn,
  });

  @override
  List<Object?> get props => [
        mainPhoto,
        bio,
        interests,
        relationshipType,
        relationshipTypesSought,
        city,
        country,
        latitude,
        longitude,
        minAge,
        maxAge,
        maxDistance,
        interestedIn,
      ];
}

/// Événement pour mettre à jour le profil
class UpdateProfileEvent extends ProfileEvent {
  final String? displayName;
  final String? bio;
  final String? city;
  final String? country;
  final List<String>? interests;
  final String? relationshipType;
  final List<String>? relationshipTypesSought;
  final SearchPreferences? searchPreferences;
  final PrivacySettings? privacySettings;

  const UpdateProfileEvent({
    this.displayName,
    this.bio,
    this.city,
    this.country,
    this.interests,
    this.relationshipType,
    this.relationshipTypesSought,
    this.searchPreferences,
    this.privacySettings,
  });

  @override
  List<Object?> get props => [
        displayName,
        bio,
        city,
        country,
        interests,
        relationshipType,
        relationshipTypesSought,
        searchPreferences,
        privacySettings,
      ];
}

/// Événement pour uploader une photo
class UploadPhoto extends ProfileEvent {
  final File photo;
  final bool isMain;
  final bool isPrivate;
  final String? caption;

  const UploadPhoto({
    required this.photo,
    required this.isMain,
    this.isPrivate = false,
    this.caption,
  });

  @override
  List<Object?> get props => [photo, isMain, isPrivate, caption];
}

/// Événement pour supprimer une photo
class DeletePhoto extends ProfileEvent {
  final String photoUrl;
  final String? photoId;

  const DeletePhoto({required this.photoUrl, this.photoId});

  @override
  List<Object?> get props => [photoUrl, photoId];
}

/// Événement pour définir une photo principale
class SetMainPhoto extends ProfileEvent {
  final String photoUrl;
  final String? photoId;

  const SetMainPhoto({required this.photoUrl, this.photoId});

  @override
  List<Object?> get props => [photoUrl, photoId];
}

/// Événement pour réorganiser les photos
class ReorderPhotos extends ProfileEvent {
  final List<String> photoUrls;

  const ReorderPhotos({required this.photoUrls});

  @override
  List<Object> get props => [photoUrls];
}

/// Événement pour basculer la visibilité du profil
class ToggleProfileVisibility extends ProfileEvent {
  final bool isHidden;

  const ToggleProfileVisibility({required this.isHidden});

  @override
  List<Object> get props => [isHidden];
}

/// Événement pour mettre à jour la localisation
class UpdateLocation extends ProfileEvent {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  const UpdateLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  @override
  List<Object> get props => [latitude, longitude, city, country];
}

/// Événement pour bloquer un utilisateur
class BlockUser extends ProfileEvent {
  final String userId;

  const BlockUser({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Événement pour débloquer un utilisateur
class UnblockUser extends ProfileEvent {
  final String userId;

  const UnblockUser({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadPrivacyPreferences extends ProfileEvent {}

class SavePrivacyPreferences extends ProfileEvent {
  final PrivacyPreferences preferences;

  const SavePrivacyPreferences(this.preferences);

  @override
  List<Object> get props => [preferences];
}

class LoadNotificationPreferences extends ProfileEvent {}

class SaveNotificationPreferences extends ProfileEvent {
  final NotificationPreferences preferences;

  const SaveNotificationPreferences(this.preferences);

  @override
  List<Object> get props => [preferences];
}

class LoadBlockedUsers extends ProfileEvent {}

class RequestDataExport extends ProfileEvent {}

class RequestAccountDeletion extends ProfileEvent {}

class LoadVerificationDetails extends ProfileEvent {}

class SubmitVerificationDocuments extends ProfileEvent {
  final File identityDocument;
  final File medicalDocument;
  final File selfieWithCode;
  final String selfieCode;

  const SubmitVerificationDocuments({
    required this.identityDocument,
    required this.medicalDocument,
    required this.selfieWithCode,
    required this.selfieCode,
  });

  @override
  List<Object> get props => [
        identityDocument,
        medicalDocument,
        selfieWithCode,
        selfieCode,
      ];
}

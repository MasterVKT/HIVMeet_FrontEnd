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

/// Événement pour mettre à jour le profil
class UpdateProfile extends ProfileEvent {
  final String? displayName;
  final String? bio;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final List<String>? interests;
  final String? relationshipType;
  final SearchPreferences? searchPreferences;
  final PrivacySettings? privacySettings;

  const UpdateProfile({
    this.displayName,
    this.bio,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.interests,
    this.relationshipType,
    this.searchPreferences,
    this.privacySettings,
  });

  @override
  List<Object?> get props => [
        displayName,
        bio,
        city,
        country,
        latitude,
        longitude,
        interests,
        relationshipType,
        searchPreferences,
        privacySettings,
      ];
}

/// Événement pour uploader une photo
class UploadPhoto extends ProfileEvent {
  final File photo;
  final bool isMain;
  final bool isPrivate;

  const UploadPhoto({
    required this.photo,
    required this.isMain,
    this.isPrivate = false,
  });

  @override
  List<Object?> get props => [photo, isMain, isPrivate];
}

/// Événement pour supprimer une photo
class DeletePhoto extends ProfileEvent {
  final String photoUrl;

  const DeletePhoto({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
}

/// Événement pour définir une photo principale
class SetMainPhoto extends ProfileEvent {
  final String photoUrl;

  const SetMainPhoto({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
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
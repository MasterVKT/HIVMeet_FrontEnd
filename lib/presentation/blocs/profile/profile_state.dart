// lib/presentation/blocs/profile/profile_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ProfileInitial extends ProfileState {}

/// État de chargement
class ProfileLoading extends ProfileState {}

/// État avec le profil chargé
class ProfileLoaded extends ProfileState {
  final Profile profile;
  final bool isEditing;
  final Map<String, dynamic>? pendingChanges;

  const ProfileLoaded({
    required this.profile,
    this.isEditing = false,
    this.pendingChanges,
  });

  ProfileLoaded copyWith({
    Profile? profile,
    bool? isEditing,
    Map<String, dynamic>? pendingChanges,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isEditing: isEditing ?? this.isEditing,
      pendingChanges: pendingChanges,
    );
  }

  @override
  List<Object?> get props => [profile, isEditing, pendingChanges];
}

/// État de mise à jour du profil
class ProfileUpdating extends ProfileState {
  final Profile profile;

  const ProfileUpdating({required this.profile});

  @override
  List<Object> get props => [profile];
}

/// État d'upload de photo
class PhotoUploading extends ProfileState {
  final Profile profile;
  final double progress;

  const PhotoUploading({
    required this.profile,
    required this.progress,
  });

  @override
  List<Object> get props => [profile, progress];
}

/// État d'erreur
class ProfileError extends ProfileState {
  final String message;
  final Profile? profile;

  const ProfileError({
    required this.message,
    this.profile,
  });

  @override
  List<Object?> get props => [message, profile];
}

/// État de succès d'une action
class ProfileActionSuccess extends ProfileState {
  final String message;
  final Profile profile;

  const ProfileActionSuccess({
    required this.message,
    required this.profile,
  });

  @override
  List<Object> get props => [message, profile];
}
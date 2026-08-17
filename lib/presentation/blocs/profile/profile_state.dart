// lib/presentation/blocs/profile/profile_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  final PremiumProfileStatus? premiumStatus;
  final VerificationDetails? verification;
  final PrivacyPreferences? privacyPreferences;
  final NotificationPreferences? notificationPreferences;
  final List<BlockedUser> blockedUsers;
  final bool isEditing;
  final Map<String, dynamic>? pendingChanges;

  const ProfileLoaded({
    required this.profile,
    this.premiumStatus,
    this.verification,
    this.privacyPreferences,
    this.notificationPreferences,
    this.blockedUsers = const [],
    this.isEditing = false,
    this.pendingChanges,
  });

  ProfileLoaded copyWith({
    Profile? profile,
    PremiumProfileStatus? premiumStatus,
    VerificationDetails? verification,
    PrivacyPreferences? privacyPreferences,
    NotificationPreferences? notificationPreferences,
    List<BlockedUser>? blockedUsers,
    bool? isEditing,
    Map<String, dynamic>? pendingChanges,
    bool clearPendingChanges = false,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      premiumStatus: premiumStatus ?? this.premiumStatus,
      verification: verification ?? this.verification,
      privacyPreferences: privacyPreferences ?? this.privacyPreferences,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isEditing: isEditing ?? this.isEditing,
      pendingChanges:
          clearPendingChanges ? null : pendingChanges ?? this.pendingChanges,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        premiumStatus,
        verification,
        privacyPreferences,
        notificationPreferences,
        blockedUsers,
        isEditing,
        pendingChanges,
      ];
}

class ProfileUpdating extends ProfileState {
  final Profile profile;

  const ProfileUpdating({required this.profile});

  @override
  List<Object> get props => [profile];
}

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

class ProfileSectionLoading extends ProfileState {
  final ProfileLoaded previousState;

  const ProfileSectionLoading(this.previousState);

  @override
  List<Object> get props => [previousState];
}

class ProfileError extends ProfileState {
  final String message;
  final Profile? profile;
  final ProfileLoaded? loadedState;

  const ProfileError({
    required this.message,
    this.profile,
    this.loadedState,
  });

  @override
  List<Object?> get props => [message, profile, loadedState];
}

class ProfileActionSuccess extends ProfileState {
  final String message;
  final Profile profile;
  final ProfileLoaded? loadedState;

  const ProfileActionSuccess({
    required this.message,
    required this.profile,
    this.loadedState,
  });

  @override
  List<Object?> get props => [message, profile, loadedState];
}

/// Action RGPD (export/delete) enregistrée et en cours de traitement côté backend.
class ProfileActionPending extends ProfileState {
  final String message;
  final String requestId;
  final String actionType; // 'export' | 'deletion'
  final DateTime? requestedAt;
  final ProfileLoaded? loadedState;

  const ProfileActionPending({
    required this.message,
    required this.requestId,
    required this.actionType,
    this.requestedAt,
    this.loadedState,
  });

  @override
  List<Object?> get props =>
      [message, requestId, actionType, requestedAt, loadedState];
}

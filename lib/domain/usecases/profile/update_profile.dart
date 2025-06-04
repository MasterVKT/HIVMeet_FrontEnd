// lib/domain/usecases/profile/update_profile.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

@injectable
class UpdateProfile implements UseCase<Profile, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      displayName: params.displayName,
      bio: params.bio,
      city: params.city,
      country: params.country,
      latitude: params.latitude,
      longitude: params.longitude,
      interests: params.interests,
      relationshipType: params.relationshipType,
      searchPreferences: params.searchPreferences,
      privacySettings: params.privacySettings,
    );
  }
}

class UpdateProfileParams extends Equatable {
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

  const UpdateProfileParams({
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

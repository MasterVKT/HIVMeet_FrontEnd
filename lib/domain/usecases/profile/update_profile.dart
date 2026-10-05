// lib/domain/usecases/profile/update_profile.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
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
      gender: params.gender,
      city: params.city,
      country: params.country,
      preferredCurrency: params.preferredCurrency,
      interests: params.interests,
      relationshipType: params.relationshipType,
      relationshipTypesSought: params.relationshipTypesSought,
      searchPreferences: params.searchPreferences,
      privacySettings: params.privacySettings,
      locationUpdate: params.locationUpdate,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? displayName;
  final String? bio;
  final String? gender;
  final String? city;
  final String? country;
  final String? preferredCurrency;
  final List<String>? interests;
  final String? relationshipType;
  final List<String>? relationshipTypesSought;
  final SearchPreferences? searchPreferences;
  final PrivacySettings? privacySettings;
  final ProfileLocationUpdate? locationUpdate;

  const UpdateProfileParams({
    this.displayName,
    this.bio,
    this.gender,
    this.city,
    this.country,
    this.preferredCurrency,
    this.interests,
    this.relationshipType,
    this.relationshipTypesSought,
    this.searchPreferences,
    this.privacySettings,
    this.locationUpdate,
  });

  @override
  List<Object?> get props => [
        displayName,
        bio,
        gender,
        city,
        country,
        preferredCurrency,
        interests,
        relationshipType,
        relationshipTypesSought,
        searchPreferences,
        privacySettings,
        locationUpdate,
      ];
}

// lib/domain/usecases/match/dislike_profile.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use case pour disliker un profil (swipe left)
///
/// Le profil ne sera plus proposé dans la découverte
/// Cette action peut être annulée avec le Rewind (feature premium)
@injectable
class DislikeProfile implements UseCase<void, DislikeProfileParams> {
  final MatchRepository repository;

  DislikeProfile(this.repository);

  @override
  Future<Either<Failure, void>> call(DislikeProfileParams params) async {
    return await repository.dislikeProfile(params.profileId);
  }
}

/// Paramètres pour le dislike d'un profil
class DislikeProfileParams extends Equatable {
  /// ID du profil à disliker
  final String profileId;

  const DislikeProfileParams({required this.profileId});

  @override
  List<Object> get props => [profileId];
}

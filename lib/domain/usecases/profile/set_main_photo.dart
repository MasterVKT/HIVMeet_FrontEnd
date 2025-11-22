// lib/domain/usecases/profile/set_main_photo.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour définir la photo principale du profil
///
/// Change quelle photo est affichée en premier sur le profil.
/// La photo principale est celle visible dans la découverte et les matches.
@injectable
class SetMainPhoto {
  final ProfileRepository repository;

  SetMainPhoto(this.repository);

  Future<Either<Failure, void>> call(SetMainPhotoParams params) async {
    // Validation: URL non vide
    if (params.photoUrl.trim().isEmpty) {
      return Left(ServerFailure(
        message: 'L\'URL de la photo est invalide',
      ));
    }

    return await repository.setMainPhoto(params.photoUrl);
  }
}

class SetMainPhotoParams extends Equatable {
  final String photoUrl;

  const SetMainPhotoParams({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
}

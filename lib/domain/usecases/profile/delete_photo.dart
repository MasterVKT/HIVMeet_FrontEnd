// lib/domain/usecases/profile/delete_photo.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour supprimer une photo de profil
///
/// Supprime une photo existante du profil utilisateur.
/// La photo est supprimée du serveur et du stockage.
///
/// Note: Si c'est la photo principale qui est supprimée,
/// le serveur devrait automatiquement définir une autre photo comme principale.
@injectable
class DeletePhoto {
  final ProfileRepository repository;

  DeletePhoto(this.repository);

  Future<Either<Failure, void>> call(DeletePhotoParams params) async {
    // Validation: URL non vide
    if (params.photoUrl.trim().isEmpty) {
      return Left(ServerFailure(
        message: 'L\'URL de la photo est invalide',
      ));
    }

    return await repository.deleteProfilePhoto(params.photoUrl);
  }
}

class DeletePhotoParams extends Equatable {
  final String photoUrl;

  const DeletePhotoParams({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
}

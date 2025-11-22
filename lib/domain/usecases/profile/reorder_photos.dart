// lib/domain/usecases/profile/reorder_photos.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour réorganiser l'ordre des photos
///
/// Permet à l'utilisateur de changer l'ordre d'affichage de ses photos.
/// L'ordre affecte comment les photos sont présentées dans le profil.
@injectable
class ReorderPhotos {
  final ProfileRepository repository;

  ReorderPhotos(this.repository);

  Future<Either<Failure, void>> call(ReorderPhotosParams params) async {
    // Validation: au moins une photo
    if (params.photoUrls.isEmpty) {
      return Left(ServerFailure(
        message: 'La liste des photos ne peut pas être vide',
      ));
    }

    return await repository.reorderPhotos(params.photoUrls);
  }
}

class ReorderPhotosParams extends Equatable {
  final List<String> photoUrls;

  const ReorderPhotosParams({required this.photoUrls});

  @override
  List<Object> get props => [photoUrls];
}

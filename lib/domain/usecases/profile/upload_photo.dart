// lib/domain/usecases/profile/upload_photo.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour uploader une photo de profil
///
/// Gère l'upload d'une photo vers le serveur avec options:
/// - Photo principale (isMain)
/// - Photo privée (isPrivate)
///
/// Note: La compression d'image devrait être faite via MediaRepository
/// avant d'appeler ce Use Case (voir Sprint 2 - Task 2.2).
@injectable
class UploadPhoto {
  final ProfileRepository repository;

  UploadPhoto(this.repository);

  Future<Either<Failure, String>> call(UploadPhotoParams params) async {
    // Validation: vérifier que le fichier existe
    if (!await params.photo.exists()) {
      return Left(ServerFailure(
        message: 'Le fichier photo n\'existe pas',
      ));
    }

    // Validation: taille du fichier (limite à 10MB avant compression)
    final fileSize = await params.photo.length();
    final fileSizeMB = fileSize / (1024 * 1024);
    if (fileSizeMB > 10) {
      return Left(ServerFailure(
        message: 'La photo est trop volumineuse (${fileSizeMB.toStringAsFixed(1)}MB). Maximum: 10MB',
      ));
    }

    return await repository.uploadProfilePhoto(
      photo: params.photo,
      isMain: params.isMain,
      isPrivate: params.isPrivate,
    );
  }
}

class UploadPhotoParams extends Equatable {
  final File photo;
  final bool isMain;
  final bool isPrivate;

  const UploadPhotoParams({
    required this.photo,
    this.isMain = false,
    this.isPrivate = false,
  });

  @override
  List<Object> get props => [photo, isMain, isPrivate];
}

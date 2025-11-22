// lib/domain/usecases/resources/add_to_favorites.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

/// Use Case pour ajouter une ressource aux favoris
///
/// Permet à l'utilisateur de sauvegarder une ressource dans sa liste personnelle
/// de favoris pour un accès rapide ultérieur.
@injectable
class AddToFavorites {
  final ResourceRepository repository;

  AddToFavorites(this.repository);

  Future<Either<Failure, void>> call(AddToFavoritesParams params) async {
    return await repository.addToFavorites(params.resourceId);
  }
}

class AddToFavoritesParams extends Equatable {
  final String resourceId;

  const AddToFavoritesParams({required this.resourceId});

  @override
  List<Object> get props => [resourceId];
}

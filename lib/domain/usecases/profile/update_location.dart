// lib/domain/usecases/profile/update_location.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour mettre à jour la localisation de l'utilisateur
///
/// Met à jour les coordonnées GPS de l'utilisateur pour:
/// - Le matching basé sur la distance
/// - L'affichage de la ville actuelle
/// - Le calcul de distance avec les autres profils
@injectable
class UpdateLocation {
  final ProfileRepository repository;

  UpdateLocation(this.repository);

  Future<Either<Failure, void>> call(UpdateLocationParams params) async {
    // Validation: coordonnées valides
    if (params.latitude < -90 || params.latitude > 90) {
      return Left(ServerFailure(
        message: 'Latitude invalide (doit être entre -90 et 90)',
      ));
    }

    if (params.longitude < -180 || params.longitude > 180) {
      return Left(ServerFailure(
        message: 'Longitude invalide (doit être entre -180 et 180)',
      ));
    }

    return await repository.updateLocation(
      latitude: params.latitude,
      longitude: params.longitude,
      city: params.city,
      country: params.country,
    );
  }
}

class UpdateLocationParams extends Equatable {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  const UpdateLocationParams({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  @override
  List<Object> get props => [latitude, longitude, city, country];
}

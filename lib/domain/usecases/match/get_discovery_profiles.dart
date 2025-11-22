// lib/domain/usecases/match/get_discovery_profiles.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use Case pour récupérer les profils de découverte (swipe)
///
/// Permet de charger une liste de profils compatibles selon l'algorithme de matching.
/// Supporte la pagination avec lastProfileId pour charger des profils supplémentaires.
@injectable
class GetDiscoveryProfiles {
  final MatchRepository repository;

  GetDiscoveryProfiles(this.repository);

  Future<Either<Failure, List<DiscoveryProfile>>> call(
    GetDiscoveryProfilesParams params,
  ) async {
    return await repository.getDiscoveryProfiles(
      limit: params.limit,
      lastProfileId: params.lastProfileId,
    );
  }
}

class GetDiscoveryProfilesParams extends Equatable {
  final int limit;
  final String? lastProfileId;

  const GetDiscoveryProfilesParams({
    this.limit = 20,
    this.lastProfileId,
  });

  /// Factory pour chargement initial (première page)
  factory GetDiscoveryProfilesParams.initial({int limit = 20}) {
    return GetDiscoveryProfilesParams(limit: limit);
  }

  /// Factory pour pagination (page suivante)
  factory GetDiscoveryProfilesParams.nextPage({
    required String lastProfileId,
    int limit = 20,
  }) {
    return GetDiscoveryProfilesParams(
      limit: limit,
      lastProfileId: lastProfileId,
    );
  }

  @override
  List<Object?> get props => [limit, lastProfileId];
}

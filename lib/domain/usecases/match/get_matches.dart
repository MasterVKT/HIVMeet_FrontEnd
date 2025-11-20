// lib/domain/usecases/match/get_matches.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Use case pour récupérer la liste des matches de l'utilisateur
///
/// Retourne une liste paginée de matches avec support de pagination cursor-based
@injectable
class GetMatches implements UseCase<List<Match>, GetMatchesParams> {
  final MatchRepository repository;

  GetMatches(this.repository);

  @override
  Future<Either<Failure, List<Match>>> call(GetMatchesParams params) async {
    return await repository.getMatches(
      limit: params.limit,
      lastMatchId: params.lastMatchId,
    );
  }
}

/// Paramètres pour la récupération des matches
class GetMatchesParams extends Equatable {
  /// Nombre de matches à récupérer (default: 20)
  final int limit;

  /// ID du dernier match pour pagination (optionnel)
  final String? lastMatchId;

  const GetMatchesParams({
    this.limit = 20,
    this.lastMatchId,
  });

  /// Helper pour créer les paramètres de la première page
  factory GetMatchesParams.initial({int limit = 20}) {
    return GetMatchesParams(limit: limit);
  }

  /// Helper pour créer les paramètres de la page suivante
  GetMatchesParams nextPage(String lastMatchId) {
    return GetMatchesParams(
      limit: limit,
      lastMatchId: lastMatchId,
    );
  }

  @override
  List<Object?> get props => [limit, lastMatchId];
}

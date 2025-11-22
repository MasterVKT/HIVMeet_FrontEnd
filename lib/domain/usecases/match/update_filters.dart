// lib/domain/usecases/match/update_filters.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use Case pour mettre à jour les filtres de recherche
///
/// Permet de modifier les critères de matching: âge, distance, genre, etc.
/// Les nouveaux filtres sont appliqués immédiatement et les prochains profils
/// de découverte respecteront ces critères.
@injectable
class UpdateFilters {
  final MatchRepository repository;

  UpdateFilters(this.repository);

  Future<Either<Failure, void>> call(UpdateFiltersParams params) async {
    return await repository.updateSearchFilters(params.filters);
  }
}

class UpdateFiltersParams extends Equatable {
  final SearchFilters filters;

  const UpdateFiltersParams({
    required this.filters,
  });

  @override
  List<Object> get props => [filters];
}

// lib/domain/usecases/match/delete_match.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use case pour supprimer un match (unmatch)
///
/// Cette action est irréversible et supprime la conversation associée
@injectable
class DeleteMatch implements UseCase<void, DeleteMatchParams> {
  final MatchRepository repository;

  DeleteMatch(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMatchParams params) async {
    return await repository.deleteMatch(params.matchId);
  }
}

/// Paramètres pour la suppression d'un match
class DeleteMatchParams extends Equatable {
  /// ID du match à supprimer
  final String matchId;

  /// Raison de la suppression (optionnel, pour analytics)
  final String? reason;

  const DeleteMatchParams({
    required this.matchId,
    this.reason,
  });

  @override
  List<Object?> get props => [matchId, reason];
}

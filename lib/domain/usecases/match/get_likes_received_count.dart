// lib/domain/usecases/match/get_likes_received_count.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use case pour récupérer le nombre total de likes reçus
///
/// FEATURE PREMIUM: Nécessite un abonnement actif
/// Affiche le nombre de personnes qui ont liké sans révéler leurs identités (sauf premium)
@injectable
class GetLikesReceivedCount implements UseCase<int, NoParams> {
  final MatchRepository repository;

  GetLikesReceivedCount(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getLikesReceivedCount();
  }
}

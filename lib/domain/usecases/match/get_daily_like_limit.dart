// lib/domain/usecases/match/get_daily_like_limit.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

/// Use Case pour récupérer la limite quotidienne de likes
///
/// Permet de savoir combien de likes l'utilisateur peut encore effectuer aujourd'hui.
/// Les utilisateurs gratuits ont une limite (ex: 50 likes/jour),
/// tandis que les utilisateurs premium ont des likes illimités.
@injectable
class GetDailyLikeLimit {
  final MatchRepository repository;

  GetDailyLikeLimit(this.repository);

  Future<Either<Failure, DailyLikeLimit>> call() async {
    return await repository.getDailyLikeLimit();
  }
}

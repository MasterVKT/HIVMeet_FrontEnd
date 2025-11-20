// lib/domain/usecases/match/rewind_swipe.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Use case pour annuler le dernier swipe (rewind)
///
/// FEATURE PREMIUM: Nécessite un abonnement actif
/// Permet d'annuler le dernier like ou dislike
/// Limite: 5 rewinds par jour pour les utilisateurs premium
@injectable
class RewindSwipe implements UseCase<SwipeResult, NoParams> {
  final MatchRepository repository;

  RewindSwipe(this.repository);

  @override
  Future<Either<Failure, SwipeResult>> call(NoParams params) async {
    return await repository.rewindLastSwipe();
  }
}

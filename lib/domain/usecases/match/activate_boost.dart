// lib/domain/usecases/match/activate_boost.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

@injectable
class ActivateBoost implements UseCase<BoostStatus, NoParams> {
  final MatchRepository repository;

  ActivateBoost(this.repository);

  @override
  Future<Either<Failure, BoostStatus>> call(NoParams params) async {
    return await repository.activateBoost();
  }
}

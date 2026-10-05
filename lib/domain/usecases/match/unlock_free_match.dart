import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

class UnlockFreeMatch implements UseCase<Match, UnlockFreeMatchParams> {
  final MatchRepository repository;

  UnlockFreeMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(UnlockFreeMatchParams params) {
    return repository.unlockFreeMatch(params.matchId);
  }
}

class UnlockFreeMatchParams extends Equatable {
  final String matchId;

  const UnlockFreeMatchParams(this.matchId);

  @override
  List<Object?> get props => [matchId];
}

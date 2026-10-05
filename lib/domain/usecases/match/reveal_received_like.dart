import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

class RevealReceivedLike implements UseCase<DiscoveryProfile, NoParams> {
  final MatchRepository repository;

  RevealReceivedLike(this.repository);

  @override
  Future<Either<Failure, DiscoveryProfile>> call(NoParams params) {
    return repository.revealReceivedLike();
  }
}

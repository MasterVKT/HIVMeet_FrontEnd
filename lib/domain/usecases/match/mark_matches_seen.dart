import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

@injectable
class MarkMatchesSeen implements UseCase<int, MarkMatchesSeenParams> {
  final MatchRepository repository;

  MarkMatchesSeen(this.repository);

  @override
  Future<Either<Failure, int>> call(MarkMatchesSeenParams params) =>
      repository.markMatchesSeen(params.matchIds);
}

class MarkMatchesSeenParams extends Equatable {
  final List<String> matchIds;

  const MarkMatchesSeenParams(this.matchIds);

  @override
  List<Object?> get props => [matchIds];
}

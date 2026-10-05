import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

@injectable
class GetUnseenMatchCount implements UseCase<int, NoParams> {
  final MatchRepository repository;

  GetUnseenMatchCount(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) =>
      repository.getUnseenMatchCount();
}

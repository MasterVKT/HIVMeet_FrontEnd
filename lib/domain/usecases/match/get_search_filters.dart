import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

@injectable
class GetSearchFilters implements UseCase<SearchPreferences, NoParams> {
  final MatchRepository repository;

  GetSearchFilters(this.repository);

  @override
  Future<Either<Failure, SearchPreferences>> call(NoParams params) async {
    return repository.getSearchFilters();
  }
}

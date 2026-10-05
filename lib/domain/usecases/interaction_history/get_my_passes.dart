// lib/domain/usecases/interaction_history/get_my_passes.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Use case pour récupérer la liste des profils passés
@injectable
class GetMyPasses
    implements UseCase<InteractionHistoryPage, GetMyPassesParams> {
  final InteractionHistoryRepository repository;

  GetMyPasses(this.repository);

  @override
  Future<Either<Failure, InteractionHistoryPage>> call(
      GetMyPassesParams params) async {
    return await repository.getMyPasses(
      page: params.page,
      pageSize: params.pageSize,
      query: params.query,
      matchFilter: params.matchFilter,
    );
  }
}

class GetMyPassesParams extends Equatable {
  final int page;
  final int pageSize;
  final String query;
  final InteractionMatchFilter matchFilter;

  const GetMyPassesParams({
    this.page = 1,
    this.pageSize = 20,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
  });

  factory GetMyPassesParams.initial() => const GetMyPassesParams();

  GetMyPassesParams copyWith({
    int? page,
    int? pageSize,
    String? query,
    InteractionMatchFilter? matchFilter,
  }) {
    return GetMyPassesParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      query: query ?? this.query,
      matchFilter: matchFilter ?? this.matchFilter,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, query, matchFilter];
}

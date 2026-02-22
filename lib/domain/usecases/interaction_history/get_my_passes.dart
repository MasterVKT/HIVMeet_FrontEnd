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
    implements UseCase<List<InteractionHistory>, GetMyPassesParams> {
  final InteractionHistoryRepository repository;

  GetMyPasses(this.repository);

  @override
  Future<Either<Failure, List<InteractionHistory>>> call(
      GetMyPassesParams params) async {
    return await repository.getMyPasses(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetMyPassesParams extends Equatable {
  final int page;
  final int pageSize;

  const GetMyPassesParams({
    this.page = 1,
    this.pageSize = 20,
  });

  factory GetMyPassesParams.initial() => const GetMyPassesParams();

  GetMyPassesParams copyWith({
    int? page,
    int? pageSize,
  }) {
    return GetMyPassesParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [page, pageSize];
}

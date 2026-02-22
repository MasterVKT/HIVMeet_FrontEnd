// lib/domain/usecases/interaction_history/get_my_likes.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Use case pour récupérer la liste des profils likés
@injectable
class GetMyLikes
    implements UseCase<List<InteractionHistory>, GetMyLikesParams> {
  final InteractionHistoryRepository repository;

  GetMyLikes(this.repository);

  @override
  Future<Either<Failure, List<InteractionHistory>>> call(
      GetMyLikesParams params) async {
    return await repository.getMyLikes(
      page: params.page,
      pageSize: params.pageSize,
      includeMatched: params.includeMatched,
    );
  }
}

class GetMyLikesParams extends Equatable {
  final int page;
  final int pageSize;
  final bool includeMatched;

  const GetMyLikesParams({
    this.page = 1,
    this.pageSize = 20,
    this.includeMatched = false,
  });

  factory GetMyLikesParams.initial() => const GetMyLikesParams();

  GetMyLikesParams copyWith({
    int? page,
    int? pageSize,
    bool? includeMatched,
  }) {
    return GetMyLikesParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      includeMatched: includeMatched ?? this.includeMatched,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, includeMatched];
}

// lib/domain/usecases/interaction_history/get_interaction_stats.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Use case pour récupérer les statistiques d'interactions
@injectable
class GetInteractionStats implements UseCase<InteractionStats, NoParams> {
  final InteractionHistoryRepository repository;

  GetInteractionStats(this.repository);

  @override
  Future<Either<Failure, InteractionStats>> call(NoParams params) async {
    return await repository.getStats();
  }
}

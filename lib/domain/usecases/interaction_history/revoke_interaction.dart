// lib/domain/usecases/interaction_history/revoke_interaction.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Use case pour révoquer une interaction
@injectable
class RevokeInteraction implements UseCase<void, RevokeInteractionParams> {
  final InteractionHistoryRepository repository;

  RevokeInteraction(this.repository);

  @override
  Future<Either<Failure, void>> call(RevokeInteractionParams params) async {
    return await repository.revokeInteraction(params.interactionId);
  }
}

class RevokeInteractionParams extends Equatable {
  final String interactionId;

  const RevokeInteractionParams({required this.interactionId});

  @override
  List<Object?> get props => [interactionId];
}

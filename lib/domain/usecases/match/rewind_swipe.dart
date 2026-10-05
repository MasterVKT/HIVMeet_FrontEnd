import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Rewinds one exact server-issued discovery interaction.
@injectable
class RewindSwipe implements UseCase<SwipeResult, RewindSwipeParams> {
  final MatchRepository repository;

  RewindSwipe(this.repository);

  @override
  Future<Either<Failure, SwipeResult>> call(
    RewindSwipeParams params,
  ) {
    return repository.rewindInteraction(params.interactionId);
  }
}

class RewindSwipeParams extends Equatable {
  final String interactionId;

  const RewindSwipeParams({required this.interactionId});

  @override
  List<Object?> get props => [interactionId];
}

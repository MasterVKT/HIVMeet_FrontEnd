import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

@injectable
class RevokeInteractions
    implements UseCase<BulkRevokeResult, BulkRevokeRequest> {
  final InteractionHistoryRepository repository;

  RevokeInteractions(this.repository);

  @override
  Future<Either<Failure, BulkRevokeResult>> call(
    BulkRevokeRequest params,
  ) =>
      repository.revokeInteractions(params);
}

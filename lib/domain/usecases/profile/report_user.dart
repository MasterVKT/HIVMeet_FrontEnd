import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

@injectable
class ReportUser {
  final ProfileRepository repository;

  ReportUser(this.repository);

  Future<Either<Failure, void>> call(ReportUserParams params) async {
    if (params.userId.trim().isEmpty) {
      return const Left(ServerFailure(message: 'Invalid user id'));
    }
    if (params.reason.trim().isEmpty) {
      return const Left(ServerFailure(message: 'Invalid report reason'));
    }

    return repository.reportUser(
      userId: params.userId,
      reason: params.reason,
      description: params.description,
    );
  }
}

class ReportUserParams extends Equatable {
  final String userId;
  final String reason;
  final String? description;

  const ReportUserParams({
    required this.userId,
    required this.reason,
    this.description,
  });

  @override
  List<Object?> get props => [userId, reason, description];
}

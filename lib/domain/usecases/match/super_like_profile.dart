// lib/domain/usecases/match/super_like_profile.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

@injectable
class SuperLikeProfile implements UseCase<SwipeResult, SuperLikeProfileParams> {
  final MatchRepository repository;

  SuperLikeProfile(this.repository);

  @override
  Future<Either<Failure, SwipeResult>> call(
      SuperLikeProfileParams params) async {
    return await repository.superLikeProfile(params.profileId);
  }
}

class SuperLikeProfileParams extends Equatable {
  final String profileId;

  const SuperLikeProfileParams({required this.profileId});

  @override
  List<Object> get props => [profileId];
}

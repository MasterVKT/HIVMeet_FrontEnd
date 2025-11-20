// lib/domain/usecases/match/like_profile.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

@injectable
class LikeProfile implements UseCase<SwipeResult, LikeProfileParams> {
  final MatchRepository repository;

  LikeProfile(this.repository);

  @override
  Future<Either<Failure, SwipeResult>> call(LikeProfileParams params) async {
    return await repository.likeProfile(params.profileId);
  }
}

class LikeProfileParams extends Equatable {
  final String profileId;

  const LikeProfileParams({required this.profileId});

  @override
  List<Object> get props => [profileId];
}

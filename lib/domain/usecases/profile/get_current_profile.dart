// lib/domain/usecases/profile/get_current_profile.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

@injectable
class GetCurrentProfile implements UseCase<Profile, NoParams> {
  final ProfileRepository repository;

  GetCurrentProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(NoParams params) async {
    return await repository.getCurrentUserProfile();
  }
}
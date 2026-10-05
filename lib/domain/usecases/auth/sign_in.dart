// lib/domain/usecases/auth/sign_in.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/utils/log_service.dart';
import 'package:hivmeet/domain/entities/user.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

@injectable
class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository repository;

  SignIn(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    LogService.debug('🔄 DEBUG SignIn: Début call avec email: ${params.email}');

    try {
      LogService.debug('🔄 DEBUG SignIn: Appel repository.signIn...');
      final result = await repository.signIn(
        email: params.email,
        password: params.password,
      );
      LogService.debug('✅ DEBUG SignIn: Repository.signIn terminé');

      return result;
    } catch (e) {
      LogService.debug('❌ DEBUG SignIn: Exception dans call: $e');
      LogService.debug('Type exception: ${e.runtimeType}');
      rethrow;
    }
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

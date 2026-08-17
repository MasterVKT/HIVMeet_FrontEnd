// lib/domain/usecases/auth/sign_in.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/user.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

@injectable
class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository repository;

  SignIn(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    debugPrint('🔄 DEBUG SignIn: Début call avec email: ${params.email}');

    try {
      debugPrint('🔄 DEBUG SignIn: Appel repository.signIn...');
      final result = await repository.signIn(
        email: params.email,
        password: params.password,
      );
      debugPrint('✅ DEBUG SignIn: Repository.signIn terminé');

      return result;
    } catch (e) {
      debugPrint('❌ DEBUG SignIn: Exception dans call: $e');
      debugPrint('Type exception: ${e.runtimeType}');
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

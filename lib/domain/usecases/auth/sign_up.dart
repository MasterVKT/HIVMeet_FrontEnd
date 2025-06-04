// lib/domain/usecases/auth/sign_up.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/user.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

@injectable
class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository repository;

  SignUp(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      birthDate: params.birthDate,
      phoneNumber: params.phoneNumber,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String displayName;
  final DateTime birthDate;
  final String? phoneNumber;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
    required this.birthDate,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, displayName, birthDate, phoneNumber];
}

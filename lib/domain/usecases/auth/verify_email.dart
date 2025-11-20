// lib/domain/usecases/auth/verify_email.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

/// Use case pour vérifier l'email de l'utilisateur avec le code reçu
///
/// Cette opération:
/// - Vérifie le code de vérification fourni par l'utilisateur
/// - Marque l'email comme vérifié dans le système
/// - Met à jour le statut de vérification dans Firestore
///
/// Erreurs possibles:
/// - [UnauthorizedFailure]: Utilisateur non connecté
/// - [ServerFailure]: Erreur de vérification (code invalide/expiré)
@injectable
class VerifyEmail implements UseCase<void, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmail(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(
      verificationCode: params.verificationCode,
    );
  }
}

class VerifyEmailParams extends Equatable {
  final String verificationCode;

  const VerifyEmailParams({required this.verificationCode});

  @override
  List<Object> get props => [verificationCode];
}

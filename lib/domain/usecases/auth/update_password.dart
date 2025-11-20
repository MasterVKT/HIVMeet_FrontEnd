// lib/domain/usecases/auth/update_password.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

/// Use case pour mettre à jour le mot de passe de l'utilisateur
///
/// Cette opération:
/// - Vérifie le mot de passe actuel pour sécurité
/// - Valide la force du nouveau mot de passe
/// - Met à jour le mot de passe dans Firebase Auth
/// - Ré-authentifie l'utilisateur avec le nouveau mot de passe
///
/// Erreurs possibles:
/// - [UnauthorizedFailure]: Utilisateur non connecté
/// - [WrongCredentialsFailure]: Mot de passe actuel incorrect
/// - [WeakPasswordFailure]: Nouveau mot de passe trop faible
/// - [ServerFailure]: Erreur lors de la mise à jour
///
/// Sécurité:
/// - Requiert ré-authentification avant changement
/// - Invalide les sessions actives après changement
@injectable
class UpdatePassword implements UseCase<void, UpdatePasswordParams> {
  final AuthRepository repository;

  UpdatePassword(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePasswordParams params) async {
    // Validation côté client
    if (params.newPassword == params.currentPassword) {
      return Left(
        ServerFailure(
          message: 'Le nouveau mot de passe doit être différent de l\'ancien',
        ),
      );
    }

    if (params.newPassword.length < 6) {
      return const Left(
        WeakPasswordFailure(),
      );
    }

    return await repository.updatePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class UpdatePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

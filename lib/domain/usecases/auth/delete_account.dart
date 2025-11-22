// lib/domain/usecases/auth/delete_account.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

/// Use case pour supprimer le compte utilisateur
///
/// Cette opération est IRRÉVERSIBLE et:
/// - Vérifie le mot de passe pour confirmation
/// - Marque le compte comme supprimé dans Firestore
/// - Supprime le compte Firebase Auth
/// - Nettoie toutes les données locales
///
/// Erreurs possibles:
/// - [UnauthorizedFailure]: Utilisateur non connecté
/// - [WrongCredentialsFailure]: Mot de passe incorrect
/// - [ServerFailure]: Erreur lors de la suppression
///
/// Sécurité:
/// - Requiert ré-authentification avant suppression
/// - Irréversible - aucune récupération possible
/// - Devrait déclencher un soft delete côté backend (garde historique)
///
/// TODO BACKEND:
/// Le backend devrait implémenter un soft delete plutôt qu'un hard delete
/// pour respecter les obligations légales (RGPD: droit à l'oubli mais conservation
/// des données nécessaires pour preuve, fraude, etc.)
@injectable
class DeleteAccount implements UseCase<void, DeleteAccountParams> {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    // Validation du mot de passe (non vide)
    if (params.password.isEmpty) {
      return Left(
        ServerFailure(
          message: 'Le mot de passe est requis pour supprimer votre compte',
        ),
      );
    }

    return await repository.deleteAccount(password: params.password);
  }
}

class DeleteAccountParams extends Equatable {
  final String password;

  const DeleteAccountParams({required this.password});

  @override
  List<Object> get props => [password];
}

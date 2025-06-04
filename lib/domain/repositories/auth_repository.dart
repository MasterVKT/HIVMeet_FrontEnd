// lib/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/user.dart';

abstract class AuthRepository {
  /// Inscrit un nouvel utilisateur avec email et mot de passe
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
    String? phoneNumber,
  });

  /// Connecte un utilisateur existant
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Déconnecte l'utilisateur actuel
  Future<Either<Failure, void>> signOut();

  /// Récupère l'utilisateur actuellement connecté
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges;

  /// Envoie un email de réinitialisation de mot de passe
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Vérifie l'email de l'utilisateur avec le code reçu
  Future<Either<Failure, void>> verifyEmail({
    required String verificationCode,
  });

  /// Renvoie l'email de vérification
  Future<Either<Failure, void>> resendVerificationEmail();

  /// Met à jour le mot de passe de l'utilisateur
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Rafraîchit le token d'authentification
  Future<Either<Failure, String>> refreshToken();

  /// Récupère le token d'authentification actuel
  Future<Either<Failure, String?>> getAuthToken();

  /// Supprime le compte utilisateur
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  });
}

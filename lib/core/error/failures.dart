// lib/core/error/failures.dart

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// Erreurs générales
class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Une erreur serveur est survenue',
    String? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Erreur de connexion réseau',
    String? code,
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Erreur de cache',
    String? code,
  }) : super(message: message, code: code);
}

// Erreurs d'authentification
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class WrongCredentialsFailure extends AuthFailure {
  const WrongCredentialsFailure()
      : super(
          message: 'Email ou mot de passe incorrect',
          code: 'wrong-credentials',
        );
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure()
      : super(
          message: 'Aucun utilisateur trouvé avec cet email',
          code: 'user-not-found',
        );
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super(
          message: 'Cet email est déjà utilisé',
          code: 'email-already-in-use',
        );
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
      : super(
          message: 'Le mot de passe est trop faible',
          code: 'weak-password',
        );
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure()
      : super(
          message: 'Format d\'email invalide',
          code: 'invalid-email',
        );
}

class EmailNotVerifiedFailure extends AuthFailure {
  const EmailNotVerifiedFailure()
      : super(
          message: 'Veuillez vérifier votre email avant de vous connecter',
          code: 'email-not-verified',
        );
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure()
      : super(
          message: 'Ce compte a été désactivé',
          code: 'user-disabled',
        );
}

// Erreurs de validation
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

// Erreurs de permission
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class UnauthorizedFailure extends PermissionFailure {
  const UnauthorizedFailure()
      : super(
          message: 'Vous n\'êtes pas autorisé à effectuer cette action',
          code: 'unauthorized',
        );
}

// Erreurs liées au profil
class ProfileFailure extends Failure {
  const ProfileFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ProfileNotFoundFailure extends ProfileFailure {
  const ProfileNotFoundFailure()
      : super(
          message: 'Profil introuvable',
          code: 'profile-not-found',
        );
}

class ProfileIncompleteFailure extends ProfileFailure {
  const ProfileIncompleteFailure()
      : super(
          message: 'Veuillez compléter votre profil',
          code: 'profile-incomplete',
        );
}

// Erreurs liées aux limites (utilisateurs gratuits)
class LimitFailure extends Failure {
  const LimitFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class DailyLikeLimitFailure extends LimitFailure {
  const DailyLikeLimitFailure()
      : super(
          message: 'Vous avez atteint votre limite quotidienne de likes',
          code: 'daily-like-limit',
        );
}

class MessageLimitFailure extends LimitFailure {
  const MessageLimitFailure()
      : super(
          message: 'Limite de messages atteinte. Passez à Premium pour continuer',
          code: 'message-limit',
        );
}

class PhotoLimitFailure extends LimitFailure {
  const PhotoLimitFailure()
      : super(
          message: 'Limite de photos atteinte. Passez à Premium pour ajouter plus de photos',
          code: 'photo-limit',
        );
}

// Erreurs de paiement
class PaymentFailure extends Failure {
  const PaymentFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

// Erreur inconnue
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'Une erreur inconnue est survenue',
    String? code,
  }) : super(message: message, code: code);
}

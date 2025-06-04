// lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  final String? code;

  ServerException({
    required this.message,
    this.code,
  });
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});
}

// Auth Exceptions
class AuthException extends ServerException {
  AuthException({required String message, String? code})
      : super(message: message, code: code);
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException()
      : super(
          message: 'Cet email est déjà utilisé',
          code: 'email-already-in-use',
        );
}

class InvalidEmailException extends AuthException {
  InvalidEmailException()
      : super(
          message: 'Format d\'email invalide',
          code: 'invalid-email',
        );
}

class WeakPasswordException extends AuthException {
  WeakPasswordException()
      : super(
          message: 'Le mot de passe est trop faible',
          code: 'weak-password',
        );
}

class UserNotFoundException extends AuthException {
  UserNotFoundException()
      : super(
          message: 'Aucun utilisateur trouvé avec cet email',
          code: 'user-not-found',
        );
}

class WrongPasswordException extends AuthException {
  WrongPasswordException()
      : super(
          message: 'Mot de passe incorrect',
          code: 'wrong-password',
        );
}

class UserDisabledException extends AuthException {
  UserDisabledException()
      : super(
          message: 'Ce compte a été désactivé',
          code: 'user-disabled',
        );
}

class EmailNotVerifiedException extends AuthException {
  EmailNotVerifiedException()
      : super(
          message: 'Veuillez vérifier votre email avant de vous connecter',
          code: 'email-not-verified',
        );
}

class UnauthorizedException extends AuthException {
  UnauthorizedException()
      : super(
          message: 'Non autorisé',
          code: 'unauthorized',
        );
}

// Profile Exceptions
class ProfileException extends ServerException {
  ProfileException({required String message, String? code})
      : super(message: message, code: code);
}

class ProfileNotFoundException extends ProfileException {
  ProfileNotFoundException()
      : super(
          message: 'Profil introuvable',
          code: 'profile-not-found',
        );
}

class ProfileIncompleteException extends ProfileException {
  ProfileIncompleteException()
      : super(
          message: 'Profil incomplet',
          code: 'profile-incomplete',
        );
}

// Limit Exceptions
class LimitException extends ServerException {
  LimitException({required String message, String? code})
      : super(message: message, code: code);
}

class DailyLikeLimitException extends LimitException {
  DailyLikeLimitException()
      : super(
          message: 'Limite quotidienne de likes atteinte',
          code: 'daily-like-limit',
        );
}

class PhotoLimitException extends LimitException {
  PhotoLimitException()
      : super(
          message: 'Limite de photos atteinte',
          code: 'photo-limit',
        );
}

class MessageLimitException extends LimitException {
  MessageLimitException()
      : super(
          message: 'Limite de messages atteinte',
          code: 'message-limit',
        );
}

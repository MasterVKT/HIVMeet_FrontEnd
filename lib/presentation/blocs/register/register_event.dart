// lib/presentation/blocs/register/register_event.dart

import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour soumettre le formulaire d'inscription
class RegisterSubmitted extends RegisterEvent {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final DateTime birthDate;
  final String? phoneNumber;
  final bool acceptTerms;

  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.displayName,
    required this.birthDate,
    this.phoneNumber,
    required this.acceptTerms,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        confirmPassword,
        displayName,
        birthDate,
        phoneNumber,
        acceptTerms,
      ];
}

/// Événement pour valider l'email
class EmailChanged extends RegisterEvent {
  final String email;

  const EmailChanged({required this.email});

  @override
  List<Object> get props => [email];
}

/// Événement pour valider le mot de passe
class PasswordChanged extends RegisterEvent {
  final String password;

  const PasswordChanged({required this.password});

  @override
  List<Object> get props => [password];
}

/// Événement pour valider la confirmation du mot de passe
class ConfirmPasswordChanged extends RegisterEvent {
  final String confirmPassword;
  final String password;

  const ConfirmPasswordChanged({
    required this.confirmPassword,
    required this.password,
  });

  @override
  List<Object> get props => [confirmPassword, password];
}

/// Événement pour renvoyer l'email de vérification
class ResendVerificationEmailRequested extends RegisterEvent {}
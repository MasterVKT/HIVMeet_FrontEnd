// lib/presentation/blocs/auth/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour vérifier si l'utilisateur est connecté au démarrage
class AppStarted extends AuthEvent {}

/// Événement déclenché lorsqu'un utilisateur se connecte avec succès
class LoggedIn extends AuthEvent {
  final String userId;

  const LoggedIn({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Événement déclenché lorsqu'un utilisateur se déconnecte
class LoggedOut extends AuthEvent {}

/// Événement pour rafraîchir le token d'authentification
class RefreshToken extends AuthEvent {}

/// Événement pour supprimer le compte
class DeleteAccountRequested extends AuthEvent {
  final String password;

  const DeleteAccountRequested({required this.password});

  @override
  List<Object> get props => [password];
}

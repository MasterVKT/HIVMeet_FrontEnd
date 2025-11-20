// lib/presentation/blocs/auth/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial, en attente de vérification d'authentification
class AuthInitial extends AuthState {}

/// État pendant la vérification de l'authentification
class AuthLoading extends AuthState {}

/// État lorsque l'utilisateur est authentifié
class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

/// État lorsque l'utilisateur n'est pas authentifié
class Unauthenticated extends AuthState {}

/// État d'erreur d'authentification
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNetworkError extends AuthState {
  final String message;
  final int retryCount;
  const AuthNetworkError(this.message, {this.retryCount = 0});

  @override
  List<Object> get props => [message, retryCount];
}

/// État pendant la suppression du compte
class DeletingAccount extends AuthState {}

/// État après la suppression réussie du compte
class AccountDeleted extends AuthState {}

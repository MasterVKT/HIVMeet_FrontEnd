// lib/presentation/blocs/auth/auth_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/auth/get_current_user.dart';
import 'package:hivmeet/domain/usecases/auth/sign_out.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;
  final AuthRepository _authRepository;
  
  StreamSubscription<void>? _authStateSubscription;

  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
    required AuthRepository authRepository,
  })  : _getCurrentUser = getCurrentUser,
        _signOut = signOut,
        _authRepository = authRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<RefreshToken>(_onRefreshToken);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);

    // Écouter les changements d'état d'authentification
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(LoggedIn(userId: user.id));
      } else {
        add(LoggedOut());
      }
    });
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _getCurrentUser(NoParams());
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLoggedIn(
    LoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _getCurrentUser(NoParams());
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _signOut(NoParams());
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onRefreshToken(
    RefreshToken event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      final result = await _authRepository.refreshToken();
      
      result.fold(
        (failure) {
          emit(AuthError(message: failure.message));
          emit(Unauthenticated());
        },
        (_) => emit(currentState),
      );
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(DeletingAccount());
    
    final result = await _authRepository.deleteAccount(
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) {
        emit(AccountDeleted());
        emit(Unauthenticated());
      },
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

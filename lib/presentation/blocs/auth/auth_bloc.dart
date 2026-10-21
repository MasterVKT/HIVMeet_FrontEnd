// lib/presentation/blocs/auth/auth_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/utils/log_service.dart';
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
      if (state is! AuthLoading) {
        // Éviter les événements en boucle pendant le chargement
        if (user != null) {
          add(LoggedIn(userId: user.id));
        } else {
          add(LoggedOut());
        }
      }
    });
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _getCurrentUser(NoParams());

      result.fold(
        (failure) {
          LogService.debug('Authentication startup failed');
          // En cas d'erreur, considérer l'utilisateur comme non authentifié
          emit(Unauthenticated());
        },
        (user) {
          if (user != null) {
            emit(Authenticated(user: user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } catch (_) {
      LogService.debug('Authentication startup failed');
      // En cas d'exception, considérer l'utilisateur comme non authentifié
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    LogService.debug('Legacy AuthBloc received a login event');

    try {
      LogService.debug('🔄 DEBUG AuthBloc: Récupération current user...');
      final result = await _getCurrentUser(NoParams());

      result.fold(
        (failure) {
          LogService.debug('Legacy AuthBloc could not restore the user');
          emit(Unauthenticated());
        },
        (user) {
          if (user != null) {
            LogService.debug('✅ DEBUG AuthBloc: authenticated user restored');
            LogService.debug('🔄 DEBUG AuthBloc: Émission Authenticated...');
            emit(Authenticated(user: user));
            LogService.debug('✅ DEBUG AuthBloc: Authenticated émis');
          } else {
            LogService.debug('❌ DEBUG AuthBloc: User null reçu');
            emit(Unauthenticated());
          }
        },
      );
    } catch (_) {
      LogService.debug('Legacy AuthBloc could not restore the user');
      emit(Unauthenticated());
    }

    LogService.debug('✅ DEBUG AuthBloc: _onLoggedIn TERMINÉ');
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    // Avoid calling signOut if we are already unauthenticated to prevent repeated FirebaseAuth signOut events
    if (state is Authenticated) {
      try {
        final result = await _signOut(NoParams());
        result.fold(
          (failure) {
            LogService.debug('Sign-out request failed');
            emit(
                Unauthenticated()); // Même en cas d'erreur, considérer comme déconnecté
          },
          (_) => emit(Unauthenticated()),
        );
      } catch (_) {
        LogService.debug('Sign-out request failed');
        emit(Unauthenticated());
      }
    } else {
      // We are already unauthenticated, just emit the state without triggering signOut again
      emit(Unauthenticated());
    }
  }

  Future<void> _onRefreshToken(
    RefreshToken event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      try {
        final result = await _authRepository.refreshToken();

        result.fold(
          (failure) {
            emit(AuthError('auth.errors.session_refresh_failed'));
            emit(Unauthenticated());
          },
          (_) => emit(currentState),
        );
      } catch (_) {
        LogService.debug('Session refresh failed');
        emit(Unauthenticated());
      }
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(DeletingAccount());

    try {
      final result = await _authRepository.deleteAccount(
        password: event.password,
      );

      result.fold(
        (failure) => emit(AuthError('auth.errors.account_deletion_failed')),
        (_) {
          emit(AccountDeleted());
          emit(Unauthenticated());
        },
      );
    } catch (_) {
      LogService.debug('Account deletion request failed');
      emit(AuthError('auth.errors.account_deletion_failed'));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

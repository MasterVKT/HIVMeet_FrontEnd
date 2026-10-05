import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hivmeet/core/utils/log_service.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/data/services/notification_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthBlocSimple extends Bloc<AuthEvent, AuthState> {
  final AuthenticationService _authService;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  StreamSubscription<AuthenticationStatus>? _statusSubscription;
  StreamSubscription<domain.User?>? _userSubscription;
  StreamSubscription<String?>? _errorSubscription;

  // Protection contre les appels multiples de AppStarted
  bool _isProcessingAppStarted = false;
  DateTime? _lastAppStartedTime;

  AuthBlocSimple(this._authService) : super(AuthInitial()) {
    LogService.log(
      '🔧 [BLOC] AuthBlocSimple initialisé avec service: ${_authService.runtimeType}',
      name: 'AuthBloc',
    );
    LogService.log(
        '📊 [BLOC] État initial du service: ${_authService.status.name}',
        name: 'AuthBloc');

    // Enregistrer les handlers d'événements
    on<AppStarted>(_onAppStarted);
    on<AuthUserChanged>((event, emit) {
      if (event.user != null && _authService.isFullyAuthenticated) {
        emit(Authenticated(user: event.user!));
      } else if (event.user == null) {
        emit(Unauthenticated());
      }
    });
    on<LoginRequested>((event, emit) async {
      LogService.debug('🔐 [BLOC] Tentative de connexion: ${event.email}');
      LogService.debug(
          '📊 [BLOC] État du service avant connexion: ${_authService.status.name}');

      emit(AuthLoading());
      LogService.debug('📊 [BLOC] État émis: AuthLoading');

      int retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries) {
        try {
          LogService.debug(
              '🔄 [BLOC] Appel _authService.signInWithEmailAndPassword... (tentative ${retries + 1}/$maxRetries)');

          final result = await _authService.signInWithEmailAndPassword(
            email: event.email,
            password: event.password,
          );

          LogService.debug(
              '📊 [BLOC] Résultat de signInWithEmailAndPassword: success=${result.success}');

          if (result.success && result.user != null) {
            LogService.debug('✅ [BLOC] Connexion réussie pour ${event.email}');
            emit(Authenticated(user: result.user!));
            return;
          } else {
            LogService.debug(
                '❌ [BLOC] Connexion Firebase échouée: ${result.error}');

            // Fallback debug: essayer login backend direct si Firebase échoue
            if (kDebugMode) {
              LogService.debug(
                  '🔄 [BLOC] Fallback: tentative login backend direct...');
              final backendResult = await _authService.loginWithBackend(
                email: event.email,
                password: event.password,
              );
              if (backendResult.success && backendResult.user != null) {
                LogService.debug(
                    '✅ [BLOC] Login backend réussi pour ${event.email}');
                emit(Authenticated(user: backendResult.user!));
                return;
              }
              LogService.debug(
                  '❌ [BLOC] Login backend aussi échoué: ${backendResult.error}');
            }

            emit(AuthError(result.error ?? 'Erreur de connexion inconnue'));
            return;
          }
        } catch (e) {
          retries++;
          LogService.debug(
              '❌ [BLOC] Exception lors de la connexion (tentative $retries/$maxRetries): $e');

          // Fallback debug: essayer login backend direct sur erreur Firebase
          if (kDebugMode && retries >= maxRetries) {
            LogService.debug(
                '🔄 [BLOC] Fallback final: tentative login backend direct...');
            try {
              final backendResult = await _authService.loginWithBackend(
                email: event.email,
                password: event.password,
              );
              if (backendResult.success && backendResult.user != null) {
                LogService.debug(
                    '✅ [BLOC] Login backend réussi pour ${event.email}');
                emit(Authenticated(user: backendResult.user!));
                return;
              }
            } catch (backendErr) {
              LogService.debug('❌ [BLOC] Login backend exception: $backendErr');
            }
          }

          // Gestion spécifique des erreurs réseau Firebase
          if (e.toString().contains('network-request-failed') ||
              e.toString().contains('timeout') ||
              e.toString().contains('unreachable host')) {
            if (retries < maxRetries) {
              LogService.debug(
                  '🔄 [BLOC] Erreur réseau détectée, retry dans 2 secondes...');
              emit(AuthNetworkError(
                'Problème de connexion réseau. Tentative $retries/$maxRetries...',
                retryCount: retries,
              ));
              await Future.delayed(const Duration(seconds: 2));
              continue;
            } else {
              LogService.debug(
                  '❌ [BLOC] Échec final après $maxRetries tentatives');
              emit(AuthError(
                  'Impossible de se connecter au serveur après $maxRetries tentatives. Vérifiez votre connexion internet.'));
              return;
            }
          } else {
            // Autres erreurs (non-réseau) - pas de retry
            LogService.debug('❌ [BLOC] Erreur non-réseau, pas de retry: $e');
            emit(AuthError('Erreur lors de l\'authentification: $e'));
            return;
          }
        }
      }
    });
    on<RegisterRequested>(_onRegisterRequested);
    on<BackendLoginRequested>(_onBackendLoginRequested);
    on<LoggedOut>(_onLoggedOut);
    on<RefreshToken>(_onRefreshToken);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);

    _initializeAuthListeners();
  }

  void _initializeAuthListeners() {
    LogService.log('📡 Configuration du listener authStateChanges...',
        name: 'AuthBloc');

    // Écouter les changements de statut d'authentification
    // IMPORTANT: On ne peut pas utiliser emit() dans les listeners
    // mais on peut déclencher un événement AppStarted pour rafraîchir l'état
    _statusSubscription = _authService.statusStream.listen(
      (status) {
        LogService.log('🔔 LISTENER DÉCLENCHÉ: status: $status',
            name: 'AuthBloc');
        _handleAuthStatusChangeInternal(status);
      },
      onError: (error) {
        LogService.log('❌ Erreur status stream: $error', name: 'AuthBloc');
      },
    );

    // Écouter les changements d'utilisateur
    _userSubscription = _authService.userStream.listen(
      (user) {
        LogService.log('👤 LISTENER USER: utilisateur changé',
            name: 'AuthBloc');
        _handleUserChangeInternal(user);
      },
      onError: (error) {
        LogService.log('❌ Erreur user stream: $error', name: 'AuthBloc');
      },
    );

    // Écouter les erreurs d'authentification
    _errorSubscription = _authService.errorStream.listen(
      (error) {
        LogService.log('❌ LISTENER ERROR: $error', name: 'AuthBloc');
        // Déclencher un AppStarted pour réévaluer l'état après une erreur
        if (!isClosed) {
          add(AppStarted());
        }
      },
      onError: (error) {
        LogService.log('❌ Erreur error stream: $error', name: 'AuthBloc');
      },
    );

    LogService.log('✅ Listener authStateChanges configuré', name: 'AuthBloc');
  }

  void _handleAuthStatusChangeInternal(AuthenticationStatus status) {
    // Cette méthode ne peut pas utiliser emit() directement
    // Déclencher un événement AppStarted pour réévaluer l'état
    LogService.log(
        '🔄 Changement de status interne: $status -> déclenchement AppStarted',
        name: 'AuthBloc');

    // Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AppStarted());
    } else {
      LogService.log('⚠️ Bloc fermé, événement AppStarted ignoré',
          name: 'AuthBloc');
    }
  }

  void _handleUserChangeInternal(domain.User? user) {
    // Cette méthode ne peut pas utiliser emit() directement
    // Déclencher un événement AppStarted pour réévaluer l'état
    LogService.log(
        '👤 Changement utilisateur interne -> déclenchement AppStarted',
        name: 'AuthBloc');

    // Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AuthUserChanged(user));
    } else {
      LogService.log('⚠️ Bloc fermé, événement AppStarted ignoré',
          name: 'AuthBloc');
    }
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    LogService.log('🚀 [BLOC] AppStarted reçu', name: 'AuthBloc');

    // Protection contre les appels répétés trop rapprochés (debounce de 500ms)
    final now = DateTime.now();
    if (_lastAppStartedTime != null &&
        now.difference(_lastAppStartedTime!).inMilliseconds < 500) {
      LogService.log('⏭️ [BLOC] AppStarted ignoré (debounce)',
          name: 'AuthBloc');
      return;
    }

    _lastAppStartedTime = now;

    // Protection contre les appels concurrents
    if (_isProcessingAppStarted) {
      LogService.log('⏭️ [BLOC] AppStarted ignoré (déjà en traitement)',
          name: 'AuthBloc');
      return;
    }

    _isProcessingAppStarted = true;

    try {
      // Émettre d'abord un état de chargement
      emit(AuthLoading());

      // Vérifier le statut actuel du service
      final currentStatus = _authService.status;
      final currentUser = _authService.currentUser;

      LogService.log('📊 Status initial: $currentStatus', name: 'AuthBloc');
      LogService.log(
        '👤 Utilisateur initial présent: ${currentUser != null}',
        name: 'AuthBloc',
      );

      switch (currentStatus) {
        case AuthenticationStatus.fullyAuthenticated:
          if (currentUser != null) {
            LogService.log('✅ Déjà authentifié -> Authenticated',
                name: 'AuthBloc');
            emit(Authenticated(user: currentUser));
          } else {
            LogService.log('❌ Status authenticated mais pas d\'utilisateur',
                name: 'AuthBloc');
            emit(Unauthenticated());
          }
          break;
        case AuthenticationStatus.disconnected:
          LogService.log('🔄 Pas connecté -> Unauthenticated',
              name: 'AuthBloc');
          emit(Unauthenticated());
          break;
        case AuthenticationStatus.authenticating:
        case AuthenticationStatus.firebaseConnected:
        case AuthenticationStatus.tokensExchanged:
          LogService.log('🔄 Status $currentStatus -> AuthLoading (en cours)',
              name: 'AuthBloc');
          // Garder AuthLoading et laisser les listeners gérer la suite
          // Le timeout est géré par le SplashPage (10 secondes)
          break;
        default:
          LogService.log('🔄 Status $currentStatus -> AuthLoading',
              name: 'AuthBloc');
          emit(AuthLoading());

          // Forcer la vérification de l'état d'authentification
          try {
            await _authService.checkAuthenticationStatus();
          } catch (e) {
            LogService.log('❌ Erreur lors de la vérification: $e',
                name: 'AuthBloc');
            emit(AuthError(
                'Erreur lors de la vérification d\'authentification'));
          }
          break;
      }
    } finally {
      _isProcessingAppStarted = false;
    }
  }

  /// Handler pour login backend direct (debug only)
  void _onBackendLoginRequested(
      BackendLoginRequested event, Emitter<AuthState> emit) async {
    LogService.debug('🔐 [BLOC] BackendLoginRequested: ${event.email}');
    emit(AuthLoading());

    try {
      final result = await _authService.loginWithBackend(
        email: event.email,
        password: event.password,
      );

      if (result.success && result.user != null) {
        LogService.debug('✅ [BLOC] Login backend réussi pour ${event.email}');
        emit(Authenticated(user: result.user!));
      } else {
        LogService.debug('❌ [BLOC] Login backend échoué: ${result.error}');
        emit(AuthError(result.error ?? 'Erreur de connexion'));
      }
    } catch (e) {
      LogService.debug('❌ [BLOC] Login backend exception: $e');
      emit(AuthError('Erreur lors de l\'authentification: $e'));
    }
  }

  void _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final result = await _authService.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (result.success && result.user != null) {
        emit(Authenticated(user: result.user!));
      } else {
        emit(AuthError(result.error ?? 'Erreur lors de l\'inscription'));
      }
    } catch (e) {
      emit(AuthError('Erreur lors de l\'inscription: $e'));
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      // Retirer le token FCM du backend AVANT d'effacer le JWT : une fois
      // `signOut()` passé, `TokenManager.clearAllTokens()` a déjà vidé le
      // secure storage et tout appel authentifié (dont `DELETE
      // /auth/fcm-token`) échoue en 401. `main.dart` déclenchait jusqu'ici
      // ce retrait après coup, sur l'état `Unauthenticated` — trop tard
      // pour réussir, d'où un token FCM qui restait attaché au compte et
      // continuait de recevoir ses notifications même après déconnexion.
      await getIt<NotificationService>().removeTokenFromBackend();
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Erreur lors de la déconnexion: $e'));
    }
  }

  void _onRefreshToken(RefreshToken event, Emitter<AuthState> emit) async {
    try {
      // Pour l'instant, on suppose que le refresh est géré automatiquement
      // Si échec, les listeners se chargeront de la gestion d'erreur
      LogService.log('🔄 Refresh token demandé', name: 'AuthBloc');
    } catch (e) {
      emit(AuthError('Erreur lors du rafraîchissement: $e'));
    }
  }

  void _onDeleteAccountRequested(
      DeleteAccountRequested event, Emitter<AuthState> emit) async {
    emit(DeletingAccount());

    try {
      // TODO: Implémenter deleteAccount dans AuthenticationService
      // final success = await _authService.deleteAccount();

      // Pour l'instant, on simule un échec
      emit(AuthError('Suppression de compte non encore implémentée'));
    } catch (e) {
      emit(AuthError('Erreur lors de la suppression: $e'));
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _userSubscription?.cancel();
    _errorSubscription?.cancel();
    return super.close();
  }
}

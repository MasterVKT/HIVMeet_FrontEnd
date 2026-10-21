import 'package:bloc/bloc.dart';
import 'package:hivmeet/core/utils/log_service.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/localization_service.dart';
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
      LogService.debug('Firebase sign-in requested');
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
            LogService.debug('Firebase sign-in succeeded');
            emit(Authenticated(user: result.user!));
            return;
          } else if (result.isEmailVerificationPending) {
            emit(EmailVerificationPending());
            return;
          } else {
            LogService.debug('Firebase sign-in was rejected');
            emit(AuthError(
              result.error ?? 'auth.errors.authentication_failed',
            ));
            return;
          }
        } catch (e) {
          retries++;
          LogService.debug(
              'Firebase sign-in failed (attempt $retries/$maxRetries)');

          // Gestion spécifique des erreurs réseau Firebase
          if (e.toString().contains('network-request-failed') ||
              e.toString().contains('timeout') ||
              e.toString().contains('unreachable host')) {
            if (retries < maxRetries) {
              LogService.debug(
                  '🔄 [BLOC] Erreur réseau détectée, retry dans 2 secondes...');
              emit(AuthNetworkError(
                'auth.errors.network_retry',
                retryCount: retries,
              ));
              await Future.delayed(const Duration(seconds: 2));
              continue;
            } else {
              LogService.debug(
                  '❌ [BLOC] Échec final après $maxRetries tentatives');
              emit(AuthError('auth.errors.connection_retries_exhausted'));
              return;
            }
          } else {
            // Autres erreurs (non-réseau) - pas de retry
            LogService.debug('Firebase sign-in failed without retry');
            emit(AuthError('auth.errors.authentication_failed'));
            return;
          }
        }
      }
    });
    on<RegisterRequested>(_onRegisterRequested);
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
      onError: (_) {
        LogService.log('Authentication-status stream failed', name: 'AuthBloc');
      },
    );

    // Écouter les changements d'utilisateur
    _userSubscription = _authService.userStream.listen(
      (user) {
        LogService.log('👤 LISTENER USER: utilisateur changé',
            name: 'AuthBloc');
        _handleUserChangeInternal(user);
      },
      onError: (_) {
        LogService.log('Authentication-user stream failed', name: 'AuthBloc');
      },
    );

    // Écouter les erreurs d'authentification
    _errorSubscription = _authService.errorStream.listen(
      (_) {
        LogService.log('Authentication service reported an error', name: 'AuthBloc');
        // Déclencher un AppStarted pour réévaluer l'état après une erreur
        if (!isClosed) {
          add(AppStarted());
        }
      },
      onError: (_) {
        LogService.log('Authentication-error stream failed', name: 'AuthBloc');
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
        case AuthenticationStatus.emailVerificationPending:
          emit(EmailVerificationPending());
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
          } catch (_) {
            LogService.log('Authentication status check failed',
                name: 'AuthBloc');
            emit(AuthError('auth.errors.authentication_status_check_failed'));
          }
          break;
      }
    } finally {
      _isProcessingAppStarted = false;
    }
  }

  void _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final result = await _authService.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        locale: LocalizationService.instance.currentLocale,
      );

      if (result.success && result.user != null) {
        emit(Authenticated(user: result.user!));
      } else if (result.isEmailVerificationPending) {
        emit(EmailVerificationPending());
      } else {
        emit(AuthError(result.error ?? 'auth.errors.registration_failed'));
      }
    } catch (_) {
      emit(AuthError('auth.errors.registration_failed'));
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
    } catch (_) {
      emit(AuthError('auth.errors.sign_out_failed'));
    }
  }

  void _onRefreshToken(RefreshToken event, Emitter<AuthState> emit) async {
    try {
      // Pour l'instant, on suppose que le refresh est géré automatiquement
      // Si échec, les listeners se chargeront de la gestion d'erreur
      LogService.log('🔄 Refresh token demandé', name: 'AuthBloc');
    } catch (_) {
      emit(AuthError('auth.errors.session_refresh_failed'));
    }
  }

  void _onDeleteAccountRequested(
      DeleteAccountRequested event, Emitter<AuthState> emit) async {
    emit(DeletingAccount());

    try {
      // TODO: Implémenter deleteAccount dans AuthenticationService
      // final success = await _authService.deleteAccount();

      // Pour l'instant, on simule un échec
      emit(AuthError('auth.errors.account_deletion_unavailable'));
    } catch (_) {
      emit(AuthError('auth.errors.account_deletion_failed'));
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

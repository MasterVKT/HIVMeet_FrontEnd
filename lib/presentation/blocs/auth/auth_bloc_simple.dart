import 'package:bloc/bloc.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'dart:async';
import 'dart:developer' as developer;
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
    developer.log(
      '🔧 [BLOC] AuthBlocSimple initialisé avec service: ${_authService.runtimeType}',
      name: 'AuthBloc',
    );
    developer.log(
        '📊 [BLOC] État initial du service: ${_authService.status.name}',
        name: 'AuthBloc');

    // Enregistrer les handlers d'événements
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>((event, emit) async {
      print('🔐 [BLOC] Tentative de connexion: ${event.email}');
      print(
          '📊 [BLOC] État du service avant connexion: ${_authService.status.name}');

      emit(AuthLoading());
      print('📊 [BLOC] État émis: AuthLoading');

      int retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries) {
        try {
          print(
              '🔄 [BLOC] Appel _authService.signInWithEmailAndPassword... (tentative ${retries + 1}/$maxRetries)');

          final result = await _authService.signInWithEmailAndPassword(
            email: event.email,
            password: event.password,
          );

          print(
              '📊 [BLOC] Résultat de signInWithEmailAndPassword: success=${result.success}');

          if (result.success && result.user != null) {
            print('✅ [BLOC] Connexion réussie pour ${event.email}');
            emit(Authenticated(user: result.user!));
            return;
          } else {
            print('❌ [BLOC] Connexion échouée: ${result.error}');
            emit(AuthError(result.error ?? 'Erreur de connexion inconnue'));
            return;
          }
        } catch (e) {
          retries++;
          print(
              '❌ [BLOC] Exception lors de la connexion (tentative $retries/$maxRetries): $e');

          // Gestion spécifique des erreurs réseau Firebase
          if (e.toString().contains('network-request-failed') ||
              e.toString().contains('timeout') ||
              e.toString().contains('unreachable host')) {
            if (retries < maxRetries) {
              print(
                  '🔄 [BLOC] Erreur réseau détectée, retry dans 2 secondes...');
              emit(AuthNetworkError(
                'Problème de connexion réseau. Tentative $retries/$maxRetries...',
                retryCount: retries,
              ));
              await Future.delayed(const Duration(seconds: 2));
              continue;
            } else {
              print('❌ [BLOC] Échec final après $maxRetries tentatives');
              emit(AuthError(
                  'Impossible de se connecter au serveur après $maxRetries tentatives. Vérifiez votre connexion internet.'));
              return;
            }
          } else {
            // Autres erreurs (non-réseau) - pas de retry
            print('❌ [BLOC] Erreur non-réseau, pas de retry: $e');
            emit(AuthError('Erreur lors de l\'authentification: $e'));
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
    developer.log('📡 Configuration du listener authStateChanges...',
        name: 'AuthBloc');

    // Écouter les changements de statut d'authentification
    // IMPORTANT: On ne peut pas utiliser emit() dans les listeners
    // mais on peut déclencher un événement AppStarted pour rafraîchir l'état
    _statusSubscription = _authService.statusStream.listen(
      (status) {
        developer.log('🔔 LISTENER DÉCLENCHÉ: status: $status',
            name: 'AuthBloc');
        _handleAuthStatusChangeInternal(status);
      },
      onError: (error) {
        developer.log('❌ Erreur status stream: $error', name: 'AuthBloc');
      },
    );

    // Écouter les changements d'utilisateur
    _userSubscription = _authService.userStream.listen(
      (user) {
        developer.log('👤 LISTENER USER: utilisateur changé: ${user?.email}',
            name: 'AuthBloc');
        _handleUserChangeInternal(user);
      },
      onError: (error) {
        developer.log('❌ Erreur user stream: $error', name: 'AuthBloc');
      },
    );

    // Écouter les erreurs d'authentification
    _errorSubscription = _authService.errorStream.listen(
      (error) {
        developer.log('❌ LISTENER ERROR: $error', name: 'AuthBloc');
        // Déclencher un AppStarted pour réévaluer l'état après une erreur
        if (!isClosed) {
          add(AppStarted());
        }
      },
      onError: (error) {
        developer.log('❌ Erreur error stream: $error', name: 'AuthBloc');
      },
    );

    developer.log('✅ Listener authStateChanges configuré', name: 'AuthBloc');
  }

  void _handleAuthStatusChangeInternal(AuthenticationStatus status) {
    // Cette méthode ne peut pas utiliser emit() directement
    // Déclencher un événement AppStarted pour réévaluer l'état
    developer.log(
        '🔄 Changement de status interne: $status -> déclenchement AppStarted',
        name: 'AuthBloc');

    // Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AppStarted());
    } else {
      developer.log('⚠️ Bloc fermé, événement AppStarted ignoré',
          name: 'AuthBloc');
    }
  }

  void _handleUserChangeInternal(domain.User? user) {
    // Cette méthode ne peut pas utiliser emit() directement
    // Déclencher un événement AppStarted pour réévaluer l'état
    developer.log(
        '👤 Changement utilisateur interne: ${user?.email} -> déclenchement AppStarted',
        name: 'AuthBloc');

    // Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AppStarted());
    } else {
      developer.log('⚠️ Bloc fermé, événement AppStarted ignoré',
          name: 'AuthBloc');
    }
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    developer.log('🚀 [BLOC] AppStarted reçu', name: 'AuthBloc');

    // Protection contre les appels répétés trop rapprochés (debounce de 500ms)
    final now = DateTime.now();
    if (_lastAppStartedTime != null &&
        now.difference(_lastAppStartedTime!).inMilliseconds < 500) {
      developer.log('⏭️ [BLOC] AppStarted ignoré (debounce)', name: 'AuthBloc');
      return;
    }

    _lastAppStartedTime = now;

    // Protection contre les appels concurrents
    if (_isProcessingAppStarted) {
      developer.log('⏭️ [BLOC] AppStarted ignoré (déjà en traitement)',
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

      developer.log('📊 Status initial: $currentStatus', name: 'AuthBloc');
      developer.log('👤 Utilisateur initial: ${currentUser?.email ?? "null"}',
          name: 'AuthBloc');

      switch (currentStatus) {
        case AuthenticationStatus.fullyAuthenticated:
          if (currentUser != null) {
            developer.log('✅ Déjà authentifié -> Authenticated',
                name: 'AuthBloc');
            emit(Authenticated(user: currentUser));
          } else {
            developer.log('❌ Status authenticated mais pas d\'utilisateur',
                name: 'AuthBloc');
            emit(Unauthenticated());
          }
          break;
        case AuthenticationStatus.disconnected:
          developer.log('🔄 Pas connecté -> Unauthenticated', name: 'AuthBloc');
          emit(Unauthenticated());
          break;
        case AuthenticationStatus.authenticating:
        case AuthenticationStatus.firebaseConnected:
        case AuthenticationStatus.tokensExchanged:
          developer.log('🔄 Status $currentStatus -> AuthLoading (en cours)',
              name: 'AuthBloc');
          // Garder AuthLoading et laisser les listeners gérer la suite
          // Le timeout est géré par le SplashPage (10 secondes)
          break;
        default:
          developer.log('🔄 Status $currentStatus -> AuthLoading',
              name: 'AuthBloc');
          emit(AuthLoading());

          // Forcer la vérification de l'état d'authentification
          try {
            await _authService.checkAuthenticationStatus();
          } catch (e) {
            developer.log('❌ Erreur lors de la vérification: $e',
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
      developer.log('🔄 Refresh token demandé', name: 'AuthBloc');
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

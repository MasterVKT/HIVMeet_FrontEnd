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
    _statusSubscription = _authService.statusStream.listen(
      _handleAuthStatusChange,
      onError: (error) {
        developer.log('❌ Erreur status stream: $error', name: 'AuthBloc');
        emit(AuthError('Erreur de statut d\'authentification'));
      },
    );

    // Écouter les changements d'utilisateur
    _userSubscription = _authService.userStream.listen(
      _handleUserChange,
      onError: (error) {
        developer.log('❌ Erreur user stream: $error', name: 'AuthBloc');
        emit(AuthError('Erreur utilisateur'));
      },
    );

    // Écouter les erreurs d'authentification
    _errorSubscription = _authService.errorStream.listen(
      (error) {
        developer.log('❌ LISTENER ERROR: $error', name: 'AuthBloc');
        emit(AuthError('Erreur d\'authentification: $error'));
      },
      onError: (error) {
        developer.log('❌ Erreur error stream: $error', name: 'AuthBloc');
        emit(AuthError('Erreur dans le flux d\'erreurs'));
      },
    );

    developer.log('✅ Listener authStateChanges configuré', name: 'AuthBloc');
  }

  void _handleAuthStatusChange(AuthenticationStatus status) {
    developer.log('🔔 LISTENER DÉCLENCHÉ: authStateChanges status: $status',
        name: 'AuthBloc');

    switch (status) {
      case AuthenticationStatus.disconnected:
        developer.log('🔄 Status: disconnected -> Unauthenticated',
            name: 'AuthBloc');
        emit(Unauthenticated());
        break;
      case AuthenticationStatus.firebaseConnected:
        developer.log('🔄 Status: firebaseConnected -> AuthLoading',
            name: 'AuthBloc');
        emit(AuthLoading());
        break;
      case AuthenticationStatus.tokensExchanged:
        developer.log('🔄 Status: tokensExchanged -> continuer...',
            name: 'AuthBloc');
        // Attendre que l'utilisateur soit disponible
        break;
      case AuthenticationStatus.fullyAuthenticated:
        developer.log('🔄 Status: fullyAuthenticated -> vérifier utilisateur',
            name: 'AuthBloc');
        final user = _authService.currentUser;
        if (user != null) {
          developer.log('✅ Utilisateur disponible -> Authenticated',
              name: 'AuthBloc');
          emit(Authenticated(user: user));
        } else {
          developer.log('❌ Pas d\'utilisateur malgré fullyAuthenticated',
              name: 'AuthBloc');
          emit(AuthError('Utilisateur non disponible après authentification'));
        }
        break;
      case AuthenticationStatus.error:
        developer.log('🔄 Status: error -> AuthError', name: 'AuthBloc');
        emit(AuthError('Erreur d\'authentification'));
        break;
      case AuthenticationStatus.authenticating:
        developer.log('🔄 Status: authenticating -> AuthLoading',
            name: 'AuthBloc');
        emit(AuthLoading());
        break;
    }
  }

  void _handleUserChange(domain.User? user) {
    developer.log('👤 LISTENER USER: utilisateur changé: ${user?.email}',
        name: 'AuthBloc');

    if (user != null &&
        _authService.status == AuthenticationStatus.fullyAuthenticated) {
      developer.log('✅ Utilisateur mis à jour -> Authenticated',
          name: 'AuthBloc');
      emit(Authenticated(user: user));
    }
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    developer.log('🚀 [BLOC] AppStarted reçu', name: 'AuthBloc');

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
          emit(AuthError('Erreur lors de la vérification d\'authentification'));
        }
        break;
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

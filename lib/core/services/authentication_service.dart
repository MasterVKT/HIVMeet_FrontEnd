import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/services/token_manager.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/core/services/network_connectivity_service.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;

/// États d'authentification selon l'architecture hybride
enum AuthenticationStatus {
  /// Aucune authentificationq
  disconnected,

  /// Connecté à Firebase mais pas encore échangé
  firebaseConnected,

  /// Tokens JWT Django obtenus
  tokensExchanged,

  /// Complètement authentifié et prêt pour les APIs
  fullyAuthenticated,

  /// En cours d'authentification
  authenticating,

  /// Erreur d'authentification
  error,
}

/// Résultat d'une tentative d'authentification
class AuthenticationResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final domain.User? user;

  const AuthenticationResult({
    required this.success,
    this.error,
    this.errorCode,
    this.user,
  });

  factory AuthenticationResult.success(domain.User user) {
    return AuthenticationResult(success: true, user: user);
  }

  factory AuthenticationResult.failure(String error, [String? errorCode]) {
    return AuthenticationResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

/// Service d'authentification centralisé gérant Firebase Auth + Django JWT
class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  final TokenManager _tokenManager;
  final ApiClient _apiClient;
  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();

  // État d'authentification
  AuthenticationStatus _status = AuthenticationStatus.disconnected;
  domain.User? _currentUser;
  String? _lastError;

  // Contrôleurs de stream pour notifier les changements
  final _statusController = StreamController<AuthenticationStatus>.broadcast();
  final _userController = StreamController<domain.User?>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  // Listeners Firebase
  StreamSubscription<User?>? _firebaseAuthSubscription;

  AuthenticationService(
    this._firebaseAuth,
    this._tokenManager,
    this._apiClient,
  ) {
    developer.log('🔧 AuthenticationService initialisé', name: 'AuthService');
    _connectivityService.initialize();
    _initializeAuthentication();
  }

  // Getters pour accéder à l'état
  AuthenticationStatus get status => _status;
  domain.User? get currentUser => _currentUser;
  String? get lastError => _lastError;

  // Streams pour écouter les changements
  Stream<AuthenticationStatus> get statusStream => _statusController.stream;
  Stream<domain.User?> get userStream => _userController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  /// Met à jour le statut d'authentification
  void _updateStatus(AuthenticationStatus status) {
    _status = status;
    _statusController.add(status);
    developer.log('📊 Statut mis à jour: $status', name: 'AuthService');
  }

  /// Met à jour l'erreur actuelle
  void _updateError(String error) {
    _lastError = error;
    _errorController.add(error);
    developer.log('❌ Erreur: $error', name: 'AuthService');
  }

  /// Initialise le service d'authentification
  void _initializeAuthentication() {
    developer.log('🔐 Initialisation du service d\'authentification',
        name: 'AuthService');

    // Vérifier l'état initial de Firebase Auth
    final currentUser = _firebaseAuth.currentUser;
    developer.log(
        '👤 Utilisateur Firebase initial: ${currentUser?.email ?? "null"} (UID: ${currentUser?.uid ?? "null"})',
        name: 'AuthService');

    // Écouter les changements d'état Firebase avec logs détaillés
    developer.log('📡 Configuration du listener authStateChanges...',
        name: 'AuthService');
    _firebaseAuthSubscription = _firebaseAuth.authStateChanges().listen(
      (user) {
        developer.log(
            '🔔 LISTENER DÉCLENCHÉ: authStateChanges pour ${user?.email ?? "null"} (UID: ${user?.uid ?? "null"})',
            name: 'AuthService');
        _onFirebaseAuthStateChanged(user);
      },
      onError: (error) {
        developer.log('❌ ERREUR LISTENER authStateChanges: $error',
            name: 'AuthService');
        _onFirebaseAuthError(error);
      },
    );

    developer.log('✅ Listener authStateChanges configuré', name: 'AuthService');

    // Vérifier si des tokens sont déjà stockés
    _checkStoredTokens();

    // Si un utilisateur est déjà connecté, forcer le traitement
    if (currentUser != null) {
      developer.log('🔄 Utilisateur déjà connecté, traitement forcé...',
          name: 'AuthService');
      Future.delayed(Duration(milliseconds: 500), () {
        _onFirebaseAuthStateChanged(currentUser);
      });
    }
  }

  /// Gère les changements d'état Firebase Auth
  Future<void> _onFirebaseAuthStateChanged(User? firebaseUser) async {
    developer.log(
        '🔄 [HANDLER] Changement d\'état Firebase: ${firebaseUser?.email ?? "null"} (UID: ${firebaseUser?.uid ?? "null"})',
        name: 'AuthService');

    developer.log('📊 État actuel du service: ${_status.name}',
        name: 'AuthService');

    if (firebaseUser == null) {
      // Utilisateur déconnecté de Firebase
      developer.log('🚪 [HANDLER] Gestion déconnexion Firebase...',
          name: 'AuthService');
      await _handleFirebaseSignOut();
    } else {
      // Utilisateur connecté à Firebase
      developer.log(
          '🔐 [HANDLER] Gestion connexion Firebase pour ${firebaseUser.email}...',
          name: 'AuthService');

      // Vérifier si on a déjà traité cet utilisateur
      if (_currentUser?.id == firebaseUser.uid &&
          _status == AuthenticationStatus.fullyAuthenticated) {
        developer.log('✅ [HANDLER] Utilisateur déjà traité, ignorer',
            name: 'AuthService');
        return;
      }

      try {
        await _handleFirebaseSignIn(firebaseUser);
        developer.log('✅ [HANDLER] _handleFirebaseSignIn terminé avec succès',
            name: 'AuthService');
      } catch (e) {
        developer.log('❌ [HANDLER] Erreur dans _handleFirebaseSignIn: $e',
            name: 'AuthService');
        _updateError('Erreur traitement connexion Firebase: $e');
        _updateStatus(AuthenticationStatus.error);
      }
    }

    developer.log('📊 [HANDLER] État final du service: ${_status.name}',
        name: 'AuthService');
  }

  /// Gère les erreurs Firebase Auth
  void _onFirebaseAuthError(dynamic error) {
    developer.log('❌ Erreur Firebase Auth: $error', name: 'AuthService');
    _updateError('Erreur Firebase Auth: $error');
    _updateStatus(AuthenticationStatus.error);
  }

  /// Vérifie les tokens stockés au démarrage
  Future<void> _checkStoredTokens() async {
    try {
      final hasValidTokens = await _tokenManager.hasValidTokens();

      if (hasValidTokens) {
        developer.log('✅ Tokens valides trouvés en cache', name: 'AuthService');

        // Récupérer les informations utilisateur stockées
        final userData = await _tokenManager.getStoredUserData();
        if (userData != null) {
          _currentUser = userData;
          _updateStatus(AuthenticationStatus.fullyAuthenticated);
          _userController.add(_currentUser);

          developer.log(
              '🎯 Utilisateur restauré depuis le cache: ${userData.email}',
              name: 'AuthService');
        }
      } else {
        developer.log('ℹ️ Aucun token valide en cache', name: 'AuthService');
      }
    } catch (e) {
      developer.log('❌ Erreur lors de la vérification des tokens: $e',
          name: 'AuthService');
    }
  }

  /// Gère la connexion Firebase réussie
  Future<void> _handleFirebaseSignIn(User firebaseUser) async {
    developer.log(
        '🎯 [SIGNIN] Début _handleFirebaseSignIn pour ${firebaseUser.email}',
        name: 'AuthService');

    _updateStatus(AuthenticationStatus.firebaseConnected);
    developer.log('📊 [SIGNIN] Statut mis à jour: firebaseConnected',
        name: 'AuthService');

    try {
      // Récupérer le token Firebase
      developer.log('🔑 [SIGNIN] Récupération du token Firebase...',
          name: 'AuthService');
      final firebaseToken =
          await firebaseUser.getIdToken(true); // true = forcer le refresh

      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception(
            'Impossible de récupérer le token Firebase (null ou vide)');
      }

      developer.log(
          '🔑 [SIGNIN] Token Firebase récupéré pour ${firebaseUser.email} (${firebaseToken.length} chars)',
          name: 'AuthService');

      // Tenter l'échange de tokens (appel réel backend)
      developer.log('🔄 [SIGNIN] Appel _exchangeFirebaseTokens...',
          name: 'AuthService');
      await _exchangeFirebaseTokens(firebaseToken, firebaseUser);
      developer.log('✅ [SIGNIN] _exchangeFirebaseTokens terminé avec succès',
          name: 'AuthService');
    } catch (e) {
      developer.log(
          '❌ [SIGNIN] Erreur lors de la gestion de connexion Firebase: $e',
          name: 'AuthService');
      _updateError('Erreur lors de l\'authentification: $e');
      _updateStatus(AuthenticationStatus.error);
      rethrow; // Re-lancer l'erreur pour que le handler parent puisse la gérer
    }

    developer.log('🎯 [SIGNIN] Fin _handleFirebaseSignIn', name: 'AuthService');
  }

  /// Gère la déconnexion Firebase
  Future<void> _handleFirebaseSignOut() async {
    developer.log('🚪 Déconnexion Firebase détectée', name: 'AuthService');

    // Nettoyer tous les tokens et données
    await _tokenManager.clearAllTokens();

    _currentUser = null;
    _updateStatus(AuthenticationStatus.disconnected);
    _userController.add(null);
  }

  /// Échange les tokens Firebase contre des tokens Django JWT
  Future<void> _exchangeFirebaseTokens(
      String firebaseToken, User firebaseUser) async {
    _updateStatus(AuthenticationStatus.authenticating);

    try {
      developer.log('🔄 Tentative d\'échange Firebase → Django JWT',
          name: 'AuthService');
      developer.log(
          '🔑 Token Firebase (${firebaseToken.length} chars): ${firebaseToken.substring(0, 50)}...',
          name: 'AuthService');

      // Retry limité sur erreurs réseau temporaires
      const int maxRetries = 2;
      int attempt = 0;
      Map<String, dynamic>? responseData;
      int? responseStatus;

      while (true) {
        try {
          // Appel réel au backend via ApiClient (endpoint exclu d'auth par intercepteur)
          final response = await _apiClient.post<Map<String, dynamic>>(
            'auth/firebase-exchange/',
            data: {
              'firebase_token': firebaseToken,
            },
          );

          responseStatus = response.statusCode;
          responseData = response.data;
          break; // succès ou réponse reçue: on sort
        } on DioException catch (e) {
          final retriable = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError;

          if (retriable && attempt < maxRetries) {
            attempt++;
            final delay = Duration(milliseconds: 600 * attempt);
            developer.log(
                '⏳ Retry échange tokens (tentative $attempt/$maxRetries) après ${delay.inMilliseconds}ms: ${e.type}',
                name: 'AuthService');
            await Future.delayed(delay);
            continue;
          }

          // Non ré-essayable ou plus de tentatives: relancer pour gestion globale
          rethrow;
        }
      }

      if (responseStatus == 200) {
        final data = responseData;

        if (data == null) {
          throw Exception('Réponse vide du serveur');
        }

        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw Exception('Tokens manquants dans la réponse');
        }

        // Construire l'utilisateur depuis la réponse si disponible, sinon fallback Firebase
        domain.User user;
        if (data['user'] is Map<String, dynamic>) {
          user = domain.User.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          user = domain.User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ??
                (firebaseUser.email ?? 'Utilisateur'),
            isEmailVerified: firebaseUser.emailVerified,
            isVerified: false,
            isPremium: false,
            lastActive: DateTime.now(),
            notificationSettings: const domain.NotificationSettings(),
            blockedUserIds: [],
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
            updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          );
        }

        // Stocker tokens + user
        await _tokenManager.storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userData: user,
        );

        _currentUser = user;
        _updateStatus(AuthenticationStatus.fullyAuthenticated);
        _userController.add(_currentUser);

        developer.log('✅ Échange de tokens réussi et utilisateur mis à jour',
            name: 'AuthService');
      } else {
        final code = responseStatus ?? 0;
        throw Exception('Échec échange tokens (HTTP $code)');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      String backendCode = '';
      String backendMessage = '';
      if (data is Map<String, dynamic>) {
        backendCode = (data['code'] as String?) ?? '';
        backendMessage = (data['message'] as String?) ?? '';
      }

      final message = backendCode == 'MISSING_TOKEN'
          ? 'auth.errors.missing_token'
          : backendCode == 'INVALID_FIREBASE_TOKEN'
              ? 'auth.errors.invalid_firebase_token'
              : status == 401
                  ? 'auth.errors.unauthorized'
                  : status == 400
                      ? 'auth.errors.bad_request'
                      : 'auth.errors.exchange_failed';

      developer.log(
          '🌐 Erreur échange tokens (HTTP $status, code=$backendCode): $backendMessage',
          name: 'AuthService');
      _updateError(message);
      _updateStatus(AuthenticationStatus.error);
    } catch (e) {
      developer.log('❌ Erreur échange de tokens: $e', name: 'AuthService');
      _updateError('Erreur lors de l\'échange de tokens: $e');
      _updateStatus(AuthenticationStatus.error);
    }
  }

  /// Connexion avec email et mot de passe avec test de connectivité préalable
  Future<AuthenticationResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('🔐 Tentative de connexion: $email', name: 'AuthService');
      _updateStatus(AuthenticationStatus.authenticating);

      // Test de connectivité réseau préalable
      developer.log('📡 Vérification connectivité réseau...',
          name: 'AuthService');
      final connectivityResult =
          await _connectivityService.testBackendConnectivity();

      if (!connectivityResult.success) {
        final errorMessage = _getConnectivityErrorMessage(connectivityResult);
        developer.log('❌ Connectivité échouée: $errorMessage',
            name: 'AuthService');
        _updateError(errorMessage);
        _updateStatus(AuthenticationStatus.error);
        return AuthenticationResult.failure(errorMessage);
      }

      // Test admin via ApiClient supprimé: faux négatif (chemin /api/v1/admin/ inexistant)
      // La vérification de connectivité a déjà réussi via NetworkConnectivityService.

      developer.log('✅ Connectivité OK, tentative login backend...',
          name: 'AuthService');

      // Utiliser directement Firebase pour l'authentification
      developer.log('🔐 Authentification Firebase...', name: 'AuthService');

      // 2) Authentification Firebase avec timeout
      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout lors de l\'authentification Firebase');
        },
      );

      if (credential.user != null) {
        developer.log('✅ Connexion Firebase réussie', name: 'AuthService');

        // Appeler le flux standard qui effectue l'échange de tokens
        final firebaseUser = credential.user!;
        await _handleFirebaseSignIn(firebaseUser);

        // À ce stade, si tout s'est bien passé, _currentUser est défini
        if (_currentUser != null &&
            _status == AuthenticationStatus.fullyAuthenticated) {
          developer.log(
              '✅ Authentification complète pour ${_currentUser!.email}',
              name: 'AuthService');
          return AuthenticationResult.success(_currentUser!);
        }

        throw Exception(
            'Échec de finalisation de l\'authentification après échange de tokens');
      } else {
        throw Exception('Connexion échouée - credential.user est null');
      }
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Erreur Firebase Auth: ${e.code} - ${e.message}',
          name: 'AuthService');

      String errorMessage = _getFirebaseErrorMessage(e.code);
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage, e.code);
    } on TimeoutException {
      const errorMessage =
          'Timeout: Connexion trop lente. Vérifiez votre réseau.';
      developer.log('⏰ $errorMessage', name: 'AuthService');
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(errorMessage);
    } on DioException catch (e) {
      final errorMessage = _getDioErrorMessage(e);
      developer.log('🌐 Erreur réseau: $errorMessage', name: 'AuthService');
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(errorMessage);
    } catch (e) {
      developer.log('❌ Erreur inattendue lors de la connexion: $e',
          name: 'AuthService');

      String errorMessage = 'Erreur de connexion: $e';
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage);
    }
  }

  /// Inscription avec email et mot de passe
  Future<AuthenticationResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      developer.log('📝 Tentative d\'inscription: $email', name: 'AuthService');
      _updateStatus(AuthenticationStatus.authenticating);

      // Créer le compte Firebase
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le profil si nom fourni
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      if (credential.user != null) {
        // Le reste sera géré par le listener authStateChanges
        return AuthenticationResult.success(_currentUser!);
      } else {
        throw Exception('Inscription échouée');
      }
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Erreur inscription Firebase: ${e.code}',
          name: 'AuthService');

      String errorMessage = _getFirebaseErrorMessage(e.code);
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage, e.code);
    } catch (e) {
      developer.log('❌ Erreur inscription: $e', name: 'AuthService');

      String errorMessage = 'Erreur d\'inscription: $e';
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      developer.log('🚪 Déconnexion utilisateur', name: 'AuthService');

      // Déconnexion Firebase (triggera le listener)
      await _firebaseAuth.signOut();

      // Nettoyer tous les tokens stockés
      await _tokenManager.clearAllTokens();

      _currentUser = null;
      _updateStatus(AuthenticationStatus.disconnected);
      _userController.add(null);
    } catch (e) {
      developer.log('❌ Erreur déconnexion: $e', name: 'AuthService');
      _updateError('Erreur lors de la déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      developer.log('📧 Email de réinitialisation envoyé à: $email',
          name: 'AuthService');
      return true;
    } catch (e) {
      developer.log('❌ Erreur envoi email réinitialisation: $e',
          name: 'AuthService');
      _updateError('Erreur envoi email: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur est complètement authentifié
  bool get isFullyAuthenticated =>
      _status == AuthenticationStatus.fullyAuthenticated;

  /// Vérifie si l'utilisateur est connecté (au moins Firebase)
  bool get isAuthenticated =>
      _status == AuthenticationStatus.firebaseConnected ||
      _status == AuthenticationStatus.tokensExchanged ||
      _status == AuthenticationStatus.fullyAuthenticated;

  /// Force la vérification de l'état d'authentification actuel
  Future<void> checkAuthenticationStatus() async {
    developer.log('🔍 Vérification forcée de l\'état d\'authentification',
        name: 'AuthService');

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      developer.log('👤 Utilisateur Firebase trouvé: ${currentUser.email}',
          name: 'AuthService');

      // Si on n'est pas déjà en cours de traitement, traiter l'utilisateur
      if (_status != AuthenticationStatus.authenticating &&
          _status != AuthenticationStatus.fullyAuthenticated) {
        await _onFirebaseAuthStateChanged(currentUser);
      }
    } else {
      developer.log('❌ Aucun utilisateur Firebase trouvé', name: 'AuthService');
      await _handleFirebaseSignOut();
    }
  }

  /// Convertit les codes d'erreur Firebase en messages lisibles
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      default:
        return 'Erreur d\'authentification: $errorCode';
    }
  }

  /// Convertit les erreurs de connectivité en messages lisibles
  String _getConnectivityErrorMessage(ConnectivityResult result) {
    if (result.error == null) {
      return 'Erreur de connectivité inconnue';
    }

    switch (result.errorType) {
      case ConnectivityErrorType.noInternet:
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case ConnectivityErrorType.timeout:
        return 'Le serveur met trop de temps à répondre. Réessayez.';
      case ConnectivityErrorType.connectionRefused:
        return 'Impossible de se connecter au serveur. Vérifiez que le backend fonctionne.';
      case ConnectivityErrorType.networkError:
        return 'Erreur de réseau. Vérifiez votre connexion internet.';
      case ConnectivityErrorType.serverError:
        return 'Erreur du serveur. ${result.error}';
      case ConnectivityErrorType.apiError:
        return 'Erreur de l\'API. ${result.error}';
      case ConnectivityErrorType.unknown:
      default:
        return 'Erreur de connexion: ${result.error}';
    }
  }

  /// Convertit les erreurs Dio en messages lisibles
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Timeout de connexion. Vérifiez votre réseau.';
      case DioExceptionType.sendTimeout:
        return 'Timeout lors de l\'envoi. Réessayez.';
      case DioExceptionType.receiveTimeout:
        return 'Timeout lors de la réception. Réessayez.';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion. Vérifiez que le serveur fonctionne.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        return 'Erreur serveur (Code: $statusCode). Réessayez plus tard.';
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      case DioExceptionType.unknown:
      default:
        return 'Erreur réseau inconnue: ${e.message}';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _statusController.close();
    _userController.close();
    _errorController.close();
  }
}

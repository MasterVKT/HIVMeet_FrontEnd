import 'dart:async';
import 'package:hivmeet/core/utils/log_service.dart' as developer;
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

  /// Firebase session retained only for email verification.
  emailVerificationPending,

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
  final bool isEmailVerificationPending;
  final bool? verificationEmailSent;

  const AuthenticationResult({
    required this.success,
    this.error,
    this.errorCode,
    this.user,
    this.isEmailVerificationPending = false,
    this.verificationEmailSent,
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

  factory AuthenticationResult.emailVerificationPending({
    bool? verificationEmailSent,
  }) {
    return AuthenticationResult(
      success: true,
      isEmailVerificationPending: true,
      verificationEmailSent: verificationEmailSent,
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
  StreamSubscription<void>? _emailVerificationRequiredSubscription;
  bool _registrationSignInInProgress = false;

  AuthenticationService(
    this._firebaseAuth,
    this._tokenManager,
    this._apiClient,
  ) {
    developer.log('🔧 AuthenticationService initialisé', name: 'AuthService');
    _connectivityService.initialize();
    _emailVerificationRequiredSubscription =
        _tokenManager.emailVerificationRequiredStream.listen((_) {
      _moveToEmailVerificationAfterServerRejection();
    });
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

  bool get isEmailVerificationPending =>
      _status == AuthenticationStatus.emailVerificationPending;

  /// Retourne le JWT access token courant (pour WebSocket auth, etc.).
  Future<String?> getAccessToken() => _tokenManager.getAccessToken();

  /// Recharge l'utilisateur faisant autorité côté Django et publie le
  /// nouveau snapshot dans la session courante, sans reconnexion.
  Future<domain.User> refreshCurrentUser() async {
    final existing = _currentUser;
    if (_status != AuthenticationStatus.fullyAuthenticated ||
        existing == null) {
      throw StateError('No authenticated user to refresh');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/user-profiles/me/',
    );
    final payload = response.data;
    final rawUser = payload?['user'];
    if (rawUser is! Map) {
      throw const FormatException('Missing user in profile response');
    }

    final merged = <String, dynamic>{
      ...existing.toJson(),
      ...rawUser.map((key, value) => MapEntry(key.toString(), value)),
    };
    final refreshed = domain.User.fromJson(merged);
    await _tokenManager.updateStoredUserData(refreshed);
    _currentUser = refreshed;
    _userController.add(refreshed);
    return refreshed;
  }

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

    // Écouter les changements d'état Firebase avec logs détaillés
    developer.log('📡 Configuration du listener authStateChanges...',
        name: 'AuthService');
    _firebaseAuthSubscription = _firebaseAuth.authStateChanges().listen(
      (user) {
        _onFirebaseAuthStateChanged(user);
      },
      onError: (error) {
        developer.log('❌ ERREUR LISTENER authStateChanges: $error',
            name: 'AuthService');
        _onFirebaseAuthError(error);
      },
    );

    developer.log('✅ Listener authStateChanges configuré', name: 'AuthService');

    // A Django session is usable only with a currently verified Firebase
    // session. This check clears stale JWTs before any protected request.
    _checkStoredTokens();

    // Si un utilisateur est déjà connecté, forcer le traitement
    if (currentUser != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        _onFirebaseAuthStateChanged(currentUser);
      });
    }
  }

  /// Gère les changements d'état Firebase Auth
  Future<void> _onFirebaseAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // Utilisateur déconnecté de Firebase
      developer.log('🚪 [HANDLER] Gestion déconnexion Firebase...',
          name: 'AuthService');
      await _handleFirebaseSignOut();
    } else if (_registrationSignInInProgress) {
      // Registration invokes the exchange itself after the backend has created
      // the canonical account. Avoid a competing listener exchange.
      return;
    } else {
      await firebaseUser.reload();
      final refreshedFirebaseUser = _firebaseAuth.currentUser;
      if (refreshedFirebaseUser == null) {
        await _handleFirebaseSignOut();
        return;
      }
      if (!refreshedFirebaseUser.emailVerified) {
        await _enterEmailVerificationPending();
        return;
      }
      // Utilisateur connecté à Firebase

      // Vérifier si on a déjà traité cet utilisateur
      if (_currentUser?.id == refreshedFirebaseUser.uid &&
          _status == AuthenticationStatus.fullyAuthenticated) {
        developer.log('✅ [HANDLER] Utilisateur déjà traité, ignorer',
            name: 'AuthService');
        return;
      }

      try {
        await _handleFirebaseSignIn(refreshedFirebaseUser);
        developer.log('✅ [HANDLER] _handleFirebaseSignIn terminé avec succès',
            name: 'AuthService');
      } catch (_) {
        developer.log('Firebase session processing failed',
            name: 'AuthService');
        _updateError('auth.errors.authentication_failed');
        _updateStatus(AuthenticationStatus.error);
      }
    }

    developer.log('📊 [HANDLER] État final du service: ${_status.name}',
        name: 'AuthService');
  }

  /// Gère les erreurs Firebase Auth
  void _onFirebaseAuthError(dynamic error) {
    developer.log('Firebase Auth state listener failed', name: 'AuthService');
    _updateError('auth.errors.firebase_unavailable');
    _updateStatus(AuthenticationStatus.error);
  }

  /// Vérifie les tokens stockés au démarrage
  Future<void> _checkStoredTokens() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        await _tokenManager.clearAllTokens();
        return;
      }
      await firebaseUser.reload();
      final refreshedFirebaseUser = _firebaseAuth.currentUser;
      if (refreshedFirebaseUser == null ||
          !refreshedFirebaseUser.emailVerified) {
        await _enterEmailVerificationPending();
        return;
      }
      // Never restore a Django JWT from storage on its own. Re-exchange a
      // fresh Firebase ID token so pre-verification credentials cannot regain
      // access after an application restart.
      await _handleFirebaseSignIn(refreshedFirebaseUser);
    } catch (_) {
      developer.log('Stored-session verification failed', name: 'AuthService');
    }
  }

  /// Gère la connexion Firebase réussie
  Future<void> _handleFirebaseSignIn(User firebaseUser) async {
    if (!firebaseUser.emailVerified) {
      await _enterEmailVerificationPending();
      return;
    }

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

      developer.log('Firebase ID token obtained for exchange',
          name: 'AuthService');

      // Tenter l'échange de tokens (appel réel backend)
      developer.log('🔄 [SIGNIN] Appel _exchangeFirebaseTokens...',
          name: 'AuthService');
      await _exchangeFirebaseTokens(firebaseToken, firebaseUser);
      developer.log('✅ [SIGNIN] _exchangeFirebaseTokens terminé avec succès',
          name: 'AuthService');
    } catch (_) {
      developer.log('Firebase session exchange failed', name: 'AuthService');
      _updateError('auth.errors.authentication_failed');
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

  Future<void> _enterEmailVerificationPending() async {
    await _tokenManager.clearAllTokens();
    _currentUser = null;
    _lastError = null;
    _updateStatus(AuthenticationStatus.emailVerificationPending);
  }

  Future<void> _moveToEmailVerificationAfterServerRejection() async {
    if (_firebaseAuth.currentUser == null) {
      await _handleFirebaseSignOut();
      return;
    }
    await _enterEmailVerificationPending();
  }

  /// Échange les tokens Firebase contre des tokens Django JWT
  Future<void> _exchangeFirebaseTokens(
      String firebaseToken, User firebaseUser) async {
    _updateStatus(AuthenticationStatus.authenticating);

    try {
      developer.log('🔄 Tentative d\'échange Firebase → Django JWT',
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
      if (data is Map<String, dynamic>) {
        backendCode =
            (data['code'] as String?) ?? (data['error'] as String?) ?? '';
      }

      if (backendCode == 'email_not_verified') {
        await _enterEmailVerificationPending();
        return;
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
          'Firebase token exchange failed (HTTP $status, code=$backendCode)',
          name: 'AuthService');
      _updateError(message);
      _updateStatus(AuthenticationStatus.error);
    } catch (_) {
      developer.log('Firebase token exchange failed', name: 'AuthService');
      _updateError('auth.errors.exchange_failed');
      _updateStatus(AuthenticationStatus.error);
    }
  }

  /// Connexion avec email et mot de passe avec test de connectivité préalable
  Future<AuthenticationResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('Firebase sign-in started', name: 'AuthService');
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

      developer.log('Backend connectivity confirmed; Firebase sign-in starting',
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

        // Refresh the user record before any Django-token exchange. Firebase
        // is the authority for this claim, not a cached local flag.
        await credential.user!.reload();
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser == null) {
          throw const FormatException('Firebase session was not retained.');
        }
        if (!firebaseUser.emailVerified) {
          await _enterEmailVerificationPending();
          return AuthenticationResult.emailVerificationPending();
        }

        // Appeler le flux standard qui effectue l'échange de tokens.
        await _handleFirebaseSignIn(firebaseUser);

        if (_status == AuthenticationStatus.emailVerificationPending) {
          return AuthenticationResult.emailVerificationPending();
        }

        // À ce stade, si tout s'est bien passé, _currentUser est défini
        if (_currentUser != null &&
            _status == AuthenticationStatus.fullyAuthenticated) {
          developer.log('Firebase sign-in completed', name: 'AuthService');
          return AuthenticationResult.success(_currentUser!);
        }

        throw Exception(
            'Échec de finalisation de l\'authentification après échange de tokens');
      } else {
        throw Exception('Connexion échouée - credential.user est null');
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase sign-in failed (code=${e.code})',
          name: 'AuthService');

      String errorMessage = _getFirebaseErrorMessage(e.code);
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage, e.code);
    } on TimeoutException {
      const errorMessage = 'auth.errors.connection_timeout';
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
    } catch (_) {
      developer.log('Unexpected sign-in failure', name: 'AuthService');

      const errorMessage = 'auth.errors.authentication_failed';
      _updateError(errorMessage);
      _updateStatus(AuthenticationStatus.error);

      return AuthenticationResult.failure(errorMessage);
    }
  }

  /// Creates the canonical backend account before signing into Firebase.
  Future<AuthenticationResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String locale,
    String? displayName,
    DateTime? birthDate,
    String? phoneNumber,
    String? gender,
  }) async {
    if (displayName == null || birthDate == null || gender == null) {
      return AuthenticationResult.failure(
        'auth.errors.registration_data_required',
        'registration_data_required',
      );
    }
    _updateStatus(AuthenticationStatus.authenticating);
    try {
      await _apiClient.post<Map<String, dynamic>>(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
          'password_confirm': password,
          'display_name': displayName,
          'birth_date': birthDate.toIso8601String().substring(0, 10),
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
          'gender': gender,
        },
      );
      _registrationSignInInProgress = true;
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const FormatException(
            'Firebase did not return the registered account.');
      }
      await _firebaseAuth.setLanguageCode(locale);
      var verificationEmailSent = true;
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        verificationEmailSent = false;
      }
      await _enterEmailVerificationPending();
      return AuthenticationResult.emailVerificationPending(
        verificationEmailSent: verificationEmailSent,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final code = data is Map ? data['code'] as String? : null;
      final readable = error.response?.statusCode == 400
          ? _registrationErrorMessage(data)
          : 'auth.errors.registration_failed';
      _updateError(readable);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(readable, code);
    } on FirebaseAuthException catch (error) {
      final readable = _getFirebaseErrorMessage(error.code);
      _updateError(readable);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(readable, error.code);
    } on FormatException catch (_) {
      const readable = 'auth.errors.registration_failed';
      _updateError(readable);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(readable);
    } catch (_) {
      const readable = 'auth.errors.registration_failed';
      _updateError(readable);
      _updateStatus(AuthenticationStatus.error);
      return AuthenticationResult.failure(readable);
    } finally {
      _registrationSignInInProgress = false;
    }
  }

  /// Traduit le contrat d'erreur stable du backend en clé i18n.
  ///
  /// Le backend renvoie `field_errors: {champ: [codes]}`. Seuls ces codes
  /// sont utilisés : aucun message backend brut n'est affiché.
  String _registrationErrorMessage(dynamic data) {
    if (data is! Map) {
      return 'auth.errors.registration_invalid';
    }

    final rawFieldErrors = data['field_errors'];
    if (rawFieldErrors is! Map) {
      return 'auth.errors.registration_invalid';
    }

    const fieldsInDisplayOrder = <String>[
      'email',
      'password',
      'password_confirm',
      'display_name',
      'birth_date',
      'phone_number',
      'gender',
    ];

    for (final field in fieldsInDisplayOrder) {
      final codes = rawFieldErrors[field];
      if (codes is List && codes.isNotEmpty) {
        return _registrationFieldMessage(field, codes.first?.toString());
      }
    }

    return 'auth.errors.registration_invalid';
  }

  String _registrationFieldMessage(String field, String? code) {
    switch (field) {
      case 'email':
        return code == 'unique'
            ? 'auth.errors.email_already_registered'
            : 'auth.validation.email_invalid';
      case 'password':
        switch (code) {
          case 'password_too_common':
            return 'auth.errors.password_too_common';
          case 'password_entirely_numeric':
            return 'auth.errors.password_entirely_numeric';
          case 'password_too_short':
            return 'auth.errors.password_too_short';
          case 'password_too_similar':
            return 'auth.errors.password_too_similar';
          default:
            return 'auth.validation.password_requirements';
        }
      case 'password_confirm':
        return 'auth.validation.password_mismatch';
      case 'display_name':
        switch (code) {
          case 'required':
            return 'auth.validation.display_name_required';
          case 'invalid_characters':
            return 'auth.errors.display_name_invalid_characters';
          default:
            return 'auth.validation.display_name_invalid';
        }
      case 'birth_date':
        switch (code) {
          case 'required':
            return 'auth.validation.birth_date_required';
          case 'age_requirement':
            return 'auth.validation.age_requirement';
          default:
            return 'auth.errors.birth_date_invalid';
        }
      case 'phone_number':
        return 'auth.validation.phone_invalid';
      case 'gender':
        return 'auth.validation.gender_required';
      default:
        return 'auth.errors.registration_invalid';
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
    } catch (_) {
      developer.log('Sign-out failed', name: 'AuthService');
      _updateError('auth.errors.sign_out_failed');
    }
  }

  Future<AuthenticationResult> resendEmailVerification({
    required String locale,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return AuthenticationResult.failure(
        'auth.email_verification.no_firebase_session',
        'no_firebase_session',
      );
    }

    try {
      await _firebaseAuth.setLanguageCode(locale);
      await firebaseUser.sendEmailVerification();
      await _enterEmailVerificationPending();
      return AuthenticationResult.emailVerificationPending(
        verificationEmailSent: true,
      );
    } catch (_) {
      await _enterEmailVerificationPending();
      return AuthenticationResult.emailVerificationPending(
        verificationEmailSent: false,
      );
    }
  }

  Future<AuthenticationResult> completeEmailVerification() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return AuthenticationResult.failure(
        'auth.email_verification.no_firebase_session',
        'no_firebase_session',
      );
    }

    try {
      await firebaseUser.reload();
      final refreshedFirebaseUser = _firebaseAuth.currentUser;
      if (refreshedFirebaseUser == null) {
        return AuthenticationResult.failure(
          'auth.email_verification.no_firebase_session',
          'no_firebase_session',
        );
      }
      if (!refreshedFirebaseUser.emailVerified) {
        await _enterEmailVerificationPending();
        return AuthenticationResult.failure(
          'auth.email_verification.still_pending',
          'email_not_verified',
        );
      }

      await _handleFirebaseSignIn(refreshedFirebaseUser);
      if (_currentUser != null &&
          _status == AuthenticationStatus.fullyAuthenticated) {
        return AuthenticationResult.success(_currentUser!);
      }
      if (_status == AuthenticationStatus.emailVerificationPending) {
        return AuthenticationResult.failure(
          'auth.email_verification.still_pending',
          'email_not_verified',
        );
      }
      return AuthenticationResult.failure('auth.errors.exchange_failed');
    } catch (_) {
      await _enterEmailVerificationPending();
      return AuthenticationResult.failure(
          'auth.email_verification.check_failed');
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      developer.log('Password-reset email request accepted',
          name: 'AuthService');
      return true;
    } catch (e) {
      developer.log('Password-reset email request failed', name: 'AuthService');
      _updateError('auth.errors.password_reset_failed');
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
        return 'auth.errors.firebase_user_not_found';
      case 'wrong-password':
        return 'auth.errors.firebase_wrong_password';
      case 'email-already-in-use':
        return 'auth.errors.firebase_email_already_in_use';
      case 'weak-password':
        return 'auth.errors.firebase_weak_password';
      case 'invalid-email':
        return 'auth.errors.firebase_invalid_email';
      case 'user-disabled':
        return 'auth.errors.firebase_user_disabled';
      case 'too-many-requests':
        return 'auth.errors.firebase_too_many_requests';
      case 'network-request-failed':
        return 'auth.errors.firebase_network';
      default:
        return 'auth.errors.firebase_unknown';
    }
  }

  /// Convertit les erreurs de connectivité en messages lisibles
  String _getConnectivityErrorMessage(ConnectivityResult result) {
    if (result.error == null) {
      return 'auth.errors.connectivity_unknown';
    }

    switch (result.errorType) {
      case ConnectivityErrorType.noInternet:
        return 'auth.errors.connectivity_no_internet';
      case ConnectivityErrorType.timeout:
        return 'auth.errors.connectivity_timeout';
      case ConnectivityErrorType.connectionRefused:
        return 'auth.errors.connectivity_refused';
      case ConnectivityErrorType.networkError:
        return 'auth.errors.connectivity_network';
      case ConnectivityErrorType.serverError:
        return 'auth.errors.connectivity_server';
      case ConnectivityErrorType.apiError:
        return 'auth.errors.connectivity_api';
      case ConnectivityErrorType.unknown:
      default:
        return 'auth.errors.connectivity_unknown';
    }
  }

  /// Convertit les erreurs Dio en messages lisibles
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'auth.errors.connection_timeout';
      case DioExceptionType.sendTimeout:
        return 'auth.errors.send_timeout';
      case DioExceptionType.receiveTimeout:
        return 'auth.errors.receive_timeout';
      case DioExceptionType.connectionError:
        return 'auth.errors.connection_error';
      case DioExceptionType.badResponse:
        return 'auth.errors.server_error';
      case DioExceptionType.cancel:
        return 'auth.errors.request_cancelled';
      case DioExceptionType.unknown:
      default:
        return 'auth.errors.network_unknown';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _emailVerificationRequiredSubscription?.cancel();
    _statusController.close();
    _userController.close();
    _errorController.close();
  }
}

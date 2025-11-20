import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'package:hivmeet/core/network/api_client.dart';

/// Clés de stockage sécurisé
class StorageKeys {
  static const String accessToken = 'hivmeet_access_token';
  static const String refreshToken = 'hivmeet_refresh_token';
  static const String userData = 'hivmeet_user_data';
  static const String firebaseToken = 'hivmeet_firebase_token';
  static const String tokenTimestamp = 'hivmeet_token_timestamp';
}

/// Résultat d'un refresh de token
class TokenRefreshResult {
  final bool success;
  final String? newAccessToken;
  final String? newRefreshToken;
  final String? error;

  const TokenRefreshResult({
    required this.success,
    this.newAccessToken,
    this.newRefreshToken,
    this.error,
  });

  factory TokenRefreshResult.success({
    required String accessToken,
    String? refreshToken,
  }) {
    return TokenRefreshResult(
      success: true,
      newAccessToken: accessToken,
      newRefreshToken: refreshToken,
    );
  }

  factory TokenRefreshResult.failure(String error) {
    return TokenRefreshResult(success: false, error: error);
  }
}

/// Gestionnaire de tokens sécurisé avec refresh automatique
class TokenManager {
  final FlutterSecureStorage _secureStorage;
  ApiClient? _apiClient;

  // Configuration du stockage sécurisé
  static const _secureStorageOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Cache en mémoire pour éviter les accès fréquents au stockage
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  domain.User? _cachedUserData;
  DateTime? _tokenCacheTime;

  // Durée de validité du cache en mémoire (5 minutes)
  static const _cacheValidityDuration = Duration(minutes: 5);

  // Marge de sécurité pour le refresh des tokens (2 minutes avant expiration)
  static const _refreshMarginDuration = Duration(minutes: 2);

  TokenManager(this._secureStorage);

  /// Initialise l'ApiClient après création (pour éviter les dépendances circulaires)
  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  /// Stocke les tokens et données utilisateur de manière sécurisée
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required domain.User userData,
  }) async {
    try {
      developer.log('💾 Stockage sécurisé des tokens', name: 'TokenManager');

      // Valider les tokens avant stockage
      if (!_isValidJWT(accessToken)) {
        throw Exception('Access token invalide');
      }

      if (!_isValidJWT(refreshToken)) {
        throw Exception('Refresh token invalide');
      }

      // Stocker les tokens avec chiffrement
      await Future.wait([
        _secureStorage.write(
          key: StorageKeys.accessToken,
          value: accessToken,
          aOptions: _secureStorageOptions,
        ),
        _secureStorage.write(
          key: StorageKeys.refreshToken,
          value: refreshToken,
          aOptions: _secureStorageOptions,
        ),
        _secureStorage.write(
          key: StorageKeys.userData,
          value: jsonEncode(userData.toJson()),
          aOptions: _secureStorageOptions,
        ),
        _secureStorage.write(
          key: StorageKeys.tokenTimestamp,
          value: DateTime.now().millisecondsSinceEpoch.toString(),
          aOptions: _secureStorageOptions,
        ),
      ]);

      // Mettre à jour le cache
      _cachedAccessToken = accessToken;
      _cachedRefreshToken = refreshToken;
      _cachedUserData = userData;
      _tokenCacheTime = DateTime.now();

      developer.log('✅ Tokens stockés avec succès', name: 'TokenManager');
    } catch (e) {
      developer.log('❌ Erreur stockage tokens: $e', name: 'TokenManager');
      throw Exception('Échec stockage tokens: $e');
    }
  }

  /// Stocke un token Firebase comme fallback
  Future<void> storeFirebaseTokenFallback(String firebaseToken) async {
    try {
      await _secureStorage.write(
        key: StorageKeys.firebaseToken,
        value: firebaseToken,
        aOptions: _secureStorageOptions,
      );

      // Mettre un timestamp pour l'expiration
      await _secureStorage.write(
        key: StorageKeys.tokenTimestamp,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
        aOptions: _secureStorageOptions,
      );

      developer.log('⚠️ Token Firebase stocké comme fallback',
          name: 'TokenManager');
    } catch (e) {
      developer.log('❌ Erreur stockage token Firebase: $e',
          name: 'TokenManager');
      throw Exception('Échec stockage token Firebase: $e');
    }
  }

  /// Récupère l'access token (avec vérification de validité)
  Future<String?> getAccessToken() async {
    try {
      // Vérifier le cache en mémoire d'abord
      if (_isCacheValid() && _cachedAccessToken != null) {
        if (_isTokenValid(_cachedAccessToken!)) {
          return _cachedAccessToken;
        }
      }

      // Récupérer depuis le stockage sécurisé
      final storedToken = await _secureStorage.read(
        key: StorageKeys.accessToken,
        aOptions: _secureStorageOptions,
      );

      if (storedToken != null) {
        // Vérifier si le token est encore valide
        if (_isTokenValid(storedToken)) {
          _cachedAccessToken = storedToken;
          _tokenCacheTime = DateTime.now();
          return storedToken;
        } else {
          developer.log('⏰ Access token expiré, tentative de refresh',
              name: 'TokenManager');

          // Tenter le refresh automatique
          final refreshResult = await refreshAccessToken();
          if (refreshResult.success) {
            return refreshResult.newAccessToken;
          }
        }
      }

      // Si pas de token Django, vérifier le fallback Firebase
      final firebaseToken = await _secureStorage.read(
        key: StorageKeys.firebaseToken,
        aOptions: _secureStorageOptions,
      );

      if (firebaseToken != null) {
        developer.log('⚠️ Utilisation du token Firebase fallback',
            name: 'TokenManager');
        return firebaseToken;
      }

      return null;
    } catch (e) {
      developer.log('❌ Erreur récupération access token: $e',
          name: 'TokenManager');
      return null;
    }
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    try {
      if (_isCacheValid() && _cachedRefreshToken != null) {
        return _cachedRefreshToken;
      }

      final storedToken = await _secureStorage.read(
        key: StorageKeys.refreshToken,
        aOptions: _secureStorageOptions,
      );

      if (storedToken != null) {
        _cachedRefreshToken = storedToken;
        _tokenCacheTime = DateTime.now();
      }

      return storedToken;
    } catch (e) {
      developer.log('❌ Erreur récupération refresh token: $e',
          name: 'TokenManager');
      return null;
    }
  }

  /// Récupère les données utilisateur stockées
  Future<domain.User?> getStoredUserData() async {
    try {
      if (_isCacheValid() && _cachedUserData != null) {
        return _cachedUserData;
      }

      final storedData = await _secureStorage.read(
        key: StorageKeys.userData,
        aOptions: _secureStorageOptions,
      );

      if (storedData != null) {
        final userJson = jsonDecode(storedData) as Map<String, dynamic>;
        final user = domain.User.fromJson(userJson);

        _cachedUserData = user;
        _tokenCacheTime = DateTime.now();

        return user;
      }

      return null;
    } catch (e) {
      developer.log('❌ Erreur récupération données utilisateur: $e',
          name: 'TokenManager');
      return null;
    }
  }

  /// Vérifie si des tokens valides sont stockés
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null;
    } catch (e) {
      return false;
    }
  }

  /// Refresh l'access token en utilisant le refresh token
  Future<TokenRefreshResult> refreshAccessToken() async {
    try {
      developer.log('🔄 Tentative de refresh du token', name: 'TokenManager');

      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return TokenRefreshResult.failure('Aucun refresh token disponible');
      }

      // Vérifier si le refresh token est encore valide
      if (!_isTokenValid(refreshToken)) {
        await clearAllTokens(); // Nettoyer les tokens expirés
        return TokenRefreshResult.failure('Refresh token expiré');
      }

      // Vérifier que l'ApiClient est disponible
      if (_apiClient == null) {
        return TokenRefreshResult.failure('ApiClient non initialisé');
      }

      // Appeler l'endpoint de refresh
      final response = await _apiClient!.post(
        'auth/refresh-token/',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken =
            (data['access_token'] ?? data['token'] ?? data['access']) as String;

        // Le refresh token peut ou non être renouvelé
        final newRefreshToken =
            (data['refresh_token'] ?? data['refresh']) as String?;

        // Stocker le nouveau access token
        await _secureStorage.write(
          key: StorageKeys.accessToken,
          value: newAccessToken,
          aOptions: _secureStorageOptions,
        );

        // Stocker le nouveau refresh token s'il a été renouvelé
        if (newRefreshToken != null) {
          await _secureStorage.write(
            key: StorageKeys.refreshToken,
            value: newRefreshToken,
            aOptions: _secureStorageOptions,
          );
          _cachedRefreshToken = newRefreshToken;
        }

        // Mettre à jour le cache
        _cachedAccessToken = newAccessToken;
        _tokenCacheTime = DateTime.now();

        developer.log('✅ Token refresh réussi', name: 'TokenManager');

        return TokenRefreshResult.success(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
      } else {
        final error = 'Refresh échoué: ${response.statusCode}';
        developer.log('❌ $error', name: 'TokenManager');
        return TokenRefreshResult.failure(error);
      }
    } catch (e) {
      developer.log('❌ Erreur refresh token: $e', name: 'TokenManager');
      return TokenRefreshResult.failure('Erreur refresh: $e');
    }
  }

  /// Vérifie si le token nécessite un refresh bientôt
  bool shouldRefreshToken(String token) {
    try {
      if (!_isValidJWT(token)) return false;

      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();

      // Refresh si expiration dans moins de 2 minutes
      return expirationDate.difference(now) <= _refreshMarginDuration;
    } catch (e) {
      return true; // En cas d'erreur, mieux vaut tenter le refresh
    }
  }

  /// Nettoie tous les tokens et données stockés
  Future<void> clearAllTokens() async {
    try {
      developer.log('🧹 Nettoyage de tous les tokens', name: 'TokenManager');

      await Future.wait([
        _secureStorage.delete(key: StorageKeys.accessToken),
        _secureStorage.delete(key: StorageKeys.refreshToken),
        _secureStorage.delete(key: StorageKeys.userData),
        _secureStorage.delete(key: StorageKeys.firebaseToken),
        _secureStorage.delete(key: StorageKeys.tokenTimestamp),
      ]);

      // Nettoyer le cache
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      _cachedUserData = null;
      _tokenCacheTime = null;

      developer.log('✅ Tokens nettoyés avec succès', name: 'TokenManager');
    } catch (e) {
      developer.log('❌ Erreur nettoyage tokens: $e', name: 'TokenManager');
    }
  }

  /// Vérifie si un token JWT est valide
  bool _isTokenValid(String token) {
    try {
      if (!_isValidJWT(token)) return false;

      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si une chaîne est un JWT valide
  bool _isValidJWT(String token) {
    try {
      final parts = token.split('.');
      return parts.length == 3;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si le cache en mémoire est encore valide
  bool _isCacheValid() {
    if (_tokenCacheTime == null) return false;

    return DateTime.now().difference(_tokenCacheTime!) <=
        _cacheValidityDuration;
  }

  /// Obtient les informations d'expiration d'un token
  DateTime? getTokenExpiration(String token) {
    try {
      if (!_isValidJWT(token)) return null;
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }

  /// Obtient le temps restant avant expiration d'un token
  Duration? getTimeUntilExpiration(String token) {
    final expiration = getTokenExpiration(token);
    if (expiration == null) return null;

    final now = DateTime.now();
    return expiration.isAfter(now) ? expiration.difference(now) : Duration.zero;
  }
}

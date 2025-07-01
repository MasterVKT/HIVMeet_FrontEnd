import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/core/network/api_client.dart';

@singleton
class TokenService {
  static const String _jwtAccessTokenKey = 'jwt_access_token';
  static const String _jwtRefreshTokenKey = 'jwt_refresh_token';

  final FlutterSecureStorage _secureStorage;
  final FirebaseAuth _firebaseAuth;
  final AuthApi _authApi;
  final ApiClient _apiClient;

  TokenService(
    this._secureStorage,
    this._firebaseAuth,
    this._authApi,
    this._apiClient,
  );

  /// Initialise les tokens JWT depuis Firebase
  Future<void> initializeTokens() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _exchangeFirebaseTokenForJWT();
    }
  }

  /// Échange le token Firebase contre des tokens JWT
  Future<bool> _exchangeFirebaseTokenForJWT() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null) return false;

      final response = await _authApi.exchangeFirebaseToken(
        firebaseIdToken: firebaseIdToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data?['access_token'] as String?;
        final refreshToken = data?['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          await _storeTokens(accessToken, refreshToken);
          _apiClient.setAccessToken(accessToken);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur lors de l\'échange de tokens: $e');
      return false;
    }
  }

  /// Stocke les tokens JWT de manière sécurisée
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _secureStorage.write(key: _jwtAccessTokenKey, value: accessToken),
      _secureStorage.write(key: _jwtRefreshTokenKey, value: refreshToken),
    ]);
  }

  /// Récupère le token d'accès JWT
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _jwtAccessTokenKey);
  }

  /// Récupère le token de rafraîchissement JWT
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _jwtRefreshTokenKey);
  }

  /// Rafraîchit le token d'accès JWT
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _authApi.refreshToken(refreshToken: refreshToken);

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data?['access_token'] as String?;
        final newRefreshToken = data?['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.write(
              key: _jwtAccessTokenKey, value: newAccessToken);
          _apiClient.setAccessToken(newAccessToken);

          if (newRefreshToken != null) {
            await _secureStorage.write(
                key: _jwtRefreshTokenKey, value: newRefreshToken);
          }

          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }

  /// Supprime tous les tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _jwtAccessTokenKey),
      _secureStorage.delete(key: _jwtRefreshTokenKey),
    ]);
    _apiClient.setAccessToken(null);
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && _firebaseAuth.currentUser != null;
  }

  /// Gère la connexion complète (Firebase + JWT)
  Future<bool> handleSignIn() async {
    return await _exchangeFirebaseTokenForJWT();
  }

  /// Gère la déconnexion complète
  Future<void> handleSignOut() async {
    await clearTokens();
    await _firebaseAuth.signOut();
  }
}

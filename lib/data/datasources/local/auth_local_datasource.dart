// lib/data/datasources/local/auth_local_datasource.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCachedUser();
  
  Future<void> cacheAuthToken(String token);
  Future<String?> getCachedAuthToken();
  Future<void> clearAuthToken();
  
  Future<void> cacheRefreshToken(String token);
  Future<String?> getCachedRefreshToken();
  Future<void> clearRefreshToken();
  
  Future<void> setRememberMe(bool remember);
  Future<bool> getRememberMe();
  
  Future<void> clearAllAuthData();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;

  static const String _userKey = 'cached_user';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _rememberMeKey = 'remember_me';

  AuthLocalDataSourceImpl(
    this._secureStorage,
    this._sharedPreferences,
  );

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _secureStorage.write(key: _userKey, value: userJson);
    } catch (e) {
      throw CacheException(message: 'Échec de mise en cache de l\'utilisateur');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;
      
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw CacheException(message: 'Échec de récupération de l\'utilisateur en cache');
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      throw CacheException(message: 'Échec de suppression du cache utilisateur');
    }
  }

  @override
  Future<void> cacheAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _authTokenKey, value: token);
    } catch (e) {
      throw CacheException(message: 'Échec de mise en cache du token');
    }
  }

  @override
  Future<String?> getCachedAuthToken() async {
    try {
      return await _secureStorage.read(key: _authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Échec de récupération du token');
    }
  }

  @override
  Future<void> clearAuthToken() async {
    try {
      await _secureStorage.delete(key: _authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Échec de suppression du token');
    }
  }

  @override
  Future<void> cacheRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw CacheException(message: 'Échec de mise en cache du refresh token');
    }
  }

  @override
  Future<String?> getCachedRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      throw CacheException(message: 'Échec de récupération du refresh token');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw CacheException(message: 'Échec de suppression du refresh token');
    }
  }

  @override
  Future<void> setRememberMe(bool remember) async {
    try {
      await _sharedPreferences.setBool(_rememberMeKey, remember);
    } catch (e) {
      throw CacheException(message: 'Échec de sauvegarde de la préférence');
    }
  }

  @override
  Future<bool> getRememberMe() async {
    try {
      return _sharedPreferences.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      throw CacheException(message: 'Échec de récupération de la préférence');
    }
  }

  @override
  Future<void> clearAllAuthData() async {
    try {
      await Future.wait([
        clearCachedUser(),
        clearAuthToken(),
        clearRefreshToken(),
      ]);
      await _sharedPreferences.remove(_rememberMeKey);
    } catch (e) {
      throw CacheException(message: 'Échec de suppression des données d\'authentification');
    }
  }
}
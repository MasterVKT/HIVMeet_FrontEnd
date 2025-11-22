// lib/data/repositories/settings_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  const SettingsRepositoryImpl(
    this._sharedPreferences,
    this._secureStorage,
  );

  @override
  Future<Either<Failure, UserSettings>> getUserSettings() async {
    try {
      final email = await _secureStorage.read(key: 'user_email') ?? '';
      final isPremium = _sharedPreferences.getBool('is_premium') ?? false;
      final isProfileVisible =
          _sharedPreferences.getBool('profile_visible') ?? true;
      final shareLocation =
          _sharedPreferences.getBool('share_location') ?? true;
      final showOnlineStatus =
          _sharedPreferences.getBool('show_online_status') ?? true;
      final notifyNewMatches =
          _sharedPreferences.getBool('notify_new_matches') ?? true;
      final notifyMessages =
          _sharedPreferences.getBool('notify_messages') ?? true;
      final notifyLikes = _sharedPreferences.getBool('notify_likes') ?? true;
      final notifyNews = _sharedPreferences.getBool('notify_news') ?? true;
      final language = _sharedPreferences.getString('language') ?? 'fr';
      final country = _sharedPreferences.getString('country') ?? 'FR';

      final settings = UserSettings(
        email: email,
        isPremium: isPremium,
        isProfileVisible: isProfileVisible,
        shareLocation: shareLocation,
        showOnlineStatus: showOnlineStatus,
        notifyNewMatches: notifyNewMatches,
        notifyMessages: notifyMessages,
        notifyLikes: notifyLikes,
        notifyNews: notifyNews,
        language: language,
        country: country,
      );

      return Right(settings);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfileVisibility(bool isVisible) async {
    try {
      await _sharedPreferences.setBool('profile_visible', isVisible);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocationSharing(
      bool shareLocation) async {
    try {
      await _sharedPreferences.setBool('share_location', shareLocation);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatusVisibility(
      bool showStatus) async {
    try {
      await _sharedPreferences.setBool('show_online_status', showStatus);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationSetting(
      NotificationType type, bool enabled) async {
    try {
      String key;
      switch (type) {
        case NotificationType.newMatches:
          key = 'notify_new_matches';
          break;
        case NotificationType.messages:
          key = 'notify_messages';
          break;
        case NotificationType.likes:
          key = 'notify_likes';
          break;
        case NotificationType.news:
          key = 'notify_news';
          break;
      }

      await _sharedPreferences.setBool(key, enabled);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLanguage(String language) async {
    try {
      await _sharedPreferences.setString('language', language);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    // ATTENTION: deleteAccount backend API n'est pas encore implémentée!
    // Ne PAS laisser l'utilisateur croire que son compte est supprimé
    // alors qu'il existe toujours côté serveur.
    //
    // TODO: Implémenter DELETE /api/v1/auth/account/ dans le backend
    // puis appeler via AuthApi
    return Left(ServerFailure(
      message: 'La suppression de compte n\'est pas encore disponible. '
          'Contactez le support pour supprimer votre compte.',
    ));

    // Code à activer une fois l'API backend implémentée:
    // try {
    //   // 1. Appeler le backend pour supprimer le compte
    //   await _authApi.deleteAccount();
    //
    //   // 2. Ensuite seulement, nettoyer les données locales
    //   await _sharedPreferences.clear();
    //   await _secureStorage.deleteAll();
    //
    //   return const Right(null);
    // } catch (e) {
    //   return Left(ServerFailure(message: e.toString()));
    // }
  }
}

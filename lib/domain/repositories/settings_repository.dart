// lib/domain/repositories/settings_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_event.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> getUserSettings();
  Future<Either<Failure, void>> updateProfileVisibility(bool isVisible);
  Future<Either<Failure, void>> updateLocationSharing(bool shareLocation);
  Future<Either<Failure, void>> updateOnlineStatusVisibility(bool showStatus);
  Future<Either<Failure, void>> updateNotificationSetting(
      NotificationType type, bool enabled);
  Future<Either<Failure, void>> updateLanguage(String language);
  Future<Either<Failure, void>> deleteAccount();
}

class UserSettings {
  final String email;
  final bool isPremium;
  final bool isProfileVisible;
  final bool shareLocation;
  final bool showOnlineStatus;
  final bool notifyNewMatches;
  final bool notifyMessages;
  final bool notifyLikes;
  final bool notifyNews;
  final String language;
  final String country;

  const UserSettings({
    required this.email,
    required this.isPremium,
    required this.isProfileVisible,
    required this.shareLocation,
    required this.showOnlineStatus,
    required this.notifyNewMatches,
    required this.notifyMessages,
    required this.notifyLikes,
    required this.notifyNews,
    required this.language,
    required this.country,
  });
}

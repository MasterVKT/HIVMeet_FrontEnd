// lib/presentation/blocs/settings/settings_event.dart

import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateProfileVisibility extends SettingsEvent {
  final bool isVisible;

  const UpdateProfileVisibility({required this.isVisible});

  @override
  List<Object> get props => [isVisible];
}

class UpdateLocationSharing extends SettingsEvent {
  final bool shareLocation;

  const UpdateLocationSharing({required this.shareLocation});

  @override
  List<Object> get props => [shareLocation];
}

class UpdateOnlineStatusVisibility extends SettingsEvent {
  final bool showStatus;

  const UpdateOnlineStatusVisibility({required this.showStatus});

  @override
  List<Object> get props => [showStatus];
}

class UpdateNotificationSetting extends SettingsEvent {
  final NotificationType type;
  final bool enabled;

  const UpdateNotificationSetting({
    required this.type,
    required this.enabled,
  });

  @override
  List<Object> get props => [type, enabled];
}

class UpdateLanguage extends SettingsEvent {
  final String language;

  const UpdateLanguage({required this.language});

  @override
  List<Object> get props => [language];
}

enum NotificationType { newMatches, messages, likes, news }
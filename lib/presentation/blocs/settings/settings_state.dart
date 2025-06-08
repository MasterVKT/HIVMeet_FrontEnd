// lib/presentation/blocs/settings/settings_state.dart

import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
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

  const SettingsLoaded({
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

  SettingsLoaded copyWith({
    String? email,
    bool? isPremium,
    bool? isProfileVisible,
    bool? shareLocation,
    bool? showOnlineStatus,
    bool? notifyNewMatches,
    bool? notifyMessages,
    bool? notifyLikes,
    bool? notifyNews,
    String? language,
    String? country,
  }) {
    return SettingsLoaded(
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      isProfileVisible: isProfileVisible ?? this.isProfileVisible,
      shareLocation: shareLocation ?? this.shareLocation,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyNews: notifyNews ?? this.notifyNews,
      language: language ?? this.language,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [
        email,
        isPremium,
        isProfileVisible,
        shareLocation,
        showOnlineStatus,
        notifyNewMatches,
        notifyMessages,
        notifyLikes,
        notifyNews,
        language,
        country,
      ];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}
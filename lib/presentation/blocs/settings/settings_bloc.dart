// lib/presentation/blocs/settings/settings_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({
    required SettingsRepository settingsRepository,
  })  : _settingsRepository = settingsRepository,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateProfileVisibility>(_onUpdateProfileVisibility);
    on<UpdateLocationSharing>(_onUpdateLocationSharing);
    on<UpdateOnlineStatusVisibility>(_onUpdateOnlineStatusVisibility);
    on<UpdateNotificationSetting>(_onUpdateNotificationSetting);
    on<ChangeLanguage>(_onChangeLanguage);
    on<DeleteAccount>(_onDeleteAccount);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final result = await _settingsRepository.getUserSettings();

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (settings) => emit(SettingsLoaded(
        email: settings.email,
        isPremium: settings.isPremium,
        isProfileVisible: settings.isProfileVisible,
        shareLocation: settings.shareLocation,
        showOnlineStatus: settings.showOnlineStatus,
        notifyNewMatches: settings.notifyNewMatches,
        notifyMessages: settings.notifyMessages,
        notifyLikes: settings.notifyLikes,
        notifyNews: settings.notifyNews,
        language: settings.language,
        country: settings.country,
      )),
    );
  }

  Future<void> _onUpdateProfileVisibility(
    UpdateProfileVisibility event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result =
          await _settingsRepository.updateProfileVisibility(event.isVisible);

      result.fold(
        (failure) => emit(SettingsError(message: failure.message)),
        (_) => emit(currentState.copyWith(isProfileVisible: event.isVisible)),
      );
    }
  }

  Future<void> _onUpdateLocationSharing(
    UpdateLocationSharing event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result =
          await _settingsRepository.updateLocationSharing(event.shareLocation);

      result.fold(
        (failure) => emit(SettingsError(message: failure.message)),
        (_) => emit(currentState.copyWith(shareLocation: event.shareLocation)),
      );
    }
  }

  Future<void> _onUpdateOnlineStatusVisibility(
    UpdateOnlineStatusVisibility event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result = await _settingsRepository
          .updateOnlineStatusVisibility(event.showStatus);

      result.fold(
        (failure) => emit(SettingsError(message: failure.message)),
        (_) => emit(currentState.copyWith(showOnlineStatus: event.showStatus)),
      );
    }
  }

  Future<void> _onUpdateNotificationSetting(
    UpdateNotificationSetting event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result = await _settingsRepository.updateNotificationSetting(
        event.type,
        event.enabled,
      );

      result.fold(
        (failure) => emit(SettingsError(message: failure.message)),
        (_) {
          switch (event.type) {
            case NotificationType.newMatches:
              emit(currentState.copyWith(notifyNewMatches: event.enabled));
              break;
            case NotificationType.messages:
              emit(currentState.copyWith(notifyMessages: event.enabled));
              break;
            case NotificationType.likes:
              emit(currentState.copyWith(notifyLikes: event.enabled));
              break;
            case NotificationType.news:
              emit(currentState.copyWith(notifyNews: event.enabled));
              break;
          }
        },
      );
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result = await _settingsRepository.updateLanguage(event.language);

      result.fold(
        (failure) => emit(SettingsError(message: failure.message)),
        (_) => emit(currentState.copyWith(language: event.language)),
      );
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsDeletingAccount());

    final result = await _settingsRepository.deleteAccount();

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (_) => emit(SettingsAccountDeleted()),
    );
  }
}

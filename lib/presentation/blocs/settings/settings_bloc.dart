// lib/presentation/blocs/settings/settings_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/settings_repository.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateProfileVisibility>(_onUpdateProfileVisibility);
    on<UpdateLocationSharing>(_onUpdateLocationSharing);
    on<UpdateOnlineStatusVisibility>(_onUpdateOnlineStatusVisibility);
    on<UpdateNotificationSetting>(_onUpdateNotificationSetting);
    on<ChangeLanguage>(_onChangeLanguage);
    on<DeleteAccount>(_onDeleteAccount);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    emit(SettingsLoaded(
        email: 'example@email.com',
        isPremium: false,
        isProfileVisible: true,
        shareLocation: true,
        showOnlineStatus: true,
        notifyNewMatches: true,
        notifyMessages: true,
        notifyLikes: true,
        notifyNews: true,
        language: 'fr',
        country: 'FR'));
  }

  void _onUpdateProfileVisibility(
      UpdateProfileVisibility event, Emitter<SettingsState> emit) {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(isProfileVisible: event.isVisible));
    }
  }

  void _onUpdateLocationSharing(
      UpdateLocationSharing event, Emitter<SettingsState> emit) {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(shareLocation: event.shareLocation));
    }
  }

  void _onUpdateOnlineStatusVisibility(
      UpdateOnlineStatusVisibility event, Emitter<SettingsState> emit) {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(showOnlineStatus: event.showStatus));
    }
  }

  void _onUpdateNotificationSetting(
      UpdateNotificationSetting event, Emitter<SettingsState> emit) {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      switch (event.type) {
        case NotificationType.newMatches:
          emit(current.copyWith(notifyNewMatches: event.enabled));
          break;
        case NotificationType.messages:
          emit(current.copyWith(notifyMessages: event.enabled));
          break;
        case NotificationType.likes:
          emit(current.copyWith(notifyLikes: event.enabled));
          break;
        case NotificationType.news:
          emit(current.copyWith(notifyNews: event.enabled));
          break;
      }
    }
  }

  void _onChangeLanguage(ChangeLanguage event, Emitter<SettingsState> emit) {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(language: event.language));
    }
  }

  void _onDeleteAccount(DeleteAccount event, Emitter<SettingsState> emit) {
    emit(SettingsDeletingAccount());
    // TODO: Implémenter la suppression réelle du compte
    emit(SettingsAccountDeleted());
  }
}

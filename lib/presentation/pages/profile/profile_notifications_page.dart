import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ProfileNotificationsPage extends StatefulWidget {
  const ProfileNotificationsPage({super.key});

  @override
  State<ProfileNotificationsPage> createState() =>
      _ProfileNotificationsPageState();
}

class _ProfileNotificationsPageState extends State<ProfileNotificationsPage> {
  NotificationPreferences? _draft;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadNotificationPreferences()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          if (loaded == null) {
            return Scaffold(
              body: RetryPanel(
                messageKey: 'profile.notifications_load_error',
                onRetry: () => context
                    .read<ProfileBloc>()
                    .add(LoadNotificationPreferences()),
              ),
            );
          }
          final prefs = _draft ??
              loaded.notificationPreferences ??
              const NotificationPreferences();
          final isSaving = state is ProfileSectionLoading;
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.notifications')),
              backgroundColor: AppColors.primaryWhite,
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => context
                          .read<ProfileBloc>()
                          .add(SaveNotificationPreferences(prefs)),
                  child: Text(_tr('common.save')),
                ),
              ],
            ),
            body: ListView(
              children: [
                _switch(
                  title: _tr('profile.notify_matches'),
                  value: prefs.newMatchNotifications,
                  onChanged: (value) =>
                      _set(prefs.copyWith(newMatchNotifications: value)),
                ),
                _switch(
                  title: _tr('profile.notify_messages'),
                  value: prefs.newMessageNotifications,
                  onChanged: (value) =>
                      _set(prefs.copyWith(newMessageNotifications: value)),
                ),
                _switch(
                  title: _tr('profile.notify_likes'),
                  subtitle: _tr('profile.premium_only'),
                  value: prefs.profileLikeNotifications,
                  onChanged: (value) =>
                      _set(prefs.copyWith(profileLikeNotifications: value)),
                ),
                _switch(
                  title: _tr('profile.notify_updates'),
                  value: prefs.appUpdateNotifications,
                  onChanged: (value) =>
                      _set(prefs.copyWith(appUpdateNotifications: value)),
                ),
                _switch(
                  title: _tr('profile.notify_promotional'),
                  value: prefs.promotionalNotifications,
                  onChanged: (value) =>
                      _set(prefs.copyWith(promotionalNotifications: value)),
                ),
                _switch(
                  title: _tr('profile.do_not_disturb'),
                  subtitle: _dndSubtitle(prefs),
                  value: prefs.doNotDisturbSettings['enabled'] == true,
                  onChanged: (value) => _set(prefs.copyWith(
                    doNotDisturbSettings: {
                      ...prefs.doNotDisturbSettings,
                      'enabled': value,
                    },
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _switch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _set(NotificationPreferences preferences) {
    setState(() => _draft = preferences);
  }
}

String _dndSubtitle(NotificationPreferences prefs) {
  final settings = prefs.doNotDisturbSettings;
  final start = settings['start_time_utc']?.toString() ?? '22:00';
  final end = settings['end_time_utc']?.toString() ?? '07:00';
  return _tr(
    'profile.do_not_disturb_window',
    params: {'start': start, 'end': end},
  );
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key, {Map<String, dynamic>? params}) =>
    LocalizationService.translate(key, params: params);

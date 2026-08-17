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

class ProfilePrivacyPage extends StatefulWidget {
  const ProfilePrivacyPage({super.key});

  @override
  State<ProfilePrivacyPage> createState() => _ProfilePrivacyPageState();
}

class _ProfilePrivacyPageState extends State<ProfilePrivacyPage> {
  PrivacyPreferences? _draft;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadPrivacyPreferences()),
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
                messageKey: 'profile.privacy_load_error',
                onRetry: () =>
                    context.read<ProfileBloc>().add(LoadPrivacyPreferences()),
              ),
            );
          }
          final prefs =
              _draft ?? loaded.privacyPreferences ?? _prefsFromProfile(loaded);
          final isSaving = state is ProfileSectionLoading;
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.privacy')),
              backgroundColor: AppColors.primaryWhite,
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => context
                          .read<ProfileBloc>()
                          .add(SavePrivacyPreferences(prefs)),
                  child: Text(_tr('common.save')),
                ),
              ],
            ),
            body: ListView(
              children: [
                SwitchListTile(
                  value: prefs.profileDiscoverable,
                  title: Text(_tr('profile.profile_discoverable')),
                  subtitle: Text(_tr('profile.profile_discoverable_subtitle')),
                  onChanged: (value) => _set(prefs.copyWith(
                    profileDiscoverable: value,
                    profileVisibility: value ? 'visible_to_all' : 'hidden',
                  )),
                ),
                SwitchListTile(
                  value: prefs.showOnlineStatus,
                  title: Text(_tr('profile.show_online')),
                  subtitle: Text(_tr('profile.show_online_subtitle')),
                  onChanged: (value) =>
                      _set(prefs.copyWith(showOnlineStatus: value)),
                ),
                SwitchListTile(
                  value: prefs.showDistance,
                  title: Text(_tr('profile.show_distance')),
                  subtitle: Text(_tr('profile.show_distance_subtitle')),
                  onChanged: (value) =>
                      _set(prefs.copyWith(showDistance: value)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _set(PrivacyPreferences preferences) {
    setState(() => _draft = preferences);
  }
}

PrivacyPreferences _prefsFromProfile(ProfileLoaded loaded) {
  final settings = loaded.profile.privacySettings;
  return PrivacyPreferences(
    profileVisibility:
        settings.profileDiscoverable ? 'visible_to_all' : 'hidden',
    showOnlineStatus: settings.showOnlineStatus,
    showDistance: settings.showDistance,
    profileDiscoverable: settings.profileDiscoverable,
  );
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);

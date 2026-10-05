import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ProfileCurrencyPage extends StatefulWidget {
  const ProfileCurrencyPage({super.key});

  @override
  State<ProfileCurrencyPage> createState() => _ProfileCurrencyPageState();
}

class _ProfileCurrencyPageState extends State<ProfileCurrencyPage> {
  String? _draft;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(
              context: context,
              message: _tr('profile.currency_save_error'),
            );
          }
          if (state is ProfileActionSuccess) {
            setState(() => _draft = state.profile.preferredCurrency);
            HIVToast.showSuccess(
              context: context,
              message: _tr('profile.success_currency_saved'),
            );
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          if (loaded == null) {
            return Scaffold(
              body: RetryPanel(
                messageKey: 'profile.currency_load_error',
                onRetry: () => context.read<ProfileBloc>().add(LoadProfile()),
              ),
            );
          }

          final selected = _draft ?? loaded.profile.preferredCurrency;
          final isSaving = state is ProfileUpdating;
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.currency_title')),
              backgroundColor: AppColors.primaryWhite,
              actions: [
                TextButton(
                  onPressed:
                      isSaving || selected == loaded.profile.preferredCurrency
                          ? null
                          : () => context.read<ProfileBloc>().add(
                                UpdateProfileEvent(
                                  preferredCurrency: selected,
                                ),
                              ),
                  child: Text(_tr('common.save')),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    _tr(
                      'profile.currency_effective',
                      params: {
                        'currency': loaded.profile.effectiveCurrency,
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                  ),
                ),
                RadioGroup<String>(
                  groupValue: selected,
                  onChanged: (value) {
                    if (!isSaving && value != null) {
                      setState(() => _draft = value);
                    }
                  },
                  child: Column(
                    children: const [
                      _CurrencyOption(
                        value: 'AUTO',
                        titleKey: 'profile.currency_auto',
                        subtitleKey: 'profile.currency_auto_subtitle',
                      ),
                      _CurrencyOption(
                        value: 'XAF',
                        titleKey: 'profile.currency_xaf',
                        subtitleKey: 'profile.currency_xaf_subtitle',
                      ),
                      _CurrencyOption(
                        value: 'EUR',
                        titleKey: 'profile.currency_eur',
                        subtitleKey: 'profile.currency_eur_subtitle',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final String value;
  final String titleKey;
  final String subtitleKey;

  const _CurrencyOption({
    required this.value,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      title: Text(_tr(titleKey)),
      subtitle: Text(_tr(subtitleKey)),
    );
  }
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileUpdating) return ProfileLoaded(profile: state.profile);
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key, {Map<String, String>? params}) =>
    LocalizationService.translate(key, params: params);

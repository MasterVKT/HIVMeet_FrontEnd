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

class ProfileDataPage extends StatelessWidget {
  const ProfileDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionPending) {
            HIVToast.showInfo(context: context, message: _tr(state.message));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          final loaded = _loadedFrom(state);
          if (loaded == null) {
            return Scaffold(
              body: RetryPanel(
                messageKey: 'profile.load_error',
                onRetry: () => context.read<ProfileBloc>().add(LoadProfile()),
              ),
            );
          }
          final isActionLoading = state is ProfileSectionLoading;
          final pending = state is ProfileActionPending ? state : null;
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.data_requests')),
              backgroundColor: AppColors.primaryWhite,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending != null) _PendingBanner(state: pending),
                _DataCard(
                  icon: Icons.download_outlined,
                  title: _tr('profile.export_data'),
                  subtitle: _tr('profile.export_data_subtitle'),
                  action: _tr('profile.request_export'),
                  onPressed: isActionLoading || pending != null
                      ? null
                      : () =>
                          context.read<ProfileBloc>().add(RequestDataExport()),
                ),
                const SizedBox(height: 12),
                _DataCard(
                  icon: Icons.delete_forever_outlined,
                  title: _tr('profile.delete_account_request'),
                  subtitle: _tr('profile.delete_account_subtitle'),
                  action: _tr('profile.request_deletion'),
                  destructive: true,
                  onPressed: isActionLoading || pending != null
                      ? null
                      : () => _confirmDeletion(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('profile.delete_account_request')),
        content: Text(_tr('profile.delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileBloc>().add(RequestAccountDeletion());
            },
            child: Text(_tr('profile.request_deletion')),
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final ProfileActionPending state;

  const _PendingBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isExport = state.actionType == 'export';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacityValues(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacityValues(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExport
                    ? Icons.download_outlined
                    : Icons.delete_forever_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                _tr(
                  isExport
                      ? 'profile.export_pending_title'
                      : 'profile.deletion_pending_title',
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_tr(state.message)),
          if (state.requestId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _tr('profile.request_id')
                    .replaceAll('{request_id}', state.requestId),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final bool destructive;
  final VoidCallback? onPressed;

  const _DataCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.destructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primaryPurple;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);

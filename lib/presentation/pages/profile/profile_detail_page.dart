// lib/presentation/pages/profile/profile_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(
              context: context,
              message: _tr(state.message),
            );
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(
              context: context,
              message: _tr(state.message),
            );
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          return AppScaffold(
            currentIndex: 3,
            appBar: AppBar(
              title: Text(_tr('profile.title')),
              backgroundColor: AppColors.primaryWhite,
              elevation: 0,
            ),
            body: _buildBody(context, state, loaded),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileState state,
    ProfileLoaded? loaded,
  ) {
    if (state is ProfileLoading || state is ProfileInitial) {
      return const Center(child: HIVLoader());
    }
    if (loaded == null) {
      return RetryPanel(
        messageKey: 'profile.load_error',
        onRetry: () => context.read<ProfileBloc>().add(LoadProfile()),
      );
    }

    final profile = loaded.profile;
    return RefreshIndicator(
      onRefresh: () async => context.read<ProfileBloc>().add(LoadProfile()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProfileHeader(profile: profile, loaded: loaded),
          const SizedBox(height: 16),
          _StatusGrid(loaded: loaded),
          const SizedBox(height: 16),
          _SectionTitle(_tr('profile.manage_profile')),
          _ActionTile(
            icon: Icons.edit_outlined,
            title: _tr('profile.edit_profile'),
            subtitle: _tr('profile.edit_profile_subtitle'),
            onTap: () => context.push('/profile/edit'),
          ),
          _ActionTile(
            icon: Icons.photo_library_outlined,
            title: _tr('profile.photos'),
            subtitle: _tr('profile.photos_subtitle'),
            trailing: Text('${profile.photoCount}/${_photoLimit(loaded)}'),
            onTap: () => context.push('/profile/photos'),
          ),
          _ActionTile(
            icon: Icons.verified_user_outlined,
            title: _tr('profile.verification'),
            subtitle: _verificationLabel(loaded.verification),
            onTap: () => context.push('/verification'),
          ),
          const SizedBox(height: 16),
          _SectionTitle(_tr('profile.privacy_security')),
          _ActionTile(
            icon: Icons.visibility_outlined,
            title: _tr('profile.privacy'),
            subtitle: _tr('profile.privacy_subtitle'),
            onTap: () => context.push('/profile/privacy'),
          ),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: _tr('profile.notifications'),
            subtitle: _tr('profile.notifications_subtitle'),
            onTap: () => context.push('/profile/notifications'),
          ),
          _ActionTile(
            icon: Icons.block_outlined,
            title: _tr('profile.blocked_users'),
            subtitle: _tr('profile.blocked_users_subtitle'),
            onTap: () => context.push('/profile/blocked-users'),
          ),
          const SizedBox(height: 16),
          _SectionTitle(_tr('profile.premium_data')),
          _ActionTile(
            icon: Icons.workspace_premium_outlined,
            title: loaded.premiumStatus?.isPremium == true
                ? _tr('profile.premium_active')
                : _tr('profile.upgrade_premium'),
            subtitle: _tr('profile.premium_subtitle'),
            onTap: () => context.push('/premium'),
          ),
          _ActionTile(
            icon: Icons.favorite_outline,
            title: _tr('profile.likes_received'),
            subtitle: loaded.premiumStatus?.canSeeLikers == true
                ? _tr('profile.likes_received_subtitle')
                : _tr('profile.likes_premium_required'),
            onTap: () => context.push(
              loaded.premiumStatus?.canSeeLikers == true
                  ? '/likes-received'
                  : '/premium',
            ),
          ),
          _ActionTile(
            icon: Icons.data_object_outlined,
            title: _tr('profile.data_requests'),
            subtitle: _tr('profile.data_requests_subtitle'),
            onTap: () => context.push('/profile/data'),
          ),
          const SizedBox(height: 16),
          _SectionTitle(_tr('profile.support_legal')),
          _ActionTile(
            icon: Icons.info_outline,
            title: _tr('profile.about'),
            subtitle: _tr('profile.about_subtitle'),
            onTap: () => context.push('/about'),
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: _tr('profile.privacy_policy'),
            subtitle: _tr('profile.privacy_policy_subtitle'),
            onTap: () => context.push('/privacy'),
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            title: _tr('profile.terms'),
            subtitle: _tr('profile.terms_subtitle'),
            onTap: () => context.push('/terms'),
          ),
          const SizedBox(height: 16),
          _SectionTitle(_tr('profile.account_access')),
          _ActionTile(
            icon: Icons.logout,
            title: _tr('profile.sign_out'),
            subtitle: _tr('profile.sign_out_subtitle'),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

void _confirmSignOut(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_tr('profile.sign_out')),
      content: Text(_tr('profile.sign_out_confirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(_tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<AuthBlocSimple>().add(LoggedOut());
            context.go('/');
          },
          child: Text(_tr('profile.sign_out')),
        ),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;
  final ProfileLoaded loaded;

  const _ProfileHeader({required this.profile, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 96,
              height: 118,
              child: OptimizedImage(
                imageUrl: profile.mainPhotoUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(profile),
                  style: Theme.of(context).textTheme.displayMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _locationText(profile),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      icon: Icons.verified,
                      label: _verificationLabel(loaded.verification),
                      color: loaded.verification?.isVerified == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    _Badge(
                      icon: Icons.workspace_premium,
                      label: loaded.premiumStatus?.isPremium == true
                          ? _tr('profile.premium')
                          : _tr('profile.free'),
                      color: loaded.premiumStatus?.isPremium == true
                          ? AppColors.primaryPurple
                          : AppColors.slate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final ProfileLoaded loaded;

  const _StatusGrid({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final profile = loaded.profile;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: _tr('profile.interests'),
            value: profile.interests.length.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: _tr('profile.photos'),
            value: profile.photoCount.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: _tr('profile.visibility'),
            value: profile.privacySettings.profileDiscoverable
                ? _tr('profile.visible')
                : _tr('profile.hidden'),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryPurple,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacityValues(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
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

String _displayName(Profile profile) {
  final age = profile.user?.age ?? profile.age;
  final name = profile.displayName.isEmpty
      ? _tr('profile.my_profile')
      : profile.displayName;
  return age > 0 ? '$name, $age' : name;
}

String _locationText(Profile profile) {
  final location = profile.displayLocation.trim();
  return location.isEmpty ? _tr('profile.location_placeholder') : location;
}

String _verificationLabel(VerificationDetails? details) {
  switch (details?.status) {
    case 'verified':
      return _tr('profile.verified');
    case 'pending_review':
    case 'pending_id':
    case 'pending_medical':
    case 'pending_selfie':
      return _tr('profile.verification_pending');
    case 'rejected':
      return _tr('profile.verification_rejected');
    case 'expired':
      return _tr('profile.verification_expired');
    default:
      return _tr('profile.verification_not_started');
  }
}

int _photoLimit(ProfileLoaded loaded) {
  return loaded.premiumStatus?.isPremium == true ||
          loaded.profile.user?.isPremium == true
      ? AppLimits.maxPhotosPremium
      : AppLimits.maxPhotosGratuit;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacityValues(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

String _tr(String key) => LocalizationService.translate(key);

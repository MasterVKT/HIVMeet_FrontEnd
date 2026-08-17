import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_state.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class LikesReceivedPage extends StatelessWidget {
  const LikesReceivedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBlocSimple, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          // Attendre l'état d'authentification avant de charger quoi que ce soit
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.likes_received')),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: const Center(child: HIVLoader()),
          );
        }

        final isPremium = authState.user.isPremium;
        if (!isPremium) {
          // Upsell immédiat sans appel API inutile
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.likes_received')),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: _ErrorState(
              icon: Icons.workspace_premium_outlined,
              title: _tr('profile.likes_premium_title'),
              subtitle: _tr('profile.likes_premium_message'),
              actionLabel: _tr('profile.upgrade_premium'),
              onPressed: () => context.push('/premium'),
            ),
          );
        }

        return BlocProvider(
          create: (_) => getIt<MatchesBloc>()..add(LoadLikesReceived()),
          child: Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.likes_received')),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: BlocBuilder<MatchesBloc, MatchesState>(
              builder: (context, state) {
                if (state is LikesReceivedLoading || state is MatchesInitial) {
                  return const Center(child: HIVLoader());
                }

                if (state is LikesReceivedLoaded) {
                  if (state.profiles.isEmpty) {
                    return _EmptyState(
                      icon: Icons.favorite_outline,
                      title: _tr('profile.likes_empty_title'),
                      subtitle: _tr('profile.likes_empty_subtitle'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<MatchesBloc>().add(LoadLikesReceived()),
                    child: GridView.builder(
                      padding: EdgeInsets.all(AppSpacing.md),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: state.profiles.length,
                      itemBuilder: (context, index) {
                        return _LikeProfileCard(profile: state.profiles[index]);
                      },
                    ),
                  );
                }

                if (state is MatchesError) {
                  final premiumRequired = state.code == 'premium-required' ||
                      state.message.toLowerCase().contains('premium');
                  return _ErrorState(
                    icon: premiumRequired
                        ? Icons.workspace_premium_outlined
                        : Icons.error_outline,
                    title: premiumRequired
                        ? _tr('profile.likes_premium_title')
                        : _tr('profile.likes_error_title'),
                    subtitle: premiumRequired
                        ? _tr('profile.likes_premium_message')
                        : _tr('profile.likes_error_message'),
                    actionLabel: premiumRequired
                        ? _tr('profile.upgrade_premium')
                        : _tr('common.retry'),
                    onPressed: premiumRequired
                        ? () => context.push('/premium')
                        : () => context.read<MatchesBloc>().add(
                              LoadLikesReceived(),
                            ),
                  );
                }

                return _ErrorState(
                  icon: Icons.error_outline,
                  title: _tr('profile.likes_error_title'),
                  subtitle: _tr('profile.likes_error_message'),
                  actionLabel: _tr('common.retry'),
                  onPressed: () =>
                      context.read<MatchesBloc>().add(LoadLikesReceived()),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LikeProfileCard extends StatelessWidget {
  final DiscoveryProfile profile;

  const _LikeProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/profile-detail?readonly=true',
        extra: profile,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityValues(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedImage(
                imageUrl: profile.mainPhotoUrl,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacityValues(0.72),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile.displayName}, ${profile.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.distance != null)
                        Text(
                          _tr(
                            'profile.distance_km',
                            params: {'distance': profile.distance!.round()},
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      if (profile.likedAt != null)
                        Text(
                          timeago.format(
                            profile.likedAt!,
                            locale: LocalizationService.instance.currentLocale,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.slate),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  const _ErrorState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.primaryPurple),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _tr(String key, {Map<String, dynamic>? params}) =>
    LocalizationService.translate(key, params: params);

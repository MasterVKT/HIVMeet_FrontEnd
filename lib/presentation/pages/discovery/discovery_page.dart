// lib/presentation/pages/discovery/discovery_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';
import 'package:go_router/go_router.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({Key? key}) : super(key: key);

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DiscoveryBloc>()..add(const LoadDiscoveryProfiles()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocConsumer<DiscoveryBloc, DiscoveryState>(
                  listener: (context, state) {
                    if (state is MatchFound) {
                      _showMatchDialog(context, state);
                    } else if (state is DailyLimitReached) {
                      _showLimitDialog(context, state.limitInfo);
                    } else if (state is DiscoveryError) {
                      HIVToast.showError(
                        context: context,
                        message: state.message,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is DiscoveryLoading || state is DiscoveryInitial) {
                      return const Center(child: HIVLoader());
                    }
                    
                    if (state is NoMoreProfiles) {
                      return _buildNoMoreProfiles(context);
                    }
                    
                    if (state is DiscoveryLoaded) {
                      return Stack(
                        children: [
                          // Next profiles preview
                          ...state.nextProfiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final profile = entry.value;
                            return Positioned.fill(
                              child: Transform.scale(
                                scale: 1 - (index + 1) * 0.05,
                                child: Transform.translate(
                                  offset: Offset(0, (index + 1) * 10.0),
                                  child: SwipeCard(
                                    profile: profile,
                                    isPreview: true,
                                  ),
                                ),
                              ),
                            );
                          }).toList().reversed,
                          
                          // Current profile
                          SwipeCard(
                            profile: state.currentProfile,
                            onSwipe: (direction) {
                              context.read<DiscoveryBloc>().add(
                                SwipeProfile(direction: direction),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    
                    return const Center(child: Text('Une erreur est survenue'));
                  },
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/discovery/filters'),
          ),
          Text(
            'Découverte',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state is DiscoveryLoaded && state.dailyLimit != null) {
                final limit = state.dailyLimit!;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: limit.hasReachedLimit
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: limit.hasReachedLimit
                            ? AppColors.error
                            : AppColors.primaryPurple,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${limit.remaining}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: limit.hasReachedLimit
                              ? AppColors.error
                              : AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.refresh,
            color: AppColors.warning,
            onTap: () {
              context.read<DiscoveryBloc>().add(RewindLastSwipe());
            },
          ),
          _ActionButton(
            icon: Icons.close,
            color: AppColors.error,
            size: 60,
            onTap: () {
              context.read<DiscoveryBloc>().add(
                const SwipeProfile(direction: SwipeDirection.left),
              );
            },
          ),
          _ActionButton(
            icon: Icons.star,
            color: AppColors.info,
            onTap: () {
              context.read<DiscoveryBloc>().add(
                const SwipeProfile(direction: SwipeDirection.up),
              );
            },
          ),
          _ActionButton(
            icon: Icons.favorite,
            color: AppColors.success,
            size: 60,
            onTap: () {
              context.read<DiscoveryBloc>().add(
                const SwipeProfile(direction: SwipeDirection.right),
              );
            },
          ),
          _ActionButton(
            icon: Icons.bolt,
            color: AppColors.primaryPurple,
            onTap: () {
              // TODO: Boost functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoMoreProfiles(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 80,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Plus de profils pour le moment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Revenez plus tard ou élargissez vos critères de recherche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.push('/discovery/filters'),
              child: const Text('Modifier les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchDialog(BuildContext context, MatchFound state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _MatchDialog(
        profile: state.matchedProfile,
        onMessage: () {
          Navigator.of(dialogContext).pop();
          context.push('/chat/${state.matchId}');
        },
        onContinue: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showLimitDialog(BuildContext context, DailyLikeLimit limit) {
    HIVDialog.show(
      context: context,
      title: 'Limite quotidienne atteinte',
      content: 'Vous avez utilisé vos ${limit.limit} likes gratuits du jour. '
          'Passez à Premium pour des likes illimités !',
      actions: [
        DialogAction(
          label: 'Plus tard',
          type: DialogActionType.text,
          onPressed: (context) => Navigator.of(context).pop(),
        ),
        DialogAction(
          label: 'Découvrir Premium',
          type: DialogActionType.primary,
          onPressed: (context) {
            Navigator.of(context).pop();
            context.push('/premium');
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _MatchDialog extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback onMessage;
  final VoidCallback onContinue;

  const _MatchDialog({
    required this.profile,
    required this.onMessage,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'C\'est un Match !',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(profile.mainPhotoUrl),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Vous et ${profile.displayName} vous êtes plu !',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onContinue,
                    child: const Text('Continuer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onMessage,
                    child: const Text('Envoyer un message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
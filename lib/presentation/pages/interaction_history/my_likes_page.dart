import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_event.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_state.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

/// Page affichant la liste des profils likés
class MyLikesPage extends StatelessWidget {
  const MyLikesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // Fournit le singleton sans le fermer à la sortie de page
      value: getIt<InteractionHistoryBloc>(),
      child: const _MyLikesPageContent(),
    );
  }
}

class _MyLikesPageContent extends StatefulWidget {
  const _MyLikesPageContent();

  @override
  State<_MyLikesPageContent> createState() => _MyLikesPageContentState();
}

class _MyLikesPageContentState extends State<_MyLikesPageContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Charger les likes au démarrage de la page (refresh: true pour vider la liste)
    getIt<InteractionHistoryBloc>().add(const LoadLikes(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<InteractionHistoryBloc>().add(LoadMoreLikes());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profils likés',
          style: TextStyle(
            color: AppColors.charcoal,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocBuilder<InteractionHistoryBloc, InteractionHistoryState>(
            builder: (context, state) {
              bool includeMatched = false;
              if (state is LikesLoaded) {
                includeMatched = state.includeMatched;
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: AppColors.charcoal),
                onSelected: (value) {
                  if (value == 'toggle_matched') {
                    context
                        .read<InteractionHistoryBloc>()
                        .add(ToggleIncludeMatched());
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_matched',
                    child: Row(
                      children: [
                        Icon(
                          includeMatched
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        const Text('Inclure les matchés'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<InteractionHistoryBloc, InteractionHistoryState>(
        listener: (context, state) {
          if (state is InteractionHistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LikesLoading) {
            return const Center(child: HIVLoader());
          }

          if (state is LikesLoaded) {
            if (state.likes.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<InteractionHistoryBloc>().add(
                      LoadLikes(
                          refresh: true, includeMatched: state.includeMatched),
                    );
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.likes.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.likes.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final interaction = state.likes[index];
                  return _buildInteractionCard(context, interaction);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInteractionCard(
      BuildContext context, InteractionHistory interaction) {
    final theme = Theme.of(context);
    final profile = interaction.profile;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            AppRoutes.profileDetail,
            extra: interaction.profile,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: profile.mainPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.person, size: 48),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.age} ans${profile.distance != null ? ' • ${profile.distance} km' : ''}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge type d'interaction
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: interaction.type == InteractionType.superLike
                              ? AppColors.primaryPurple.withOpacity(0.2)
                              : AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              interaction.type == InteractionType.superLike
                                  ? Icons.star
                                  : Icons.favorite,
                              size: 16,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              interaction.type == InteractionType.superLike
                                  ? 'Super Like'
                                  : 'Like',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Timestamp + Match badge
                  Row(
                    children: [
                      Text(
                        timeago.format(interaction.timestamp, locale: 'fr'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (interaction.isMatched) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Match',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Bouton d'annulation
                  if (interaction.canRevoke) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _revokeInteraction(interaction),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Annuler ce like'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.slate.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun like pour l\'instant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez à liker des profils\npour les retrouver ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _revokeInteraction(InteractionHistory interaction) {
    // Capturer le bloc avant d'ouvrir le dialog
    final bloc = context.read<InteractionHistoryBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler ce like ?'),
        content: Text(
          'Voulez-vous annuler votre like sur ${interaction.profile.displayName} ?\n\n'
          'Ce profil apparaîtra à nouveau dans vos découvertes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Utiliser le bloc capturé au lieu de context.read
              bloc.add(
                RevokeInteractionEvent(
                  interactionId: interaction.id,
                  isLike: true,
                ),
              );
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Interaction annulée - Le profil réapparaîtra dans vos découvertes'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}

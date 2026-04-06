// lib/presentation/pages/interaction_history/my_passes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_event.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_state.dart';

/// Page affichant la liste des profils que l'utilisateur a passés (disliked)
class MyPassesPage extends StatelessWidget {
  const MyPassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // Fournit le singleton sans le fermer à la sortie de page
      value: getIt<InteractionHistoryBloc>(),
      child: const _MyPassesPageContent(),
    );
  }
}

class _MyPassesPageContent extends StatefulWidget {
  const _MyPassesPageContent();

  @override
  State<_MyPassesPageContent> createState() => _MyPassesPageContentState();
}

class _MyPassesPageContentState extends State<_MyPassesPageContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Charger les passes au démarrage de la page (refresh: true pour vider la liste)
    getIt<InteractionHistoryBloc>().add(const LoadPasses(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<InteractionHistoryBloc>().state;
      if (state is PassesLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<InteractionHistoryBloc>().add(LoadMorePasses());
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<InteractionHistoryBloc>().add(const LoadPasses(refresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _revokeInteraction(InteractionHistory interaction) {
    // Capturer le bloc avant d'ouvrir le dialog
    final bloc = context.read<InteractionHistoryBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler cette interaction ?'),
        content: Text(
          'Voulez-vous annuler votre pass sur ${interaction.profile.displayName} ?\n\n'
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
                  isLike: false, // C'est un pass
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Passes'),
        elevation: 0,
      ),
      body: BlocBuilder<InteractionHistoryBloc, InteractionHistoryState>(
        builder: (context, state) {
          if (state is PassesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InteractionHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<InteractionHistoryBloc>().add(LoadPasses());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is PassesLoaded) {
            if (state.passes.isEmpty && !state.isLoadingMore) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aucun pass',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous n\'avez passé aucun profil',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.passes.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.passes.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final interaction = state.passes[index];
                  final profile = interaction.profile;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Navigation vers le profil utilisateur
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
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.displayName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${profile.age} ans${profile.distance != null ? ' • ${profile.distance} km' : ''}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
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
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pass',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Timestamp
                                Text(
                                  timeago.format(interaction.timestamp,
                                      locale: 'fr'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                                // Bouton d'annulation
                                if (interaction.canRevoke) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _revokeInteraction(interaction),
                                      icon: const Icon(Icons.undo, size: 18),
                                      label: const Text('Annuler ce pass'),
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
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

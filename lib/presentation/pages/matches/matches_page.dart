// lib/presentation/pages/matches/matches_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/injection.dart' show getIt;
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_state.dart';
import 'package:hivmeet/presentation/blocs/matches/unseen_matches_cubit.dart';
import 'package:hivmeet/presentation/widgets/matches/matches_widgets.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';
import 'package:hivmeet/core/services/localization_service.dart';

/// Page principale des matches
///
/// Features:
/// - Liste/Grille des matches
/// - Filtrage (Tous/Nouveaux/Actifs)
/// - Recherche par nom
/// - Pull-to-refresh
/// - Infinite scroll
/// - Navigation vers conversations
/// - Bottom navigation bar
class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MatchesBloc>()..add(LoadMatches()),
      child: const _MatchesPageContent(),
    );
  }
}

class _MatchesPageContent extends StatefulWidget {
  const _MatchesPageContent();

  @override
  State<_MatchesPageContent> createState() => _MatchesPageContentState();
}

class _MatchesPageContentState extends State<_MatchesPageContent> {
  final _scrollController = ScrollController();
  final Set<String> _seenMatchIds = <String>{};
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    getIt<RealtimeEventBus>().setActiveRoute('/matches');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    getIt<RealtimeEventBus>().setActiveRoute(null);
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<MatchesBloc>().add(LoadMoreMatches());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  /// A match is considered consulted when this participant has successfully
  /// loaded it in the Matches page. The server owns this state independently
  /// for each participant; the local bloc only updates the current rendering.
  void _markLoadedMatchesAsSeen(
    BuildContext context,
    MatchesLoaded state,
  ) {
    final unseenIds = state.allMatches
        .where((match) => match.isNew && _seenMatchIds.add(match.id))
        .map((match) => match.id)
        .toList(growable: false);
    if (unseenIds.isEmpty) return;

    for (final id in unseenIds) {
      context.read<MatchesBloc>().add(MarkMatchAsSeen(matchId: id));
    }
    try {
      unawaited(
        context
            .read<UnseenMatchesCubit>()
            .markSeen(unseenIds, unseenIds.length),
      );
    } on ProviderNotFoundException {
      // Isolated widget tests and pre-authentication pages do not provide the
      // global badge cubit. The match list remains usable in that context.
    }
  }

  void _onMatchTap(Match match) {
    if (match.isLocked) {
      _showLockedMatchDialog();
      return;
    }
    // Construire le Conversation depuis le Match (match.id == conversationId)
    final conversation = Conversation(
      id: match.id,
      participantIds: [match.profile.userId],
      otherUserId: match.profile.userId,
      otherUserName: match.profile.displayName,
      otherUserPhotoUrl: match.profile.mainPhotoUrl,
      lastMessage: match.lastMessage,
      unreadCount: match.unreadCount,
      updatedAt: match.matchedAt,
      canSendMessages: match.canSendMessages,
      freeMessagesRemaining: match.freeMessagesRemaining,
    );
    context.push('/chat/${match.id}', extra: conversation);
  }

  void _showLockedMatchDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('matches.locked_title')),
        content: Text(_tr('matches.locked_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push(
                  PremiumNavigation.location(returnTo: AppRoutes.matches));
            },
            child: Text(_tr('matches.upgrade')),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        context.read<MatchesBloc>().add(const SearchMatches(query: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      currentIndex: 1, // Matches tab
      appBar: AppBar(
        title: _showSearch
            ? null
            : const Text(
                'Mes Matches',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Rechercher',
            ),
          if (!_showSearch)
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.interactionHistory),
              icon: const Icon(Icons.history, size: 20),
              label: const Text('Historique'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Ouvrir filtres avancés
              },
              tooltip: 'Filtres',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche (visible si activée)
          if (_showSearch)
            MatchesSearchBar(
              onSearchChanged: (query) {
                context.read<MatchesBloc>().add(SearchMatches(query: query));
              },
            ),

          // Barre de filtres
          BlocBuilder<MatchesBloc, MatchesState>(
            builder: (context, state) {
              if (state is MatchesLoaded) {
                return MatchesFilterBar(
                  currentFilter: state.currentFilter,
                  onFilterChanged: (filter) {
                    context
                        .read<MatchesBloc>()
                        .add(FilterMatches(filter: filter));
                  },
                  newMatchesCount: state.newMatchesCount,
                  activeMatchesCount: state.filteredMatches
                      .where((m) => m.lastMessage != null)
                      .length,
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Liste des matches
          Expanded(
            child: BlocConsumer<MatchesBloc, MatchesState>(
              listenWhen: (previous, current) =>
                  current is MatchesLoaded ||
                  current is MatchesError ||
                  (current is MatchesLoaded &&
                      current.actionMessage != null &&
                      current.actionSequence !=
                          (previous is MatchesLoaded
                              ? previous.actionSequence
                              : -1)),
              listener: (context, state) {
                if (state is MatchesLoaded) {
                  _markLoadedMatchesAsSeen(context, state);
                }
                if (state is MatchesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                      action: SnackBarAction(
                        label: 'Réessayer',
                        textColor: Colors.white,
                        onPressed: () {
                          context
                              .read<MatchesBloc>()
                              .add(LoadMatches(refresh: true));
                        },
                      ),
                    ),
                  );
                }
                if (state is MatchesLoaded && state.actionMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionMessage!),
                      backgroundColor: state.actionSucceeded
                          ? null
                          : theme.colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MatchesLoading) {
                  return const MatchesLoadingView();
                }

                if (state is MatchesError) {
                  return MatchesErrorView(
                    message: state.message,
                    onRetry: () {
                      context
                          .read<MatchesBloc>()
                          .add(LoadMatches(refresh: true));
                    },
                  );
                }

                if (state is MatchesLoaded) {
                  final matches = state.filteredMatches;

                  if (matches.isEmpty) {
                    return EmptyMatchesView(
                      filter: state.currentFilter,
                      searchQuery: state.searchQuery,
                      onDiscoverTap: () {
                        context.go('/discovery');
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<MatchesBloc>()
                          .add(LoadMatches(refresh: true));
                      // Attendre que le chargement soit terminé
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: matches.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1, indent: 88);
                      },
                      itemBuilder: (context, index) {
                        // Loading indicator à la fin
                        if (index >= matches.length) {
                          return _buildLoadingMoreIndicator(state);
                        }

                        final match = matches[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: MatchCard(
                            match: match,
                            onTap: () => _onMatchTap(match),
                            onLongPress: () =>
                                _showMatchOptions(context, match),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(MatchesLoaded state) {
    if (!state.isLoadingMore) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  void _showMatchOptions(BuildContext context, Match match) {
    final pageContext = context;
    showModalBottomSheet(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.isLocked)
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: Text(_tr('matches.retry_access')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pageContext
                      .read<MatchesBloc>()
                      .add(UnlockFreeMatchEvent(matchId: match.id));
                },
              ),
            if (match.isLocked)
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(_tr('matches.upgrade')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showLockedMatchDialog();
                },
              ),
            if (!match.isLocked)
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Envoyer un message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _onMatchTap(match);
                },
              ),
            if (!match.isLocked)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Voir le profil'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pageContext.push('/profile/${match.profile.userId}');
                },
              ),
            if (match.isNew && !match.isLocked)
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(pageContext).colorScheme.primary,
                ),
                title: const Text('Marquer comme lu'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pageContext
                      .read<MatchesBloc>()
                      .add(MarkMatchAsSeen(matchId: match.id));
                  try {
                    unawaited(
                      pageContext.read<UnseenMatchesCubit>().markSeen(
                        [match.id],
                        1,
                      ),
                    );
                  } on ProviderNotFoundException {
                    // See the page-level acknowledgement comment above.
                  }
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.heart_broken,
                color: Theme.of(pageContext).colorScheme.error,
              ),
              title: Text(
                'Supprimer ce match',
                style: TextStyle(
                  color: Theme.of(pageContext).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteMatch(pageContext, match);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMatch(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce match?'),
        content: Text(
          'Vous ne pourrez plus communiquer avec ${match.profile.displayName}. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<MatchesBloc>()
                  .add(DeleteMatchEvent(matchId: match.id));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

String _tr(String key, {Map<String, dynamic>? params}) =>
    LocalizationService.translate(key, params: params);

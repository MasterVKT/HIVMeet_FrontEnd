// lib/presentation/pages/matches/matches_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/di/injection.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_state.dart';
import 'package:hivmeet/presentation/widgets/matches/matches_widgets.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';

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
      create: (context) => getIt<MatchesBloc>()..add(LoadMatches()),
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
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _onMatchTap(Match match) {
    // TODO: Naviguer vers la conversation du match
    // Pour l'instant, afficher un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation avec ${match.profile.displayName}'),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // context.go('/conversations/${match.id}');
          },
        ),
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
                    context.read<MatchesBloc>().add(FilterMatches(filter: filter));
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
              listener: (context, state) {
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
              },
              builder: (context, state) {
                if (state is MatchesLoading) {
                  return const MatchesLoadingView();
                }

                if (state is MatchesError) {
                  return MatchesErrorView(
                    message: state.message,
                    onRetry: () {
                      context.read<MatchesBloc>().add(LoadMatches(refresh: true));
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
                      context.read<MatchesBloc>().add(LoadMatches(refresh: true));
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
                            onLongPress: () => _showMatchOptions(context, match),
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
      bottomNavigationBar: _buildBottomNavigationBar(context),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Envoyer un message'),
              onTap: () {
                Navigator.pop(context);
                _onMatchTap(match);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers le profil
              },
            ),
            if (!match.isNew)
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Marquer comme lu'),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<MatchesBloc>()
                      .add(MarkMatchAsSeen(matchId: match.id));
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.heart_broken,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Supprimer ce match',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMatch(context, match);
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

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Match avec ${match.profile.displayName} supprimé'),
                ),
              );
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

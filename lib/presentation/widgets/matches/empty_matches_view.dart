// lib/presentation/widgets/matches/empty_matches_view.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';

/// Widget d'état vide pour les matches
///
/// Affiche des messages appropriés selon le contexte:
/// - Aucun match du tout
/// - Aucun nouveau match
/// - Aucun match actif
/// - Aucun résultat de recherche
class EmptyMatchesView extends StatelessWidget {
  final MatchFilter filter;
  final String? searchQuery;
  final VoidCallback? onDiscoverTap;

  const EmptyMatchesView({
    super.key,
    required this.filter,
    this.searchQuery,
    this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Si recherche active, afficher résultat vide
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun résultat',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun match ne correspond à "$searchQuery"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sinon, afficher selon le filtre
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(theme),
            const SizedBox(height: 24),
            _buildTitle(theme),
            const SizedBox(height: 12),
            _buildSubtitle(theme),
            if (onDiscoverTap != null && filter == MatchFilter.all) ...[
              const SizedBox(height: 32),
              _buildActionButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData iconData;
    Color? color = Colors.grey[400];

    switch (filter) {
      case MatchFilter.newMatches:
        iconData = Icons.new_releases_outlined;
        break;
      case MatchFilter.active:
        iconData = Icons.chat_bubble_outline;
        break;
      case MatchFilter.all:
      default:
        iconData = Icons.favorite_border;
        break;
    }

    return Icon(
      iconData,
      size: 80,
      color: color,
    );
  }

  Widget _buildTitle(ThemeData theme) {
    String title;

    switch (filter) {
      case MatchFilter.newMatches:
        title = 'Aucun nouveau match';
        break;
      case MatchFilter.active:
        title = 'Aucune conversation active';
        break;
      case MatchFilter.all:
      default:
        title = 'Aucun match pour le moment';
        break;
    }

    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: Colors.grey[700],
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    String subtitle;

    switch (filter) {
      case MatchFilter.newMatches:
        subtitle =
            'Les nouveaux matches apparaîtront ici.\nContinuez à swiper!';
        break;
      case MatchFilter.active:
        subtitle =
            'Commencez une conversation avec vos matches\npour qu\'ils apparaissent ici';
        break;
      case MatchFilter.all:
      default:
        subtitle =
            'Commencez à swiper dans l\'onglet Découvrir\npour trouver votre match parfait! 💕';
        break;
    }

    return Text(
      subtitle,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onDiscoverTap,
      icon: const Icon(Icons.explore),
      label: const Text('Découvrir des profils'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

/// Widget d'état de chargement pour les matches
class MatchesLoadingView extends StatelessWidget {
  const MatchesLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de vos matches...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'erreur pour les matches
class MatchesErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MatchesErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups, une erreur est survenue',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

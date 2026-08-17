// lib/presentation/widgets/conversations/empty_conversations_view.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hivmeet/core/services/localization_service.dart';

/// Widget d'état vide pour les conversations
///
/// Affiche des messages appropriés selon le contexte:
/// - Aucune conversation
/// - Aucun résultat de recherche
class EmptyConversationsView extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onMatchesTap;

  const EmptyConversationsView({
    super.key,
    this.searchQuery,
    this.onMatchesTap,
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
                LocalizationService.translate(
                    'conversations.empty_search_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocalizationService.translate(
                  'conversations.empty_search_subtitle',
                  params: {'query': searchQuery ?? ''},
                ),
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

    // Sinon, afficher l'état vide par défaut
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.translate('conversations.empty_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationService.translate('conversations.empty_subtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onMatchesTap != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onMatchesTap,
                icon: const Icon(Icons.favorite),
                label: Text(
                    LocalizationService.translate('conversations.view_matches')),
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
          ],
        ),
      ),
    );
  }
}

/// Widget d'état de chargement pour les conversations (F79).
///
/// Skeleton shimmer plutôt qu'un simple spinner: donne une idée immédiate de
/// la forme du contenu à venir (avatar + 2 lignes de texte par ligne), perçu
/// comme plus réactif qu'un indicateur générique.
class ConversationsLoadingView extends StatelessWidget {
  const ConversationsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget d'erreur pour les conversations
class ConversationsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ConversationsErrorView({
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
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.translate('conversations.error_title'),
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
              // Réutilise common.retry (déjà existant) plutôt qu'une clé
              // conversations.retry dupliquée.
              label: Text(LocalizationService.translate('common.retry')),
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

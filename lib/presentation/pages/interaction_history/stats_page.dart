// lib/presentation/pages/interaction_history/stats_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_event.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_state.dart';

/// Page affichant les statistiques d'interactions de l'utilisateur
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<InteractionHistoryBloc>()..add(LoadStats()),
      child: const _StatsPageContent(),
    );
  }
}

class _StatsPageContent extends StatefulWidget {
  const _StatsPageContent();

  @override
  State<_StatsPageContent> createState() => _StatsPageContentState();
}

class _StatsPageContentState extends State<_StatsPageContent> {
  Future<void> _onRefresh() async {
    context.read<InteractionHistoryBloc>().add(LoadStats());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        elevation: 0,
      ),
      body: BlocBuilder<InteractionHistoryBloc, InteractionHistoryState>(
        builder: (context, state) {
          if (state is StatsLoading) {
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
                      context.read<InteractionHistoryBloc>().add(LoadStats());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is StatsLoaded) {
            final stats = state.stats;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vue d'ensemble
                  Text(
                    'Vue d\'ensemble',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    icon: Icons.favorite,
                    iconColor: Colors.pink,
                    title: 'Total Likes',
                    value: stats.totalLikes.toString(),
                    subtitle: '${stats.totalSuperLikes} Super Likes inclus',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.close_rounded,
                    iconColor: Colors.grey,
                    title: 'Total Passes',
                    value: stats.totalDislikes.toString(),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.offline_bolt,
                    iconColor: Colors.blue,
                    title: 'Total Matches',
                    value: stats.totalMatches.toString(),
                    subtitle: stats.totalLikes > 0
                        ? 'Taux de match: ${stats.matchRate.toStringAsFixed(1)}%'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // Ratios
                  Text(
                    'Ratios',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _RatioRow(
                            label: 'Likes / Total',
                            value: stats.totalInteractions > 0
                                ? (stats.totalLikes /
                                        stats.totalInteractions *
                                        100)
                                    .toStringAsFixed(1)
                                : '0.0',
                            color: Colors.pink,
                          ),
                          const Divider(),
                          _RatioRow(
                            label: 'Passes / Total',
                            value: stats.totalInteractions > 0
                                ? (stats.totalDislikes /
                                        stats.totalInteractions *
                                        100)
                                    .toStringAsFixed(1)
                                : '0.0',
                            color: Colors.grey,
                          ),
                          const Divider(),
                          _RatioRow(
                            label: 'Matches / Likes',
                            value: stats.matchRate.toStringAsFixed(1),
                            color: Colors.blue,
                          ),
                          const Divider(),
                          _RatioRow(
                            label: 'Super Likes / Likes',
                            value: stats.totalLikes > 0
                                ? (stats.totalSuperLikes /
                                        stats.totalLikes *
                                        100)
                                    .toStringAsFixed(1)
                                : '0.0',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Activité
                  Text(
                    'Activité',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    icon: Icons.today,
                    iconColor: Colors.orange,
                    title: 'Activité aujourd\'hui',
                    value: stats.todayInteractions.toString(),
                    subtitle: 'interactions',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.calendar_month,
                    iconColor: Colors.green,
                    title: 'Activité cette semaine',
                    value: stats.weekInteractions.toString(),
                    subtitle: 'interactions',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.timeline,
                    iconColor: Colors.deepPurple,
                    title: 'Total interactions',
                    value: stats.totalInteractions.toString(),
                    subtitle: 'depuis le début',
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Aucune statistique disponible'),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
}

class _RatioRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RatioRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Row(
            children: [
              Text(
                '$value%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                size: 12,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// lib/presentation/widgets/matches/matches_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';

/// Barre de filtres pour les matches
///
/// Permet de filtrer par:
/// - Tous les matches
/// - Nouveaux matches uniquement
/// - Matches actifs (avec conversations)
class MatchesFilterBar extends StatelessWidget {
  final MatchFilter currentFilter;
  final Function(MatchFilter) onFilterChanged;
  final int? newMatchesCount;
  final int? activeMatchesCount;

  const MatchesFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.newMatchesCount,
    this.activeMatchesCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            isSelected: currentFilter == MatchFilter.all,
            onTap: () => onFilterChanged(MatchFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Nouveaux',
            isSelected: currentFilter == MatchFilter.newMatches,
            onTap: () => onFilterChanged(MatchFilter.newMatches),
            count: newMatchesCount,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Actifs',
            isSelected: currentFilter == MatchFilter.active,
            onTap: () => onFilterChanged(MatchFilter.active),
            count: activeMatchesCount,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

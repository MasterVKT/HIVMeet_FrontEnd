// lib/presentation/pages/interaction_history/interaction_history_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';

/// Page principale de l'historique des interactions
///
/// Permet de naviguer vers les différentes sections:
/// - Profils likés
/// - Profils passés
/// - Statistiques
class InteractionHistoryPage extends StatelessWidget {
  const InteractionHistoryPage({super.key});

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
          'Historique des interactions',
          style: TextStyle(
            color: AppColors.charcoal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            context,
            title: 'Profils likés',
            subtitle: 'Revoir les profils que vous avez aimés',
            icon: Icons.favorite,
            iconColor: AppColors.primaryPurple,
            onTap: () => context.push('/interaction-history/likes'),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: 'Profils passés',
            subtitle: 'Profils que vous avez passés ou unlikés',
            icon: Icons.close,
            iconColor: AppColors.slate,
            onTap: () => context.push('/interaction-history/passes'),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: 'Statistiques',
            subtitle: 'Vos statistiques d\'interactions',
            icon: Icons.bar_chart,
            iconColor: AppColors.turquoise,
            onTap: () => context.push('/interaction-history/stats'),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.slate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primaryPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'À propos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous pouvez annuler une interaction pour qu\'un profil réapparaisse dans votre découverte. Cependant, vous ne pouvez pas annuler un like qui a abouti à un match actif.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.charcoal.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

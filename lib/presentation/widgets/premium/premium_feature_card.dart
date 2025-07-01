import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/providers/localization_provider.dart';
import 'package:hivmeet/domain/entities/premium.dart';

class PremiumFeatureCard extends StatelessWidget {
  final PremiumFeature feature;
  final LocalizationProvider localization;

  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.silver.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: _buildContent(),
          ),
          if (feature.isAvailable)
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            )
          else
            Icon(
              Icons.lock,
              color: AppColors.slate,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(),
        color: AppColors.primaryPurple,
        size: 24,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          feature.description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }

  IconData _getIconData() {
    switch (feature.iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'visibility':
        return Icons.visibility;
      case 'star':
        return Icons.star;
      case 'trending_up':
        return Icons.trending_up;
      case 'undo':
        return Icons.undo;
      case 'perm_media':
        return Icons.perm_media;
      case 'videocam':
        return Icons.videocam;
      case 'support':
        return Icons.support;
      case 'tune':
        return Icons.tune;
      case 'visibility_off':
        return Icons.visibility_off;
      default:
        return Icons.diamond;
    }
  }
}

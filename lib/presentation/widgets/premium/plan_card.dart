import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/providers/localization_provider.dart';
import 'package:hivmeet/domain/entities/premium.dart';

class PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool isSelected;
  final VoidCallback onTap;
  final LocalizationProvider localization;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 2,
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.primaryPurple.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPrice(),
            const SizedBox(height: 16),
            _buildFeatures(),
            const Spacer(),
            _buildCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? AppColors.primaryPurple : AppColors.charcoal,
                ),
              ),
              if (plan.isPopular)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.turquoise,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'POPULAIRE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (plan.savings > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '-${plan.savings}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${plan.price.toStringAsFixed(0)}€',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? AppColors.primaryPurple : AppColors.charcoal,
              ),
            ),
            Text(
              '/${_getBillingPeriod()}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
        if (plan.trialPeriodDays > 0)
          Text(
            '${plan.trialPeriodDays} jours gratuits',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildFeatures() {
    final features = _getMainFeatures();

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? null : Border.all(color: AppColors.primaryPurple),
      ),
      child: Text(
        isSelected ? 'Sélectionné' : 'Choisir',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getBillingPeriod() {
    switch (plan.billingInterval) {
      case BillingInterval.monthly:
        return 'mois';
      case BillingInterval.yearly:
        return 'an';
      case BillingInterval.weekly:
        return 'semaine';
    }
  }

  List<String> _getMainFeatures() {
    final features = <String>[];

    if (plan.features.unlimitedLikes) {
      features.add('Likes illimités');
    }
    if (plan.features.canSeeWhoLiked) {
      features.add('Voir qui vous a liké');
    }
    if (plan.features.dailySuperLikes > 0) {
      features.add('${plan.features.dailySuperLikes} Super Likes/jour');
    }
    if (plan.features.monthlyBoosts > 0) {
      features.add('${plan.features.monthlyBoosts} Boost/mois');
    }
    if (plan.features.mediaMessaging) {
      features.add('Messages médias');
    }
    if (plan.features.videoCalls) {
      features.add('Appels vidéo');
    }

    return features.take(5).toList(); // Limite à 5 features principales
  }
}

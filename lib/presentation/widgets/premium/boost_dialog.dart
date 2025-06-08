// lib/presentation/widgets/premium/boost_dialog.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

class BoostDialog extends StatelessWidget {
  final int boostsRemaining;
  final VoidCallback onActivate;

  const BoostDialog({
    Key? key,
    required this.boostsRemaining,
    required this.onActivate,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required int boostsRemaining,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BoostDialog(
        boostsRemaining: boostsRemaining,
        onActivate: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Boost ton profil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sois vu par 10x plus de personnes pendant 30 minutes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (boostsRemaining > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.platinum,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$boostsRemaining boost${boostsRemaining > 1 ? 's' : ''} restant${boostsRemaining > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Activer le boost',
                onPressed: onActivate,
                fullWidth: true,
              ),
            ] else ...[
              Text(
                'Tu n\'as plus de boost disponible',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Obtenir plus de boosts',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/premium');
                },
                fullWidth: true,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
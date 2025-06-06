// lib/presentation/pages/verification/steps/verification_intro_step.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class VerificationIntroStep extends StatelessWidget {
  final VoidCallback onStart;

  const VerificationIntroStep({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              size: 60,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Title
          Text(
            'Vérifiez votre compte',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Description
          Text(
            'La vérification de votre compte nous aide à maintenir une communauté sûre et authentique.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // What you'll need
          Text(
            'Ce dont vous aurez besoin :',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildRequirement(
            context,
            Icons.badge,
            'Document d\'identité',
            'Carte d\'identité, passeport ou permis de conduire',
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildRequirement(
            context,
            Icons.medical_information,
            'Document médical',
            'Document attestant de votre statut (confidentiel)',
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildRequirement(
            context,
            Icons.camera_alt,
            'Selfie avec code',
            'Pour confirmer que vous êtes bien la personne sur les documents',
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // Privacy note
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock,
                  size: 20,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Vos documents sont stockés de manière sécurisée et ne sont jamais partagés avec d\'autres utilisateurs.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // Start button
          AppButton(
            onPressed: onStart,
            text: 'Commencer la vérification',
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
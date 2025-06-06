// lib/presentation/pages/verification/steps/verification_review_step.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_bloc.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_event.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class VerificationReviewStep extends StatelessWidget {
  final VoidCallback onBack;

  const VerificationReviewStep({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationBloc, VerificationState>(
      builder: (context, state) {
        if (state is! VerificationLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final isComplete = state.identityDocumentStatus.isUploaded &&
            state.medicalDocumentStatus.isUploaded &&
            state.selfieStatus.isUploaded;

        final isPending = state.status.status == 'pending_review';
        final isVerified = state.status.status == 'verified';
        final isRejected = state.status.status == 'rejected';

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getStatusColor(state.status.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(state.status.status),
                    size: 60,
                    color: _getStatusColor(state.status.status),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                _getStatusTitle(state.status.status, isComplete),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Description
              Text(
                _getStatusDescription(state.status.status, isComplete),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              // Document status list
              if (!isVerified) ...[
                Text(
                  'Documents soumis :',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildDocumentStatus(
                  context,
                  'Document d\'identité',
                  state.identityDocumentStatus.isUploaded,
                  state.identityDocumentStatus.isVerified,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                _buildDocumentStatus(
                  context,
                  'Document médical',
                  state.medicalDocumentStatus.isUploaded,
                  state.medicalDocumentStatus.isVerified,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                _buildDocumentStatus(
                  context,
                  'Selfie de vérification',
                  state.selfieStatus.isUploaded,
                  state.selfieStatus.isVerified,
                ),
              ],
              
              if (isRejected && state.status.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raison du rejet :',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.status.rejectionReason!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Information box
              if (isPending)
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
                        Icons.info,
                        size: 20,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'La vérification peut prendre 24 à 48 heures. Vous recevrez une notification dès que le processus sera terminé.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Buttons
              if (isComplete && !isPending && !isVerified)
                AppButton(
                  onPressed: () {
                    context.read<VerificationBloc>().add(
                      FinalizeVerificationSubmission(),
                    );
                  },
                  text: 'Soumettre pour vérification',
                  type: ButtonType.primary,
                )
              else if (isRejected)
                Column(
                  children: [
                    AppButton(
                      onPressed: () {
                        context.read<VerificationBloc>().add(ResetVerification());
                      },
                      text: 'Recommencer la vérification',
                      type: ButtonType.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      onPressed: () {
                        // Navigate to support
                      },
                      text: 'Contacter le support',
                      type: ButtonType.secondary,
                    ),
                  ],
                )
              else if (!isComplete && !isVerified)
                AppButton(
                  onPressed: onBack,
                  text: 'Compléter les documents',
                  type: ButtonType.primary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentStatus(
    BuildContext context,
    String title,
    bool isUploaded,
    bool isVerified,
  ) {
    IconData icon;
    Color color;
    String status;

    if (isVerified) {
      icon = Icons.check_circle;
      color = AppColors.success;
      status = 'Vérifié';
    } else if (isUploaded) {
      icon = Icons.upload_file;
      color = AppColors.info;
      status = 'Téléchargé';
    } else {
      icon = Icons.circle_outlined;
      color = AppColors.slate;
      status = 'En attente';
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
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
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified_user;
      case 'pending_review':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.upload_file;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'pending_review':
        return AppColors.info;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primaryPurple;
    }
  }

  String _getStatusTitle(String status, bool isComplete) {
    switch (status) {
      case 'verified':
        return 'Compte vérifié !';
      case 'pending_review':
        return 'Vérification en cours';
      case 'rejected':
        return 'Vérification refusée';
      default:
        return isComplete 
            ? 'Prêt pour la vérification' 
            : 'Documents manquants';
    }
  }

  String _getStatusDescription(String status, bool isComplete) {
    switch (status) {
      case 'verified':
        return 'Votre compte a été vérifié avec succès. Vous pouvez maintenant profiter de tous les avantages d\'un compte vérifié.';
      case 'pending_review':
        return 'Vos documents sont en cours de vérification par notre équipe. Nous vous notifierons dès que le processus sera terminé.';
      case 'rejected':
        return 'Votre demande de vérification a été refusée. Veuillez consulter la raison ci-dessous et soumettre à nouveau vos documents.';
      default:
        return isComplete
            ? 'Tous vos documents ont été téléchargés. Vous pouvez maintenant soumettre votre demande de vérification.'
            : 'Veuillez compléter le téléchargement de tous les documents requis pour procéder à la vérification.';
    }
  }
}
// lib/presentation/pages/verification/steps/selfie_verification_step.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_bloc.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_event.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';

class SelfieVerificationStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const SelfieVerificationStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<SelfieVerificationStep> createState() => _SelfieVerificationStepState();
}

class _SelfieVerificationStepState extends State<SelfieVerificationStep> {
  File? _selectedSelfie;
  final ImagePicker _imagePicker = ImagePicker();
  String? _verificationCode;

  @override
  void initState() {
    super.initState();
    // Generate verification code if not already present
    final state = context.read<VerificationBloc>().state;
    if (state is VerificationLoaded) {
      _verificationCode = state.verificationCode;
    }
    if (_verificationCode == null) {
      context.read<VerificationBloc>().add(GenerateVerificationCode());
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _selectedSelfie = File(image.path);
        });
      }
    } catch (e) {
      HIVToast.showError(
        context: context,
        message: 'Erreur lors de la prise de photo',
      );
    }
  }

  void _submitSelfie() {
    if (_selectedSelfie != null && _verificationCode != null) {
      context.read<VerificationBloc>().add(
        SubmitSelfieWithCode(
          selfie: _selectedSelfie!,
          code: _verificationCode!,
        ),
      );
      widget.onNext();
    } else {
      HIVToast.showError(
        context: context,
        message: 'Veuillez prendre un selfie avec le code',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationBloc, VerificationState>(
      builder: (context, state) {
        bool isUploaded = false;
        
        if (state is VerificationLoaded) {
          isUploaded = state.selfieStatus.isUploaded;
          _verificationCode = state.verificationCode ?? _verificationCode;
          if (isUploaded && _selectedSelfie == null) {
            _selectedSelfie = File(''); // Placeholder
          }
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Selfie de vérification',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Description
              Text(
                'Prenez un selfie en tenant une feuille avec le code ci-dessous écrit lisiblement.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Verification code
              if (_verificationCode != null)
                Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Votre code de vérification',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _verificationCode!,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Écrivez ce code sur une feuille blanche',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              
              // Selfie preview
              GestureDetector(
                onTap: isUploaded ? null : _takeSelfie,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.platinum,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.silver,
                      width: 2,
                      style: _selectedSelfie != null 
                          ? BorderStyle.none 
                          : BorderStyle.solid,
                    ),
                  ),
                  child: _selectedSelfie != null && _selectedSelfie!.path.isNotEmpty
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedSelfie!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (!isUploaded)
                              Positioned(
                                top: AppSpacing.sm,
                                right: AppSpacing.sm,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedSelfie = null;
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            if (isUploaded)
                              Positioned(
                                bottom: AppSpacing.sm,
                                right: AppSpacing.sm,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Selfie téléchargé',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : isUploaded
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 40,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Selfie déjà téléchargé',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: AppColors.slate,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Appuyez pour prendre un selfie',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Instructions
              Text(
                'Instructions importantes :',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              _buildInstruction('Écrivez le code sur une feuille blanche'),
              _buildInstruction('Tenez la feuille visible près de votre visage'),
              _buildInstruction('Assurez-vous que le code est lisible'),
              _buildInstruction('Votre visage doit être clairement visible'),
              _buildInstruction('Bon éclairage, pas de lunettes de soleil'),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      onPressed: widget.onBack,
                      text: 'Retour',
                      type: ButtonType.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      onPressed: isUploaded ? widget.onNext : _submitSelfie,
                      text: isUploaded ? 'Suivant' : 'Télécharger',
                      type: ButtonType.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
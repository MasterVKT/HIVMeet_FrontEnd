// lib/presentation/pages/verification/steps/medical_document_step.dart

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

class MedicalDocumentStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const MedicalDocumentStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<MedicalDocumentStep> createState() => _MedicalDocumentStepState();
}

class _MedicalDocumentStepState extends State<MedicalDocumentStep> {
  File? _selectedDocument;
  final ImagePicker _imagePicker = ImagePicker();
  bool _acceptedPrivacy = false;

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _selectedDocument = File(image.path);
        });
      }
    } catch (e) {
      HIVToast.showError(
        context: context,
        message: 'Erreur lors de la sélection du document',
      );
    }
  }

  Future<void> _showSourceSelector() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir une source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument(ImageSource.camera);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir de la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitDocument() {
    if (!_acceptedPrivacy) {
      HIVToast.showError(
        context: context,
        message: 'Veuillez accepter les conditions de confidentialité',
      );
      return;
    }
    
    if (_selectedDocument != null) {
      context.read<VerificationBloc>().add(
        SubmitMedicalDocument(document: _selectedDocument!),
      );
      widget.onNext();
    } else {
      HIVToast.showError(
        context: context,
        message: 'Veuillez sélectionner un document',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationBloc, VerificationState>(
      builder: (context, state) {
        bool isUploaded = false;
        if (state is VerificationLoaded) {
          isUploaded = state.medicalDocumentStatus.isUploaded;
          if (isUploaded && _selectedDocument == null) {
            _selectedDocument = File(''); // Placeholder
            _acceptedPrivacy = true;
          }
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Document médical',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Description
              Text(
                'Téléchargez un document attestant de votre statut sérologique. Ce document restera strictement confidentiel.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Privacy banner
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.1),
                      AppColors.lightPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Confidentialité absolue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Vos documents médicaux sont chiffrés et stockés de manière sécurisée. Ils ne sont jamais partagés et sont uniquement utilisés pour la vérification.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Document preview
              GestureDetector(
                onTap: isUploaded ? null : _showSourceSelector,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.platinum,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.silver,
                      width: 2,
                      style: _selectedDocument != null 
                          ? BorderStyle.none 
                          : BorderStyle.solid,
                    ),
                  ),
                  child: _selectedDocument != null && _selectedDocument!.path.isNotEmpty
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedDocument!,
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
                                      _selectedDocument = null;
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
                                        'Document téléchargé',
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
                                  'Document déjà téléchargé',
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
                                  Icons.upload_file,
                                  size: 48,
                                  color: AppColors.slate,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Appuyez pour télécharger',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Accepted documents
              Text(
                'Documents acceptés :',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              _buildAcceptedDocument('Résultat de test récent (moins de 6 mois)'),
              _buildAcceptedDocument('Certificat médical'),
              _buildAcceptedDocument('Ordonnance de traitement'),
              _buildAcceptedDocument('Attestation de suivi médical'),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Privacy checkbox
              if (!isUploaded)
                CheckboxListTile(
                  value: _acceptedPrivacy,
                  onChanged: (value) {
                    setState(() {
                      _acceptedPrivacy = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryPurple,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'J\'accepte que ce document soit vérifié de manière confidentielle par l\'équipe HIVMeet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              
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
                      onPressed: isUploaded ? widget.onNext : _submitDocument,
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

  Widget _buildAcceptedDocument(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
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
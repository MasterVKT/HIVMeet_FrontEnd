// lib/presentation/pages/verification/verification_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_bloc.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_event.dart';
import 'package:hivmeet/presentation/blocs/verification/verification_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:hivmeet/presentation/pages/verification/steps/identity_document_step.dart';
import 'package:hivmeet/presentation/pages/verification/steps/medical_document_step.dart';
import 'package:hivmeet/presentation/pages/verification/steps/selfie_verification_step.dart';
import 'package:hivmeet/presentation/pages/verification/steps/verification_intro_step.dart';
import 'package:hivmeet/presentation/pages/verification/steps/verification_review_step.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({Key? key}) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<VerificationBloc>()..add(LoadVerificationStatus()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        body: SafeArea(
          child: BlocConsumer<VerificationBloc, VerificationState>(
            listener: (context, state) {
              if (state is VerificationError) {
                HIVToast.showError(
                  context: context,
                  message: state.message,
                );
                
                if (state.previousState != null) {
                  // Restore previous state after error
                  Future.delayed(const Duration(milliseconds: 500), () {
                    context.read<VerificationBloc>().add(LoadVerificationStatus());
                  });
                }
              }
              
              if (state is VerificationSubmitted) {
                HIVDialog.show(
                  context: context,
                  title: 'Vérification soumise',
                  content: state.message,
                  actions: [
                    DialogAction(
                      label: 'OK',
                      onPressed: (context) {
                        Navigator.of(context).pop();
                        context.go('/home');
                      },
                    ),
                  ],
                );
              }
              
              if (state is VerificationLoaded) {
                // Auto navigate to current step
                switch (state.currentStep) {
                  case 'identity_document':
                    _goToPage(1);
                    break;
                  case 'medical_document':
                    _goToPage(2);
                    break;
                  case 'selfie_with_code':
                    _goToPage(3);
                    break;
                  case 'ready_to_submit':
                  case 'pending_review':
                  case 'verified':
                    _goToPage(4);
                    break;
                  default:
                    _goToPage(0);
                }
              }
            },
            builder: (context, state) {
              if (state is VerificationLoading || state is VerificationInitial) {
                return const Center(child: HIVLoader());
              }
              
              if (state is DocumentUploading) {
                return HIVFullScreenLoader(
                  message: 'Téléchargement en cours... ${(state.uploadProgress * 100).toInt()}%',
                );
              }
              
              if (state is VerificationSubmitting) {
                return const HIVFullScreenLoader(
                  message: 'Soumission de votre vérification...',
                );
              }
              
              return Column(
                children: [
                  // Header with progress
                  _buildHeader(context, state),
                  
                  // Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      children: [
                        VerificationIntroStep(
                          onStart: _goToNextPage,
                        ),
                        IdentityDocumentStep(
                          onNext: _goToNextPage,
                          onBack: _goToPreviousPage,
                        ),
                        MedicalDocumentStep(
                          onNext: _goToNextPage,
                          onBack: _goToPreviousPage,
                        ),
                        SelfieVerificationStep(
                          onNext: _goToNextPage,
                          onBack: _goToPreviousPage,
                        ),
                        VerificationReviewStep(
                          onBack: _goToPreviousPage,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VerificationState state) {
    double progress = 0.0;
    String title = 'Vérification du compte';
    
    if (state is VerificationLoaded) {
      progress = state.progress;
    }
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/profile'),
              ),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the close button
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.platinum,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Step indicator
          Text(
            _getStepText(_currentPageIndex),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepText(int index) {
    switch (index) {
      case 0:
        return 'Introduction';
      case 1:
        return 'Étape 1 sur 3: Document d\'identité';
      case 2:
        return 'Étape 2 sur 3: Document médical';
      case 3:
        return 'Étape 3 sur 3: Selfie de vérification';
      case 4:
        return 'Révision et soumission';
      default:
        return '';
    }
  }
}
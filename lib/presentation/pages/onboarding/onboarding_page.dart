// lib/presentation/pages/onboarding/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Bienvenue sur HIVMeet',
      description: 'Trouvez des connexions authentiques dans un espace sécurisé et bienveillant.',
      imagePath: 'assets/images/onboarding1.png',
      icon: Icons.favorite,
    ),
    OnboardingContent(
      title: 'Sécurité et Confidentialité',
      description: 'Vos données sont protégées. Profils vérifiés pour une expérience sûre.',
      imagePath: 'assets/images/onboarding2.png',
      icon: Icons.verified_user,
    ),
    OnboardingContent(
      title: 'Connexions Significatives',
      description: 'Rencontrez des personnes qui comprennent votre parcours.',
      imagePath: 'assets/images/onboarding3.png',
      icon: Icons.people,
    ),
    OnboardingContent(
      title: 'Ressources et Support',
      description: 'Accédez à des informations utiles et une communauté de soutien.',
      imagePath: 'assets/images/onboarding4.png',
      icon: Icons.support,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Ignorer',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _contents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(content: _contents[index]);
                },
              ),
            ),
            
            // Indicators and buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Page indicators
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _contents.length,
                    effect: ExpandingDotsEffect(
                      dotColor: AppColors.silver,
                      activeDotColor: AppColors.primaryPurple,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button
                      if (_currentPage > 0)
                        AppButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          text: 'Précédent',
                          type: ButtonType.tertiary,
                          fullWidth: false,
                        )
                      else
                        const SizedBox(width: 100),
                      
                      // Next/Start button
                      AppButton(
                        onPressed: () {
                          if (_currentPage < _contents.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        text: _currentPage < _contents.length - 1 ? 'Suivant' : 'Commencer',
                        type: ButtonType.primary,
                        fullWidth: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingPageContent({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration or icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              content.icon,
              size: 100,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // Title
          Text(
            content.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Description
          Text(
            content.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}
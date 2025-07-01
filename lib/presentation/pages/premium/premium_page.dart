// lib/presentation/pages/premium/premium_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/providers/localization_provider.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:hivmeet/presentation/widgets/premium/plan_card.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedPlanId = '';
  bool _isYearlyView = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPremiumData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _loadPremiumData() {
    context.read<PremiumBloc>().add(LoadPremiumPlans());
    context.read<PremiumBloc>().add(LoadCurrentSubscription());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state is PremiumError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is PremiumLoading) {
            return const Center(child: HIVLoader());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, localization),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildHeader(localization),
                        _buildCurrentSubscriptionInfo(state),
                        _buildBillingToggle(localization),
                        _buildPlansSection(state, localization),
                        _buildFeaturesSection(localization),
                        _buildTestimonialsSection(localization),
                        _buildFAQSection(localization),
                        _buildFooter(localization),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, LocalizationProvider localization) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'HIVMeet Premium',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.diamond,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildHeader(LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Découvrez HIVMeet Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Accédez à toutes les fonctionnalités pour des rencontres authentiques',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionInfo(PremiumState state) {
    if (state is! PremiumLoaded || state.currentSubscription == null) {
      return const SizedBox();
    }

    final subscription = state.currentSubscription!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.diamond,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan actuel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subscription.plan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  subscription.isInTrial
                      ? 'Essai jusqu\'au ${_formatDate(subscription.trialEnd!)}'
                      : 'Renouvellement le ${_formatDate(subscription.currentPeriodEnd)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (subscription.cancelAtPeriodEnd)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Annulation',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(LocalizationProvider localization) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearlyView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !_isYearlyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  'Mensuel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isYearlyView ? Colors.white : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearlyView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearlyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Text(
                      'Annuel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _isYearlyView ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isYearlyView)
                      const Text(
                        'Économisez 33%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(
      PremiumState state, LocalizationProvider localization) {
    if (state is! PremiumLoaded) return const SizedBox();

    final filteredPlans = state.plans.where((plan) {
      return _isYearlyView
          ? plan.billingInterval == BillingInterval.yearly
          : plan.billingInterval == BillingInterval.monthly;
    }).toList();

    if (filteredPlans.isEmpty) return const SizedBox();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Choisissez votre plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredPlans.length,
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];
              final isSelected = _selectedPlanId == plan.id;

              return PlanCard(
                plan: plan,
                isSelected: isSelected,
                onTap: () => _selectPlan(plan),
                localization: localization,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedPlanId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              text: 'Commencer Premium',
              onPressed:
                  state is PremiumProcessing ? null : _handleStartPremium,
              isLoading: state is PremiumProcessing,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(LocalizationProvider localization) {
    final features = [
      {
        'title': 'Likes illimités',
        'description': 'Likez autant de profils que vous le souhaitez',
        'icon': Icons.favorite,
      },
      {
        'title': 'Voir qui vous aime',
        'description': 'Découvrez qui vous a liké en premier',
        'icon': Icons.visibility,
      },
      {
        'title': 'Super Likes',
        'description': '5 Super Likes par jour pour vous démarquer',
        'icon': Icons.star,
      },
      {
        'title': 'Boost mensuel',
        'description': 'Soyez vu par plus de personnes',
        'icon': Icons.rocket_launch,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fonctionnalités Premium',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(LocalizationProvider localization) {
    final testimonials = [
      {
        'name': 'Marie, 28 ans',
        'text':
            'HIVMeet Premium m\'a permis de rencontrer ma moitié. Les fonctionnalités avancées font vraiment la différence.',
        'rating': 5,
      },
      {
        'name': 'Antoine, 34 ans',
        'text':
            'Une communauté bienveillante et des outils parfaits pour créer des liens authentiques.',
        'rating': 5,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce que disent nos utilisateurs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonials[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          testimonial['rating'] as int,
                          (index) => Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          testimonial['text'] as String,
                          style: TextStyle(
                            color: AppColors.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Text(
                        testimonial['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(LocalizationProvider localization) {
    final faqs = [
      {
        'question': 'Puis-je annuler mon abonnement à tout moment ?',
        'answer':
            'Oui, vous pouvez annuler votre abonnement à tout moment. Vous conserverez l\'accès premium jusqu\'à la fin de votre période de facturation.',
      },
      {
        'question': 'Les fonctionnalités premium sont-elles sécurisées ?',
        'answer':
            'Absolument. Toutes vos données sont chiffrées et nous respectons strictement votre confidentialité.',
      },
      {
        'question': 'Y a-t-il une période d\'essai gratuite ?',
        'answer':
            'Oui, nous offrons 7 jours d\'essai gratuit pour découvrir toutes les fonctionnalités premium.',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer']!,
                        style: TextStyle(
                          color: AppColors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFooter(LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Rejoignez des milliers d\'utilisateurs qui ont trouvé l\'amour avec HIVMeet Premium',
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showTermsOfService(),
                child: Text(
                  'Conditions d\'utilisation',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
              ),
              TextButton(
                onPressed: () => _showPrivacyPolicy(),
                child: Text(
                  'Politique de confidentialité',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPlan(PremiumPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });
  }

  void _handleStartPremium() {
    if (_selectedPlanId.isEmpty) return;

    context.read<PremiumBloc>().add(PurchasePremium(planId: _selectedPlanId));
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showTermsOfService() {
    // Navigation vers les conditions d'utilisation
  }

  void _showPrivacyPolicy() {
    // Navigation vers la politique de confidentialité
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

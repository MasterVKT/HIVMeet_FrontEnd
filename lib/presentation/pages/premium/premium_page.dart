// lib/presentation/pages/premium/premium_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedPlanIndex = 1; // Default to monthly

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PremiumBloc>()..add(LoadPremiumPlans()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        body: BlocConsumer<PremiumBloc, PremiumState>(
          listener: (context, state) {
            if (state is PremiumPurchaseSuccess) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Bienvenue dans HIVMeet Premium !'),
                  content: const Text(
                    'Votre abonnement est maintenant actif. Profitez de toutes les fonctionnalités premium.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.pop();
                      },
                      child: const Text('Commencer'),
                    ),
                  ],
                ),
              );
            } else if (state is PremiumError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is PremiumLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is PremiumLoaded) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildFeatures(context),
                        _buildPlans(context, state),
                        _buildPurchaseButton(context, state),
                        _buildTerms(context),
                      ],
                    ),
                  ),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    size: 48,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'HIVMeet Premium',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Débloquez toutes les fonctionnalités',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      ('Likes illimités', Icons.favorite),
      ('Voir qui vous a liké', Icons.visibility),
      ('5 Super Likes par jour', Icons.star),
      ('1 Boost par mois', Icons.bolt),
      ('Filtres avancés', Icons.tune),
      ('Mode incognito', Icons.visibility_off),
      ('Annuler les swipes', Icons.replay),
      ('Messagerie illimitée', Icons.message),
      ('Appels vidéo', Icons.videocam),
      ('Contenu exclusif', Icons.lock_open),
    ];

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fonctionnalités Premium',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature.$2,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      feature.$1,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPlans(BuildContext context, PremiumLoaded state) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez votre plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...state.plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            final isSelected = _selectedPlanIndex == index;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: Container(
                margin: EdgeInsets.only(bottom: AppSpacing.md),
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.silver,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _selectedPlanIndex,
                      onChanged: (value) => setState(() => _selectedPlanIndex = value!),
                      activeColor: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plan.discountPercentage > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '-${plan.discountPercentage}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${plan.price} CFA/${plan.duration}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plan.originalPrice != null)
                            Text(
                              '${plan.originalPrice} CFA',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.slate,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context, PremiumLoaded state) {
    final selectedPlan = state.plans[_selectedPlanIndex];
    
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: AppButton(
        text: 'S\'abonner pour ${selectedPlan.price} CFA',
        onPressed: () {
          context.read<PremiumBloc>().add(
            PurchasePremium(planId: selectedPlan.id),
          );
        },
        fullWidth: true,
      ),
    );
  }

  Widget _buildTerms(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'En vous abonnant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/terms'),
                child: const Text('Conditions'),
              ),
              const Text('•', style: TextStyle(color: AppColors.slate)),
              TextButton(
                onPressed: () => context.push('/privacy'),
                child: const Text('Confidentialité'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Renouvellement automatique. Annulez à tout moment.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}
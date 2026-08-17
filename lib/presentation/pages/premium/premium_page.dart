import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  late PremiumBloc _premiumBloc;
  String? _selectedPlanId;
  bool _proration = true;

  @override
  void initState() {
    super.initState();
    _premiumBloc = getIt<PremiumBloc>();
    if (_premiumBloc.state is PremiumInitial) {
      _premiumBloc.add(LoadPremiumPlans());
    }
  }

  @override
  void dispose() {
    _premiumBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PremiumBloc>.value(
      value: _premiumBloc,
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: Text(_tr('premium.title')),
          backgroundColor: AppColors.primaryWhite,
        ),
        body: BlocConsumer<PremiumBloc, PremiumState>(
          listener: _onStateChange,
          builder: (context, state) {
            if (state is PremiumLoading || state is PremiumInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PremiumError) {
              return _ErrorView(message: state.message);
            }
            if (state is PremiumLoaded) {
              return _buildContent(context, state);
            }
            // PremiumProcessing, PremiumModifySuccess, etc.
            // On affiche le dernier contenu connu si disponible
            if (_premiumBloc.state is PremiumLoaded) {
              return _buildContent(
                context,
                _premiumBloc.state as PremiumLoaded,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, PremiumState state) {
    if (state is PremiumModifySuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('premium.plan_updated')),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (state is PremiumModifyError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is PremiumPurchaseSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('premium.purchase_success')),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (state is PremiumPurchaseError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, PremiumLoaded state) {
    final plans = state.plans;
    final currentSub = state.currentSubscription;

    // Sélectionner le plan courant par défaut
    if (_selectedPlanId == null && plans.isNotEmpty) {
      _selectedPlanId = currentSub?.plan.planId ?? plans.first.planId;
    }

    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        // Section : avantages premium
        Text(
          _tr('premium.benefits'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        _FeatureTile(
          icon: Icons.favorite,
          title: _tr('premium.feature_likes_title'),
          subtitle: _tr('premium.feature_likes_subtitle'),
        ),
        _FeatureTile(
          icon: Icons.visibility,
          title: _tr('premium.feature_likers_title'),
          subtitle: _tr('premium.feature_likers_subtitle'),
        ),
        _FeatureTile(
          icon: Icons.replay,
          title: _tr('premium.feature_rewind_title'),
          subtitle: _tr('premium.feature_rewind_subtitle'),
        ),
        const SizedBox(height: 20),

        // Section : plan courant (si abonnement actif)
        if (currentSub != null && currentSub.isActive) ...[
          _CurrentPlanCard(subscription: currentSub),
          const SizedBox(height: 20),
        ],

        // Section : sélection de plan
        if (plans.isEmpty)
          Text(_tr('premium.no_active_subscription'))
        else
          ...plans.map((plan) => _PlanOption(
                id: plan.planId,
                title: plan.name,
                subtitle:
                    '${plan.price.toStringAsFixed(2)} ${plan.currency} / ${_billingIntervalLabel(plan.billingInterval)}',
                groupValue: _selectedPlanId ?? '',
                onTap: () => setState(() => _selectedPlanId = plan.planId),
              )),

        const SizedBox(height: 16),

        // Section : toggle proration (immédiat vs prochain cycle)
        if (currentSub != null && currentSub.isActive) ...[
          _ProrationToggle(
            value: _proration,
            onChanged: (v) => setState(() => _proration = v),
          ),
          const SizedBox(height: 20),
          // Bouton : changer de plan
          _ChangePlanButton(
            onPressed: _onChangePlan,
            isProcessing: _premiumBloc.state is PremiumProcessing,
          ),
        ] else ...[
          // Nouvel abonnement (non-premium)
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _selectedPlanId == null ? null : _onSubscribe,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: Text(_tr('premium.subscribe')),
          ),
        ],
      ],
    );
  }

  void _onChangePlan() {
    if (_selectedPlanId == null) return;
    _premiumBloc.add(ModifySubscription(
      newPlanId: _selectedPlanId!,
      proration: _proration,
    ));
  }

  void _onSubscribe() {
    if (_selectedPlanId == null) return;
    _premiumBloc.add(PurchasePremium(planId: _selectedPlanId!));
  }

  String _billingIntervalLabel(BillingInterval interval) {
    switch (interval) {
      case BillingInterval.monthly:
        return _tr('premium.monthly_plan').toLowerCase();
      case BillingInterval.yearly:
        return _tr('premium.yearly_plan').toLowerCase();
      case BillingInterval.weekly:
        return _tr('premium.weekly_plan').toLowerCase();
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<PremiumBloc>().add(LoadPremiumPlans()),
              child: Text(_tr('premium.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final UserSubscription subscription;

  const _CurrentPlanCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryPurple.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  _tr('premium.current_plan'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subscription.plan.name,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              '${subscription.currentPeriodStart.day}/${subscription.currentPeriodStart.month}/${subscription.currentPeriodStart.year} '
              '— ${subscription.currentPeriodEnd.day}/${subscription.currentPeriodEnd.month}/${subscription.currentPeriodEnd.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProrationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProrationToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value
                  ? _tr('premium.proration_immediate')
                  : _tr('premium.proration_next_cycle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    thumbColor:
                        WidgetStateProperty.all(AppColors.primaryPurple),
                  ),
                ),
                Text(
                  value
                      ? _tr('premium.proration_immediate_short')
                      : _tr('premium.proration_next_cycle_short'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePlanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isProcessing;

  const _ChangePlanButton({
    required this.onPressed,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : onPressed,
        icon: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.swap_horiz),
        label: Text(_tr('premium.change_plan')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryPurple),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String groupValue;
  final VoidCallback onTap;

  const _PlanOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioListTile<String>(
        value: id,
        groupValue: groupValue,
        onChanged: (_) => onTap(),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

String _tr(String key) => LocalizationService.translate(key);

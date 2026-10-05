import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class PremiumPage extends StatefulWidget {
  final String? paymentReturnStatus;
  final String? paymentEventId;
  final String? returnTo;

  const PremiumPage({
    super.key,
    this.paymentReturnStatus,
    this.paymentEventId,
    this.returnTo,
  });

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with WidgetsBindingObserver {
  late PremiumBloc _premiumBloc;
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedPlanId;
  String? _pendingPaymentId;
  String? _pendingPaymentUrl;
  PremiumLoaded? _lastLoadedState;
  PremiumState? _paymentUiState;
  bool _proration = true;
  String? _returnTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _returnTo = PremiumNavigation.sanitizeReturnTo(widget.returnTo);
    _premiumBloc = getIt<PremiumBloc>();
    if (_premiumBloc.state is PremiumInitial) {
      _premiumBloc.add(LoadPremiumPlans());
    }
    _premiumBloc.add(const RestorePendingPayment());
    if (widget.paymentReturnStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyReturnedPayment(widget.paymentReturnStatus);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PremiumPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentEventId != oldWidget.paymentEventId &&
        widget.paymentReturnStatus != null) {
      _verifyReturnedPayment(widget.paymentReturnStatus);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
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
              return _ErrorView(message: _tr('premium.load_error'));
            }
            if (state is PremiumLoaded) {
              _lastLoadedState = state;
              return _buildContent(context, state);
            }
            // PremiumProcessing, PremiumModifySuccess, etc.
            // On affiche le dernier contenu connu si disponible
            if (_lastLoadedState != null) {
              return _buildContent(context, _lastLoadedState!);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, PremiumState state) {
    if (state is PremiumProcessing) {
      _paymentUiState = null;
    } else if (state is PremiumPaymentReady) {
      _paymentUiState = state;
      _pendingPaymentId = state.session.sessionId;
      _pendingPaymentUrl = state.session.paymentUrl;
      _openPaymentPage(state.session);
    } else if (state is PremiumPaymentRestored) {
      _paymentUiState = state;
      _pendingPaymentId = state.attempt.paymentId;
      _pendingPaymentUrl = state.attempt.paymentUrl;
      _selectedPlanId = state.attempt.planId;
      _returnTo = state.attempt.returnTo ?? _returnTo;
    } else if (state is PremiumPaymentVerifying) {
      _paymentUiState = state;
      _pendingPaymentId = state.attempt.paymentId;
      _pendingPaymentUrl = state.attempt.paymentUrl;
    } else if (state is PremiumPaymentPending) {
      _paymentUiState = state;
      _pendingPaymentId = state.paymentId;
      _pendingPaymentUrl = state.paymentUrl ?? _pendingPaymentUrl;
    } else if (state is PremiumModifySuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('premium.plan_updated')),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (state is PremiumModifyError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_localizedPremiumError(
            state.code,
            fallbackKey: 'premium.plan_update_error',
          )),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is PremiumPurchaseSuccess) {
      _paymentUiState = null;
      _pendingPaymentId = null;
      _pendingPaymentUrl = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('premium.purchase_success')),
          backgroundColor: AppColors.success,
        ),
      );
      final destination = PremiumNavigation.sanitizeReturnTo(
        state.returnTo ?? _returnTo,
      );
      if (destination != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(destination);
        });
      }
    } else if (state is PremiumPurchaseError) {
      _paymentUiState = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_localizedPremiumError(
            state.code,
            fallbackKey: 'premium.purchase_error',
          )),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is PremiumPaymentCancelled) {
      _paymentUiState = state;
      _pendingPaymentId = null;
      _pendingPaymentUrl = null;
    } else if (state is PremiumPaymentFailed) {
      _paymentUiState = state;
      _pendingPaymentId = null;
      _pendingPaymentUrl = null;
    } else if (state is PremiumPaymentAbandoned) {
      _paymentUiState = state;
      _pendingPaymentId = null;
      _pendingPaymentUrl = null;
    } else if (state is PremiumPaymentNetworkError) {
      _paymentUiState = state;
    } else if (state is PremiumActivationPending) {
      _paymentUiState = state;
      _pendingPaymentId = state.attempt.paymentId;
      _pendingPaymentUrl = state.attempt.paymentUrl;
      _returnTo = state.attempt.returnTo ?? _returnTo;
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
        if (_paymentStatusCard(_paymentUiState ?? _premiumBloc.state)
            case final card?) ...[
          card,
          const SizedBox(height: 16),
        ],
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
          isLocked: currentSub?.isActive != true,
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
          RadioGroup<String>(
            groupValue: _selectedPlanId,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPlanId = value);
              }
            },
            child: Column(
              children: plans
                  .map(
                    (plan) => _PlanOption(
                      id: plan.planId,
                      title: _planTitle(plan),
                      price: _formatMoney(context, plan.price, plan.currency),
                      interval: _billingIntervalLabel(plan.billingInterval),
                      monthlyEquivalent:
                          plan.billingInterval == BillingInterval.yearly
                              ? _tr(
                                  'premium.monthly_equivalent',
                                  params: {
                                    'price': _formatMoney(
                                      context,
                                      plan.monthlyEquivalent,
                                      plan.currency,
                                    ),
                                  },
                                )
                              : null,
                      savings: plan.savings > 0
                          ? _tr(
                              'premium.annual_savings',
                              params: {'percent': plan.savings.toString()},
                            )
                          : null,
                      isRecommended: plan.isRecommended,
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 16),

        _CurrencyNotice(
          effectiveCurrency: state.paymentCapabilities.effectiveCurrency,
        ),

        if (state.paymentCapabilities.available &&
            !state.paymentCapabilities.automaticReturnAvailable) ...[
          const SizedBox(height: 16),
          const _PollingOnlyNotice(),
        ],

        const SizedBox(height: 16),

        // This is a draft choice for a confirmed plan change, never an
        // automatic-renewal preference. Do not show it for the current plan.
        if (currentSub != null &&
            currentSub.isActive &&
            _selectedPlanId != null &&
            _selectedPlanId != currentSub.plan.planId) ...[
          _ProrationTimingChoice(
            value: _proration,
            onChanged: (v) => setState(() => _proration = v),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('premium.change_timing_confirmation'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          // Un changement immédiat peut nécessiter un nouveau Paylink
          // (MyCoolPay n'a pas d'API de modification) si le montant net
          // proratisé est positif — le numéro sert à l'initier le cas
          // échéant ; ignoré si le crédit restant couvre déjà le nouveau plan.
          if (_proration) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: _tr('premium.payment_phone'),
                hintText: _tr('premium.payment_phone_hint'),
                prefixIcon: const Icon(Icons.phone_android),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Bouton : changer de plan — désactivé tant que le plan
          // sélectionné est celui déjà actif (le backend rejette sinon en
          // `same_plan`).
          _ChangePlanButton(
            onPressed: _selectedPlanId == currentSub.plan.planId
                ? null
                : _onChangePlan,
            isProcessing: _premiumBloc.state is PremiumProcessing,
          ),
        ] else ...[
          // Nouvel abonnement (non-premium)
          const SizedBox(height: 20),
          if (!state.paymentCapabilities.available)
            _PaymentUnavailableNotice(
              callbackVerificationAvailable:
                  state.paymentCapabilities.callbackVerificationAvailable,
            )
          else ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: _tr('premium.payment_phone'),
                hintText: _tr('premium.payment_phone_hint'),
                prefixIcon: const Icon(Icons.phone_android),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selectedPlanId == null ||
                      _premiumBloc.state is PremiumProcessing
                  ? null
                  : _onSubscribe,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(_tr('premium.subscribe')),
            ),
          ],
          if (_pendingPaymentId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checkPendingPayment,
              icon: const Icon(Icons.refresh),
              label: Text(_tr('premium.verify_payment')),
            ),
          ],
        ],
      ],
    );
  }

  void _onChangePlan() {
    if (_selectedPlanId == null) return;
    // Le montant net proratisé (et donc le besoin réel d'un numéro pour
    // créer un Paylink) n'est connu que côté serveur : ne pas bloquer ici
    // si le champ est vide, sous peine d'empêcher à tort un changement qui
    // n'a en fait besoin d'aucun paiement (crédit restant suffisant). Un
    // numéro déjà saisi et manifestement invalide est corrigé tout de suite
    // pour éviter un aller-retour réseau inutile ; sinon, si le backend
    // répond `phone_number_required`, l'erreur localisée invite à le remplir.
    final rawPhone =
        _proration ? _phoneController.text.replaceAll(RegExp(r'\s+'), '') : '';
    if (_proration &&
        rawPhone.isNotEmpty &&
        !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(rawPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('premium.payment_phone_error'))),
      );
      return;
    }
    _premiumBloc.add(ModifySubscription(
      newPlanId: _selectedPlanId!,
      proration: _proration,
      phoneNumber: rawPhone.isEmpty ? null : rawPhone,
      language: Localizations.localeOf(context).languageCode,
    ));
  }

  void _onSubscribe() {
    if (_selectedPlanId == null) return;
    final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('premium.payment_phone_error'))),
      );
      return;
    }
    _premiumBloc.add(PurchasePremium(
      planId: _selectedPlanId!,
      phoneNumber: phone,
      language: Localizations.localeOf(context).languageCode,
      returnTo: _returnTo,
    ));
  }

  Future<void> _openPaymentPage(PaymentSession session) async {
    await _launchPaymentUrl(session.paymentUrl);
  }

  Future<void> _openPendingPaymentPage() async {
    await _launchPaymentUrl(_pendingPaymentUrl);
  }

  Future<void> _launchPaymentUrl(String? value) async {
    if (value == null) return;
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // A browser/platform failure is recoverable from the persisted attempt.
    }
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('premium.payment_open_error'))),
    );
  }

  void _checkPendingPayment() {
    final paymentId = _pendingPaymentId;
    if (paymentId != null) {
      _premiumBloc.add(const VerifyPendingPayment());
    }
  }

  void _verifyReturnedPayment(String? returnStatus) {
    _premiumBloc.add(VerifyPendingPayment(returnStatus: returnStatus));
  }

  Widget? _paymentStatusCard(PremiumState state) {
    if (state is PremiumPaymentReady) {
      return _PaymentStatusCard(
        icon: Icons.open_in_browser,
        title: _tr('premium.payment_resume_title'),
        message: _tr('premium.payment_resume_message'),
        primaryLabel: _tr('premium.continue_payment'),
        onPrimary: () => _openPaymentPage(state.session),
        secondaryLabel: _tr('premium.abandon_payment'),
        onSecondary: () => _premiumBloc.add(const AbandonPendingPayment()),
      );
    }
    if (state is PremiumPaymentRestored) {
      final canVerify = state.attempt.hasPaymentId;
      return _PaymentStatusCard(
        icon: Icons.open_in_browser,
        title: _tr('premium.payment_resume_title'),
        message: canVerify
            ? _tr('premium.payment_resume_message')
            : _tr('premium.payment_draft_resume_message'),
        primaryLabel: state.attempt.canOpenPaymentPage
            ? _tr('premium.reopen_payment')
            : canVerify
                ? _tr('premium.verify_payment')
                : _tr('premium.continue_payment'),
        onPrimary: state.attempt.canOpenPaymentPage
            ? _openPendingPaymentPage
            : canVerify
                ? _checkPendingPayment
                : _onSubscribe,
        secondaryLabel: _tr('premium.abandon_payment'),
        onSecondary: () => _premiumBloc.add(const AbandonPendingPayment()),
      );
    }
    if (state is PremiumPaymentVerifying) {
      return _PaymentStatusCard(
        icon: Icons.sync,
        title: _tr('premium.payment_verifying_title'),
        message: _tr(
          'premium.payment_verifying_message',
          params: {
            'attempt': state.attemptNumber.toString(),
            'total': state.maxAttempts.toString(),
          },
        ),
        busy: true,
      );
    }
    if (state is PremiumPaymentPending) {
      final returnedAfterCancellation = state.returnStatus == 'cancelled';
      final returnedAfterFailure = state.returnStatus == 'failed';
      final title = returnedAfterCancellation
          ? _tr('premium.payment_return_cancelled_pending_title')
          : returnedAfterFailure
              ? _tr('premium.payment_return_failed_pending_title')
              : _tr('premium.payment_pending_title');
      final message = returnedAfterCancellation
          ? _tr('premium.payment_return_cancelled_pending_message')
          : returnedAfterFailure
              ? _tr('premium.payment_return_failed_pending_message')
              : _tr('premium.payment_pending');
      final canReopen = _pendingPaymentUrl != null;
      return _PaymentStatusCard(
        icon: Icons.schedule,
        title: title,
        message: message,
        primaryLabel: canReopen
            ? _tr('premium.reopen_payment')
            : _tr('premium.verify_payment'),
        onPrimary: canReopen ? _openPendingPaymentPage : _checkPendingPayment,
        secondaryLabel: _tr('premium.abandon_payment'),
        onSecondary: () => _premiumBloc.add(const AbandonPendingPayment()),
      );
    }
    if (state is PremiumPaymentNetworkError) {
      return _PaymentStatusCard(
        icon: Icons.cloud_off,
        title: _tr('premium.payment_network_title'),
        message: _tr('premium.payment_network_message'),
        primaryLabel: _tr('premium.retry'),
        onPrimary: _checkPendingPayment,
        secondaryLabel: _tr('premium.abandon_payment'),
        onSecondary: () => _premiumBloc.add(const AbandonPendingPayment()),
      );
    }
    if (state is PremiumActivationPending) {
      return _PaymentStatusCard(
        icon: Icons.sync_problem,
        title: _tr('premium.premium_activation_pending_title'),
        message: _tr('premium.premium_activation_pending'),
        primaryLabel: _tr('premium.retry'),
        onPrimary: _checkPendingPayment,
        secondaryLabel:
            _returnTo == null ? null : _tr('premium.return_to_previous'),
        onSecondary: _returnTo == null ? null : _returnToOrigin,
      );
    }
    if (state is PremiumPaymentCancelled) {
      return _PaymentStatusCard(
        icon: Icons.cancel_outlined,
        title: _tr('premium.payment_cancelled_title'),
        message: _tr('premium.payment_cancelled_message'),
        primaryLabel: _tr('premium.retry_subscription'),
        onPrimary: _returnToPlans,
        secondaryLabel:
            _returnTo == null ? null : _tr('premium.return_to_previous'),
        onSecondary: _returnTo == null ? null : _returnToOrigin,
      );
    }
    if (state is PremiumPaymentFailed) {
      return _PaymentStatusCard(
        icon: Icons.error_outline,
        title: _tr('premium.payment_failed_title'),
        message: _tr('premium.payment_failed_message'),
        primaryLabel: _tr('premium.retry_subscription'),
        onPrimary: _returnToPlans,
        secondaryLabel:
            _returnTo == null ? null : _tr('premium.return_to_previous'),
        onSecondary: _returnTo == null ? null : _returnToOrigin,
      );
    }
    if (state is PremiumPaymentAbandoned) {
      return _PaymentStatusCard(
        icon: Icons.info_outline,
        title: _tr('premium.payment_abandoned_title'),
        message: _tr('premium.payment_abandoned_message'),
      );
    }
    return null;
  }

  void _returnToPlans() {
    setState(() => _paymentUiState = null);
    _premiumBloc.add(LoadPremiumPlans());
  }

  void _returnToOrigin() {
    final destination = PremiumNavigation.sanitizeReturnTo(_returnTo);
    if (destination != null) context.go(destination);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingPayment();
    }
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

  String _planTitle(PremiumPlan plan) {
    switch (plan.billingInterval) {
      case BillingInterval.monthly:
        return _tr('premium.monthly_plan_title');
      case BillingInterval.yearly:
        return _tr('premium.yearly_plan_title');
      case BillingInterval.weekly:
        return plan.name;
    }
  }
}

class _PaymentStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

  const _PaymentStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Card(
        color: AppColors.primaryPurple.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (busy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(icon, color: AppColors.primaryPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message),
              if (primaryLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (primaryLabel != null)
                      FilledButton(
                        onPressed: onPrimary,
                        child: Text(primaryLabel!),
                      ),
                    if (secondaryLabel != null)
                      TextButton(
                        onPressed: onSecondary,
                        child: Text(secondaryLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            if (subscription.scheduledChange case final change?) ...[
              const SizedBox(height: 8),
              Text(
                _tr(
                  'premium.scheduled_change',
                  params: {
                    'plan': change.planName,
                    'date': change.effectiveAt == null
                        ? ''
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).languageCode,
                          ).format(change.effectiveAt!),
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProrationTimingChoice extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProrationTimingChoice({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                _tr('premium.change_timing'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            RadioGroup<bool>(
              groupValue: value,
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: Text(_tr('premium.change_timing_immediate_title')),
                    subtitle: Text(
                      _tr('premium.change_timing_immediate_description'),
                    ),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(_tr('premium.change_timing_next_cycle_title')),
                    subtitle: Text(
                      _tr('premium.change_timing_next_cycle_description'),
                    ),
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

class _ChangePlanButton extends StatelessWidget {
  final VoidCallback? onPressed;
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
        onPressed: (isProcessing || onPressed == null) ? null : onPressed,
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
  final bool isLocked;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isLocked
            ? Semantics(
                label: _tr('premium.premium_locked'),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryPurple,
                ),
              )
            : null,
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String interval;
  final String? monthlyEquivalent;
  final String? savings;
  final bool isRecommended;

  const _PlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.interval,
    this.monthlyEquivalent,
    this.savings,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioListTile<String>(
        value: id,
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (isRecommended) _PlanBadge(label: _tr('premium.recommended')),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$price / $interval'),
              if (monthlyEquivalent != null) Text(monthlyEquivalent!),
              if (savings != null) ...[
                const SizedBox(height: 4),
                _PlanBadge(label: savings!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;

  const _PlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CurrencyNotice extends StatelessWidget {
  final String effectiveCurrency;

  const _CurrencyNotice({required this.effectiveCurrency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.currency_exchange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _tr(
              'premium.prices_in_currency',
              params: {'currency': effectiveCurrency},
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentUnavailableNotice extends StatelessWidget {
  final bool callbackVerificationAvailable;

  const _PaymentUnavailableNotice({
    required this.callbackVerificationAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              callbackVerificationAvailable
                  ? _tr('premium.payment_temporarily_unavailable')
                  : _tr('premium.payment_configuration_incomplete'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollingOnlyNotice extends StatelessWidget {
  const _PollingOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.info),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.open_in_browser, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(child: Text(_tr('premium.payment_polling_only_notice'))),
        ],
      ),
    );
  }
}

String _formatMoney(BuildContext context, double amount, String currency) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final digits = currency == 'XAF' ? 0 : 2;
  final number = NumberFormat.currency(
    locale: locale,
    symbol: '',
    decimalDigits: digits,
  ).format(amount).trim();
  return '$number $currency';
}

String _localizedPremiumError(String? code, {required String fallbackKey}) {
  switch (code) {
    case 'payment_not_configured':
    case 'payment_provider_unavailable':
    case 'payment_capabilities_unavailable':
      return _tr('premium.payment_temporarily_unavailable');
    case 'callback_verification_unavailable':
      return _tr('premium.payment_configuration_incomplete');
    case 'active_subscription_exists':
      return _tr('premium.active_subscription_exists');
    case 'idempotency_conflict':
      return _tr('premium.payment_retry_conflict');
    case 'payment_in_progress':
      return _tr('premium.payment_in_progress');
    case 'payment_not_found':
      return _tr('premium.payment_not_found');
    case 'payment_network_error':
      return _tr('premium.payment_network_message');
    case 'payment_security_error':
    case 'invalid_payment_url':
      return _tr('premium.payment_security_error');
    case 'premium_activation_pending':
      return _tr('premium.premium_activation_pending');
    case 'validation_error':
    case 'invalid_plan':
      return _tr('premium.invalid_purchase_request');
    case 'no_active_subscription':
      return _tr('premium.no_active_subscription');
    case 'same_plan':
      return _tr('premium.same_plan');
    case 'phone_number_required':
      return _tr('premium.phone_number_required');
    default:
      return _tr(fallbackKey);
  }
}

String _tr(String key, {Map<String, String>? params}) =>
    LocalizationService.translate(key, params: params);

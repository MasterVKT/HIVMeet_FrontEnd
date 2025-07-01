// lib/presentation/pages/premium/payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/providers/localization_provider.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class PaymentPage extends StatefulWidget {
  final PremiumPlan plan;
  final PaymentSession? paymentSession;

  const PaymentPage({
    super.key,
    required this.plan,
    this.paymentSession,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isProcessing = false;
  PaymentStatus _paymentStatus = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkExistingSession();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _checkExistingSession() {
    if (widget.paymentSession != null) {
      _handlePaymentFlow();
    }
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
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.charcoal,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Paiement sécurisé',
          style: TextStyle(
            color: AppColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state is PremiumPurchaseSuccess) {
            _handlePaymentSuccess();
          } else if (state is PremiumPurchaseError) {
            _showErrorMessage(state.message);
            setState(() {
              _isProcessing = false;
            });
          } else if (state is PremiumError) {
            _showErrorMessage(state.message);
            setState(() {
              _isProcessing = false;
            });
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSecurityBadge(),
                            const SizedBox(height: 24),
                            _buildOrderSummary(localization),
                            const SizedBox(height: 24),
                            _buildPaymentMethodSection(localization),
                            const SizedBox(height: 24),
                            _buildPricingBreakdown(localization),
                            const SizedBox(height: 24),
                            _buildLegalNotice(localization),
                          ],
                        ),
                      ),
                    ),
                    _buildPaymentButton(state, localization),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement 100% sécurisé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Vos données sont protégées par MyCoolPay',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Image.network(
            'https://mycoolpay.com/assets/logo-badge.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.payment,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Récapitulatif de commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      widget.plan.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.plan.price.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  Text(
                    _getBillingPeriod(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.plan.trialPeriodDays > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.plan.trialPeriodDays} jours d\'essai gratuit',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Méthode de paiement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            icon: Icons.credit_card,
            title: 'Carte bancaire',
            subtitle: 'Visa, Mastercard, American Express',
            isSelected: true,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            icon: Icons.account_balance,
            title: 'Virement bancaire',
            subtitle: 'SEPA, virement instantané',
            isSelected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryPurple.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryPurple : AppColors.silver,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryPurple : AppColors.slate,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.charcoal,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: AppColors.primaryPurple,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(LocalizationProvider localization) {
    final subtotal = widget.plan.price;
    final tax = subtotal * 0.2; // TVA 20%
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          _buildPriceRow('Sous-total', '${subtotal.toStringAsFixed(2)}€'),
          const SizedBox(height: 8),
          _buildPriceRow('TVA (20%)', '${tax.toStringAsFixed(2)}€'),
          const Divider(height: 24),
          _buildPriceRow(
            'Total',
            '${total.toStringAsFixed(2)}€',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.charcoal : AppColors.slate,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primaryPurple : AppColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalNotice(LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.platinum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.slate,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Informations importantes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Renouvellement automatique jusqu\'à annulation\n'
            '• Annulation possible à tout moment\n'
            '• Aucun engagement de durée\n'
            '• Support client disponible 7j/7',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.slate,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(
      PremiumState state, LocalizationProvider localization) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          AppButton(
            text: _getButtonText(),
            onPressed: _isProcessing ? null : _handlePayment,
            isLoading: _isProcessing || state is PremiumProcessing,
            gradient: AppColors.primaryGradient,
            icon: Icons.security,
          ),
          const SizedBox(height: 12),
          Text(
            'En continuant, vous acceptez nos conditions générales',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_isProcessing) {
      return 'Traitement en cours...';
    }

    if (widget.plan.trialPeriodDays > 0) {
      return 'Commencer l\'essai gratuit';
    }

    return 'Payer ${widget.plan.price.toStringAsFixed(2)}€';
  }

  String _getBillingPeriod() {
    switch (widget.plan.billingInterval) {
      case BillingInterval.monthly:
        return 'par mois';
      case BillingInterval.yearly:
        return 'par an';
      case BillingInterval.weekly:
        return 'par semaine';
    }
  }

  void _handlePayment() {
    setState(() {
      _isProcessing = true;
    });

    // Si nous avons déjà une session de paiement, la traiter
    if (widget.paymentSession != null) {
      _handlePaymentFlow();
    } else {
      // Créer une nouvelle session de paiement
      _createPaymentSession();
    }
  }

  void _createPaymentSession() {
    context.read<PremiumBloc>().add(PurchasePremium(planId: widget.plan.id));
  }

  void _handlePaymentFlow() {
    // Simuler le processus de paiement MyCoolPay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Simuler un paiement réussi pour la démo
        _simulatePaymentSuccess();
      }
    });
  }

  void _simulatePaymentSuccess() {
    setState(() {
      _paymentStatus = PaymentStatus.succeeded;
      _isProcessing = false;
    });

    _showSuccessDialog();
  }

  void _handlePaymentSuccess() {
    setState(() {
      _isProcessing = false;
      _paymentStatus = PaymentStatus.succeeded;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bienvenue dans HIVMeet Premium !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre abonnement est maintenant actif. Profitez de toutes les fonctionnalités premium.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Commencer',
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la dialog
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // Retour à l'accueil
              },
              gradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

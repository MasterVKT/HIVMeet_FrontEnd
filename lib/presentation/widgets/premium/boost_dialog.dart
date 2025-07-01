// lib/presentation/widgets/premium/boost_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class BoostDialog extends StatefulWidget {
  final UserSubscription? subscription;
  final VoidCallback? onSuccess;

  const BoostDialog({
    super.key,
    this.subscription,
    this.onSuccess,
  });

  @override
  State<BoostDialog> createState() => _BoostDialogState();
}

class _BoostDialogState extends State<BoostDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  bool _isActivating = false;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeOut,
    ));

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PremiumBloc, PremiumState>(
      listener: (context, state) {
        if (state is BoostActivated) {
          _handleBoostSuccess(state.result);
        }
        if (state is PremiumError) {
          _handleError(state.message);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isActivated ? _buildSuccessContent() : _buildBoostContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildBoostContent() {
    final boostsRemaining =
        widget.subscription?.featuresUsage?.boostsRemaining ?? 0;
    final canUseBoost = boostsRemaining > 0 && !_isActivating;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBoostIcon(),
        const SizedBox(height: 20),
        _buildTitle(),
        const SizedBox(height: 12),
        _buildDescription(),
        const SizedBox(height: 20),
        _buildBoostStats(),
        const SizedBox(height: 24),
        _buildActionButtons(canUseBoost),
      ],
    );
  }

  Widget _buildBoostIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isActivating ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning,
                  AppColors.coral,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 36,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      'Boost ton profil',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.charcoal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      'Sois vu par plus de personnes pendant 30 minutes et augmente tes chances de match !',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.slate,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBoostStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Durée', '30 min'),
              _buildStatItem('Visibilité', '+500%'),
              _buildStatItem('Portée', '+50 profils'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: AppColors.warning,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Boosts restants: ${widget.subscription?.featuresUsage?.boostsRemaining ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.warning,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool canUseBoost) {
    if (!canUseBoost) {
      return _buildUpgradeButton();
    }

    return Column(
      children: [
        AppButton(
          text: _isActivating ? 'Activation...' : 'Activer le Boost',
          onPressed: _isActivating ? null : _activateBoost,
          isLoading: _isActivating,
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.coral],
          ),
          icon: Icons.bolt,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Peut-être plus tard',
            style: TextStyle(
              color: AppColors.slate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    return Column(
      children: [
        AppButton(
          text: 'Passer au Premium',
          onPressed: () {
            Navigator.of(context).pop();
            // Navigation vers la page premium
          },
          gradient: AppColors.primaryGradient,
          icon: Icons.diamond,
        ),
        const SizedBox(height: 8),
        Text(
          'Obtenez plus de boosts avec Premium',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.slate,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSuccessIcon(),
        const SizedBox(height: 20),
        Text(
          'Boost activé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Ton profil est maintenant mis en avant pendant 30 minutes. Tu vas recevoir plus de vues !',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.slate,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildSuccessStats(),
        const SizedBox(height: 24),
        AppButton(
          text: 'Génial !',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSuccess?.call();
          },
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.turquoise],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercles d'onde
            for (int i = 0; i < 3; i++)
              Opacity(
                opacity: (1 - _sparkleAnimation.value) * 0.3,
                child: Container(
                  width: 80 + (i * 20) * _sparkleAnimation.value,
                  height: 80 + (i * 20) * _sparkleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success,
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Icône centrale
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.turquoise,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSuccessStatItem('⚡', 'Boost actif'),
          _buildSuccessStatItem('👁️', '+250 vues'),
          _buildSuccessStatItem('⏰', '29 min restantes'),
        ],
      ),
    );
  }

  Widget _buildSuccessStatItem(String emoji, String text) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  void _activateBoost() {
    setState(() {
      _isActivating = true;
    });

    _pulseController.repeat(reverse: true);

    context.read<PremiumBloc>().add(UseBoost());
  }

  void _handleBoostSuccess(BoostResult result) {
    setState(() {
      _isActivating = false;
      _isActivated = true;
    });

    _pulseController.stop();
    _sparkleController.forward();
  }

  void _handleError(String error) {
    setState(() {
      _isActivating = false;
    });

    _pulseController.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ),
    );
  }

  static void show(
    BuildContext context, {
    UserSubscription? subscription,
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BoostDialog(
        subscription: subscription,
        onSuccess: onSuccess,
      ),
    );
  }
}

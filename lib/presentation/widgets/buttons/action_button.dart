// lib/presentation/widgets/buttons/action_button.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double size;
  final bool isPremium;
  final String? tooltip;
  final String? semanticLabel;

  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.onPressed,
    this.size = 50,
    this.isPremium = false,
    this.tooltip,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure button meets minimum touch target size for accessibility
    final isAccessible = AccessibilityHelper.meetsMinTouchTarget(size, size);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? tooltip ?? '',
      hint: isPremium ? 'Fonctionnalité premium requise' : null,
      child: Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onPressed,
          // Ensure minimum touch target for accessibility
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onPressed == null ? color.withOpacity(0.5) : color,
              shape: BoxShape.circle,
              boxShadow: onPressed != null ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: size * 0.4,
                    semanticLabel: semanticLabel ?? tooltip,
                  ),
                ),
                if (isPremium)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Semantics(
                      label: 'Premium',
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

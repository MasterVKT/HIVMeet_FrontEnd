// lib/presentation/widgets/buttons/hiv_button.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

enum HIVButtonStyle {
  primary,
  secondary,
  outlined,
  text,
}

class HIVButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HIVButtonStyle style;
  final bool fullWidth;
  final bool isLoading;
  final IconData? icon;
  final bool enabled;

  const HIVButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = HIVButtonStyle.primary,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingButton(context);
    }

    switch (style) {
      case HIVButtonStyle.primary:
        return _buildPrimaryButton(context);
      case HIVButtonStyle.secondary:
        return _buildSecondaryButton(context);
      case HIVButtonStyle.outlined:
        return _buildOutlinedButton(context);
      case HIVButtonStyle.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryPurple.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.silver,
          disabledForegroundColor: AppColors.slate,
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.coral.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.silver,
          disabledForegroundColor: AppColors.slate,
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: BorderSide(
            color: enabled ? AppColors.primaryPurple : AppColors.silver,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledForegroundColor: AppColors.slate,
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledForegroundColor: AppColors.slate,
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildLoadingButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.silver,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.slate),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Chargement...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

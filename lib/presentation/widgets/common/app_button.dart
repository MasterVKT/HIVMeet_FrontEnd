// app_button.dart
import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';

enum ButtonType { primary, secondary, tertiary, icon }

class AppButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final double width;
  final double height;
  final bool fullWidth;
  final Gradient? gradient;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 48.0,
    this.fullWidth = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context);
      case ButtonType.secondary:
        return _buildSecondaryButton(context);
      case ButtonType.tertiary:
        return _buildTertiaryButton(context);
      case ButtonType.icon:
        return _buildIconButton(context);
      default:
        return _buildPrimaryButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? width : null,
      height: height,
      child: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: _buildButtonChild(),
              ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: _buildButtonChild(),
            ),
    );
  }

  Widget _buildButtonChild() {
    return isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : (icon != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  if (text != null) const SizedBox(width: 8),
                  if (text != null) Text(text!),
                ],
              )
            : Text(text ?? '');
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? width : null,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: const BorderSide(color: AppColors.primaryPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 2,
                ),
              )
            : (icon != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      if (text != null) const SizedBox(width: 8),
                      if (text != null) Text(text!),
                    ],
                  )
                : Text(text ?? ''),
      ),
    );
  }

  Widget _buildTertiaryButton(BuildContext context) {
    return SizedBox(
      width: fullWidth ? width : null,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 2,
                ),
              )
            : (icon != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      if (text != null) const SizedBox(width: 8),
                      if (text != null) Text(text!),
                    ],
                  )
                : Text(text ?? ''),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    return Container(
      width: height, // Carré
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon ?? Icons.help_outline, color: AppColors.primaryPurple),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

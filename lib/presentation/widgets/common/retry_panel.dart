import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class RetryPanel extends StatelessWidget {
  final String messageKey;
  final VoidCallback onRetry;
  final IconData icon;

  const RetryPanel({
    super.key,
    required this.messageKey,
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate(messageKey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(LocalizationService.translate('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/widgets/common/empty_state_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    print('🔄 DEBUG EmptyStateWidget: build - title=$title');
    print('🔄 DEBUG EmptyStateWidget: icon=$icon, message=$message');
    print(
        '🔄 DEBUG EmptyStateWidget: actionText=$actionText, onAction=${onAction != null}');

    return Container(
      color: Colors.yellow.withOpacity(0.3), // DEBUG: fond jaune visible
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône avec fond circulaire coloré
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 70,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 32),
                // Titre
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    message,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: AppColors.slate,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 40),
                  // Bouton d'action principal
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.tune, size: 22),
                    label: Text(
                      actionText!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

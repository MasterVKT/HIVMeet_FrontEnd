// lib/core/utils/accessibility_helper.dart

import 'package:flutter/material.dart';

/// Helper class for accessibility features throughout the app
class AccessibilityHelper {
  /// Check if animations should be reduced for accessibility
  /// Returns true if the user has enabled "Reduce Motion" in system settings
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration based on accessibility settings
  /// Returns a shorter duration if animations should be reduced
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration standard = const Duration(milliseconds: 300),
    Duration reduced = const Duration(milliseconds: 100),
  }) {
    return shouldReduceMotion(context) ? reduced : standard;
  }

  /// Check if text is bold enough for accessibility
  static bool isBoldText(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get accessible text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Generate semantic label for swipe card profile
  static String getProfileCardSemanticLabel({
    required String name,
    required int age,
    required String distance,
    required String? bio,
    bool isVerified = false,
    bool isPremium = false,
    bool isOnline = false,
    int? compatibilityScore,
  }) {
    final StringBuffer label = StringBuffer();

    label.write('Profile de $name, $age ans, à $distance kilomètres');

    if (isOnline) {
      label.write(', en ligne maintenant');
    }

    if (isVerified) {
      label.write(', profil vérifié');
    }

    if (isPremium) {
      label.write(', membre premium');
    }

    if (compatibilityScore != null && compatibilityScore > 0) {
      label.write(', compatibilité de $compatibilityScore pour cent');
    }

    if (bio != null && bio.isNotEmpty) {
      // Limit bio length for screen reader
      final shortBio = bio.length > 100 ? '${bio.substring(0, 100)}...' : bio;
      label.write('. Bio: $shortBio');
    }

    label.write('. Balayez à droite pour aimer, à gauche pour passer, ou vers le haut pour super like');

    return label.toString();
  }

  /// Generate semantic label for action buttons
  static String getActionButtonLabel(String action, {bool isPremium = false}) {
    final String label = switch (action) {
      'like' => 'Aimer ce profil',
      'dislike' => 'Passer ce profil',
      'superlike' => 'Super like ce profil',
      'rewind' => 'Annuler la dernière action',
      'filters' => 'Ouvrir les filtres de recherche',
      _ => action,
    };

    return isPremium ? '$label (fonctionnalité premium)' : label;
  }

  /// Generate semantic label for sliders
  static String getSliderSemanticLabel({
    required String label,
    required double value,
    required String unit,
    double? minValue,
    double? maxValue,
  }) {
    final StringBuffer text = StringBuffer(label);
    text.write(', valeur actuelle: ${value.toStringAsFixed(0)} $unit');

    if (minValue != null && maxValue != null) {
      text.write(', plage de ${minValue.toStringAsFixed(0)} à ${maxValue.toStringAsFixed(0)} $unit');
    }

    return text.toString();
  }

  /// Generate semantic label for range sliders
  static String getRangeSliderSemanticLabel({
    required String label,
    required double startValue,
    required double endValue,
    required String unit,
  }) {
    return '$label, de ${startValue.toStringAsFixed(0)} à ${endValue.toStringAsFixed(0)} $unit';
  }

  /// Generate semantic label for toggle switches
  static String getToggleSemanticLabel({
    required String label,
    required bool value,
    bool isPremium = false,
  }) {
    final String status = value ? 'activé' : 'désactivé';
    final String premiumText = isPremium ? ' (fonctionnalité premium)' : '';
    return '$label, $status$premiumText';
  }

  /// Minimum touch target size for accessibility (44x44 dp per WCAG)
  static const double minTouchTargetSize = 44.0;

  /// Check if a widget meets minimum touch target size
  static bool meetsMinTouchTarget(double width, double height) {
    return width >= minTouchTargetSize && height >= minTouchTargetSize;
  }

  /// Wrap a widget with minimum touch target padding if needed
  static Widget ensureMinTouchTarget({
    required Widget child,
    double? currentWidth,
    double? currentHeight,
  }) {
    final needsPadding =
      (currentWidth != null && currentWidth < minTouchTargetSize) ||
      (currentHeight != null && currentHeight < minTouchTargetSize);

    if (!needsPadding) return child;

    final horizontalPadding = currentWidth != null && currentWidth < minTouchTargetSize
      ? (minTouchTargetSize - currentWidth) / 2
      : 0.0;

    final verticalPadding = currentHeight != null && currentHeight < minTouchTargetSize
      ? (minTouchTargetSize - currentHeight) / 2
      : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: child,
    );
  }

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 100),
        behavior: SnackBarBehavior.floating,
        // Hide the snackbar visually but keep it for screen readers
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

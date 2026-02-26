// lib/core/utils/accessibility_helper.dart

import 'dart:math';
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

  // ====================================================================
  // COLOR CONTRAST ACCESSIBILITY HELPERS
  // ====================================================================

  /// Calculate relative luminance of a color
  /// Based on WCAG 2.1 specification
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double getRelativeLuminance(Color color) {
    // Convert RGB values to sRGB
    final r = _getSRGBValue(color.red);
    final g = _getSRGBValue(color.green);
    final b = _getSRGBValue(color.blue);

    // Calculate relative luminance
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Convert RGB component to sRGB value
  static double _getSRGBValue(int component) {
    final value = component / 255.0;
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Calculate contrast ratio between two colors
  /// Based on WCAG 2.1 specification
  /// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
  /// Returns a value between 1 and 21
  static double getContrastRatio(Color color1, Color color2) {
    final luminance1 = getRelativeLuminance(color1);
    final luminance2 = getRelativeLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standard (4.5:1 for normal text)
  static bool meetsWCAGAA(Color foreground, Color background,
      {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    // Large text (18pt+ or 14pt+ bold) requires 3:1, normal text requires 4.5:1
    final minimumRatio = isLargeText ? 3.0 : 4.5;
    return ratio >= minimumRatio;
  }

  /// Check if contrast ratio meets WCAG AAA standard (7:1 for normal text)
  static bool meetsWCAGAAA(Color foreground, Color background,
      {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    // Large text requires 4.5:1, normal text requires 7:1
    final minimumRatio = isLargeText ? 4.5 : 7.0;
    return ratio >= minimumRatio;
  }

  /// Get a description of the contrast quality
  static String getContrastQuality(Color foreground, Color background,
      {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);

    if (meetsWCAGAAA(foreground, background, isLargeText: isLargeText)) {
      return 'Excellent (AAA)';
    } else if (meetsWCAGAA(foreground, background, isLargeText: isLargeText)) {
      return 'Good (AA)';
    } else {
      return 'Poor (Fails WCAG)';
    }
  }

  /// Validate contrast ratios for theme colors
  /// Returns a map of color combination names to their contrast ratios
  static Map<String, ContrastTestResult> validateThemeContrast(ThemeData theme) {
    final results = <String, ContrastTestResult>{};

    // Test primary color combinations
    results['Primary on Background'] = ContrastTestResult(
      foreground: theme.colorScheme.primary,
      background: theme.scaffoldBackgroundColor,
      ratio: getContrastRatio(
          theme.colorScheme.primary, theme.scaffoldBackgroundColor),
    );

    results['OnPrimary on Primary'] = ContrastTestResult(
      foreground: theme.colorScheme.onPrimary,
      background: theme.colorScheme.primary,
      ratio: getContrastRatio(
          theme.colorScheme.onPrimary, theme.colorScheme.primary),
    );

    results['OnSurface on Surface'] = ContrastTestResult(
      foreground: theme.colorScheme.onSurface,
      background: theme.colorScheme.surface,
      ratio: getContrastRatio(
          theme.colorScheme.onSurface, theme.colorScheme.surface),
    );

    results['Error on Background'] = ContrastTestResult(
      foreground: theme.colorScheme.error,
      background: theme.scaffoldBackgroundColor,
      ratio: getContrastRatio(
          theme.colorScheme.error, theme.scaffoldBackgroundColor),
    );

    results['OnError on Error'] = ContrastTestResult(
      foreground: theme.colorScheme.onError,
      background: theme.colorScheme.error,
      ratio:
          getContrastRatio(theme.colorScheme.onError, theme.colorScheme.error),
    );

    return results;
  }
}

/// Result of a contrast test
class ContrastTestResult {
  final Color foreground;
  final Color background;
  final double ratio;

  ContrastTestResult({
    required this.foreground,
    required this.background,
    required this.ratio,
  });

  /// Check if this contrast ratio meets WCAG AA
  bool get meetsAA => ratio >= 4.5;

  /// Check if this contrast ratio meets WCAG AAA
  bool get meetsAAA => ratio >= 7.0;

  /// Get a human-readable quality description
  String get quality {
    if (meetsAAA) return 'Excellent (AAA - ${ratio.toStringAsFixed(2)}:1)';
    if (meetsAA) return 'Good (AA - ${ratio.toStringAsFixed(2)}:1)';
    return 'Poor (${ratio.toStringAsFixed(2)}:1 - Fails WCAG)';
  }
}

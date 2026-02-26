// lib/core/utils/locale_formatter.dart

import 'package:intl/intl.dart';
import 'package:hivmeet/core/services/localization_service.dart';

/// Utility class for locale-aware formatting of numbers, dates, distances, etc.
///
/// This class provides formatting functions that respect the current locale
/// and use appropriate translations from the LocalizationService.
class LocaleFormatter {
  /// Formats a distance in kilometers with the appropriate unit
  ///
  /// Example:
  /// - FR: "5 km"
  /// - EN: "5 km"
  static String formatDistance(double distanceKm) {
    return LocalizationService.translate(
      'discovery.distance_km',
      params: {'km': distanceKm.round().toString()},
    );
  }

  /// Formats an age with the appropriate unit
  ///
  /// Example:
  /// - FR: "25 ans"
  /// - EN: "25 years"
  static String formatAge(int age) {
    return LocalizationService.translate(
      'discovery.age_years',
      params: {'age': age.toString()},
    );
  }

  /// Formats a number using the current locale's number format
  ///
  /// Example:
  /// - FR: "1 234,56"
  /// - EN: "1,234.56"
  static String formatNumber(num value, {int? decimalDigits}) {
    final locale = LocalizationService.instance.currentLocale;
    final formatter = decimalDigits != null
        ? NumberFormat.decimalPattern(locale)
        : NumberFormat.decimalPattern(locale);

    if (decimalDigits != null) {
      formatter.maximumFractionDigits = decimalDigits;
      formatter.minimumFractionDigits = decimalDigits;
    }

    return formatter.format(value);
  }

  /// Formats a date using the current locale's date format
  ///
  /// Example:
  /// - FR: "15 février 2026"
  /// - EN: "February 15, 2026"
  static String formatDate(DateTime date, {String? pattern}) {
    final locale = LocalizationService.instance.currentLocale;
    final formatter = pattern != null
        ? DateFormat(pattern, locale)
        : DateFormat.yMMMMd(locale);
    return formatter.format(date);
  }

  /// Formats a time duration (e.g., for countdown timers)
  ///
  /// Example:
  /// - "2h 30m"
  /// - "45m"
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Formats a percentage with the appropriate symbol
  ///
  /// Example:
  /// - "85%"
  static String formatPercentage(num value) {
    return '${value.round()}%';
  }

  /// Checks if the current locale uses RTL (Right-To-Left) layout
  ///
  /// Returns true for Arabic, Hebrew, and other RTL languages
  static bool isRTL() {
    final locale = LocalizationService.instance.currentLocale;
    // Common RTL language codes
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(locale);
  }

  /// Returns the appropriate text direction based on locale
  ///
  /// Returns TextDirection.rtl for RTL locales, TextDirection.ltr otherwise
  static String getTextDirection() {
    return isRTL() ? 'rtl' : 'ltr';
  }

  /// Formats a count with proper pluralization
  ///
  /// Example:
  /// - FR: "1 like restant", "5 likes restants"
  /// - EN: "1 like remaining", "5 likes remaining"
  static String formatCount(int count, String singularKey, String pluralKey) {
    final key = count == 1 ? singularKey : pluralKey;
    return LocalizationService.translate(key, params: {'count': count.toString()});
  }

  /// Formats a relative time (e.g., "2 hours ago", "just now")
  ///
  /// This is useful for "last seen" timestamps
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return LocalizationService.translate('common.just_now');
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return LocalizationService.translate(
        'common.minutes_ago',
        params: {'count': minutes.toString()},
      );
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return LocalizationService.translate(
        'common.hours_ago',
        params: {'count': hours.toString()},
      );
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return LocalizationService.translate(
        'common.days_ago',
        params: {'count': days.toString()},
      );
    } else {
      return formatDate(dateTime, pattern: 'MMM d, yyyy');
    }
  }

  /// Formats a currency amount with the appropriate symbol and locale
  ///
  /// Example:
  /// - FR: "19,99 €"
  /// - EN: "$19.99"
  static String formatCurrency(num amount, {String currencySymbol = '€'}) {
    final locale = LocalizationService.instance.currentLocale;
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

// lib/core/config/logging_config.dart

import 'package:flutter/foundation.dart';
import '../../core/utils/log_service.dart';

class LoggingConfig {
  static bool _initialized = false;

  static void init() {
    if (!_initialized) {
      _initialized = true;
      // Top-level Dart variables are initialized lazily. Capturing debugPrint
      // in a top-level `final` and reading it only inside the replacement made
      // it resolve to the replacement itself, causing infinite recursion on
      // the first framework diagnostic. Capture it eagerly before assignment.
      final platformDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (!kDebugMode) return;
        platformDebugPrint(
          PrivacyLogSanitizer.sanitize(message),
          wrapWidth: wrapWidth,
        );
      };
    }

    // Initialiser le service de logging
    LogService.info('Logging configuration initialized',
        name: 'HIVMeet.Config');
  }

  static void logInfo(String message, {String? name}) {
    LogService.info(message, name: name);
  }

  static void logWarning(String message, {String? name}) {
    LogService.warning(message, name: name);
  }

  static void logError(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    LogService.error(message, name: name, error: error, stackTrace: stackTrace);
  }

  static void logDebug(String message, {String? name}) {
    LogService.debug(message, name: name);
  }

  /// Méthode pour logguer sans filtrage - pour les logs critiques
  static void logUnfiltered(String message, {String? name}) {
    LogService.logUnfiltered(message, name: name);
  }
}

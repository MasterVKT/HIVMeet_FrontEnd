// lib/core/config/logging_config.dart

import 'package:flutter/foundation.dart';
import '../../core/utils/log_service.dart';

class LoggingConfig {
  static void init() {
    // Désactiver les logs Flutter verbeux en mode release
    if (!kDebugMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }

    // Initialiser le service de logging
    LogService.info('Logging configuration initialized', name: 'HIVMeet.Config');
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

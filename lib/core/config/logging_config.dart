// lib/core/config/logging_config.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LoggingConfig {
  static void init() {
    if (kDebugMode) {
      // Filtrer les logs EGL répétitifs qui ne sont pas utiles
      developer.log(
        'Logging configuration initialized',
        name: 'HIVMeet',
        level: 800, // INFO level
      );
    }
  }

  static void logInfo(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'HIVMeet',
        level: 800, // INFO level
      );
    }
  }

  static void logWarning(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'HIVMeet',
        level: 900, // WARNING level
      );
    }
  }

  static void logError(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'HIVMeet',
        level: 1000, // ERROR level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void logDebug(String message, {String? name}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'HIVMeet',
        level: 500, // DEBUG level
      );
    }
  }
}

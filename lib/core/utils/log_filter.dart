// lib/core/utils/log_filter.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LogFilter {
  static const List<String> _filteredLogs = [
    'EGL_emulation',
    'app_time_stats',
    'D/EGL_emulation',
    'D/EGL_emulation(24420): app_time_stats',
  ];

  static bool shouldLog(String message) {
    if (!kDebugMode) return false;

    // Filtrer les logs EGL répétitifs
    for (final filteredLog in _filteredLogs) {
      if (message.contains(filteredLog)) {
        return false;
      }
    }

    return true;
  }

  static void log(String message, {String? name, int? level}) {
    if (shouldLog(message)) {
      developer.log(
        message,
        name: name ?? 'HIVMeet',
        level: level ?? 800,
      );
    }
  }
}

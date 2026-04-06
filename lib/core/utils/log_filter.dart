// lib/core/utils/log_filter.dart

import 'package:flutter/foundation.dart';
import 'log_service.dart';

/// Ancien fichier de filtre de logs conservé pour compatibilité
/// Utilisez désormais LogService dans lib/core/utils/log_service.dart
@Deprecated('Utilisez LogService à la place')
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
      // Appeler le nouveau service de logging
      // ignore: deprecated_member_use
      LogService.log(message, name: name, level: level);
    }
  }
}

// lib/core/utils/log_service.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Removes direct identifiers before a diagnostic message leaves the app.
///
/// UUIDs are replaced by a stable pseudonym so two messages can still be
/// correlated without exposing a user/profile identifier.
class PrivacyLogSanitizer {
  static final RegExp _email = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );
  static final RegExp _url = RegExp(r'''https?://[^\s\]\[{}()<>'"]+''');
  static final RegExp _phone = RegExp(r'\+\d(?:[\s().-]*\d){7,14}');
  static final RegExp _coordinate = RegExp(
    r'\b(latitude|longitude|lat|lng)\b\s*[:=]\s*[-+]?\d{1,3}(?:\.\d+)?',
    caseSensitive: false,
  );
  static final RegExp _sensitiveField = RegExp(
    r'''(\b(?:display_?name|first_?name|last_?name|bio|address|city|location|photo(?:_url)?|thumbnail(?:_url)?|media_url|fcm_?token)\b\s*[:=]\s*)(?:"[^"]*"|'[^']*'|[^,\s}\]\n]+)''',
    caseSensitive: false,
  );
  // JWT (three base64url segments) and "Bearer <token>" headers, wherever
  // they appear — not just after a recognized field name like the pattern
  // above requires.
  static final RegExp _jwtOrBearer = RegExp(
    r'''(Bearer\s+)?\b[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b''',
  );

  static String sanitize(Object? value) {
    var result = value?.toString() ?? 'null';
    result = result.replaceAll(_email, '<email:redacted>');
    result = result.replaceAllMapped(
      _uuid,
      (match) => '<id:${_fingerprint(match.group(0)!.toLowerCase())}>',
    );
    result = result.replaceAll(_phone, '<phone:redacted>');
    result = result.replaceAll(_jwtOrBearer, '<token:redacted>');
    result = result.replaceAllMapped(
      _coordinate,
      (match) => '${match.group(1)}=<coordinate:redacted>',
    );
    result = result.replaceAllMapped(
      _sensitiveField,
      (match) => '${match.group(1)}<redacted>',
    );
    result = result.replaceAllMapped(_url, (match) {
      final uri = Uri.tryParse(match.group(0)!);
      final host = uri?.host.isNotEmpty == true ? uri!.host : 'unknown';
      return '<url:$host>';
    });
    return result;
  }

  static String _fingerprint(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

/// Privacy-safe drop-in for the subset of dart:developer.log used by the
/// application. Legacy callers can keep their developer alias.
void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  LogService.log(
    message,
    name: name.isEmpty ? null : name,
    level: level,
    error: error,
    stackTrace: stackTrace,
  );
}

class LogService {
  static const bool _enableVerboseLogs = kDebugMode;
  static const List<String> _filteredMessages = [
    'EGL_emulation',
    'app_time_stats',
    'goldfish-opengl',
    'GL error',
    'eglCodecCommon',
    'HostConnection',
    'D/EGL_emulation',
    'D/HostConnection',
    'D/OpenGLRenderer',
    'Skia Shader compilation',
    'GrPipeline',
    'Program',
    'SurfaceView',
    'chatty',
    'RenderThread',
    'Gralloc4',
    'BufferQueueProducer',
    'BufferQueueConsumer',
    'SurfaceComposerClient',
  ];

  static void log(
    dynamic message, {
    String? name,
    int? level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enableVerboseLogs) return;

    final messageStr = PrivacyLogSanitizer.sanitize(message);

    // Vérifier si le message contient un motif à filtrer
    if (_filteredMessages.any((filter) => messageStr.contains(filter))) {
      return; // Ne pas logger les messages filtrés
    }

    developer.log(messageStr, name: name ?? 'HIVMeet', level: level ?? 0);
    if (error != null || stackTrace != null) {
      developer.log(
        PrivacyLogSanitizer.sanitize(
          'Error type: ${error?.runtimeType}\nStackTrace: $stackTrace',
        ),
        name: name ?? 'HIVMeet.Error',
        level: level ?? 200,
      );
    }
  }

  static void debug(dynamic message, {String? name}) {
    log(message, name: name, level: 500); // Level debug
  }

  static void info(dynamic message, {String? name}) {
    log(message, name: name, level: 400); // Level info
  }

  static void warning(dynamic message, {String? name}) {
    log(message, name: name, level: 300); // Level warning
  }

  static void error(dynamic message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    log(message, name: name, level: 200); // Level error

    // Toujours logguer les erreurs avec le détail si disponible
    if (error != null || stackTrace != null) {
      developer.log(
        PrivacyLogSanitizer.sanitize(
          'Error type: ${error?.runtimeType}\nStackTrace: $stackTrace',
        ),
        name: name ?? 'HIVMeet.Error',
        level: 200,
      );
    }
  }

  /// Loggue un message sans filtrage - à utiliser pour les logs critiques
  static void logUnfiltered(dynamic message, {String? name, int? level}) {
    developer.log(PrivacyLogSanitizer.sanitize(message),
        name: name ?? 'HIVMeet.Unfiltered', level: level ?? 0);
  }
}

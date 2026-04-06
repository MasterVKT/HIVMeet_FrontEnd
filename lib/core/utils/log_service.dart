// lib/core/utils/log_service.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

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

  static void log(dynamic message, {String? name, int? level}) {
    if (!_enableVerboseLogs) return;
    
    final messageStr = message.toString();
    
    // Vérifier si le message contient un motif à filtrer
    if (_filteredMessages.any((filter) => messageStr.contains(filter))) {
      return; // Ne pas logger les messages filtrés
    }
    
    developer.log(messageStr, name: name ?? 'HIVMeet', level: level ?? 0);
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
  
  static void error(dynamic message, {String? name, Object? error, StackTrace? stackTrace}) {
    log(message, name: name, level: 200); // Level error
    
    // Toujours logguer les erreurs avec le détail si disponible
    if (error != null || stackTrace != null) {
      developer.log(
        'Error Details: $error\nStackTrace: $stackTrace',
        name: name ?? 'HIVMeet.Error',
        level: 200,
      );
    }
  }

  /// Loggue un message sans filtrage - à utiliser pour les logs critiques
  static void logUnfiltered(dynamic message, {String? name, int? level}) {
    developer.log(message.toString(), name: name ?? 'HIVMeet.Unfiltered', level: level ?? 0);
  }
}
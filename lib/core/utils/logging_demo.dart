// lib/core/utils/logging_demo.dart

import 'log_service.dart';

/// Ce fichier démontre l'utilisation du service de logging centralisé
/// avec filtres pour supprimer les logs répétitifs
class LoggingDemo {
  /// Exemple d'utilisation du service de logging
  static void demonstrateLogging() {
    LogService.info('Démonstration du service de logging');
    
    // Ces logs seront affichés normalement
    LogService.debug('Ceci est un message de debug');
    LogService.info('Ceci est un message d\'information');
    LogService.warning('Ceci est un message d\'avertissement');
    LogService.error('Ceci est un message d\'erreur');
    
    // Ces logs contiennent des termes filtrés et seront ignorés
    LogService.debug('D/EGL_emulation app_time_stats: avg=45.51ms');
    LogService.info('EGL_emulation rendering frame');
    LogService.warning('goldfish-opengl initialization');
    
    // Ces logs seront affichés car ils sont marqués comme non filtrés
    LogService.logUnfiltered('Message critique qui ne doit pas être filtré');
  }
}
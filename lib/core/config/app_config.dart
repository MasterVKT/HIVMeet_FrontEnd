import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;

  // Configuration par défaut (développement)
  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  // Configuration automatique basée sur le mode de build
  static void configure() {
    if (kDebugMode) {
      _environment = Environment.development;
    } else if (kProfileMode) {
      _environment = Environment.staging;
    } else {
      _environment = Environment.production;
    }
  }

  // Configuration Firebase
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'hivmeet-dev';
      case Environment.staging:
        return 'hivmeet-staging';
      case Environment.production:
        return 'hivmeet-prod';
    }
  }

  // URL de l'API Backend - seule différence entre dev et prod
  static String get apiBaseUrl {
    if (kDebugMode) {
      // Mode développement
      return ' http://10.0.2.2:8000';
    } else {
      // Mode production
      return 'https://api.hivmeet.com';
    }
  }

  // Configuration WebSocket
  static String get websocketUrl {
    if (kDebugMode) {
      return 'wss://ws-dev.hivmeet.com';
    } else {
      return 'wss://ws.hivmeet.com';
    }
  }

  // Configuration des logs (activés uniquement en debug)
  static bool get enableLogs => kDebugMode;

  // Configuration des analytics
  static bool get enableAnalytics {
    return _environment != Environment.development;
  }

  // Configuration du cache
  static Duration get cacheTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(minutes: 1); // Cache court pour dev
      case Environment.staging:
        return const Duration(minutes: 5);
      case Environment.production:
        return const Duration(minutes: 15);
    }
  }

  // Nom de l'application
  static String get appName {
    if (kDebugMode) {
      return 'HIVMeet Dev';
    } else {
      return 'HIVMeet';
    }
  }

  // Version de l'API
  static String get apiVersion => 'v1';

  // Configuration des timeouts
  static Duration get httpTimeout => const Duration(seconds: 30);

  // Configuration de la géolocalisation
  static double get defaultLocationRadius {
    return 50.0; // 50 km par défaut
  }

  // Configuration des notifications
  static bool get enablePushNotifications {
    return true;
  }

  // Configuration des fonctionnalités premium
  static bool get enablePremiumFeatures {
    return true;
  }

  // Configuration de debug
  static bool get isDebug {
    return _environment == Environment.development;
  }

  // Configuration des erreurs
  static bool get reportErrors {
    return _environment == Environment.production;
  }
}

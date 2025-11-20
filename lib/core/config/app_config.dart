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
      // - Android Emulator: 10.0.2.2
      // - iOS Simulator: localhost
      // - Web: même machine -> localhost
      // - Fallback: 10.0.2.2 (cas Android devices configurés via port-forwarding)
      if (kIsWeb) {
        return 'http://localhost:8000';
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'http://10.0.2.2:8000';
        case TargetPlatform.iOS:
          return 'http://localhost:8000';
        default:
          return 'http://10.0.2.2:8000';
      }
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

  // ✅ NOUVELLE CONFIGURATION CENTRALISÉE DES ENDPOINTS
  // Endpoints d'authentification
  static const String authBase = '/auth';
  static String get firebaseExchange => '$authBase/firebase-exchange/';
  static String get login => '$authBase/login/';
  static String get register => '$authBase/register/';
  static String get refreshToken => '$authBase/refresh-token/';

  // Endpoints de découverte
  static String get discovery => '/discovery/';
  static String get matches => '/matches/';
  static String get profiles => '/profiles/';

  // Endpoints de messagerie
  static String get conversations => '/conversations/';
  static String get messages => '/messages/';

  // Endpoints de ressources
  static String get resources => '/resources/';

  // Endpoints de premium
  static String get premium => '/premium/';
  static String get subscriptions => '/subscriptions/';

  // Méthode pour construire les URLs complètes
  static String buildUrl(String endpoint) => '$apiBaseUrl/api/v1$endpoint';

  // URLs complètes pré-construites pour les endpoints critiques
  static String get firebaseExchangeUrl => buildUrl(firebaseExchange);
  static String get loginUrl => buildUrl(login);
  static String get registerUrl => buildUrl(register);
  static String get discoveryUrl => buildUrl(discovery);
  static String get matchesUrl => buildUrl(matches);
}

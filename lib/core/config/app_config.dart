import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;
  static bool _isPhysicalDevice = false;
  static bool _initialized = false;

  // Configuration par défaut (développement)
  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Must be called early (before any network call) to detect the device type.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    configure();

    if (kDebugMode && !kIsWeb) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _isPhysicalDevice = !androidInfo.isPhysicalDevice;
          // Invert: isPhysicalDevice = NOT emulator
          _isPhysicalDevice = !_isPhysicalDevice;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _isPhysicalDevice = iosInfo.isPhysicalDevice;
        }
      } catch (_) {
        // If detection fails, assume emulator (safer default for dev)
        _isPhysicalDevice = false;
      }
    }
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
    // --dart-define=API_URL=http://192.168.1.x:8000 overrides all defaults
    const overrideUrl = String.fromEnvironment('API_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl
          .replaceAll(RegExp(r'/+$'), '')
          .replaceAll(RegExp(r'/api/v\d+$'), '');
    }
    if (kDebugMode) {
      // Mode développement
      if (kIsWeb) {
        return 'http://localhost:8000';
      }
      if (_isPhysicalDevice) {
        // Physical device: use the host machine's LAN IP.
        // Default to current machine IP; override with --dart-define=API_URL=...
        // if your host has a different IP.
        return 'http://192.168.1.118:8000';
      }
      // Emulator / simulator
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

  // Configuration WebSocket — co-localisé avec l'API (ws(s)://host/ws/)
  static String get websocketUrl {
    final base = apiBaseUrl;
    // Remplace le schéma http(s) par ws(s)
    return base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
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

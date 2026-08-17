import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/config/app_config.dart';

/// Service de test de connectivité réseau pour le backend Django
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  late final Dio _dio;
  String get baseUrl => AppConfig.apiBaseUrl;

  /// Initialise le service avec configuration Dio optimisée
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'HIVMeet-Flutter',
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) =>
            developer.log(obj.toString(), name: 'NetworkConnectivity'),
      ));
    }
  }

  /// Test de connectivité complet avec le backend Django
  Future<ConnectivityResult> testBackendConnectivity() async {
    developer.log('🔍 Début test connectivité backend...',
        name: 'NetworkConnectivity');

    try {
      // Test 1: Connectivité réseau générale
      if (!await _testGeneralConnectivity()) {
        return ConnectivityResult(
          success: false,
          error: 'Pas de connexion réseau disponible',
          errorType: ConnectivityErrorType.noInternet,
        );
      }

      // Test 2: Accessibilité du serveur Django
      final serverResult = await _testDjangoServerAccess();
      if (!serverResult.success) {
        return serverResult;
      }

      // Test 3: API Django disponible
      final apiResult = await _testDjangoApiEndpoint();
      return apiResult;
    } catch (e) {
      developer.log('❌ Erreur test connectivité: $e',
          name: 'NetworkConnectivity');
      return ConnectivityResult(
        success: false,
        error: 'Erreur inattendue: $e',
        errorType: ConnectivityErrorType.unknown,
      );
    }
  }

  /// Test de connectivité réseau générale
  Future<bool> _testGeneralConnectivity() async {
    try {
      developer.log('📡 Test connectivité réseau générale...',
          name: 'NetworkConnectivity');

      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );

      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      developer.log(
          hasConnection ? '✅ Connexion réseau OK' : '❌ Pas de connexion réseau',
          name: 'NetworkConnectivity');

      return hasConnection;
    } catch (e) {
      developer.log('❌ Test réseau échoué: $e', name: 'NetworkConnectivity');
      return false;
    }
  }

  /// Test d'accessibilité du serveur Django
  Future<ConnectivityResult> _testDjangoServerAccess() async {
    try {
      developer.log('🖥️ Test accès serveur Django: $baseUrl',
          name: 'NetworkConnectivity');

      // Tentative d'accès au health check Django
      final response = await _dio.get('/health/simple/').timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        developer.log('✅ Serveur Django accessible',
            name: 'NetworkConnectivity');
        return ConnectivityResult(success: true, message: 'Serveur accessible');
      } else {
        developer.log(
            '⚠️ Serveur Django répond mais status: ${response.statusCode}',
            name: 'NetworkConnectivity');
        return ConnectivityResult(
          success: false,
          error: 'Serveur inaccessible (Status: ${response.statusCode})',
          errorType: ConnectivityErrorType.serverError,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, 'Erreur accès serveur Django');
    } on TimeoutException {
      return ConnectivityResult(
        success: false,
        error: 'Timeout: Le serveur Django ne répond pas',
        errorType: ConnectivityErrorType.timeout,
      );
    } catch (e) {
      developer.log('❌ Erreur test serveur Django: $e',
          name: 'NetworkConnectivity');
      return ConnectivityResult(
        success: false,
        error: 'Erreur serveur: $e',
        errorType: ConnectivityErrorType.serverError,
      );
    }
  }

  /// Test de l'endpoint API Django
  Future<ConnectivityResult> _testDjangoApiEndpoint() async {
    try {
      developer.log('🔗 Test endpoint API Django...',
          name: 'NetworkConnectivity');

      // Tester un endpoint health (pas d'auth), puis un endpoint API protégé
      final health = await _dio.get('/health/simple/').timeout(
            const Duration(seconds: 10),
          );
      if (health.statusCode == 200) {
        developer.log('✅ Health OK', name: 'NetworkConnectivity');
      }

      final response = await _dio.get('/api/v1/discovery/profiles').timeout(
            const Duration(seconds: 10),
          );

      // 401 = bon signe (API fonctionne mais pas authentifié)
      if (response.statusCode == 401) {
        developer.log('✅ API Django fonctionne (401 = non authentifié, normal)',
            name: 'NetworkConnectivity');
        return ConnectivityResult(
          success: true,
          message: 'API Django opérationnelle (authentification requise)',
        );
      }

      // 200 = très bon signe
      if (response.statusCode == 200) {
        developer.log('✅ API Django accessible et fonctionne',
            name: 'NetworkConnectivity');
        return ConnectivityResult(
            success: true, message: 'API Django pleinement accessible');
      }

      // Autres codes
      developer.log('⚠️ API Django répond avec status: ${response.statusCode}',
          name: 'NetworkConnectivity');
      return ConnectivityResult(
        success: true, // Même si pas 200/401, le serveur répond
        message: 'API Django répond (Status: ${response.statusCode})',
      );
    } on DioException catch (e) {
      // Pour l'API, 401 ou 403 sont des signes positifs
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        developer.log(
            '✅ API Django fonctionne (${e.response?.statusCode} = authentification requise)',
            name: 'NetworkConnectivity');
        return ConnectivityResult(
          success: true,
          message: 'API Django opérationnelle (authentification requise)',
        );
      }

      return _handleDioError(e, 'Erreur test API Django');
    } catch (e) {
      developer.log('❌ Erreur test API Django: $e',
          name: 'NetworkConnectivity');
      return ConnectivityResult(
        success: false,
        error: 'Erreur API: $e',
        errorType: ConnectivityErrorType.apiError,
      );
    }
  }

  /// Gestion centralisée des erreurs Dio
  ConnectivityResult _handleDioError(DioException e, String context) {
    developer.log('❌ $context: ${e.type} - ${e.message}',
        name: 'NetworkConnectivity');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ConnectivityResult(
          success: false,
          error: 'Timeout: Le serveur met trop de temps à répondre',
          errorType: ConnectivityErrorType.timeout,
        );

      case DioExceptionType.connectionError:
        if (e.error is SocketException) {
          return ConnectivityResult(
            success: false,
            error:
                'Impossible de se connecter au serveur (vérifiez que Django fonctionne)',
            errorType: ConnectivityErrorType.connectionRefused,
          );
        }
        return ConnectivityResult(
          success: false,
          error: 'Erreur de connexion réseau',
          errorType: ConnectivityErrorType.networkError,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        return ConnectivityResult(
          success: false,
          error: 'Erreur serveur (Status: $statusCode)',
          errorType: ConnectivityErrorType.serverError,
        );

      default:
        return ConnectivityResult(
          success: false,
          error: 'Erreur réseau: ${e.message}',
          errorType: ConnectivityErrorType.unknown,
        );
    }
  }

  /// Test rapide de connectivité (version simplifiée)
  Future<bool> isBackendReachable() async {
    try {
      final result = await testBackendConnectivity();
      return result.success;
    } catch (e) {
      developer.log('❌ Test connectivité rapide échoué: $e',
          name: 'NetworkConnectivity');
      return false;
    }
  }

  /// Diagnostic complet avec rapport détaillé
  Future<ConnectivityDiagnostic> performDiagnostic() async {
    final diagnostic = ConnectivityDiagnostic();

    try {
      developer.log('🔍 Diagnostic connectivité complet...',
          name: 'NetworkConnectivity');

      // Test 1: Réseau général
      diagnostic.internetAccess = await _testGeneralConnectivity();

      // Test 2: Serveur Django
      final serverResult = await _testDjangoServerAccess();
      diagnostic.serverAccess = serverResult.success;
      diagnostic.serverError = serverResult.error;

      // Test 3: API Django
      final apiResult = await _testDjangoApiEndpoint();
      diagnostic.apiAccess = apiResult.success;
      diagnostic.apiError = apiResult.error;

      // Résumé
      diagnostic.overallSuccess = diagnostic.internetAccess &&
          diagnostic.serverAccess &&
          diagnostic.apiAccess;

      developer.log(
          '📊 Diagnostic terminé: ${diagnostic.overallSuccess ? "SUCCÈS" : "ÉCHEC"}',
          name: 'NetworkConnectivity');

      return diagnostic;
    } catch (e) {
      developer.log('❌ Diagnostic échoué: $e', name: 'NetworkConnectivity');
      diagnostic.overallSuccess = false;
      diagnostic.serverError = 'Erreur diagnostic: $e';
      return diagnostic;
    }
  }
}

/// Résultat d'un test de connectivité
class ConnectivityResult {
  final bool success;
  final String? message;
  final String? error;
  final ConnectivityErrorType? errorType;

  ConnectivityResult({
    required this.success,
    this.message,
    this.error,
    this.errorType,
  });

  @override
  String toString() {
    if (success) {
      return 'ConnectivityResult(SUCCESS: $message)';
    } else {
      return 'ConnectivityResult(FAILURE: $error, type: $errorType)';
    }
  }
}

/// Types d'erreurs de connectivité
enum ConnectivityErrorType {
  noInternet,
  timeout,
  connectionRefused,
  networkError,
  serverError,
  apiError,
  unknown,
}

/// Diagnostic complet de connectivité
class ConnectivityDiagnostic {
  bool internetAccess = false;
  bool serverAccess = false;
  bool apiAccess = false;
  bool overallSuccess = false;
  String? serverError;
  String? apiError;

  Map<String, dynamic> toMap() {
    return {
      'internetAccess': internetAccess,
      'serverAccess': serverAccess,
      'apiAccess': apiAccess,
      'overallSuccess': overallSuccess,
      'serverError': serverError,
      'apiError': apiError,
    };
  }

  @override
  String toString() {
    return 'ConnectivityDiagnostic(${toMap()})';
  }
}

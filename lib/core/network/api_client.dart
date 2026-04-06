import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hivmeet/core/config/app_config.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/services/token_manager.dart';
import 'package:hivmeet/injection.dart';
import 'dart:developer' as developer;

class ApiClient {
  late final Dio _dio;
  final TokenManager _tokenManager;

  ApiClient(this._tokenManager) {
    _dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  String _getBaseUrl() {
    return '${AppConfig.apiBaseUrl}/api/v1/';
  }

  void _setupInterceptors() {
    // Intercepteur intelligent avec gestion automatique des tokens
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _handleRequestAuthentication(options);
          _addLanguageHeader(options);
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          await _handleRequestError(error, handler);
        },
      ),
    );
  }

  /// Gère l'authentification automatique des requêtes
  Future<void> _handleRequestAuthentication(RequestOptions options) async {
    try {
      // Exclure les endpoints qui n'ont pas besoin d'authentification
      final excludedPaths = [
        'auth/firebase-exchange/',
        'auth/register/',
        'auth/login', // match both with and without trailing slash
        'auth/refresh-token',
        'auth/refresh-token/',
        '/health/',
        '/health/simple/',
        '/health/ready/',
      ];

      final isExcluded =
          excludedPaths.any((path) => options.path.contains(path));

      if (isExcluded) {
        developer.log('⚪ Requête sans authentification: ${options.path}',
            name: 'ApiClient');
        return;
      }

      // Récupérer le token via TokenManager
      final token = await _tokenManager.getAccessToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';

        // Vérifier si le token doit être rafraîchi bientôt
        if (_tokenManager.shouldRefreshToken(token)) {
          developer.log('⏰ Token proche de l\'expiration, refresh préventif',
              name: 'ApiClient');

          // Tentative de refresh en arrière-plan (n'interrompt pas la requête courante)
          _tokenManager.refreshAccessToken().then((result) {
            if (result.success) {
              developer.log('✅ Refresh préventif réussi', name: 'ApiClient');
            }
          }).catchError((e) {
            developer.log('⚠️ Refresh préventif échoué: $e', name: 'ApiClient');
          });
        }

        developer.log('🔐 Token ajouté à la requête: ${options.path}',
            name: 'ApiClient');
      } else {
        developer.log('⚠️ Aucun token disponible pour: ${options.path}',
            name: 'ApiClient');
      }
    } catch (e) {
      developer.log('❌ Erreur authentification requête: $e', name: 'ApiClient');
    }
  }

  /// Ajoute l'header de langue
  void _addLanguageHeader(RequestOptions options) {
    try {
      final localizationService = getIt<LocalizationService>();
      options.headers['Accept-Language'] = localizationService.currentLocale;
    } catch (e) {
      options.headers['Accept-Language'] = 'fr'; // Fallback
    }
  }

  /// Log les requêtes pour le debugging
  void _logRequest(RequestOptions options) {
    if (kDebugMode) {
      developer.log('🚀 ${options.method} ${options.uri}', name: 'ApiClient');
      developer.log('📤 DATA: ${options.data}', name: 'ApiClient');

      final hasAuth = options.headers['Authorization'] != null;
      developer.log('🔐 Auth: ${hasAuth ? "✅" : "❌"}', name: 'ApiClient');
    }
  }

  /// Log les réponses pour le debugging
  void _logResponse(Response response) {
    if (kDebugMode) {
      developer.log(
        '✅ ${response.statusCode} ${response.requestOptions.path}',
        name: 'ApiClient',
      );
    }
  }

  /// Gère les erreurs de requête avec retry intelligent
  Future<void> _handleRequestError(
      DioException error, ErrorInterceptorHandler handler) async {
    developer.log(
      '❌ ${error.response?.statusCode ?? "NETWORK"} ${error.requestOptions.path}',
      name: 'ApiClient',
    );

    // Gestion spéciale des erreurs 401 (token expiré)
    if (error.response?.statusCode == 401) {
      final retryResult =
          await _handleUnauthorizedWithRetry(error.requestOptions);

      if (retryResult != null) {
        // Retry réussi, retourner la nouvelle réponse
        handler.resolve(retryResult);
        return;
      }
    }

    handler.next(error);
  }

  /// Gère les erreurs 401 avec tentative de retry automatique
  Future<Response?> _handleUnauthorizedWithRetry(
      RequestOptions originalRequest) async {
    try {
      developer.log('🔄 Tentative de refresh token suite à 401',
          name: 'ApiClient');

      // Tenter le refresh du token
      final refreshResult = await _tokenManager.refreshAccessToken();

      if (refreshResult.success && refreshResult.newAccessToken != null) {
        developer.log('✅ Refresh réussi, retry de la requête',
            name: 'ApiClient');

        // Mettre à jour le header Authorization
        originalRequest.headers['Authorization'] =
            'Bearer ${refreshResult.newAccessToken}';

        // Retry de la requête originale avec le nouveau token
        return await _dio.fetch(originalRequest);
      } else {
        developer.log('❌ Refresh échoué: ${refreshResult.error}',
            name: 'ApiClient');

        // Si le refresh échoue, l'utilisateur doit se reconnecter
        // Note: L'AuthenticationService se chargera de la déconnexion
        return null;
      }
    } catch (e) {
      developer.log('❌ Erreur lors du retry: $e', name: 'ApiClient');
      return null;
    }
  }

  /// Requête GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête PATCH
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Exceptions personnalisées pour l'API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() =>
      'ApiException: $message (Status: $statusCode, Code: $code)';
}

/// Helper pour créer des exceptions depuis les réponses Dio
ApiException createApiException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiException(
        message: 'Délai d\'attente dépassé',
        code: 'TIMEOUT',
      );
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      String message = 'Erreur serveur';
      String? code;

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'];
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        code: code,
      );
    case DioExceptionType.cancel:
      return const ApiException(
        message: 'Requête annulée',
        code: 'CANCELLED',
      );
    case DioExceptionType.connectionError:
      return const ApiException(
        message: 'Erreur de connexion',
        code: 'CONNECTION_ERROR',
      );
    default:
      return const ApiException(
        message: 'Erreur inconnue',
        code: 'UNKNOWN',
      );
  }
}

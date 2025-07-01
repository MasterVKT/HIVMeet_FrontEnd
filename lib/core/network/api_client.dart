import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';

@singleton
class ApiClient {
  static const String _devBaseUrl = 'http://localhost:8000/api/v1/';
  static const String _stagingBaseUrl =
      'https://staging-api.hivmeet.com/api/v1/';
  static const String _prodBaseUrl = 'https://api.hivmeet.com/api/v1/';

  late final Dio _dio;
  String? _accessToken;

  ApiClient() {
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
    if (kDebugMode) {
      return _devBaseUrl;
    } else if (kProfileMode) {
      return _stagingBaseUrl;
    } else {
      return _prodBaseUrl;
    }
  }

  void _setupInterceptors() {
    // Intercepteur pour ajouter les headers d'authentification et de langue
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'authentification
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }

          // Ajouter la langue
          try {
            final localizationService = getIt<LocalizationService>();
            options.headers['Accept-Language'] =
                localizationService.currentLocale;
          } catch (e) {
            options.headers['Accept-Language'] = 'fr'; // Fallback
          }

          if (kDebugMode) {
            debugPrint('🚀 REQUEST: ${options.method} ${options.uri}');
            debugPrint('📤 DATA: ${options.data}');
            debugPrint('📋 HEADERS: ${options.headers}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
                '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('📥 DATA: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('❌ ERROR: ${error.requestOptions.uri}');
            debugPrint('💥 MESSAGE: ${error.message}');
            debugPrint('📊 STATUS: ${error.response?.statusCode}');
          }

          // Gestion automatique des erreurs d'authentification
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }

          handler.next(error);
        },
      ),
    );
  }

  void _handleUnauthorized() {
    // Supprimer le token expiré
    _accessToken = null;
    // TODO: Rediriger vers l'écran de connexion
    debugPrint('🔒 Token expiré - redirection vers connexion nécessaire');
  }

  /// Définir le token d'accès
  void setAccessToken(String? token) {
    _accessToken = token;
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

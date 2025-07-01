import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';

@injectable
class SubscriptionsApi {
  final ApiClient _apiClient;

  const SubscriptionsApi(this._apiClient);

  /// Liste des plans premium disponibles
  /// GET /subscriptions/plans
  Future<Response<Map<String, dynamic>>> getPlans({
    String language = "fr",
    String currency = "EUR",
  }) async {
    return await _apiClient.get('/subscriptions/plans', queryParameters: {
      'language': language,
      'currency': currency,
    });
  }

  /// Abonnement actuel de l'utilisateur
  /// GET /subscriptions/current
  Future<Response<Map<String, dynamic>>> getCurrentSubscription() async {
    return await _apiClient.get('/subscriptions/current');
  }

  /// Créer un nouvel abonnement
  /// POST /subscriptions
  Future<Response<Map<String, dynamic>>> createSubscription({
    required String planId,
    required String paymentMethod,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    return await _apiClient.post('/subscriptions', data: {
      'plan_id': planId,
      'payment_method': paymentMethod,
      'return_url': returnUrl,
      'cancel_url': cancelUrl,
    });
  }

  /// Valider un paiement
  /// GET /subscriptions/validate/{session_id}
  Future<Response<Map<String, dynamic>>> validatePayment(
      String sessionId) async {
    return await _apiClient.get('/subscriptions/validate/$sessionId');
  }

  /// Modifier l'auto-renouvellement
  /// PATCH /subscriptions/current/auto-renew
  Future<Response<Map<String, dynamic>>> updateAutoRenew({
    required bool autoRenew,
  }) async {
    return await _apiClient.patch('/subscriptions/current/auto-renew', data: {
      'auto_renew': autoRenew,
    });
  }

  /// Annuler l'abonnement
  /// DELETE /subscriptions/current
  Future<Response<Map<String, dynamic>>> cancelSubscription({
    bool cancelImmediately = false,
    String? cancellationReason,
    String? feedback,
  }) async {
    return await _apiClient.delete('/subscriptions/current', data: {
      'cancel_immediately': cancelImmediately,
      'reason': cancellationReason,
      'feedback': feedback,
    });
  }

  /// Utiliser un boost
  /// POST /subscriptions/boost
  Future<Response<Map<String, dynamic>>> useBoost() async {
    return await _apiClient.post('/subscriptions/boost');
  }

  /// Utiliser un super like
  /// POST /subscriptions/super-like
  Future<Response<Map<String, dynamic>>> useSuperLike({
    required String profileId,
  }) async {
    return await _apiClient.post('/subscriptions/super-like', data: {
      'profile_id': profileId,
    });
  }

  /// Statistiques premium
  /// GET /subscriptions/stats
  Future<Response<Map<String, dynamic>>> getStats() async {
    return await _apiClient.get('/subscriptions/stats');
  }

  /// Usage des fonctionnalités
  /// GET /subscriptions/features-usage
  Future<Response<Map<String, dynamic>>> getFeaturesUsage() async {
    return await _apiClient.get('/subscriptions/features-usage');
  }

  /// Historique des paiements
  /// GET /subscriptions/payment-history
  Future<Response<Map<String, dynamic>>> getPaymentHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    return await _apiClient
        .get('/subscriptions/payment-history', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
  }
}

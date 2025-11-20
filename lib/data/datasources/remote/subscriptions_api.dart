// lib/data/datasources/remote/subscriptions_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class SubscriptionsApi {
  final ApiClient _apiClient;

  SubscriptionsApi(this._apiClient);

  /// Récupérer les plans d'abonnement disponibles
  /// GET /api/v1/subscriptions/plans/
  Future<Response<Map<String, dynamic>>> getSubscriptionPlans() async {
    return await _apiClient.get('/api/v1/subscriptions/plans/');
  }

  /// Récupérer l'abonnement actuel
  /// GET /api/v1/subscriptions/current/
  Future<Response<Map<String, dynamic>>> getCurrentSubscription() async {
    return await _apiClient.get('/api/v1/subscriptions/current/');
  }

  /// Acheter un abonnement
  /// POST /api/v1/subscriptions/purchase/
  Future<Response<Map<String, dynamic>>> purchaseSubscription({
    required String planId,
    required String paymentMethodId,
  }) async {
    return await _apiClient.post('/api/v1/subscriptions/purchase/', data: {
      'plan_id': planId,
      'payment_method_id': paymentMethodId,
    });
  }

  /// Annuler l'abonnement actuel
  /// POST /api/v1/subscriptions/current/cancel/
  Future<Response<Map<String, dynamic>>> cancelSubscription() async {
    return await _apiClient.post('/api/v1/subscriptions/current/cancel/');
  }

  /// Réactiver l'abonnement
  /// POST /api/v1/subscriptions/current/reactivate/
  Future<Response<Map<String, dynamic>>> reactivateSubscription() async {
    return await _apiClient.post('/api/v1/subscriptions/current/reactivate/');
  }

  /// Utiliser un boost (fonctionnalité premium)
  /// POST /api/v1/subscriptions/use-boost
  Future<Response<Map<String, dynamic>>> useBoost() async {
    return await _apiClient.post('/api/v1/subscriptions/use-boost');
  }

  /// Utiliser un super like (fonctionnalité premium)
  /// POST /api/v1/subscriptions/use-super-like
  Future<Response<Map<String, dynamic>>> useSuperLike({
    required String targetProfileId,
  }) async {
    return await _apiClient.post('/api/v1/subscriptions/use-super-like', data: {
      'target_profile_id': targetProfileId,
    });
  }

  /// Récupérer les statistiques premium
  /// GET /api/v1/subscriptions/premium-stats
  Future<Response<Map<String, dynamic>>> getPremiumStats() async {
    return await _apiClient.get('/api/v1/subscriptions/premium-stats');
  }

  /// Récupérer l'utilisation des fonctionnalités
  /// GET /api/v1/subscriptions/features-usage
  Future<Response<Map<String, dynamic>>> getFeaturesUsage() async {
    return await _apiClient.get('/api/v1/subscriptions/features-usage');
  }

  /// Récupérer les fonctionnalités disponibles
  /// GET /api/v1/subscriptions/available-features
  Future<Response<Map<String, dynamic>>> getAvailableFeatures() async {
    return await _apiClient.get('/api/v1/subscriptions/available-features');
  }

  /// Modifier l'abonnement actuel
  /// PUT /api/v1/subscriptions/current
  Future<Response<Map<String, dynamic>>> modifySubscription({
    required String newPlanId,
    bool proration = true,
  }) async {
    return await _apiClient.put('/api/v1/subscriptions/current', data: {
      'new_plan_id': newPlanId,
      'proration': proration,
    });
  }

  /// Valider un paiement
  /// GET /api/v1/subscriptions/validate-payment/{session_id}
  Future<Response<Map<String, dynamic>>> validatePayment(
      String sessionId) async {
    return await _apiClient
        .get('/api/v1/subscriptions/validate-payment/$sessionId');
  }
}

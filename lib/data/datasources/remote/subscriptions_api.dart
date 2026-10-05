// lib/data/datasources/remote/subscriptions_api.dart

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

class SubscriptionsApi {
  final ApiClient _apiClient;

  SubscriptionsApi(this._apiClient);

  /// Récupérer les plans d'abonnement disponibles
  /// GET /api/v1/subscriptions/plans/
  /// Returns a List of plan objects (ListAPIView returns an array)
  Future<Response<dynamic>> getSubscriptionPlans() async {
    return await _apiClient.get('/subscriptions/plans/');
  }

  /// Récupérer la disponibilité non sensible du paiement MyCoolPay.
  /// GET /api/v1/subscriptions/payment-capabilities/
  Future<Response<Map<String, dynamic>>> getPaymentCapabilities() async {
    return await _apiClient.get('/subscriptions/payment-capabilities/');
  }

  /// Récupérer l'abonnement actuel
  /// GET /api/v1/subscriptions/current/
  Future<Response<Map<String, dynamic>>> getCurrentSubscription() async {
    return await _apiClient.get('/subscriptions/current/');
  }

  /// Acheter un abonnement
  /// POST /api/v1/subscriptions/purchase/
  Future<Response<Map<String, dynamic>>> purchaseSubscription({
    required String planId,
    required String phoneNumber,
    required String language,
    required String idempotencyKey,
  }) async {
    return await _apiClient.post(
      '/subscriptions/purchase/',
      data: {
        'plan_id': planId,
        'phone_number': phoneNumber,
        'language': language,
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  /// Statut backend d'un paiement. Le frontend ne confirme jamais lui-mÃªme.
  Future<Response<Map<String, dynamic>>> getPaymentStatus(
      String paymentId) async {
    return await _apiClient.get('/subscriptions/payments/$paymentId/');
  }

  /// Annuler l'abonnement actuel
  /// POST /api/v1/subscriptions/current/cancel/
  Future<Response<Map<String, dynamic>>> cancelSubscription() async {
    return await _apiClient.post('/subscriptions/current/cancel/');
  }

  /// Réactiver l'abonnement
  /// POST /api/v1/subscriptions/current/reactivate/
  Future<Response<Map<String, dynamic>>> reactivateSubscription() async {
    return await _apiClient.post('/subscriptions/current/reactivate/');
  }

  /// Utiliser un boost (fonctionnalité premium)
  /// POST /api/v1/subscriptions/use-boost
  Future<Response<Map<String, dynamic>>> useBoost() async {
    return await _apiClient.post('/subscriptions/use-boost');
  }

  /// Utiliser un super like (fonctionnalité premium)
  /// POST /api/v1/subscriptions/use-super-like
  Future<Response<Map<String, dynamic>>> useSuperLike({
    required String targetProfileId,
  }) async {
    return await _apiClient.post('/subscriptions/use-super-like', data: {
      'target_profile_id': targetProfileId,
    });
  }

  /// Récupérer les statistiques premium
  /// GET /api/v1/subscriptions/premium-stats
  Future<Response<Map<String, dynamic>>> getPremiumStats() async {
    return await _apiClient.get('/subscriptions/premium-stats');
  }

  /// Récupérer l'utilisation des fonctionnalités
  /// GET /api/v1/subscriptions/features-usage
  Future<Response<Map<String, dynamic>>> getFeaturesUsage() async {
    return await _apiClient.get('/subscriptions/features-usage');
  }

  /// Récupérer les fonctionnalités disponibles
  /// GET /api/v1/subscriptions/available-features
  Future<Response<Map<String, dynamic>>> getAvailableFeatures() async {
    return await _apiClient.get('/subscriptions/available-features');
  }

  /// Modifier l'abonnement actuel (changement de plan / upgrade / downgrade)
  /// POST /api/v1/subscriptions/current/modify/
  ///
  /// `phoneNumber`/`language` ne sont utiles que si le changement s'avère
  /// nécessiter un vrai paiement (montant net positif) — le backend crée
  /// alors un nouveau Paylink, exactement comme pour un achat. `idempotencyKey`
  /// permet un retry sûr côté serveur sur ce même Paylink.
  Future<Response<Map<String, dynamic>>> modifySubscription({
    required String newPlanId,
    bool proration = true,
    String? phoneNumber,
    String? language,
    String? idempotencyKey,
  }) async {
    return await _apiClient.post(
      '/subscriptions/current/modify/',
      data: {
        'new_plan_id': newPlanId,
        'proration': proration,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (language != null) 'language': language,
      },
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }
}

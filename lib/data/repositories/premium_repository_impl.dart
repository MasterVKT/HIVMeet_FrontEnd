import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/data/services/payment_service.dart' as payment_service;
import 'package:dio/dio.dart';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  final SubscriptionsApi _subscriptionsApi;
  final payment_service.PaymentService _paymentService;

  const PremiumRepositoryImpl(
    this._subscriptionsApi,
    this._paymentService,
  );

  @override
  Future<Either<Failure, List<PremiumPlan>>> getAvailablePlans() async {
    try {
      final response = await _subscriptionsApi.getSubscriptionPlans();
      final payload = response.data!;
      final list = (payload['results'] ??
          payload['plans'] ??
          payload['data'] ??
          []) as List;
      final plans = list
          .map((json) => _mapJsonToPremiumPlan(json as Map<String, dynamic>))
          .toList();
      return Right(plans);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des plans: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSubscription?>> getCurrentSubscription() async {
    try {
      final response = await _subscriptionsApi.getCurrentSubscription();
      final payload = response.data ?? const <String, dynamic>{};

      // Le backend retourne les champs directement à la racine (pas de
      // wrapper `subscription`). L'état « aucun abonnement actif » est
      // signalé par `status: "none"` ou `subscription_id: null`.
      final status = payload['status'] as String?;
      final subscriptionId = payload['subscription_id'] as String?;
      if (status == 'none' || subscriptionId == null) {
        return const Right(null);
      }

      final subscription = _mapJsonToUserSubscription(payload);
      return Right(subscription);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement de l\'abonnement: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentSession>> createPaymentSession(
      String planId) async {
    try {
      final session = await _paymentService.createPaymentSession(
        planId: planId,
        userId: 'current_user_id', // TODO: Récupérer le vrai ID utilisateur
      );
      return Right(session);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors de la création de la session de paiement: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> verifyPayment(String sessionId) async {
    try {
      final result = await _paymentService.verifyPayment(sessionId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors de la validation du paiement: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> purchasePlan(String planId) async {
    // IMPORTANT: Cette méthode NE DOIT PAS simuler de paiement!
    // Le vrai flux est:
    // 1. Frontend appelle createPaymentSession() pour obtenir l'URL
    // 2. Frontend redirige l'utilisateur vers l'URL de paiement
    // 3. Utilisateur paie sur la plateforme de paiement
    // 4. Webhook backend valide le paiement et active l'abonnement
    // 5. Frontend poll getCurrentSubscription() pour vérifier l'activation
    //
    // Cette méthode ne devrait PAS être utilisée directement.
    // Utiliser createPaymentSession() à la place.
    return Left(ServerFailure(
      message:
          'Utiliser createPaymentSession() puis rediriger vers payment_url. '
          'Le paiement est validé via webhook backend, pas par le frontend.',
    ));
  }

  @override
  Future<Either<Failure, void>> updateAutoRenew(bool autoRenew) async {
    try {
      // Non documenté dans backend: exposer via POST current/reactivate|cancel.
      if (autoRenew) {
        await _subscriptionsApi.reactivateSubscription();
      } else {
        await _subscriptionsApi.cancelSubscription();
      }
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors de la modification de l\'abonnement: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentHistory>>> getPaymentHistory() async {
    try {
      // TODO: Implémenter avec les vrais modèles
      return const Right([]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement de l\'historique: $e'));
    }
  }

  @override
  Future<Either<Failure, CancellationResult>> cancelSubscription() async {
    try {
      await _subscriptionsApi.cancelSubscription();
      // CancelSubscriptionResponseSerializer retourne `status`,
      // `cancel_at_period_end`, `current_period_end`, `message` — pas
      // assez de champs pour reconstruire un `UserSubscription` complet.
      // Le frontend doit appeler `getCurrentSubscription()` pour obtenir
      // l'état à jour après l'annulation.
      return const Right(CancellationResult(subscription: null));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de l\'annulation: $e'));
    }
  }

  @override
  Future<Either<Failure, BoostResult>> activateBoost() async {
    try {
      final response = await _subscriptionsApi.useBoost();
      final data = response.data!;

      final result = BoostResult(
        boostId: data['boost']['id'] as String,
        activatedAt: data['boost']['activated_at'] != null
            ? DateTime.parse(data['boost']['activated_at'] as String)
            : null,
        expiresAt: data['boost']['expires_at'] != null
            ? DateTime.parse(data['boost']['expires_at'] as String)
            : null,
        estimatedViews:
            data['boost']['estimated_additional_views'] as int? ?? 0,
        boostsRemaining: data['boosts_remaining'] as int? ?? 0,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors de l\'utilisation du boost: $e'));
    }
  }

  @override
  Future<Either<Failure, BoostResult>> useBoost() async {
    // Alias pour activateBoost - même logique
    return activateBoost();
  }

  @override
  Future<Either<Failure, PaymentResult>> validatePayment(
      String sessionId) async {
    try {
      final response = await _subscriptionsApi.validatePayment(sessionId);
      final data = response.data!;

      final result = PaymentResult(
        status: _parsePaymentStatus(data['payment_status'] as String),
        subscriptionId: data['subscription']['id'] as String,
        activatedAt: data['subscription']['activated_at'] != null
            ? DateTime.parse(data['subscription']['activated_at'] as String)
            : null,
        featuresUnlocked:
            (data['features_unlocked'] as List?)?.cast<String>() ?? [],
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors de la validation du paiement: $e'));
    }
  }

  @override
  Future<Either<Failure, SuperLikeResult>> useSuperLike(
      String profileId) async {
    try {
      final response = await _subscriptionsApi.useSuperLike(
        targetProfileId: profileId,
      );
      final data = response.data!;

      final result = SuperLikeResult(
        success: data['success'] as bool,
        superLikesRemaining: data['super_likes_remaining'] as int,
        isMatch: data['is_match'] as bool? ?? false,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du super like: $e'));
    }
  }

  @override
  Future<Either<Failure, PremiumStats>> getPremiumStats() async {
    try {
      final response = await _subscriptionsApi.getPremiumStats();
      final data = response.data!;

      final stats = PremiumStats(
        usageStats: UsageStats(
          likesSentThisPeriod:
              data['usage_stats']['likes_sent_this_period'] as int? ?? 0,
          superLikesUsed: data['usage_stats']['super_likes_used'] as int? ?? 0,
          boostsUsed: data['usage_stats']['boosts_used'] as int? ?? 0,
          profileViewsGained:
              data['usage_stats']['profile_views_gained'] as int? ?? 0,
          matchesFromPremium:
              data['usage_stats']['matches_from_premium'] as int? ?? 0,
        ),
        featureUsage: FeatureUsage(
          whoLikedYouViews:
              data['feature_usage']['who_liked_you_views'] as int? ?? 0,
          mediaMessagesSent:
              data['feature_usage']['media_messages_sent'] as int? ?? 0,
          videoCallsMade:
              data['feature_usage']['video_calls_made'] as int? ?? 0,
          rewindsUsed: data['feature_usage']['rewinds_used'] as int? ?? 0,
        ),
        periodStart: data['period']['start'] != null
            ? DateTime.parse(data['period']['start'] as String)
            : null,
        periodEnd: data['period']['end'] != null
            ? DateTime.parse(data['period']['end'] as String)
            : null,
      );
      return Right(stats);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement des statistiques: $e'));
    }
  }

  @override
  Future<Either<Failure, FeaturesUsage>> getFeaturesUsage() async {
    try {
      final response = await _subscriptionsApi.getFeaturesUsage();
      final data = response.data!;

      final usage = FeaturesUsage(
        boostsRemaining: data['boosts_remaining'] as int? ?? 0,
        superLikesRemaining: data['super_likes_remaining'] as int? ?? 0,
        lastBoostReset: data['last_boost_reset'] != null
            ? DateTime.parse(data['last_boost_reset'] as String)
            : null,
        lastSuperLikesReset: data['last_super_likes_reset'] != null
            ? DateTime.parse(data['last_super_likes_reset'] as String)
            : null,
      );
      return Right(usage);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement de l\'usage: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PremiumFeature>>> getAvailableFeatures() async {
    try {
      const features = <PremiumFeature>[
        PremiumFeature(
          id: 'unlimited_likes',
          name: 'Likes illimités',
          description: 'Likez autant que vous voulez',
          iconName: 'heart',
        ),
      ];
      return const Right(features);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement des fonctionnalités: $e'));
    }
  }

  /// Extrait un message d'erreur lisible depuis une réponse d'erreur Dio.
  /// Gère deux formats backend :
  /// 1. Format custom : {"error": "code", "message": "message lisible"}
  /// 2. Format DRF field-level : {"new_plan_id": ["Ce champ est obligatoire."]}
  String _extractServerErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Format d'erreur standard du backend : {"error": "...", "message": "..."}
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
      final error = data['error'] as String?;
      if (error != null) {
        return error;
      }
      // Format DRF field-level : {"field": ["error1", "error2"], ...}
      final fieldErrors = data.entries
          .where((entry) => entry.value is List)
          .map((entry) => (entry.value as List).cast<String>().join(", "))
          .join('; ');
      if (fieldErrors.isNotEmpty) {
        return fieldErrors;
      }
    }
    return e.message ?? 'Erreur de serveur';
  }

  @override
  Future<Either<Failure, UserSubscription>> modifySubscription({
    required String newPlanId,
    bool proration = true,
  }) async {
    try {
      final response = await _subscriptionsApi.modifySubscription(
        newPlanId: newPlanId,
        proration: proration,
      );
      final data = response.data ?? const <String, dynamic>{};

      // Le backend retourne les champs à plat (CurrentSubscriptionSerializer),
      // identique à GET /current/. Pas de wrapper `subscription`.
      final result = _mapJsonToUserSubscription(data);
      return Right(result);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractServerErrorMessage(e);

      // 402 → un paiement est requis (proration avec nouveau débit)
      if (statusCode == 402) {
        return Left(ServerFailure(
          message: message,
          code: 'payment_required',
        ));
      }

      // 400 → erreur de validation métier (same_plan, no_active_subscription,
      // invalid_plan ou erreur DRF field-level)
      if (statusCode == 400) {
        return Left(ServerFailure(message: message));
      }

      return Left(ServerFailure(message: message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la modification: $e'));
    }
  }

  // Helper methods pour mapper les données JSON
  PremiumPlan _mapJsonToPremiumPlan(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>;

    return PremiumPlan(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      billingInterval:
          _parseBillingInterval(json['billing_interval'] as String),
      trialPeriodDays: json['trial_period_days'] as int? ?? 0,
      features: PremiumFeatures(
        unlimitedLikes: features['unlimited_likes'] as bool? ?? false,
        canSeeWhoLiked: features['can_see_likers'] as bool? ?? false,
        canRewind: features['can_rewind'] as bool? ?? false,
        monthlyBoosts: features['monthly_boosts_count'] as int? ?? 0,
        dailySuperLikes: features['daily_super_likes_count'] as int? ?? 0,
        mediaMessaging: features['media_messaging_enabled'] as bool? ?? false,
        videoCalls: features['audio_video_calls_enabled'] as bool? ?? false,
        prioritySupport: features['priority_support'] as bool? ?? false,
        advancedFilters: features['advanced_filters'] as bool? ?? false,
        incognitoMode: features['incognito_mode'] as bool? ?? false,
      ),
      savings: json['savings_percentage'] as int? ?? 0,
      isPopular: json['most_popular'] as bool? ?? false,
      isRecommended: json['recommended'] as bool? ?? false,
    );
  }

  UserSubscription _mapJsonToUserSubscription(Map<String, dynamic> json) {
    // CurrentSubscriptionSerializer retourne les champs à plat :
    // subscription_id, plan_id, plan_name, status, current_period_start/end,
    // auto_renew, cancel_at_period_end, features_summary.
    // Il n'y a pas de Map imbriquée `plan` ni de `features_usage` (les
    // compteurs runtime s'obtiennent via getFeaturesUsage()).
    final featuresSummary = json['features_summary'] as Map<String, dynamic>?;

    final plan = PremiumPlan(
      id: json['plan_id'] as String? ?? '',
      planId: json['plan_id'] as String? ?? '',
      name: json['plan_name'] as String? ?? '',
      description: '',
      price: 0,
      currency: 'EUR',
      billingInterval: BillingInterval.monthly,
      trialPeriodDays: 0,
      features: featuresSummary != null
          ? PremiumFeatures(
              unlimitedLikes:
                  featuresSummary['unlimited_likes'] as bool? ?? false,
              canSeeWhoLiked:
                  featuresSummary['can_see_likers'] as bool? ?? false,
              canRewind: featuresSummary['can_rewind'] as bool? ?? false,
              monthlyBoosts:
                  featuresSummary['monthly_boosts_count'] as int? ?? 0,
              dailySuperLikes:
                  featuresSummary['daily_super_likes_count'] as int? ?? 0,
              mediaMessaging:
                  featuresSummary['media_messaging_enabled'] as bool? ?? false,
              videoCalls:
                  featuresSummary['audio_video_calls_enabled'] as bool? ??
                      false,
            )
          : const PremiumFeatures(),
    );

    return UserSubscription(
      id: json['subscription_id'] as String? ?? '',
      plan: plan,
      status: _parseSubscriptionStatus(json['status'] as String? ?? 'active'),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : DateTime.now(),
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : DateTime.now(),
      trialEnd: null,
      autoRenew: json['auto_renew'] as bool? ?? true,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      nextBillingDate: null,
      featuresUsage: null,
    );
  }

  BillingInterval _parseBillingInterval(String interval) {
    switch (interval) {
      case 'month':
        return BillingInterval.monthly;
      case 'year':
        return BillingInterval.yearly;
      case 'week':
        return BillingInterval.weekly;
      default:
        return BillingInterval.monthly;
    }
  }

  SubscriptionStatus _parseSubscriptionStatus(String status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      // Le backend utilise "trialing" (un L) — pas "trial"
      case 'trialing':
      case 'trial':
        return SubscriptionStatus.trial;
      case 'expired':
        return SubscriptionStatus.expired;
      // Le backend utilise l'orthographe américaine "canceled" (un L)
      case 'canceled':
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'pending':
        return SubscriptionStatus.pending;
      // Le backend peut retourner "past_due" — traiter comme en attente
      case 'past_due':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.expired;
    }
  }

  PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
        return PaymentStatus.pending;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }
}

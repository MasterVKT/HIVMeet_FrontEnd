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
      final payload = response.data!;
      final sub = payload['subscription'] as Map<String, dynamic>?;
      if (sub == null) return const Right(null);
      final subscription = _mapJsonToUserSubscription(sub);
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
      message: 'Utiliser createPaymentSession() puis rediriger vers payment_url. '
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
      final response = await _subscriptionsApi.cancelSubscription();
      final payload = response.data;
      UserSubscription? sub;
      if (payload != null && payload['subscription'] is Map<String, dynamic>) {
        sub = _mapJsonToUserSubscription(
            payload['subscription'] as Map<String, dynamic>);
      }
      return Right(CancellationResult(subscription: sub));
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
      final data = response.data!;
      final subscriptionData = data['subscription'] as Map<String, dynamic>;

      final result = _mapJsonToUserSubscription(subscriptionData);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
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
    final planData = json['plan'] as Map<String, dynamic>;
    final featuresUsage = json['features_usage'] as Map<String, dynamic>?;

    return UserSubscription(
      id: json['id'] as String,
      plan: _mapJsonToPremiumPlan(planData),
      status: _parseSubscriptionStatus(json['status'] as String),
      currentPeriodStart:
          DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'] as String)
          : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.parse(json['next_billing_date'] as String)
          : null,
      featuresUsage: featuresUsage != null
          ? FeaturesUsage(
              boostsRemaining: featuresUsage['boosts_remaining'] as int? ?? 0,
              superLikesRemaining:
                  featuresUsage['super_likes_remaining'] as int? ?? 0,
              lastBoostReset: featuresUsage['last_boosts_reset'] != null
                  ? DateTime.parse(featuresUsage['last_boosts_reset'] as String)
                  : null,
              lastSuperLikesReset:
                  featuresUsage['last_super_likes_reset'] != null
                      ? DateTime.parse(
                          featuresUsage['last_super_likes_reset'] as String)
                      : null,
            )
          : null,
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
      case 'trial':
        return SubscriptionStatus.trial;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'pending':
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

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/data/services/payment_service.dart' as payment_service;
import 'package:hivmeet/core/services/token_service.dart';
import 'package:dio/dio.dart';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  final SubscriptionsApi _subscriptionsApi;
  final payment_service.PaymentService _paymentService;
  final TokenService _tokenService;

  const PremiumRepositoryImpl(
    this._subscriptionsApi,
    this._paymentService,
    this._tokenService,
  );

  @override
  Future<Either<Failure, List<PremiumPlan>>> getAvailablePlans() async {
    try {
      // TODO: Implémenter avec les vrais modèles
      return const Right([]);
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des plans: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSubscription?>> getCurrentSubscription() async {
    try {
      // TODO: Implémenter avec les vrais modèles
        return const Right(null);
    } on DioError catch (e) {
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
    } on DioError catch (e) {
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
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors de la validation du paiement: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> purchasePlan(String planId) async {
    try {
      final sessionResult = await createPaymentSession(planId);
      return sessionResult.fold(
        (failure) => Left(failure),
        (session) async {
          // Dans une vraie app, on redirigerait vers l'URL de paiement
          // et attendrait le callback de validation
          // Pour la démo, on simule un paiement réussi
          return const Right(PaymentResult(
            status: PaymentStatus.succeeded,
            subscriptionId: 'sub_demo',
            activatedAt: null,
            featuresUnlocked: ['unlimited_likes', 'see_who_liked'],
          ));
        },
      );
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors de l\'achat du plan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAutoRenew(bool autoRenew) async {
    try {
      // TODO: Implémenter avec la vraie API
      return const Right(null);
    } on DioError catch (e) {
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
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement de l\'historique: $e'));
    }
  }

  @override
  Future<Either<Failure, CancellationResult>> cancelSubscription() async {
    try {
      // TODO: Implémenter avec les vrais modèles
      final result = CancellationResult(
        subscription: UserSubscription(
          id: 'sub_id',
          plan: PremiumPlan(
            id: 'plan_id',
            planId: 'plan_external_id',
            name: 'Premium',
            description: 'Plan premium',
            price: 9.99,
            currency: 'EUR',
            billingInterval: BillingInterval.monthly,
            features: PremiumFeatures(),
          ),
          status: SubscriptionStatus.cancelled,
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now().add(Duration(days: 30)),
        ),
      );
      return Right(result);
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de l\'annulation: $e'));
    }
  }

  @override
  Future<Either<Failure, BoostResult>> activateBoost() async {
    try {
      const result = BoostResult(
        boostId: 'boost_id',
        activatedAt: null,
        expiresAt: null,
        estimatedViews: 100,
        boostsRemaining: 2,
      );
      return const Right(result);
    } on DioError catch (e) {
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
      final result = PaymentResult(
        status: PaymentStatus.succeeded,
        subscriptionId: 'sub_id',
        activatedAt: DateTime.now(),
        featuresUnlocked: ['unlimited_likes', 'super_likes'],
      );
      return Right(result);
    } on DioError catch (e) {
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
      const result = SuperLikeResult(
        success: true,
        superLikesRemaining: 5,
        isMatch: false,
      );
      return const Right(result);
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du super like: $e'));
    }
  }

  @override
  Future<Either<Failure, PremiumStats>> getPremiumStats() async {
    try {
      const stats = PremiumStats(
        usageStats: UsageStats(),
        featureUsage: FeatureUsage(),
        periodStart: null,
        periodEnd: null,
      );
      return const Right(stats);
    } on DioError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Erreur de serveur'));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement des statistiques: $e'));
    }
  }

  @override
  Future<Either<Failure, FeaturesUsage>> getFeaturesUsage() async {
    try {
      const usage = FeaturesUsage(
        boostsRemaining: 3,
        superLikesRemaining: 5,
      );
      return const Right(usage);
    } on DioError catch (e) {
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
    } on DioError catch (e) {
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
      // TODO: Implémenter avec la vraie API
      final result = UserSubscription(
        id: 'sub_modified',
        plan: PremiumPlan(
          id: newPlanId,
          planId: newPlanId,
          name: 'Premium Modified',
          description: 'Plan modifié',
          price: 9.99,
          currency: 'EUR',
          billingInterval: BillingInterval.monthly,
          features: PremiumFeatures(),
        ),
        status: SubscriptionStatus.active,
        currentPeriodStart: DateTime.now(),
        currentPeriodEnd: DateTime.now().add(Duration(days: 30)),
      );
      return Right(result);
    } on DioError catch (e) {
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

  RetentionOffer _mapJsonToRetentionOffer(Map<String, dynamic> json) {
    return RetentionOffer(
      discountPercentage: json['discount_percentage'] as int,
      offerExpiresAt: DateTime.parse(json['offer_expires_at'] as String),
      specialMessage: json['special_message'] as String?,
    );
  }

  UsageStats _mapJsonToUsageStats(Map<String, dynamic> json) {
    return UsageStats(
      likesSentThisPeriod: json['likes_sent_this_period'] as int? ?? 0,
      superLikesUsed: json['super_likes_used'] as int? ?? 0,
      boostsUsed: json['boosts_used'] as int? ?? 0,
      profileViewsGained: json['profile_views_gained'] as int? ?? 0,
      matchesFromPremium: json['matches_from_premium'] as int? ?? 0,
    );
  }

  FeatureUsage _mapJsonToFeatureUsage(Map<String, dynamic> json) {
    return FeatureUsage(
      whoLikedYouViews: json['who_liked_you_views'] as int? ?? 0,
      mediaMessagesSent: json['media_messages_sent'] as int? ?? 0,
      videoCallsMade: json['video_calls_made'] as int? ?? 0,
      rewindsUsed: json['rewinds_used'] as int? ?? 0,
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

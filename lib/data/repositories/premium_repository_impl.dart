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
      final data = response.data;

      // L'endpoint ListAPIView retourne directement une liste JSON (array),
      // mais DRF pagination peut aussi retourner {results: [...]}.
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = (data['results'] ?? data['plans'] ?? data['data'] ?? []) as List;
      } else {
        list = [];
      }

      final plans = list
          .map((json) => _mapJsonToPremiumPlan(json as Map<String, dynamic>))
          .where((plan) => const {
                'hivmeet_monthly',
                'hivmeet_annual',
              }.contains(plan.planId))
          .toList()
        ..sort((a, b) => _planOrder(a).compareTo(_planOrder(b)));
      return Right(plans);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _extractServerErrorMessage(e)));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des plans: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentCapabilities>> getPaymentCapabilities() async {
    try {
      final response = await _subscriptionsApi.getPaymentCapabilities();
      final data = response.data ?? const <String, dynamic>{};
      return Right(PaymentCapabilities(
        provider: data['provider']?.toString() ?? 'mycoolpay',
        available: data['available'] as bool? ?? false,
        callbackVerificationAvailable:
            data['callback_verification_available'] as bool? ?? false,
        automaticReturnAvailable:
            data['automatic_return_available'] as bool? ?? false,
        confirmationMode:
            data['confirmation_mode']?.toString() ?? 'polling_only',
        enabledCurrencies:
            (data['enabled_currencies'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value.toString())
                .toList(growable: false),
        defaultCurrency: data['default_currency']?.toString() ?? 'EUR',
        effectiveCurrency: data['effective_currency']?.toString() ?? 'EUR',
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: _extractServerErrorMessage(e),
        code: e.response?.data is Map
            ? (e.response?.data as Map)['error']?.toString()
            : null,
      ));
    } catch (e) {
      return const Left(ServerFailure(
        message: 'Payment capabilities are temporarily unavailable',
        code: 'payment_capabilities_unavailable',
      ));
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
      return Left(ServerFailure(message: _extractServerErrorMessage(e)));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement de l\'abonnement: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentSession>> createPaymentSession({
    required String planId,
    required String phoneNumber,
    required String language,
    String? returnTo,
  }) async {
    try {
      final session = await _paymentService.createPaymentSession(
        planId: planId,
        phoneNumber: phoneNumber,
        language: language,
        returnTo: returnTo,
      );
      return Right(session);
    } on payment_service.PaymentException catch (e) {
      return Left(PaymentFailure(
        message: 'The payment could not be started',
        code: e.code ?? 'payment_start_failed',
      ));
    } on DioException catch (e) {
      return Left(PaymentFailure(
        message: 'The payment could not be started',
        code: _paymentErrorCode(e, fallback: 'payment_start_failed'),
      ));
    } catch (_) {
      return const Left(PaymentFailure(
        message: 'The payment could not be started',
        code: 'payment_start_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> verifyPayment(String sessionId) async {
    try {
      final result = await _paymentService.verifyPayment(sessionId);
      return Right(result);
    } on DioException catch (e) {
      return Left(PaymentFailure(
        message: 'The payment status could not be checked',
        code: _paymentErrorCode(e, fallback: 'payment_verification_failed'),
      ));
    } catch (_) {
      return const Left(PaymentFailure(
        message: 'The payment status could not be checked',
        code: 'payment_verification_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, PendingPaymentAttempt?>> getPendingPayment() async {
    try {
      return Right(await _paymentService.getPendingPayment());
    } catch (_) {
      return const Left(CacheFailure(
        message: 'The pending payment could not be restored',
        code: 'payment_restore_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> clearPendingPayment() async {
    try {
      await _paymentService.clearPendingPayment();
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure(
        message: 'The pending payment could not be cleared',
        code: 'payment_clear_failed',
      ));
    }
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
    return verifyPayment(sessionId);
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

  String _paymentErrorCode(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return 'payment_network_error';
      case DioExceptionType.badCertificate:
        return 'payment_security_error';
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return fallback;
    }
  }

  @override
  Future<Either<Failure, ModifySubscriptionOutcome>> modifySubscription({
    required String newPlanId,
    bool proration = true,
    String? phoneNumber,
    String language = 'fr',
  }) async {
    try {
      // Une clé d'idempotence permet un retry sûr côté serveur si la réponse
      // se perd après création d'un Paylink (voir `purchaseSubscription` /
      // `PaymentService.createPaymentSession`, même principe).
      final idempotencyKey = _paymentService.newIdempotencyKey();
      final response = await _subscriptionsApi.modifySubscription(
        newPlanId: newPlanId,
        proration: proration,
        phoneNumber: phoneNumber,
        language: language,
        idempotencyKey: idempotencyKey,
      );
      final data = response.data ?? const <String, dynamic>{};

      final paymentId = data['payment_id']?.toString();
      if (paymentId != null && paymentId.isNotEmpty) {
        // MyCoolPay n'a pas d'API de modification d'abonnement : un montant
        // net positif nécessite un nouveau Paylink, exactement comme un
        // achat. Le plan ne bascule qu'à la confirmation du webhook.
        final rawPaymentUrl = data['payment_url']?.toString();
        String? paymentUrl;
        if (rawPaymentUrl != null && rawPaymentUrl.isNotEmpty) {
          try {
            paymentUrl = _paymentService.validatePaymentUrl(rawPaymentUrl);
          } on payment_service.PaymentException {
            return const Left(ServerFailure(
              message: 'Invalid payment URL',
              code: 'invalid_payment_url',
            ));
          }
        }
        final paymentStatus =
            _paymentService.parsePaymentStatus(data['payment_status']?.toString());

        await _paymentService.recordExternalPendingPayment(
          paymentId: paymentId,
          planId: newPlanId,
          idempotencyKey: idempotencyKey,
          paymentUrl: paymentUrl,
          returnTo: null,
        );

        return Right(ModifySubscriptionOutcome.paymentRequired(PaymentSession(
          sessionId: paymentId,
          paymentUrl: paymentUrl,
          planId: newPlanId,
          idempotencyKey: idempotencyKey,
          status: paymentStatus,
        )));
      }

      // Le backend retourne les champs à plat (CurrentSubscriptionSerializer),
      // identique à GET /current/. Pas de wrapper `subscription`.
      final result = _mapJsonToUserSubscription(data);
      return Right(ModifySubscriptionOutcome.applied(result));
    } on DioException catch (e) {
      // Propage le code d'erreur backend quel que soit le statut HTTP :
      // 400 → validation métier (same_plan, no_active_subscription,
      // phone_number_required, invalid_plan, erreur DRF field-level) ;
      // 502/503 → Paylink/provider indisponible (mêmes codes que l'achat).
      return Left(ServerFailure(
        message: _extractServerErrorMessage(e),
        code: e.response?.data is Map
            ? (e.response?.data as Map)['error']?.toString()
            : null,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la modification: $e'));
    }
  }

  // Helper methods pour mapper les données JSON
  PremiumPlan _mapJsonToPremiumPlan(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final featureMap = rawFeatures is Map<String, dynamic>
        ? rawFeatures
        : const <String, dynamic>{};
    final featureKeys = rawFeatures is List
        ? rawFeatures.map((value) => value.toString()).toSet()
        : const <String>{};
    bool enabled(String key) =>
        featureMap[key] as bool? ?? featureKeys.contains(key);
    int count(String key, String listKey, int fallback) =>
        featureMap[key] as int? ??
        (featureKeys.contains(listKey) ? fallback : 0);
    final planId = json['plan_id'] as String;
    final rawPrice = json['price'];
    final price = _toDouble(rawPrice);

    return PremiumPlan(
      id: json['id']?.toString() ?? planId,
      planId: planId,
      name: json['name'] as String,
      description: json['description'] as String,
      price: price,
      currency: json['currency']?.toString() ?? 'EUR',
      basePrice: _toDouble(json['base_price'], fallback: price),
      baseCurrency: json['base_currency']?.toString() ?? 'EUR',
      monthlyEquivalent: _toDouble(json['monthly_equivalent'], fallback: price),
      billingInterval:
          _parseBillingInterval(json['billing_interval'] as String),
      trialPeriodDays: json['trial_period_days'] as int? ?? 0,
      features: PremiumFeatures(
        unlimitedLikes: enabled('unlimited_likes'),
        canSeeWhoLiked: enabled('can_see_likers'),
        canRewind: enabled('can_rewind'),
        monthlyBoosts: count('monthly_boosts_count', 'monthly_boosts', 1),
        dailySuperLikes:
            count('daily_super_likes_count', 'daily_super_likes', 5),
        dailyRewinds: count('daily_rewinds_count', 'daily_rewinds', 5),
        mediaMessaging: enabled('media_messaging_enabled') ||
            featureKeys.contains('media_messaging'),
        videoCalls: enabled('audio_video_calls_enabled') ||
            featureKeys.contains('audio_video_calls'),
        prioritySupport: enabled('priority_support'),
        advancedFilters: enabled('advanced_filters'),
        incognitoMode: enabled('incognito_mode'),
      ),
      savings: _toInt(json['savings_percentage']),
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
              dailyRewinds: featuresSummary['daily_rewinds_count'] as int? ?? 0,
              mediaMessaging:
                  featuresSummary['media_messaging_enabled'] as bool? ?? false,
              videoCalls:
                  featuresSummary['audio_video_calls_enabled'] as bool? ??
                      false,
            )
          : const PremiumFeatures(),
    );

    final scheduledChangeJson = json['scheduled_change'];
    final scheduledChange = scheduledChangeJson is Map
        ? ScheduledPlanChange(
            planId: scheduledChangeJson['plan_id']?.toString() ?? '',
            planName: scheduledChangeJson['plan_name']?.toString() ?? '',
            effectiveAt: DateTime.tryParse(
              scheduledChangeJson['effective_at']?.toString() ?? '',
            ),
          )
        : null;

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
      scheduledChange: scheduledChange,
    );
  }

  BillingInterval _parseBillingInterval(String interval) {
    switch (interval) {
      case 'month':
      case 'monthly':
        return BillingInterval.monthly;
      case 'year':
      case 'yearly':
        return BillingInterval.yearly;
      case 'week':
      case 'weekly':
        return BillingInterval.weekly;
      default:
        return BillingInterval.monthly;
    }
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _planOrder(PremiumPlan plan) {
    switch (plan.billingInterval) {
      case BillingInterval.monthly:
        return 0;
      case BillingInterval.yearly:
        return 1;
      case BillingInterval.weekly:
        return 2;
    }
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
}

// lib/domain/entities/premium.dart

import 'package:equatable/equatable.dart';

// Plan d'abonnement premium
class PremiumPlan extends Equatable {
  final String id;
  final String planId; // Identifiant unique pour MyCoolPay
  final String name;
  final String description;
  final double price;
  final String currency;
  final double basePrice;
  final String baseCurrency;
  final double monthlyEquivalent;
  final BillingInterval billingInterval;
  final int trialPeriodDays;
  final PremiumFeatures features;
  final int savings; // Pourcentage d'économie par rapport au mensuel
  final bool isPopular;
  final bool isRecommended;

  const PremiumPlan({
    required this.id,
    required this.planId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    double? basePrice,
    String? baseCurrency,
    double? monthlyEquivalent,
    required this.billingInterval,
    this.trialPeriodDays = 0,
    required this.features,
    this.savings = 0,
    this.isPopular = false,
    this.isRecommended = false,
  })  : basePrice = basePrice ?? price,
        baseCurrency = baseCurrency ?? currency,
        monthlyEquivalent = monthlyEquivalent ?? price;

  @override
  List<Object?> get props => [
        id,
        planId,
        name,
        description,
        price,
        currency,
        basePrice,
        baseCurrency,
        monthlyEquivalent,
        billingInterval,
        trialPeriodDays,
        features,
        savings,
        isPopular,
        isRecommended,
      ];
}

// Fonctionnalités incluses dans un plan premium
class PremiumFeatures extends Equatable {
  final bool unlimitedLikes;
  final bool canSeeWhoLiked;
  final bool canRewind;
  final int monthlyBoosts;
  final int dailySuperLikes;
  final int dailyRewinds;
  final bool mediaMessaging;
  final bool videoCalls;
  final bool prioritySupport;
  final bool advancedFilters;
  final bool incognitoMode;

  const PremiumFeatures({
    this.unlimitedLikes = false,
    this.canSeeWhoLiked = false,
    this.canRewind = false,
    this.monthlyBoosts = 0,
    this.dailySuperLikes = 0,
    this.dailyRewinds = 0,
    this.mediaMessaging = false,
    this.videoCalls = false,
    this.prioritySupport = false,
    this.advancedFilters = false,
    this.incognitoMode = false,
  });

  @override
  List<Object> get props => [
        unlimitedLikes,
        canSeeWhoLiked,
        canRewind,
        monthlyBoosts,
        dailySuperLikes,
        dailyRewinds,
        mediaMessaging,
        videoCalls,
        prioritySupport,
        advancedFilters,
        incognitoMode,
      ];
}

/// Capacités publiques de paiement exposées par le backend.
///
/// Aucun secret fournisseur n'est transporté dans ce contrat.
class PaymentCapabilities extends Equatable {
  final String provider;
  final bool available;
  final bool callbackVerificationAvailable;
  final bool automaticReturnAvailable;
  final String confirmationMode;
  final List<String> enabledCurrencies;
  final String defaultCurrency;
  final String effectiveCurrency;

  const PaymentCapabilities({
    required this.provider,
    required this.available,
    required this.callbackVerificationAvailable,
    this.automaticReturnAvailable = false,
    this.confirmationMode = 'polling_only',
    required this.enabledCurrencies,
    required this.defaultCurrency,
    required this.effectiveCurrency,
  });

  const PaymentCapabilities.unavailable({this.effectiveCurrency = 'EUR'})
      : provider = 'mycoolpay',
        available = false,
        callbackVerificationAvailable = false,
        automaticReturnAvailable = false,
        confirmationMode = 'polling_only',
        enabledCurrencies = const [],
        defaultCurrency = 'EUR';

  @override
  List<Object> get props => [
        provider,
        available,
        callbackVerificationAvailable,
        automaticReturnAvailable,
        confirmationMode,
        enabledCurrencies,
        defaultCurrency,
        effectiveCurrency,
      ];
}

class ScheduledPlanChange extends Equatable {
  final String planId;
  final String planName;
  final DateTime? effectiveAt;

  const ScheduledPlanChange({
    required this.planId,
    required this.planName,
    required this.effectiveAt,
  });

  @override
  List<Object?> get props => [planId, planName, effectiveAt];
}

// Abonnement utilisateur
class UserSubscription extends Equatable {
  final String id;
  final PremiumPlan plan;
  final SubscriptionStatus status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialEnd;
  final bool autoRenew;
  final bool cancelAtPeriodEnd;
  final DateTime? nextBillingDate;
  final FeaturesUsage? featuresUsage;
  final ScheduledPlanChange? scheduledChange;

  const UserSubscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialEnd,
    this.autoRenew = true,
    this.cancelAtPeriodEnd = false,
    this.nextBillingDate,
    this.featuresUsage,
    this.scheduledChange,
  });

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
  bool get isInTrial => trialEnd != null && DateTime.now().isBefore(trialEnd!);

  @override
  List<Object?> get props => [
        id,
        plan,
        status,
        currentPeriodStart,
        currentPeriodEnd,
        trialEnd,
        autoRenew,
        cancelAtPeriodEnd,
        nextBillingDate,
        featuresUsage,
        scheduledChange,
      ];
}

// Usage des fonctionnalités premium
class FeaturesUsage extends Equatable {
  final int boostsRemaining;
  final int superLikesRemaining;
  final DateTime? lastBoostReset;
  final DateTime? lastSuperLikesReset;

  const FeaturesUsage({
    this.boostsRemaining = 0,
    this.superLikesRemaining = 0,
    this.lastBoostReset,
    this.lastSuperLikesReset,
  });

  @override
  List<Object?> get props => [
        boostsRemaining,
        superLikesRemaining,
        lastBoostReset,
        lastSuperLikesReset,
      ];
}

// Session de paiement MyCoolPay
class PaymentSession extends Equatable {
  final String sessionId;
  final String? paymentUrl;
  final String planId;
  final String idempotencyKey;
  final PaymentStatus status;
  final DateTime? expiresAt;
  final String? returnTo;

  const PaymentSession({
    required this.sessionId,
    required this.paymentUrl,
    this.planId = '',
    this.idempotencyKey = '',
    this.status = PaymentStatus.pending,
    this.expiresAt,
    this.returnTo,
  });

  bool get canOpenPaymentPage =>
      paymentUrl != null && paymentUrl!.trim().isNotEmpty;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        sessionId,
        paymentUrl,
        planId,
        idempotencyKey,
        status,
        expiresAt,
        returnTo,
      ];
}

/// Result of [PremiumRepository.modifySubscription].
///
/// MyCoolPay is Paylink-only and has no subscription-modification API: an
/// immediate plan change either costs nothing extra (the outgoing plan's
/// unused credit covers the new plan in full) and is [applied] right away,
/// or requires a real charge, in which case a fresh [PaymentSession] is
/// created and the plan itself only switches once the webhook confirms that
/// payment — exactly like [PremiumRepository.createPaymentSession].
class ModifySubscriptionOutcome extends Equatable {
  final UserSubscription? subscription;
  final PaymentSession? paymentSession;

  const ModifySubscriptionOutcome.applied(this.subscription)
      : paymentSession = null;

  const ModifySubscriptionOutcome.paymentRequired(this.paymentSession)
      : subscription = null;

  bool get requiresPayment => paymentSession != null;

  @override
  List<Object?> get props => [subscription, paymentSession];
}

/// Minimal encrypted local record used to resume a hosted checkout.
///
/// It deliberately excludes the phone number and all provider credentials.
class PendingPaymentAttempt extends Equatable {
  final String? paymentId;
  final String planId;
  final String idempotencyKey;
  final String? paymentUrl;
  final DateTime createdAt;
  final String? returnTo;

  const PendingPaymentAttempt({
    required this.paymentId,
    required this.planId,
    required this.idempotencyKey,
    required this.paymentUrl,
    required this.createdAt,
    this.returnTo,
  });

  bool get hasPaymentId => paymentId != null && paymentId!.isNotEmpty;
  bool get canOpenPaymentPage =>
      paymentUrl != null && paymentUrl!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        paymentId,
        planId,
        idempotencyKey,
        paymentUrl,
        createdAt,
        returnTo,
      ];
}

// Résultat d'un paiement
class PaymentResult extends Equatable {
  final PaymentStatus status;
  final bool fulfilled;
  final String? subscriptionId;
  final DateTime? activatedAt;
  final List<String> featuresUnlocked;

  const PaymentResult({
    required this.status,
    this.fulfilled = false,
    this.subscriptionId,
    this.activatedAt,
    this.featuresUnlocked = const [],
  });

  bool get isSuccessful => status == PaymentStatus.succeeded && fulfilled;
  bool get success => isSuccessful;
  String? get errorMessage {
    switch (status) {
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled';
      case PaymentStatus.pending:
        return 'Payment is still pending';
      case PaymentStatus.succeeded:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        status,
        fulfilled,
        subscriptionId,
        activatedAt,
        featuresUnlocked,
      ];
}

// Résultat d'annulation
class CancellationResult extends Equatable {
  final UserSubscription? subscription;
  final DateTime? accessUntil;
  final RetentionOffer? retentionOffer;

  const CancellationResult({
    this.subscription,
    this.accessUntil,
    this.retentionOffer,
  });

  @override
  List<Object?> get props => [subscription, accessUntil, retentionOffer];
}

// Offre de rétention
class RetentionOffer extends Equatable {
  final int discountPercentage;
  final DateTime offerExpiresAt;
  final String? specialMessage;

  const RetentionOffer({
    required this.discountPercentage,
    required this.offerExpiresAt,
    this.specialMessage,
  });

  bool get isExpired => DateTime.now().isAfter(offerExpiresAt);

  @override
  List<Object?> get props =>
      [discountPercentage, offerExpiresAt, specialMessage];
}

// Résultat d'utilisation de boost
class BoostResult extends Equatable {
  final String boostId;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final int estimatedViews;
  final int boostsRemaining;
  final DateTime? nextResetAt;

  const BoostResult({
    required this.boostId,
    this.activatedAt,
    this.expiresAt,
    required this.estimatedViews,
    required this.boostsRemaining,
    this.nextResetAt,
  });

  bool get isActive => expiresAt != null && DateTime.now().isBefore(expiresAt!);
  Duration? get remainingTime => expiresAt?.difference(DateTime.now());

  @override
  List<Object?> get props => [
        boostId,
        activatedAt,
        expiresAt,
        estimatedViews,
        boostsRemaining,
        nextResetAt,
      ];
}

// Résultat d'utilisation de super like
class SuperLikeResult extends Equatable {
  final bool success;
  final int superLikesRemaining;
  final DateTime? nextResetAt;
  final bool isMatch;
  final String? matchId;

  const SuperLikeResult({
    required this.success,
    required this.superLikesRemaining,
    this.nextResetAt,
    this.isMatch = false,
    this.matchId,
  });

  @override
  List<Object?> get props => [
        success,
        superLikesRemaining,
        nextResetAt,
        isMatch,
        matchId,
      ];
}

// Statistiques premium
class PremiumStats extends Equatable {
  final UsageStats usageStats;
  final FeatureUsage featureUsage;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int savedTime; // En minutes
  final int extraMatches;

  const PremiumStats({
    required this.usageStats,
    required this.featureUsage,
    this.periodStart,
    this.periodEnd,
    this.savedTime = 0,
    this.extraMatches = 0,
  });

  @override
  List<Object?> get props => [
        usageStats,
        featureUsage,
        periodStart,
        periodEnd,
        savedTime,
        extraMatches,
      ];
}

// Statistiques d'usage
class UsageStats extends Equatable {
  final int likesSentThisPeriod;
  final int superLikesUsed;
  final int boostsUsed;
  final int profileViewsGained;
  final int matchesFromPremium;

  const UsageStats({
    this.likesSentThisPeriod = 0,
    this.superLikesUsed = 0,
    this.boostsUsed = 0,
    this.profileViewsGained = 0,
    this.matchesFromPremium = 0,
  });

  @override
  List<Object> get props => [
        likesSentThisPeriod,
        superLikesUsed,
        boostsUsed,
        profileViewsGained,
        matchesFromPremium,
      ];
}

// Usage des fonctionnalités
class FeatureUsage extends Equatable {
  final int whoLikedYouViews;
  final int mediaMessagesSent;
  final int videoCallsMade;
  final int rewindsUsed;

  const FeatureUsage({
    this.whoLikedYouViews = 0,
    this.mediaMessagesSent = 0,
    this.videoCallsMade = 0,
    this.rewindsUsed = 0,
  });

  @override
  List<Object> get props => [
        whoLikedYouViews,
        mediaMessagesSent,
        videoCallsMade,
        rewindsUsed,
      ];
}

// Fonctionnalité premium
class PremiumFeature extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool isAvailable;

  const PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.isAvailable = true,
  });

  @override
  List<Object> get props => [id, name, description, iconName, isAvailable];
}

// Enums
enum BillingInterval { weekly, monthly, yearly }

enum SubscriptionStatus { active, trial, expired, cancelled, pending }

enum PaymentStatus { succeeded, failed, pending, cancelled }

// Classe pour l'ancien PremiumSubscription (maintenant remplacé par UserSubscription)
// Gardé pour compatibilité
class PremiumSubscription extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final String paymentMethod;

  const PremiumSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.autoRenew,
    required this.paymentMethod,
  });

  @override
  List<Object> get props => [
        id,
        userId,
        planId,
        startDate,
        endDate,
        isActive,
        autoRenew,
        paymentMethod,
      ];
}

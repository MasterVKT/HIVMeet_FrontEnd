// lib/presentation/blocs/premium/premium_event.dart

import 'package:equatable/equatable.dart';

abstract class PremiumEvent extends Equatable {
  const PremiumEvent();

  @override
  List<Object?> get props => [];
}

class LoadPremiumPlans extends PremiumEvent {}

class LoadAvailablePlans extends PremiumEvent {}

class LoadCurrentSubscription extends PremiumEvent {}

class PurchasePremium extends PremiumEvent {
  final String planId;
  final String phoneNumber;
  final String language;
  final String? returnTo;

  const PurchasePremium({
    required this.planId,
    required this.phoneNumber,
    required this.language,
    this.returnTo,
  });

  @override
  List<Object?> get props => [planId, phoneNumber, language, returnTo];
}

class CancelPremium extends PremiumEvent {}

class UpdateAutoRenew extends PremiumEvent {
  final bool autoRenew;

  const UpdateAutoRenew({required this.autoRenew});

  @override
  List<Object> get props => [autoRenew];
}

class UseBoost extends PremiumEvent {}

class UseSuperLike extends PremiumEvent {
  final String targetUserId;

  const UseSuperLike({required this.targetUserId});

  @override
  List<Object> get props => [targetUserId];
}

class LoadPremiumStats extends PremiumEvent {}

class LoadPaymentHistory extends PremiumEvent {}

class RetryPayment extends PremiumEvent {
  final String sessionId;

  const RetryPayment({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class RestorePendingPayment extends PremiumEvent {
  const RestorePendingPayment();
}

class VerifyPendingPayment extends PremiumEvent {
  /// UX-only signal received from the hosted return URL.
  final String? returnStatus;

  const VerifyPendingPayment({this.returnStatus});

  @override
  List<Object?> get props => [returnStatus];
}

class AbandonPendingPayment extends PremiumEvent {
  const AbandonPendingPayment();
}

class ModifySubscription extends PremiumEvent {
  final String newPlanId;
  final bool proration;

  /// Requis uniquement si le changement s'avère nécessiter un vrai paiement
  /// (montant net positif) — un nouveau Paylink est alors créé et ce numéro
  /// sert à l'initier, comme pour un premier achat.
  final String? phoneNumber;
  final String language;

  const ModifySubscription({
    required this.newPlanId,
    this.proration = true,
    this.phoneNumber,
    this.language = 'fr',
  });

  @override
  List<Object?> get props => [newPlanId, proration, phoneNumber, language];
}

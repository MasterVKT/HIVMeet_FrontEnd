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

  const PurchasePremium({required this.planId});

  @override
  List<Object> get props => [planId];
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

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';

abstract class PremiumState extends Equatable {
  const PremiumState();

  @override
  List<Object?> get props => [];
}

class PremiumInitial extends PremiumState {}

class PremiumLoading extends PremiumState {}

class PremiumLoaded extends PremiumState {
  final List<PremiumPlan> plans;
  final UserSubscription? currentSubscription;

  const PremiumLoaded({
    required this.plans,
    this.currentSubscription,
  });

  @override
  List<Object?> get props => [plans, currentSubscription];
}

class PremiumProcessing extends PremiumState {}

class PremiumPurchaseSuccess extends PremiumState {
  final UserSubscription subscription;

  const PremiumPurchaseSuccess({required this.subscription});

  @override
  List<Object> get props => [subscription];
}

class PremiumPurchaseError extends PremiumState {
  final String message;

  const PremiumPurchaseError({required this.message});

  @override
  List<Object> get props => [message];
}

class PremiumError extends PremiumState {
  final String message;

  const PremiumError({required this.message});

  @override
  List<Object> get props => [message];
}

class BoostActivated extends PremiumState {
  final BoostResult result;

  const BoostActivated({required this.result});

  @override
  List<Object> get props => [result];
}

class SuperLikeUsed extends PremiumState {
  final SuperLikeResult result;

  const SuperLikeUsed({required this.result});

  @override
  List<Object> get props => [result];
}

class PremiumStatsLoaded extends PremiumState {
  final PremiumStats stats;

  const PremiumStatsLoaded({required this.stats});

  @override
  List<Object> get props => [stats];
}

class PaymentHistoryLoading extends PremiumState {}

class PaymentHistoryError extends PremiumState {
  final String message;

  const PaymentHistoryError({required this.message});

  @override
  List<Object> get props => [message];
}

class PaymentHistoryLoaded extends PremiumState {
  final List<PaymentHistory> payments;

  const PaymentHistoryLoaded({required this.payments});

  @override
  List<Object> get props => [payments];
}

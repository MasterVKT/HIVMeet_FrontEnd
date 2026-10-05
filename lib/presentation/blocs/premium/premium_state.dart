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
  final PaymentCapabilities paymentCapabilities;

  const PremiumLoaded({
    required this.plans,
    this.currentSubscription,
    this.paymentCapabilities = const PaymentCapabilities.unavailable(),
  });

  @override
  List<Object?> get props => [plans, currentSubscription, paymentCapabilities];
}

class PremiumProcessing extends PremiumState {}

class PremiumPaymentReady extends PremiumState {
  final PaymentSession session;

  const PremiumPaymentReady({required this.session});

  @override
  List<Object> get props => [session];
}

class PremiumPaymentRestored extends PremiumState {
  final PendingPaymentAttempt attempt;

  const PremiumPaymentRestored({required this.attempt});

  @override
  List<Object> get props => [attempt];
}

class PremiumPaymentVerifying extends PremiumState {
  final PendingPaymentAttempt attempt;
  final int attemptNumber;
  final int maxAttempts;

  const PremiumPaymentVerifying({
    required this.attempt,
    required this.attemptNumber,
    required this.maxAttempts,
  });

  @override
  List<Object> get props => [attempt, attemptNumber, maxAttempts];
}

class PremiumPaymentPending extends PremiumState {
  final String paymentId;
  final String? paymentUrl;
  final String? returnStatus;

  const PremiumPaymentPending({
    required this.paymentId,
    this.paymentUrl,
    this.returnStatus,
  });

  @override
  List<Object?> get props => [paymentId, paymentUrl, returnStatus];
}

class PremiumPaymentNetworkError extends PremiumState {
  final PendingPaymentAttempt attempt;

  const PremiumPaymentNetworkError({required this.attempt});

  @override
  List<Object> get props => [attempt];
}

class PremiumActivationPending extends PremiumState {
  final PendingPaymentAttempt attempt;

  const PremiumActivationPending({required this.attempt});

  @override
  List<Object> get props => [attempt];
}

class PremiumPaymentCancelled extends PremiumState {
  const PremiumPaymentCancelled();
}

class PremiumPaymentFailed extends PremiumState {
  const PremiumPaymentFailed();
}

class PremiumPaymentAbandoned extends PremiumState {
  const PremiumPaymentAbandoned();
}

class PremiumPurchaseSuccess extends PremiumState {
  final UserSubscription subscription;
  final String? returnTo;

  const PremiumPurchaseSuccess({required this.subscription, this.returnTo});

  @override
  List<Object?> get props => [subscription, returnTo];
}

class PremiumPurchaseError extends PremiumState {
  final String message;
  final String? code;

  const PremiumPurchaseError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class PremiumError extends PremiumState {
  final String message;
  final String? code;

  const PremiumError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
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

class PremiumModifySuccess extends PremiumState {
  final UserSubscription subscription;

  const PremiumModifySuccess({required this.subscription});

  @override
  List<Object> get props => [subscription];
}

class PremiumModifyError extends PremiumState {
  final String message;
  final String? code;

  const PremiumModifyError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

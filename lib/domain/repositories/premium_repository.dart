// lib/domain/repositories/premium_repository.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/premium.dart';

abstract class PremiumRepository {
  // Plans et abonnements
  Future<Either<Failure, List<PremiumPlan>>> getAvailablePlans();

  Future<Either<Failure, UserSubscription?>> getCurrentSubscription();

  // Gestion des paiements MyCoolPay
  Future<Either<Failure, PaymentSession>> createPaymentSession(String planId);

  Future<Either<Failure, PaymentResult>> verifyPayment(String sessionId);

  Future<Either<Failure, PaymentResult>> validatePayment(String sessionId);

  Future<Either<Failure, PaymentResult>> purchasePlan(String planId);

  Future<Either<Failure, void>> updateAutoRenew(bool autoRenew);

  Future<Either<Failure, List<PaymentHistory>>> getPaymentHistory();

  // Modification et annulation
  Future<Either<Failure, UserSubscription>> modifySubscription({
    required String newPlanId,
    bool proration = true,
  });

  Future<Either<Failure, CancellationResult>> cancelSubscription();

  // Fonctionnalités premium
  Future<Either<Failure, BoostResult>> activateBoost();
  Future<Either<Failure, BoostResult>> useBoost();
  Future<Either<Failure, SuperLikeResult>> useSuperLike(String profileId);

  // Statistiques et analytics
  Future<Either<Failure, PremiumStats>> getPremiumStats();
  Future<Either<Failure, List<PremiumFeature>>> getAvailableFeatures();

  Future<Either<Failure, FeaturesUsage>> getFeaturesUsage();
}

// Classe pour l'historique des paiements (gardée pour compatibilité)
class PaymentHistory extends Equatable {
  final String id;
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
  final PaymentStatus status;

  const PaymentHistory({
    required this.id,
    required this.date,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
  });

  @override
  List<Object> get props => [id, date, amount, currency, description, status];
}

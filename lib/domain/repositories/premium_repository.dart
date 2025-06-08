// lib/domain/repositories/premium_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/premium.dart';

abstract class PremiumRepository {
  Future<Either<Failure, List<PremiumPlan>>> getAvailablePlans();
  Future<Either<Failure, PremiumSubscription?>> getCurrentSubscription();
  Future<Either<Failure, PremiumSubscription>> purchasePlan(String planId);
  Future<Either<Failure, void>> cancelSubscription();
  Future<Either<Failure, void>> updateAutoRenew(bool autoRenew);
  Future<Either<Failure, List<PaymentHistory>>> getPaymentHistory();
}

class PaymentHistory extends Equatable {
  final String id;
  final DateTime date;
  final int amount;
  final String description;
  final String status;

  const PaymentHistory({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.status,
  });

  @override
  List<Object> get props => [id, date, amount, description, status];
}
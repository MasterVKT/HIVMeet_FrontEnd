// lib/domain/entities/premium.dart

import 'package:equatable/equatable.dart';

class PremiumPlan extends Equatable {
  final String id;
  final String name;
  final String duration; // 'mois', 'an'
  final int price;
  final int? originalPrice;
  final int discountPercentage;
  final List<String> features;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    this.originalPrice,
    required this.discountPercentage,
    required this.features,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        duration,
        price,
        originalPrice,
        discountPercentage,
        features,
      ];
}

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
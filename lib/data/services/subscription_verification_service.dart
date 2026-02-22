// lib/data/services/subscription_verification_service.dart

import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'dart:developer' as developer;

/// Service pour vérifier la cohérence entre le flag premium et l'abonnement réel
@lazySingleton
class SubscriptionVerificationService {
  final AuthenticationService _authService;
  final PremiumRepository _premiumRepository;

  const SubscriptionVerificationService(
    this._authService,
    this._premiumRepository,
  );

  /// Vérifie la cohérence entre is_premium et l'existence d'une subscription active
  ///
  /// Cette vérification devrait être appelée au démarrage de l'app et après connexion
  /// pour s'assurer qu'un utilisateur avec isPremium=true a bien une subscription active
  Future<SubscriptionConsistencyResult> verifyPremiumConsistency() async {
    try {
      final user = _authService.currentUser;

      if (user == null) {
        return SubscriptionConsistencyResult.notAuthenticated();
      }

      // Si l'utilisateur n'est pas premium, pas besoin de vérifier
      if (!user.isPremium) {
        developer.log(
          'User is not premium, skipping subscription verification',
          name: 'SubscriptionVerification',
        );
        return SubscriptionConsistencyResult.consistent(
          hasPremium: false,
          hasSubscription: false,
        );
      }

      // Récupérer la subscription depuis le backend
      final subscriptionResult =
          await _premiumRepository.getCurrentSubscription();

      return subscriptionResult.fold(
        (failure) {
          // Erreur lors de la récupération
          developer.log(
            'Error fetching subscription: ${failure.message}',
            name: 'SubscriptionVerification',
            level: 900, // Warning
          );
          return SubscriptionConsistencyResult.error(
            message: 'Impossible de vérifier l\'abonnement: ${failure.message}',
          );
        },
        (subscription) {
          // Vérifier la cohérence
          if (subscription == null || !subscription.isActive) {
            // INCOHÉRENCE DÉTECTÉE
            developer.log(
              '⚠️ INCONSISTENCY: User ${user.id} has isPremium=true but no active subscription',
              name: 'SubscriptionVerification',
              level: 1000, // Error
            );
            return SubscriptionConsistencyResult.inconsistent(
              user: user,
              subscription: subscription,
              reason: subscription == null
                  ? 'Aucune subscription trouvée'
                  : 'Subscription status: ${subscription.status}',
            );
          }

          // Tout est cohérent
          developer.log(
            'Premium status consistent for user ${user.id}',
            name: 'SubscriptionVerification',
          );
          return SubscriptionConsistencyResult.consistent(
            hasPremium: true,
            hasSubscription: true,
            subscription: subscription,
          );
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during subscription verification',
        name: 'SubscriptionVerification',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return SubscriptionConsistencyResult.error(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Vérifie si l'utilisateur a des super likes disponibles
  ///
  /// Retourne le nombre de super likes restants, ou null en cas d'erreur
  Future<int?> checkSuperLikesAvailable() async {
    try {
      final subscriptionResult =
          await _premiumRepository.getCurrentSubscription();

      return subscriptionResult.fold(
        (failure) {
          developer.log(
            'Error checking super likes: ${failure.message}',
            name: 'SubscriptionVerification',
          );
          return null;
        },
        (subscription) {
          if (subscription == null || !subscription.isActive) {
            return 0;
          }

          final usage = subscription.featuresUsage;
          if (usage == null) {
            developer.log(
              'No features usage data available',
              name: 'SubscriptionVerification',
            );
            return null;
          }

          return usage.superLikesRemaining;
        },
      );
    } catch (e) {
      developer.log(
        'Error checking super likes availability',
        name: 'SubscriptionVerification',
        error: e,
      );
      return null;
    }
  }
}

/// Résultat de la vérification de cohérence
class SubscriptionConsistencyResult {
  final bool isConsistent;
  final bool hasPremium;
  final bool hasSubscription;
  final domain.User? user;
  final dynamic subscription;
  final String? reason;
  final String? errorMessage;

  const SubscriptionConsistencyResult._({
    required this.isConsistent,
    required this.hasPremium,
    required this.hasSubscription,
    this.user,
    this.subscription,
    this.reason,
    this.errorMessage,
  });

  factory SubscriptionConsistencyResult.consistent({
    required bool hasPremium,
    required bool hasSubscription,
    dynamic subscription,
  }) {
    return SubscriptionConsistencyResult._(
      isConsistent: true,
      hasPremium: hasPremium,
      hasSubscription: hasSubscription,
      subscription: subscription,
    );
  }

  factory SubscriptionConsistencyResult.inconsistent({
    required domain.User user,
    required dynamic subscription,
    required String reason,
  }) {
    return SubscriptionConsistencyResult._(
      isConsistent: false,
      hasPremium: true,
      hasSubscription: subscription != null,
      user: user,
      subscription: subscription,
      reason: reason,
    );
  }

  factory SubscriptionConsistencyResult.error({
    required String message,
  }) {
    return SubscriptionConsistencyResult._(
      isConsistent: false,
      hasPremium: false,
      hasSubscription: false,
      errorMessage: message,
    );
  }

  factory SubscriptionConsistencyResult.notAuthenticated() {
    return const SubscriptionConsistencyResult._(
      isConsistent: true,
      hasPremium: false,
      hasSubscription: false,
    );
  }

  bool get hasError => errorMessage != null;
}

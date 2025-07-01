// lib/presentation/blocs/premium/premium_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'premium_event.dart';
import 'premium_state.dart';

@injectable
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PremiumRepository _premiumRepository;

  PremiumBloc({
    required PremiumRepository premiumRepository,
  })  : _premiumRepository = premiumRepository,
        super(PremiumInitial()) {
    on<LoadPremiumPlans>(_onLoadPremiumPlans);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
    on<PurchasePremium>(_onPurchasePremium);
    on<CancelPremium>(_onCancelPremium);
    on<UpdateAutoRenew>(_onUpdateAutoRenew);
    on<UseBoost>(_onUseBoost);
    on<UseSuperLike>(_onUseSuperLike);
    on<LoadPremiumStats>(_onLoadPremiumStats);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RetryPayment>(_onRetryPayment);
  }

  Future<void> _onLoadPremiumPlans(
    LoadPremiumPlans event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumLoading());

    final plansResult = await _premiumRepository.getAvailablePlans();
    final subscriptionResult =
        await _premiumRepository.getCurrentSubscription();

    plansResult.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (plans) {
        subscriptionResult.fold(
          (failure) => emit(PremiumLoaded(
            plans: plans,
            currentSubscription: null,
          )),
          (subscription) => emit(PremiumLoaded(
            plans: plans,
            currentSubscription: subscription,
          )),
        );
      },
    );
  }

  Future<void> _onLoadAvailablePlans(
    LoadAvailablePlans event,
    Emitter<PremiumState> emit,
  ) async {
    // Même logique que LoadPremiumPlans
    add(LoadPremiumPlans());
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    final result = await _premiumRepository.getCurrentSubscription();

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (subscription) {
        // Recharger les plans avec l'abonnement actuel
        add(LoadPremiumPlans());
      },
    );
  }

  Future<void> _onPurchasePremium(
    PurchasePremium event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());

    final result = await _premiumRepository.purchasePlan(event.planId);

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (paymentResult) {
        if (paymentResult.isSuccessful) {
          // Pour la démo, on simule la création d'un abonnement
          final subscription = UserSubscription(
            id: paymentResult.subscriptionId ?? 'sub_demo',
            plan: PremiumPlan(
              id: event.planId,
              planId: event.planId,
              name: 'Premium',
              description: 'Plan premium',
              price: 9.99,
              currency: 'EUR',
              billingInterval: BillingInterval.monthly,
              features: const PremiumFeatures(),
            ),
            status: SubscriptionStatus.active,
            currentPeriodStart: DateTime.now(),
            currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          );
          emit(PremiumPurchaseSuccess(subscription: subscription));
        } else {
          emit(PremiumPurchaseError(
              message: paymentResult.errorMessage ?? 'Payment failed'));
        }
      },
    );
  }

  Future<void> _onCancelPremium(
    CancelPremium event,
    Emitter<PremiumState> emit,
  ) async {
    final result = await _premiumRepository.cancelSubscription();

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (_) {
        add(LoadPremiumPlans());
      },
    );
  }

  Future<void> _onUpdateAutoRenew(
    UpdateAutoRenew event,
    Emitter<PremiumState> emit,
  ) async {
    final result = await _premiumRepository.updateAutoRenew(event.autoRenew);

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (_) => add(LoadCurrentSubscription()),
    );
  }

  Future<void> _onUseBoost(
    UseBoost event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());

    final result = await _premiumRepository.useBoost();

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (boostResult) => emit(BoostActivated(result: boostResult)),
    );
  }

  Future<void> _onUseSuperLike(
    UseSuperLike event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());

    final result = await _premiumRepository.useSuperLike(event.targetUserId);

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (superLikeResult) => emit(SuperLikeUsed(result: superLikeResult)),
    );
  }

  Future<void> _onLoadPremiumStats(
    LoadPremiumStats event,
    Emitter<PremiumState> emit,
  ) async {
    final result = await _premiumRepository.getPremiumStats();

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (stats) => emit(PremiumStatsLoaded(stats: stats)),
    );
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PaymentHistoryLoading());

    final result = await _premiumRepository.getPaymentHistory();

    result.fold(
      (failure) => emit(PaymentHistoryError(message: failure.message)),
      (payments) => emit(PaymentHistoryLoaded(payments: payments)),
    );
  }

  Future<void> _onRetryPayment(
    RetryPayment event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());

    final result = await _premiumRepository.validatePayment(event.sessionId);

    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (paymentResult) {
        if (paymentResult.isSuccessful) {
          add(LoadPremiumPlans());
        } else {
          emit(PremiumError(
              message: paymentResult.errorMessage ?? 'Payment failed'));
        }
      },
    );
  }
}

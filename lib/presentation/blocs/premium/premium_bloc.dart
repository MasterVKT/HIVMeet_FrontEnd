// lib/presentation/blocs/premium/premium_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'premium_event.dart';
import 'premium_state.dart';

@injectable
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PremiumRepository _premiumRepository;
  final AuthenticationService _authenticationService;
  final RealtimeEventBus _realtimeBus;
  final List<Duration> _paymentPollingDelays;
  bool _purchaseInProgress = false;
  bool _verificationInProgress = false;

  PremiumBloc({
    required PremiumRepository premiumRepository,
    required AuthenticationService authenticationService,
    required RealtimeEventBus realtimeBus,
    List<Duration> paymentPollingDelays = const [
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ],
  })  : _premiumRepository = premiumRepository,
        _authenticationService = authenticationService,
        _realtimeBus = realtimeBus,
        _paymentPollingDelays = List.unmodifiable(paymentPollingDelays),
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
    on<RestorePendingPayment>(_onRestorePendingPayment);
    on<VerifyPendingPayment>(_onVerifyPendingPayment);
    on<AbandonPendingPayment>(_onAbandonPendingPayment);
    on<ModifySubscription>(_onModifySubscription);
  }

  Future<void> _onLoadPremiumPlans(
    LoadPremiumPlans event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumLoading());

    final plansResult = await _premiumRepository.getAvailablePlans();
    final capabilitiesResult =
        await _premiumRepository.getPaymentCapabilities();
    final subscriptionResult =
        await _premiumRepository.getCurrentSubscription();
    final capabilities = capabilitiesResult.fold(
      (_) => const PaymentCapabilities.unavailable(),
      (value) => value,
    );

    plansResult.fold(
      (failure) => emit(PremiumError(
        message: failure.message,
        code: failure.code,
      )),
      (plans) {
        subscriptionResult.fold(
          (failure) => emit(PremiumLoaded(
            plans: plans,
            currentSubscription: null,
            paymentCapabilities: capabilities,
          )),
          (subscription) => emit(PremiumLoaded(
            plans: plans,
            currentSubscription: subscription,
            paymentCapabilities: capabilities,
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
    if (_purchaseInProgress) return;
    _purchaseInProgress = true;
    emit(PremiumProcessing());

    try {
      final result = await _premiumRepository.createPaymentSession(
        planId: event.planId,
        phoneNumber: event.phoneNumber,
        language: event.language,
        returnTo: event.returnTo,
      );

      result.fold(
        (failure) => emit(PremiumPurchaseError(
          message: failure.message,
          code: failure.code,
        )),
        (session) {
          if (session.status == PaymentStatus.failed) {
            emit(const PremiumPaymentFailed());
          } else if (session.status == PaymentStatus.cancelled) {
            emit(const PremiumPaymentCancelled());
          } else if (session.canOpenPaymentPage) {
            emit(PremiumPaymentReady(session: session));
          } else {
            emit(PremiumPaymentPending(paymentId: session.sessionId));
          }
        },
      );
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> _onRestorePendingPayment(
    RestorePendingPayment event,
    Emitter<PremiumState> emit,
  ) async {
    final result = await _premiumRepository.getPendingPayment();
    result.fold(
      (failure) => emit(PremiumPurchaseError(
        message: failure.message,
        code: failure.code,
      )),
      (attempt) {
        if (attempt != null) emit(PremiumPaymentRestored(attempt: attempt));
      },
    );
  }

  Future<void> _onVerifyPendingPayment(
    VerifyPendingPayment event,
    Emitter<PremiumState> emit,
  ) async {
    if (_verificationInProgress) return;
    _verificationInProgress = true;
    try {
      final pendingResult = await _premiumRepository.getPendingPayment();
      final pending = pendingResult.fold<PendingPaymentAttempt?>(
        (_) => null,
        (value) => value,
      );
      if (pending == null || !pending.hasPaymentId) {
        emit(const PremiumPurchaseError(
          message: 'No pending payment could be restored',
          code: 'payment_not_found',
        ));
        return;
      }

      var hadNetworkFailure = false;
      for (var index = 0; index < _paymentPollingDelays.length; index++) {
        final delay = _paymentPollingDelays[index];
        if (delay > Duration.zero) await Future<void>.delayed(delay);
        emit(PremiumPaymentVerifying(
          attempt: pending,
          attemptNumber: index + 1,
          maxAttempts: _paymentPollingDelays.length,
        ));

        final result = await _premiumRepository.verifyPayment(
          pending.paymentId!,
        );
        final failure = result.fold((value) => value, (_) => null);
        final payment = result.fold((_) => null, (value) => value);
        if (failure != null) {
          hadNetworkFailure = failure.code == 'payment_network_error';
          if (!hadNetworkFailure) {
            emit(PremiumPurchaseError(
              message: failure.message,
              code: failure.code,
            ));
            return;
          }
          continue;
        }
        hadNetworkFailure = false;
        if (payment!.isSuccessful) {
          await _emitConfirmedSubscription(
            emit,
            pending: pending,
          );
          return;
        }
        if (payment.status == PaymentStatus.cancelled) {
          emit(const PremiumPaymentCancelled());
          return;
        }
        if (payment.status == PaymentStatus.failed) {
          emit(const PremiumPaymentFailed());
          return;
        }
      }

      if (hadNetworkFailure) {
        emit(PremiumPaymentNetworkError(attempt: pending));
      } else {
        emit(PremiumPaymentPending(
          paymentId: pending.paymentId!,
          paymentUrl: pending.paymentUrl,
          returnStatus: event.returnStatus,
        ));
      }
    } finally {
      _verificationInProgress = false;
    }
  }

  Future<void> _onAbandonPendingPayment(
    AbandonPendingPayment event,
    Emitter<PremiumState> emit,
  ) async {
    // Stop the active wait without deleting the recovery record: the hosted
    // transaction may still complete and must not be duplicated by a retry.
    emit(const PremiumPaymentAbandoned());
  }

  Future<void> _emitConfirmedSubscription(
    Emitter<PremiumState> emit, {
    required PendingPaymentAttempt pending,
  }) async {
    final subscriptionResult =
        await _premiumRepository.getCurrentSubscription();
    await subscriptionResult.fold<Future<void>>(
      (_) async => emit(PremiumActivationPending(attempt: pending)),
      (subscription) async {
        if (subscription == null) {
          emit(PremiumActivationPending(attempt: pending));
          return;
        }
        try {
          final user = await _authenticationService.refreshCurrentUser();
          if (!user.isPremiumActive) {
            throw const FormatException('Premium user snapshot not active');
          }
        } catch (_) {
          emit(PremiumActivationPending(attempt: pending));
          return;
        }
        // Cleanup is deliberately last: until the active user snapshot exists,
        // the fulfilled transaction must remain recoverable and retryable.
        // A cleanup failure cannot revoke server-confirmed Premium rights.
        await _premiumRepository.clearPendingPayment();
        _realtimeBus.publish(const RealtimeEvent(
          type: RealtimeEventType.subscriptionChanged,
          source: RealtimeSource.local,
        ));
        emit(PremiumPurchaseSuccess(
          subscription: subscription,
          returnTo: pending.returnTo,
        ));
        add(LoadPremiumPlans());
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

    final pendingResult = await _premiumRepository.getPendingPayment();
    final pending = pendingResult.fold<PendingPaymentAttempt?>(
      (_) => null,
      (attempt) => attempt,
    );

    final result = await _premiumRepository.validatePayment(event.sessionId);

    await result.fold<Future<void>>(
      (failure) async => emit(PremiumPurchaseError(message: failure.message)),
      (paymentResult) async {
        if (paymentResult.isSuccessful) {
          if (pending == null || !pending.hasPaymentId) {
            emit(const PremiumPurchaseError(
              message: 'No pending payment could be restored',
              code: 'payment_not_found',
            ));
          } else {
            await _emitConfirmedSubscription(emit, pending: pending);
          }
        } else if (paymentResult.status == PaymentStatus.pending) {
          emit(PremiumPaymentPending(paymentId: event.sessionId));
        } else {
          emit(PremiumPurchaseError(
              message: paymentResult.errorMessage ?? 'Payment failed'));
        }
      },
    );
  }

  Future<void> _onModifySubscription(
    ModifySubscription event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());

    final result = await _premiumRepository.modifySubscription(
      newPlanId: event.newPlanId,
      proration: event.proration,
      phoneNumber: event.phoneNumber,
      language: event.language,
    );

    result.fold(
      (failure) => emit(PremiumModifyError(
        message: failure.message,
        code: failure.code,
      )),
      (outcome) {
        if (outcome.requiresPayment) {
          // MyCoolPay n'a pas d'API de modification : un montant net positif
          // a créé un nouveau Paylink. Le reste du flux (ouverture navigateur,
          // reprise après fermeture d'app, vérification) est identique à un
          // premier achat — même état, même pipeline.
          emit(PremiumPaymentReady(session: outcome.paymentSession!));
          return;
        }
        emit(PremiumModifySuccess(subscription: outcome.subscription!));
        // Recharger les plans + abonnement courant pour rafraîchir l'UI
        add(LoadPremiumPlans());
      },
    );
  }
}

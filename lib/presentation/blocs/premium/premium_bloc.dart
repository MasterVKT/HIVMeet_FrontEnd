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
    on<PurchasePremium>(_onPurchasePremium);
    on<CancelPremium>(_onCancelPremium);
    on<UpdateAutoRenew>(_onUpdateAutoRenew);
  }

  Future<void> _onLoadPremiumPlans(
    LoadPremiumPlans event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumLoading());
    
    final plansResult = await _premiumRepository.getAvailablePlans();
    final subscriptionResult = await _premiumRepository.getCurrentSubscription();
    
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

  Future<void> _onPurchasePremium(
    PurchasePremium event,
    Emitter<PremiumState> emit,
  ) async {
    emit(PremiumProcessing());
    
    final result = await _premiumRepository.purchasePlan(event.planId);
    
    result.fold(
      (failure) => emit(PremiumError(message: failure.message)),
      (subscription) => emit(PremiumPurchaseSuccess(subscription: subscription)),
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
      (_) {
        add(LoadPremiumPlans());
      },
    );
  }
}
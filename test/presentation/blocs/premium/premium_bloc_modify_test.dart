// test/presentation/blocs/premium/premium_bloc_modify_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';

// --- Mocks -------------------------------------------------------------

class MockPremiumRepository extends Mock implements PremiumRepository {}

class MockAuthenticationService extends Mock implements AuthenticationService {}

// --- Fixtures -----------------------------------------------------------

final _testSubscription = UserSubscription(
  id: 'sub_123',
  plan: PremiumPlan(
    id: 'hivmeet_yearly',
    planId: 'hivmeet_yearly',
    name: 'HIVMeet Premium Annuel',
    description: 'Plan annuel',
    price: 59.99,
    currency: 'EUR',
    billingInterval: BillingInterval.yearly,
    features: const PremiumFeatures(
      unlimitedLikes: true,
      canSeeWhoLiked: true,
    ),
  ),
  status: SubscriptionStatus.active,
  currentPeriodStart: DateTime(2026, 7, 31),
  currentPeriodEnd: DateTime(2027, 7, 31),
);

// --- Tests ---------------------------------------------------------------

void main() {
  late MockPremiumRepository mockRepository;
  late PremiumBloc bloc;
  late RealtimeEventBus realtimeBus;

  setUp(() {
    mockRepository = MockPremiumRepository();
    when(() => mockRepository.getPaymentCapabilities()).thenAnswer(
      (_) async => const Right(PaymentCapabilities.unavailable()),
    );
    realtimeBus = RealtimeEventBus();
    bloc = PremiumBloc(
      premiumRepository: mockRepository,
      authenticationService: MockAuthenticationService(),
      realtimeBus: realtimeBus,
    );
  });

  tearDown(() {
    bloc.close();
    realtimeBus.dispose();
  });

  group('LoadPremiumPlans event', () {
    test('exposes backend payment capabilities with the catalogue', () async {
      when(() => mockRepository.getAvailablePlans())
          .thenAnswer((_) async => const Right(<PremiumPlan>[]));
      when(() => mockRepository.getCurrentSubscription())
          .thenAnswer((_) async => const Right(null));
      when(() => mockRepository.getPaymentCapabilities()).thenAnswer(
        (_) async => const Right(PaymentCapabilities(
          provider: 'mycoolpay',
          available: true,
          callbackVerificationAvailable: true,
          enabledCurrencies: ['EUR', 'XAF'],
          defaultCurrency: 'EUR',
          effectiveCurrency: 'XAF',
        )),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumLoading(),
          isA<PremiumLoaded>()
              .having(
                (state) => state.paymentCapabilities.available,
                'available',
                true,
              )
              .having(
                (state) => state.paymentCapabilities.effectiveCurrency,
                'effectiveCurrency',
                'XAF',
              ),
        ]),
      );

      bloc.add(LoadPremiumPlans());
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('keeps plans visible but disables checkout when capability fails',
        () async {
      when(() => mockRepository.getAvailablePlans())
          .thenAnswer((_) async => const Right(<PremiumPlan>[]));
      when(() => mockRepository.getCurrentSubscription())
          .thenAnswer((_) async => const Right(null));
      when(() => mockRepository.getPaymentCapabilities()).thenAnswer(
        (_) async => const Left(ServerFailure(
          message: 'raw provider failure',
          code: 'payment_capabilities_unavailable',
        )),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumLoading(),
          isA<PremiumLoaded>().having(
            (state) => state.paymentCapabilities.available,
            'available',
            false,
          ),
        ]),
      );

      bloc.add(LoadPremiumPlans());
      await Future.delayed(const Duration(milliseconds: 50));
    });
  });

  group('ModifySubscription event', () {
    test(
        'should emit [PremiumProcessing, PremiumModifySuccess] when the '
        'change applies immediately (no payment needed)', () async {
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
          )).thenAnswer((_) async =>
          Right(ModifySubscriptionOutcome.applied(_testSubscription)));

      // After PremiumModifySuccess, the bloc re-dispatches LoadPremiumPlans
      // which calls getAvailablePlans() and getCurrentSubscription().
      // We stub those to avoid throwing.
      when(() => mockRepository.getAvailablePlans())
          .thenAnswer((_) async => const Right(<PremiumPlan>[]));
      when(() => mockRepository.getCurrentSubscription())
          .thenAnswer((_) async => const Right(null));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumModifySuccess>()
              .having((s) => s.subscription.id, 'subscriptionId', 'sub_123')
              .having((s) => s.subscription.plan.planId, 'planId',
                  'hivmeet_yearly'),
        ]),
      );

      bloc.add(const ModifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      ));

      // Allow async events to propagate (LoadPremiumPlans re-dispatch)
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test(
        'should emit [PremiumProcessing, PremiumPaymentReady] when the '
        'backend creates a Paylink for a positive net amount', () async {
      const session = PaymentSession(
        sessionId: 'payment-id-mod',
        paymentUrl:
            'https://my-coolpay.com/payment/checkout/provider-reference',
        planId: 'hivmeet_yearly',
      );
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: '+237699009900',
            language: any(named: 'language'),
          )).thenAnswer((_) async =>
          const Right(ModifySubscriptionOutcome.paymentRequired(session)));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumPaymentReady>()
              .having((s) => s.session, 'session', session),
        ]),
      );

      bloc.add(const ModifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
        phoneNumber: '+237699009900',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // No LoadPremiumPlans re-dispatch: the plan itself hasn't changed yet.
      verifyNever(() => mockRepository.getAvailablePlans());
    });

    test('should emit [PremiumProcessing, PremiumModifyError] on failed modify',
        () async {
      when(() => mockRepository.modifySubscription(
                newPlanId: 'invalid_plan',
                proration: true,
                phoneNumber: any(named: 'phoneNumber'),
                language: any(named: 'language'),
              ))
          .thenAnswer((_) async =>
              const Left(ServerFailure(message: 'Invalid plan ID')));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumModifyError>()
              .having((s) => s.message, 'message', 'Invalid plan ID'),
        ]),
      );

      bloc.add(const ModifySubscription(
        newPlanId: 'invalid_plan',
        proration: true,
      ));

      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should pass proration=false to repository when requested', () async {
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: false,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
          )).thenAnswer((_) async =>
          Right(ModifySubscriptionOutcome.applied(_testSubscription)));

      when(() => mockRepository.getAvailablePlans())
          .thenAnswer((_) async => const Right(<PremiumPlan>[]));
      when(() => mockRepository.getCurrentSubscription())
          .thenAnswer((_) async => const Right(null));

      bloc.add(const ModifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: false,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
          )).called(1);
    });

    test('should emit PremiumModifyError on 400 phone_number_required',
        () async {
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
          )).thenAnswer((_) async => const Left(ServerFailure(
            message:
                'Un numéro de téléphone est requis pour ce changement de plan.',
            code: 'phone_number_required',
          )));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumModifyError>().having((s) => s.code, 'code',
              'phone_number_required'),
        ]),
      );

      bloc.add(const ModifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      ));

      await Future.delayed(const Duration(milliseconds: 100));
    });
  });

  group('MyCoolPay checkout', () {
    test('emits a backend payment session without simulating Premium',
        () async {
      const session = PaymentSession(
        sessionId: 'payment-id',
        paymentUrl:
            'https://my-coolpay.com/payment/checkout/provider-reference',
      );
      when(() => mockRepository.createPaymentSession(
            planId: 'hivmeet_yearly',
            phoneNumber: '699009900',
            language: 'fr',
            returnTo: null,
          )).thenAnswer((_) async => const Right(session));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumPaymentReady>()
              .having((state) => state.session, 'session', session),
        ]),
      );

      bloc.add(const PurchasePremium(
        planId: 'hivmeet_yearly',
        phoneNumber: '699009900',
        language: 'fr',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('keeps Premium inactive while payment is pending', () async {
      when(() => mockRepository.getPendingPayment())
          .thenAnswer((_) async => const Right(null));
      when(() => mockRepository.validatePayment('payment-id')).thenAnswer(
        (_) async => const Right(PaymentResult(status: PaymentStatus.pending)),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          const PremiumPaymentPending(paymentId: 'payment-id'),
        ]),
      );

      bloc.add(const RetryPayment(sessionId: 'payment-id'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verifyNever(() => mockRepository.getCurrentSubscription());
    });
  });
}

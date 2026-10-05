import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/entities/user.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';
import 'package:mocktail/mocktail.dart';

class MockPremiumRepository extends Mock implements PremiumRepository {}

class MockAuthenticationService extends Mock implements AuthenticationService {}

final pendingAttempt = PendingPaymentAttempt(
  paymentId: 'payment-id',
  planId: 'hivmeet_monthly',
  idempotencyKey: 'checkout-12345678',
  paymentUrl: 'https://my-coolpay.com/payment/checkout/payment-id',
  createdAt: DateTime.utc(2026, 9, 13),
  returnTo: '/likes-received',
);

final activeSubscription = UserSubscription(
  id: 'subscription-id',
  plan: const PremiumPlan(
    id: 'plan-id',
    planId: 'hivmeet_monthly',
    name: 'Premium',
    description: '',
    price: 7.99,
    currency: 'EUR',
    billingInterval: BillingInterval.monthly,
    features: PremiumFeatures(unlimitedLikes: true),
  ),
  status: SubscriptionStatus.active,
  currentPeriodStart: DateTime.utc(2026, 9, 13),
  currentPeriodEnd: DateTime.utc(2026, 10, 13),
);

final activeUser = User(
  id: 'user-id',
  email: 'user@example.test',
  displayName: 'User',
  isVerified: true,
  isPremium: true,
  premiumUntil: DateTime.now().add(const Duration(days: 30)),
  lastActive: DateTime.now(),
  isEmailVerified: true,
  notificationSettings: const NotificationSettings(),
  blockedUserIds: const [],
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.now(),
);

void main() {
  late MockPremiumRepository repository;
  late MockAuthenticationService authenticationService;
  late RealtimeEventBus realtimeBus;

  setUp(() {
    repository = MockPremiumRepository();
    authenticationService = MockAuthenticationService();
    realtimeBus = RealtimeEventBus();
    when(() => repository.getPendingPayment())
        .thenAnswer((_) async => Right(pendingAttempt));
    when(() => repository.clearPendingPayment())
        .thenAnswer((_) async => const Right(null));
  });

  tearDown(() => realtimeBus.dispose());

  test('bounded polling stops after the configured number of attempts',
      () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Right(PaymentResult(status: PaymentStatus.pending)),
    );
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ],
    );

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<PremiumPaymentVerifying>(),
        isA<PremiumPaymentVerifying>(),
        isA<PremiumPaymentVerifying>(),
        isA<PremiumPaymentPending>(),
      ]),
    );
    bloc.add(const VerifyPendingPayment(returnStatus: 'success'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verify(() => repository.verifyPayment('payment-id')).called(3);
    await bloc.close();
  });

  test('a lost network is distinct and keeps the recovery attempt', () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Left(PaymentFailure(
        message: 'not displayed raw',
        code: 'payment_network_error',
      )),
    );
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [Duration.zero, Duration.zero],
    );

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<PremiumPaymentVerifying>(),
        isA<PremiumPaymentVerifying>(),
        isA<PremiumPaymentNetworkError>(),
      ]),
    );
    bloc.add(const VerifyPendingPayment());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verifyNever(() => repository.clearPendingPayment());
    await bloc.close();
  });

  test('a browser cancellation stays pending until the backend confirms it',
      () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Right(PaymentResult(status: PaymentStatus.pending)),
    );
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [Duration.zero],
    );

    bloc.add(const VerifyPendingPayment(returnStatus: 'cancelled'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      bloc.state,
      isA<PremiumPaymentPending>().having(
        (state) => state.returnStatus,
        'returnStatus',
        'cancelled',
      ),
    );
    verifyNever(() => repository.clearPendingPayment());
    await bloc.close();
  });

  test('fulfilled payment refreshes user before publishing Premium change',
      () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Right(PaymentResult(
        status: PaymentStatus.succeeded,
        fulfilled: true,
      )),
    );
    when(() => repository.getCurrentSubscription())
        .thenAnswer((_) async => Right(activeSubscription));
    when(() => repository.getAvailablePlans())
        .thenAnswer((_) async => const Right(<PremiumPlan>[]));
    when(() => repository.getPaymentCapabilities()).thenAnswer(
      (_) async => const Right(PaymentCapabilities.unavailable()),
    );
    when(() => authenticationService.refreshCurrentUser())
        .thenAnswer((_) async => activeUser);

    final published = <RealtimeEvent>[];
    final eventSubscription = realtimeBus.events.listen(published.add);
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [Duration.zero],
    );
    final states = <PremiumState>[];
    final stateSubscription = bloc.stream.listen(states.add);

    bloc.add(const VerifyPendingPayment(returnStatus: 'success'));
    await Future<void>.delayed(const Duration(milliseconds: 150));

    verify(() => authenticationService.refreshCurrentUser()).called(1);
    verify(() => repository.clearPendingPayment()).called(1);
    expect(
      published.map((event) => event.type),
      contains(RealtimeEventType.subscriptionChanged),
    );
    expect(
      states.whereType<PremiumPurchaseSuccess>().single.returnTo,
      '/likes-received',
    );
    await eventSubscription.cancel();
    await stateSubscription.cancel();
    await bloc.close();
  });

  test('a terminal payment failure never refreshes or unlocks the session',
      () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Right(PaymentResult(status: PaymentStatus.failed)),
    );
    final published = <RealtimeEvent>[];
    final eventSubscription = realtimeBus.events.listen(published.add);
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [Duration.zero],
    );

    bloc.add(const VerifyPendingPayment(returnStatus: 'failed'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state, isA<PremiumPaymentFailed>());
    verifyNever(() => authenticationService.refreshCurrentUser());
    expect(published, isEmpty);
    await eventSubscription.cancel();
    await bloc.close();
  });

  test('fulfilment without an active user snapshot stays locked', () async {
    when(() => repository.verifyPayment('payment-id')).thenAnswer(
      (_) async => const Right(PaymentResult(
        status: PaymentStatus.succeeded,
        fulfilled: true,
      )),
    );
    when(() => repository.getCurrentSubscription())
        .thenAnswer((_) async => Right(activeSubscription));
    when(() => authenticationService.refreshCurrentUser())
        .thenAnswer((_) async => activeUser.copyWith(isPremium: false));
    final published = <RealtimeEvent>[];
    final eventSubscription = realtimeBus.events.listen(published.add);
    final bloc = PremiumBloc(
      premiumRepository: repository,
      authenticationService: authenticationService,
      realtimeBus: realtimeBus,
      paymentPollingDelays: const [Duration.zero],
    );

    bloc.add(const VerifyPendingPayment(returnStatus: 'success'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      bloc.state,
      isA<PremiumActivationPending>(),
    );
    verifyNever(() => repository.clearPendingPayment());
    expect(published, isEmpty);
    await eventSubscription.cancel();
    await bloc.close();
  });
}

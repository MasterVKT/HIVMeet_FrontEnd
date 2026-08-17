// test/presentation/blocs/premium/premium_bloc_modify_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_bloc.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_event.dart';
import 'package:hivmeet/presentation/blocs/premium/premium_state.dart';

// --- Mocks -------------------------------------------------------------

class MockPremiumRepository extends Mock implements PremiumRepository {}

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

  setUp(() {
    mockRepository = MockPremiumRepository();
    bloc = PremiumBloc(premiumRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ModifySubscription event', () {
    test(
        'should emit [PremiumProcessing, PremiumModifySuccess] on successful modify',
        () async {
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenAnswer((_) async => Right(_testSubscription));

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

    test('should emit [PremiumProcessing, PremiumModifyError] on failed modify',
        () async {
      when(() => mockRepository.modifySubscription(
                newPlanId: 'invalid_plan',
                proration: true,
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
          )).thenAnswer((_) async => Right(_testSubscription));

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
          )).called(1);
    });

    test('should emit PremiumModifyError on 402 payment_required', () async {
      when(() => mockRepository.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenAnswer((_) async => const Left(ServerFailure(
            message: 'Un paiement est requis pour ce changement.',
            code: 'payment_required',
          )));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumProcessing(),
          isA<PremiumModifyError>().having((s) => s.message, 'message',
              'Un paiement est requis pour ce changement.'),
        ]),
      );

      bloc.add(const ModifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      ));

      await Future.delayed(const Duration(milliseconds: 100));
    });
  });
}

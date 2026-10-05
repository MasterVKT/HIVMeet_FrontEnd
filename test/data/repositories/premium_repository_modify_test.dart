// test/data/repositories/premium_repository_modify_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:hivmeet/data/repositories/premium_repository_impl.dart';
import 'package:hivmeet/data/services/payment_service.dart' as payment_service;
import 'package:hivmeet/domain/entities/premium.dart';

// --- Mocks -------------------------------------------------------------

class MockSubscriptionsApi extends Mock implements SubscriptionsApi {}

class MockPaymentService extends Mock
    implements payment_service.PaymentService {}

// --- Helpers ------------------------------------------------------------

Response<Map<String, dynamic>> _successResponse(
  Map<String, dynamic> data,
) {
  return Response<Map<String, dynamic>>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/subscriptions/current/modify/'),
  );
}

DioException _dioError({
  required int statusCode,
  Map<String, dynamic>? data,
}) {
  return DioException(
    response: Response<Map<String, dynamic>>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: '/subscriptions/current/modify/'),
    ),
    type: DioExceptionType.badResponse,
    requestOptions: RequestOptions(path: '/subscriptions/current/modify/'),
  );
}

/// Réponse à plat (CurrentSubscriptionSerializer) — pas de wrapper
/// `subscription`.
const Map<String, dynamic> _flatSubscriptionJson = {
  'subscription_id': 'sub_123',
  'plan_id': 'hivmeet_yearly',
  'plan_name': 'HIVMeet Premium Annuel',
  'status': 'active',
  'current_period_start': '2026-07-31T16:00:00Z',
  'current_period_end': '2027-07-31T16:00:00Z',
  'auto_renew': true,
  'cancel_at_period_end': false,
  'features_summary': {
    'unlimited_likes': true,
    'can_see_likers': true,
    'can_rewind': true,
    'monthly_boosts_count': 5,
    'daily_super_likes_count': 5,
    'media_messaging_enabled': true,
    'audio_video_calls_enabled': true,
  },
  'proration': {
    'credit_amount': 3.50,
    'charge_amount': 0.00,
    'currency': 'EUR',
  },
};

// --- Tests ---------------------------------------------------------------

void main() {
  late MockSubscriptionsApi mockApi;
  late MockPaymentService mockPayment;
  late PremiumRepositoryImpl repository;

  setUp(() {
    mockApi = MockSubscriptionsApi();
    mockPayment = MockPaymentService();
    repository = PremiumRepositoryImpl(mockApi, mockPayment);
    when(() => mockPayment.newIdempotencyKey()).thenReturn('idem-key-123');
    when(() => mockPayment.recordExternalPendingPayment(
          paymentId: any(named: 'paymentId'),
          planId: any(named: 'planId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          paymentUrl: any(named: 'paymentUrl'),
          returnTo: any(named: 'returnTo'),
        )).thenAnswer((_) async {});
  });

  group('PaymentService backend contract', () {
    test('maps the backend Paylink session and forwards purchase fields',
        () async {
      when(
        () => mockApi.purchaseSubscription(
          planId: 'hivmeet_monthly',
          phoneNumber: '+237699009900',
          language: 'fr',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'payment_id': 'payment-id',
            'payment_status': 'pending',
            'payment_url':
                'https://my-coolpay.com/payment/checkout/provider-ref',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
        ),
      );
      final service = payment_service.PaymentService(mockApi);

      final session = await service.createPaymentSession(
        planId: 'hivmeet_monthly',
        phoneNumber: '+237699009900',
        language: 'fr',
      );

      expect(session.sessionId, 'payment-id');
      expect(
        session.paymentUrl,
        'https://my-coolpay.com/payment/checkout/provider-ref',
      );
      verify(
        () => mockApi.purchaseSubscription(
          planId: 'hivmeet_monthly',
          phoneNumber: '+237699009900',
          language: 'fr',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });

    test('maps success only from the authenticated backend payment status',
        () async {
      when(() => mockApi.getPaymentStatus('payment-id')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'payment_status': 'success',
            'fulfilled': true,
            'subscription_id': 'subscription-id',
            'activated_at': '2026-09-10T20:00:00Z',
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/subscriptions/payments/payment-id/'),
        ),
      );
      final service = payment_service.PaymentService(mockApi);

      final result = await service.verifyPayment('payment-id');

      expect(result.status, PaymentStatus.succeeded);
      expect(result.fulfilled, true);
      expect(result.subscriptionId, 'subscription-id');
      expect(result.activatedAt?.toUtc(), DateTime.utc(2026, 9, 10, 20));
    });

    test('rejects a checkout URL outside the official MyCoolPay host',
        () async {
      when(
        () => mockApi.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'payment_id': 'payment-id',
            'payment_url': 'https://example.com/fake-checkout',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
        ),
      );
      final service = payment_service.PaymentService(mockApi);

      expect(
        () => service.createPaymentSession(
          planId: 'hivmeet_monthly',
          phoneNumber: '+237699009900',
          language: 'fr',
        ),
        throwsA(isA<payment_service.PaymentException>()),
      );
    });
  });

  group('getAvailablePlans', () {
    test('parses the direct DRF list with string prices and feature keys',
        () async {
      when(() => mockApi.getSubscriptionPlans()).thenAnswer(
        (_) async => Response<dynamic>(
          data: const <Map<String, dynamic>>[
            {
              'plan_id': 'hivmeet_monthly',
              'name': 'HIVMeet Premium Mensuel',
              'description': 'Toutes les fonctions premium',
              'price': '9.99',
              'currency': 'EUR',
              'billing_interval': 'monthly',
              'features': <String>[
                'unlimited_likes',
                'can_see_likers',
                'can_rewind',
                'monthly_boosts',
                'daily_super_likes',
                'media_messaging',
                'audio_video_calls',
              ],
              'trial_period_days': 7,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscriptions/plans/'),
        ),
      );

      final result = await repository.getAvailablePlans();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (plans) {
          expect(plans, hasLength(1));
          final plan = plans.single;
          expect(plan.id, 'hivmeet_monthly');
          expect(plan.planId, 'hivmeet_monthly');
          expect(plan.price, 9.99);
          expect(plan.billingInterval, BillingInterval.monthly);
          expect(plan.features.unlimitedLikes, true);
          expect(plan.features.canSeeWhoLiked, true);
          expect(plan.features.canRewind, true);
          expect(plan.features.monthlyBoosts, 1);
          expect(plan.features.dailySuperLikes, 5);
          expect(plan.features.mediaMessaging, true);
          expect(plan.features.videoCalls, true);
        },
      );
    });

    test('keeps only canonical offers and maps pricing metadata', () async {
      when(() => mockApi.getSubscriptionPlans()).thenAnswer(
        (_) async => Response<dynamic>(
          data: const {
            'count': 3,
            'results': [
              {
                'plan_id': 'legacy_premium_9_99',
                'name': 'Premium',
                'description': 'Legacy',
                'price': '9.99',
                'currency': 'EUR',
                'billing_interval': 'month',
                'features': <String, dynamic>{},
              },
              {
                'plan_id': 'hivmeet_annual',
                'name': 'HIVMeet Premium Annuel',
                'description': 'Toutes les fonctions premium',
                'price': '38038',
                'currency': 'XAF',
                'base_price': '57.99',
                'base_currency': 'EUR',
                'monthly_equivalent': '3170',
                'billing_interval': 'year',
                'features': <String, dynamic>{
                  'can_rewind': true,
                  'daily_rewinds_count': 5,
                },
                'savings_percentage': 40,
                'recommended': true,
              },
              {
                'plan_id': 'hivmeet_monthly',
                'name': 'HIVMeet Premium Mensuel',
                'description': 'Toutes les fonctions premium',
                'price': '5241',
                'currency': 'XAF',
                'base_price': '7.99',
                'base_currency': 'EUR',
                'monthly_equivalent': '5241',
                'billing_interval': 'month',
                'features': <String, dynamic>{},
                'savings_percentage': 0,
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscriptions/plans/'),
        ),
      );

      final result = await repository.getAvailablePlans();

      result.fold(
        (_) => fail('Should be Right'),
        (plans) {
          expect(plans.map((plan) => plan.planId), [
            'hivmeet_monthly',
            'hivmeet_annual',
          ]);
          final annual = plans.last;
          expect(annual.price, 38038);
          expect(annual.basePrice, 57.99);
          expect(annual.baseCurrency, 'EUR');
          expect(annual.monthlyEquivalent, 3170);
          expect(annual.savings, 40);
          expect(annual.isRecommended, true);
          expect(annual.features.dailyRewinds, 5);
        },
      );
    });
  });

  group('getPaymentCapabilities', () {
    test('maps the safe provider readiness contract', () async {
      when(() => mockApi.getPaymentCapabilities()).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'provider': 'mycoolpay',
            'available': true,
            'callback_verification_available': true,
            'automatic_return_available': true,
            'confirmation_mode': 'webhook_and_polling',
            'enabled_currencies': ['XAF', 'EUR'],
            'default_currency': 'XAF',
            'effective_currency': 'XAF',
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/subscriptions/payment-capabilities/',
          ),
        ),
      );

      final result = await repository.getPaymentCapabilities();

      result.fold(
        (_) => fail('Should be Right'),
        (capabilities) {
          expect(capabilities.provider, 'mycoolpay');
          expect(capabilities.available, true);
          expect(capabilities.callbackVerificationAvailable, true);
          expect(capabilities.automaticReturnAvailable, true);
          expect(capabilities.confirmationMode, 'webhook_and_polling');
          expect(capabilities.enabledCurrencies, ['XAF', 'EUR']);
          expect(capabilities.effectiveCurrency, 'XAF');
        },
      );
    });
  });

  group('modifySubscription', () {
    test(
        'should return an applied ModifySubscriptionOutcome on success '
        '(flat response, no wrapper, no payment needed)', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(_flatSubscriptionJson));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (outcome) {
          expect(outcome.requiresPayment, false);
          final subscription = outcome.subscription!;
          expect(subscription.id, 'sub_123');
          expect(subscription.plan.planId, 'hivmeet_yearly');
          expect(subscription.plan.name, 'HIVMeet Premium Annuel');
          expect(subscription.isActive, true);
        },
      );

      verify(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).called(1);
    });

    test('maps a confirmed next-cycle change from the flat response', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson)
        ..['scheduled_change'] = {
          'plan_id': 'hivmeet_monthly',
          'plan_name': 'HIVMeet Premium Mensuel',
          'effective_at': '2027-08-31T16:00:00Z',
        };
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_monthly',
            proration: false,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_monthly',
        proration: false,
      );

      result.fold(
        (_) => fail('Should be Right'),
        (outcome) {
          final change = outcome.subscription!.scheduledChange;
          expect(change?.planId, 'hivmeet_monthly');
          expect(change?.planName, 'HIVMeet Premium Mensuel');
          expect(change?.effectiveAt, DateTime.utc(2027, 8, 31, 16));
        },
      );
    });

    test(
        'should return a paymentRequired ModifySubscriptionOutcome when the '
        'backend creates a Paylink for a positive net amount', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(const {
            'payment_id': 'payment-id-mod',
            'payment_url':
                'https://my-coolpay.com/payment/checkout/provider-ref',
            'payment_status': 'pending',
            'amount': '70.00',
            'currency': 'EUR',
            'idempotent_replay': false,
          }));
      when(() => mockPayment.validatePaymentUrl(
            'https://my-coolpay.com/payment/checkout/provider-ref',
          )).thenReturn('https://my-coolpay.com/payment/checkout/provider-ref');
      when(() => mockPayment.parsePaymentStatus('pending'))
          .thenReturn(PaymentStatus.pending);

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
        phoneNumber: '+237699009900',
        language: 'fr',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (outcome) {
          expect(outcome.requiresPayment, true);
          expect(outcome.paymentSession!.sessionId, 'payment-id-mod');
          expect(
            outcome.paymentSession!.paymentUrl,
            'https://my-coolpay.com/payment/checkout/provider-ref',
          );
          expect(outcome.paymentSession!.planId, 'hivmeet_yearly');
        },
      );

      verify(() => mockPayment.recordExternalPendingPayment(
            paymentId: 'payment-id-mod',
            planId: 'hivmeet_yearly',
            idempotencyKey: any(named: 'idempotencyKey'),
            paymentUrl:
                'https://my-coolpay.com/payment/checkout/provider-ref',
            returnTo: any(named: 'returnTo'),
          )).called(1);
    });

    test('should return ServerFailure on 400 phone_number_required',
        () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(_dioError(
        statusCode: 400,
        data: {
          'error': 'phone_number_required',
          'message':
              'Un numéro de téléphone est requis pour ce changement de plan.',
        },
      ));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.code, 'phone_number_required');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on 400 same_plan', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_monthly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(_dioError(
        statusCode: 400,
        data: {
          'error': 'same_plan',
          'message': 'Le nouveau plan est identique au plan actuel.',
        },
      ));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_monthly',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('identique'));
          expect(failure.code, 'same_plan');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on 400 no_active_subscription', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(_dioError(
        statusCode: 400,
        data: {
          'error': 'no_active_subscription',
          'message': 'Aucun abonnement actif à modifier.',
        },
      ));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('abonnement'));
        },
        (_) => fail('Should be Left'),
      );
    });

    test(
        'should handle DRF field-level validation error (no custom error code)',
        () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'invalid_plan',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(_dioError(
        statusCode: 400,
        data: {
          'new_plan_id': ['Invalid plan ID'],
        },
      ));

      final result = await repository.modifySubscription(
        newPlanId: 'invalid_plan',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Invalid plan ID'));
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should not access data["subscription"] wrapper', () async {
      // This test verifies the fix for anomaly #2:
      // the old code did data['subscription'] which returned null and crashed.
      // The response is flat — _mapJsonToUserSubscription receives the
      // entire response.data, not a sub-key.
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: false,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(_flatSubscriptionJson));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: false,
      );

      // If the old bug (data['subscription']) were still present,
      // this would throw a TypeError and we'd get a Left(ServerFailure).
      expect(result.isRight(), true);
    });
  });

  group('_parseSubscriptionStatus (via modifySubscription response)', () {
    test('should map "trialing" to SubscriptionStatus.trial', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson);
      json['status'] = 'trialing';

      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (outcome) => expect(
          outcome.subscription!.status,
          SubscriptionStatus.trial,
        ),
      );
    });

    test('should map "canceled" to SubscriptionStatus.cancelled', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson);
      json['status'] = 'canceled';

      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (outcome) => expect(
          outcome.subscription!.status,
          SubscriptionStatus.cancelled,
        ),
      );
    });

    test('should map "past_due" to SubscriptionStatus.pending', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson);
      json['status'] = 'past_due';

      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
            phoneNumber: any(named: 'phoneNumber'),
            language: any(named: 'language'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (outcome) => expect(
          outcome.subscription!.status,
          SubscriptionStatus.pending,
        ),
      );
    });
  });
}

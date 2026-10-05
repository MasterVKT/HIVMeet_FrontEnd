import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:hivmeet/data/services/payment_service.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionsApi extends Mock implements SubscriptionsApi {}

void main() {
  late MockSubscriptionsApi api;
  late FlutterSecureStorage storage;
  late PaymentService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    api = MockSubscriptionsApi();
    storage = const FlutterSecureStorage();
    service = PaymentService(api, storage);
  });

  test('persists before purchase and reuses one hosted transaction', () async {
    when(() => api.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {
          'payment_id': 'payment-id',
          'payment_status': 'pending',
          'payment_url': 'https://my-coolpay.com/payment/checkout/provider-ref',
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
      ),
    );

    final first = await service.createPaymentSession(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
      returnTo: '/likes-received',
    );
    final second = await service.createPaymentSession(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
    );

    expect(second.sessionId, first.sessionId);
    final pending = await service.getPendingPayment();
    expect(pending?.paymentId, 'payment-id');
    expect(pending?.idempotencyKey, startsWith('checkout-'));
    expect(pending?.returnTo, '/likes-received');
    expect(first.returnTo, '/likes-received');
    final rawPending =
        await storage.read(key: PaymentService.pendingStorageKey);
    expect(rawPending, isNot(contains('+237699009900')));
    expect(rawPending, isNot(contains('phone_number')));
    verify(() => api.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).called(1);
  });

  test('concurrent double taps share the same creation request', () async {
    final response = Completer<Response<Map<String, dynamic>>>();
    when(() => api.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) => response.future);

    final first = service.createPaymentSession(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
    );
    final second = service.createPaymentSession(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
    );
    response.complete(Response<Map<String, dynamic>>(
      data: const {
        'payment_id': 'single-payment',
        'payment_status': 'pending',
        'payment_url': 'https://my-coolpay.com/payment/checkout/single',
      },
      statusCode: 201,
      requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
    ));

    final sessions = await Future.wait([first, second]);
    expect(
        sessions.map((value) => value.sessionId).toSet(), {'single-payment'});
    verify(() => api.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).called(1);
  });

  test('reuses the same idempotency key after a lost response', () async {
    var calls = 0;
    when(() => api.purchaseSubscription(
          planId: any(named: 'planId'),
          phoneNumber: any(named: 'phoneNumber'),
          language: any(named: 'language'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((invocation) async {
      calls++;
      if (calls == 1) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
          reason: 'offline',
        );
      }
      return Response<Map<String, dynamic>>(
        data: const {
          'payment_id': 'recovered-payment',
          'payment_status': 'pending',
          'payment_url': 'https://my-coolpay.com/payment/checkout/recovered',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
      );
    });

    await expectLater(
      service.createPaymentSession(
        planId: 'hivmeet_monthly',
        phoneNumber: '+237699009900',
        language: 'fr',
      ),
      throwsA(isA<DioException>()),
    );
    final firstKey = (await service.getPendingPayment())!.idempotencyKey;
    await service.createPaymentSession(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
    );
    final secondKey = (await service.getPendingPayment())!.idempotencyKey;

    expect(secondKey, firstKey);
    expect(calls, 2);
  });

  test('does not trust provider success without backend fulfilment', () async {
    when(() => api.getPaymentStatus('payment-id')).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {
          'payment_status': 'succeeded',
          'fulfilled': false,
        },
        statusCode: 200,
        requestOptions:
            RequestOptions(path: '/subscriptions/payments/payment-id/'),
      ),
    );

    final result = await service.verifyPayment('payment-id');

    expect(result.status, PaymentStatus.pending);
    expect(result.isSuccessful, isFalse);
  });

  test('keeps fulfilled recovery until the local Premium refresh completes',
      () async {
    await storage.write(
      key: PaymentService.pendingStorageKey,
      value: '{"payment_id":"payment-id","plan_id":"hivmeet_monthly",'
          '"idempotency_key":"checkout-12345678","payment_url":null,'
          '"created_at":"2026-09-13T08:00:00Z"}',
    );
    when(() => api.getPaymentStatus('payment-id')).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {
          'payment_status': 'succeeded',
          'fulfilled': true,
          'subscription_id': 'subscription-id',
        },
        statusCode: 200,
        requestOptions:
            RequestOptions(path: '/subscriptions/payments/payment-id/'),
      ),
    );

    final result = await service.verifyPayment('payment-id');

    expect(result.isSuccessful, isTrue);
    expect(await service.getPendingPayment(), isNotNull);
    await service.clearPendingPayment();
    expect(await service.getPendingPayment(), isNull);
  });

  test('clears secure recovery after a backend-confirmed payment failure',
      () async {
    await storage.write(
      key: PaymentService.pendingStorageKey,
      value: '{"payment_id":"payment-id","plan_id":"hivmeet_monthly",'
          '"idempotency_key":"checkout-12345678","payment_url":null,'
          '"created_at":"2026-09-13T08:00:00Z"}',
    );
    when(() => api.getPaymentStatus('payment-id')).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {
          'payment_status': 'failed',
          'fulfilled': false,
        },
        statusCode: 200,
        requestOptions:
            RequestOptions(path: '/subscriptions/payments/payment-id/'),
      ),
    );

    final result = await service.verifyPayment('payment-id');

    expect(result.status, PaymentStatus.failed);
    expect(await service.getPendingPayment(), isNull);
  });

  test('rejects an unsafe payment identifier before building an API path',
      () async {
    await expectLater(
      service.verifyPayment('../another-user'),
      throwsA(
        isA<PaymentException>().having(
          (error) => error.code,
          'code',
          'invalid_payment_id',
        ),
      ),
    );
    verifyNever(() => api.getPaymentStatus(any()));
  });

  test('clears a tampered secure recovery record', () async {
    await storage.write(
      key: PaymentService.pendingStorageKey,
      value: '{"payment_id":"../another-user","plan_id":"hivmeet_monthly",'
          '"idempotency_key":"checkout-12345678","payment_url":null,'
          '"created_at":"2026-09-13T08:00:00Z"}',
    );

    expect(await service.getPendingPayment(), isNull);
    expect(
      await storage.read(key: PaymentService.pendingStorageKey),
      isNull,
    );
  });

  test('drops a non-allowlisted return route without losing recovery',
      () async {
    await storage.write(
      key: PaymentService.pendingStorageKey,
      value: '{"payment_id":"payment-id","plan_id":"hivmeet_monthly",'
          '"idempotency_key":"checkout-12345678","payment_url":null,'
          '"return_to":"https://attacker.example/steal",'
          '"created_at":"2026-09-13T08:00:00Z"}',
    );

    final pending = await service.getPendingPayment();

    expect(pending, isNotNull);
    expect(pending?.returnTo, isNull);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() => registerFallbackValue(FakeOptions()));

  test('sends the idempotency key as a request header', () async {
    final client = MockApiClient();
    final api = SubscriptionsApi(client);
    when(() => client.post<Map<String, dynamic>>(
          '/subscriptions/purchase/',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'payment_id': 'payment-id'},
        requestOptions: RequestOptions(path: '/subscriptions/purchase/'),
      ),
    );

    await api.purchaseSubscription(
      planId: 'hivmeet_monthly',
      phoneNumber: '+237699009900',
      language: 'fr',
      idempotencyKey: 'checkout-12345678',
    );

    final captured = verify(() => client.post<Map<String, dynamic>>(
          '/subscriptions/purchase/',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        )).captured;
    final data = captured[0] as Map<String, dynamic>;
    final options = captured[1] as Options;
    expect(data, {
      'plan_id': 'hivmeet_monthly',
      'phone_number': '+237699009900',
      'language': 'fr',
    });
    expect(options.headers?['Idempotency-Key'], 'checkout-12345678');
  });
}

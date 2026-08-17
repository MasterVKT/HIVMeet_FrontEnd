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
  });

  group('modifySubscription', () {
    test(
        'should return UserSubscription on success (flat response, no wrapper)',
        () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenAnswer((_) async => _successResponse(_flatSubscriptionJson));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
        proration: true,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (subscription) {
          expect(subscription.id, 'sub_123');
          expect(subscription.plan.planId, 'hivmeet_yearly');
          expect(subscription.plan.name, 'HIVMeet Premium Annuel');
          expect(subscription.isActive, true);
        },
      );

      verify(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).called(1);
    });

    test('should return ServerFailure on 402 payment_required', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenThrow(_dioError(
        statusCode: 402,
        data: {
          'error': 'payment_required',
          'message': 'Un paiement est requis pour ce changement.',
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
          expect(failure.message, contains('paiement'));
          expect(failure.code, 'payment_required');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on 400 same_plan', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_monthly',
            proration: true,
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
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on 400 no_active_subscription', () async {
      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
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
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (subscription) => expect(subscription.status, SubscriptionStatus.trial),
      );
    });

    test('should map "canceled" to SubscriptionStatus.cancelled', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson);
      json['status'] = 'canceled';

      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (subscription) =>
            expect(subscription.status, SubscriptionStatus.cancelled),
      );
    });

    test('should map "past_due" to SubscriptionStatus.pending', () async {
      final json = Map<String, dynamic>.from(_flatSubscriptionJson);
      json['status'] = 'past_due';

      when(() => mockApi.modifySubscription(
            newPlanId: 'hivmeet_yearly',
            proration: true,
          )).thenAnswer((_) async => _successResponse(json));

      final result = await repository.modifySubscription(
        newPlanId: 'hivmeet_yearly',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (subscription) =>
            expect(subscription.status, SubscriptionStatus.pending),
      );
    });
  });
}

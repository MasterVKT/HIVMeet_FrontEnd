import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/data/datasources/remote/subscriptions_api.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';

/// Client for the backend-owned MyCoolPay flow.
///
/// The hosted return URI is only a navigation hint. A payment is successful
/// exclusively when the authenticated backend returns `fulfilled: true`.
@singleton
class PaymentService {
  static const pendingStorageKey = 'hivmeet.payment.pending_attempt.v1';
  static final RegExp _safeIdentifier = RegExp(r'^[A-Za-z0-9._:-]{8,128}$');

  final SubscriptionsApi _subscriptionsApi;
  final FlutterSecureStorage? _secureStorage;
  final Random _random;
  Future<PaymentSession>? _inFlightCreation;
  String? _inFlightPlanId;

  PaymentService(
    this._subscriptionsApi, [
    this._secureStorage,
    Random? random,
  ]) : _random = random ?? Random.secure();

  Future<PaymentSession> createPaymentSession({
    required String planId,
    required String phoneNumber,
    required String language,
    String? returnTo,
  }) {
    _validateIdentifier(planId, code: 'invalid_plan_id');
    final inFlight = _inFlightCreation;
    if (inFlight != null) {
      if (_inFlightPlanId != planId) {
        throw const PaymentException(
          'A payment is already in progress',
          code: 'payment_in_progress',
        );
      }
      return inFlight;
    }
    _inFlightPlanId = planId;
    final operation = _createPaymentSession(
      planId: planId,
      phoneNumber: phoneNumber,
      language: language,
      returnTo: PremiumNavigation.sanitizeReturnTo(returnTo),
    );
    _inFlightCreation = operation;
    return operation.whenComplete(() {
      if (identical(_inFlightCreation, operation)) {
        _inFlightCreation = null;
        _inFlightPlanId = null;
      }
    });
  }

  Future<PaymentSession> _createPaymentSession({
    required String planId,
    required String phoneNumber,
    required String language,
    String? returnTo,
  }) async {
    final existing = await getPendingPayment();
    if (existing != null && existing.planId != planId) {
      throw const PaymentException(
        'A payment is already in progress',
        code: 'payment_in_progress',
      );
    }

    if (existing?.hasPaymentId == true && existing!.canOpenPaymentPage) {
      return PaymentSession(
        sessionId: existing.paymentId!,
        paymentUrl: existing.paymentUrl,
        planId: existing.planId,
        idempotencyKey: existing.idempotencyKey,
        returnTo: existing.returnTo,
      );
    }

    final idempotencyKey = existing?.idempotencyKey ?? _newIdempotencyKey();
    final createdAt = existing?.createdAt ?? DateTime.now().toUtc();

    // Persist before the network call. If the response is lost, retrying uses
    // the same backend idempotency key and cannot create another transaction.
    await _writePending(PendingPaymentAttempt(
      paymentId: existing?.paymentId,
      planId: planId,
      idempotencyKey: idempotencyKey,
      paymentUrl: existing?.paymentUrl,
      createdAt: createdAt,
      returnTo: returnTo ?? existing?.returnTo,
    ));

    final response = await _subscriptionsApi.purchaseSubscription(
      planId: planId,
      phoneNumber: phoneNumber,
      language: language,
      idempotencyKey: idempotencyKey,
    );
    final data = response.data ?? const <String, dynamic>{};
    final paymentId = data['payment_id']?.toString();
    if (paymentId == null || !_safeIdentifier.hasMatch(paymentId)) {
      throw const PaymentException(
        'Invalid payment response',
        code: 'invalid_payment_response',
      );
    }

    final rawPaymentUrl = data['payment_url']?.toString();
    final paymentUrl = rawPaymentUrl == null || rawPaymentUrl.isEmpty
        ? null
        : _validatedPaymentUrl(rawPaymentUrl).toString();
    final status = _parsePaymentStatus(data['payment_status']?.toString());

    await _writePending(PendingPaymentAttempt(
      paymentId: paymentId,
      planId: planId,
      idempotencyKey: idempotencyKey,
      paymentUrl: paymentUrl,
      createdAt: createdAt,
      returnTo: returnTo ?? existing?.returnTo,
    ));

    if (status == PaymentStatus.failed || status == PaymentStatus.cancelled) {
      try {
        await clearPendingPayment();
      } catch (_) {
        // The backend result remains authoritative if cleanup must be retried.
      }
    }

    return PaymentSession(
      sessionId: paymentId,
      paymentUrl: paymentUrl,
      planId: planId,
      idempotencyKey: idempotencyKey,
      status: status,
      returnTo: returnTo ?? existing?.returnTo,
    );
  }

  Future<PaymentResult> verifyPayment(String paymentId) async {
    _validateIdentifier(paymentId, code: 'invalid_payment_id');
    final response = await _subscriptionsApi.getPaymentStatus(paymentId);
    final data = response.data ?? const <String, dynamic>{};
    var status = _parsePaymentStatus(data['payment_status']?.toString());
    final fulfilled = data['fulfilled'] as bool? ?? false;

    // A browser success URL never promotes a user. Even a provider "success"
    // remains pending until Django confirms atomic fulfilment.
    if (status == PaymentStatus.succeeded && !fulfilled) {
      status = PaymentStatus.pending;
    }

    final result = PaymentResult(
      status: status,
      fulfilled: fulfilled,
      subscriptionId: data['subscription_id']?.toString(),
      activatedAt: data['activated_at'] == null
          ? null
          : DateTime.tryParse(data['activated_at'].toString()),
    );
    // A fulfilled payment stays recoverable until PremiumBloc has refreshed
    // both authoritative snapshots. A transient refresh failure can therefore
    // be retried without creating another checkout.
    if (result.status == PaymentStatus.cancelled ||
        result.status == PaymentStatus.failed) {
      try {
        await clearPendingPayment();
      } catch (_) {
        // Never downgrade an authoritative terminal result to a local error.
      }
    }
    return result;
  }

  Future<PendingPaymentAttempt?> getPendingPayment() async {
    final storage = _secureStorage;
    if (storage == null) return null;
    try {
      final value = await storage.read(key: pendingStorageKey);
      if (value == null || value.isEmpty) return null;
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic>) throw const FormatException();
      final planId = json['plan_id']?.toString() ?? '';
      final idempotencyKey = json['idempotency_key']?.toString() ?? '';
      final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
      final paymentId = json['payment_id']?.toString();
      final returnTo = PremiumNavigation.sanitizeReturnTo(
        json['return_to']?.toString(),
      );
      if (!_safeIdentifier.hasMatch(planId) ||
          !_safeIdentifier.hasMatch(idempotencyKey) ||
          (paymentId != null && !_safeIdentifier.hasMatch(paymentId)) ||
          createdAt == null) {
        throw const FormatException();
      }
      final rawPaymentUrl = json['payment_url']?.toString();
      final paymentUrl = rawPaymentUrl == null || rawPaymentUrl.isEmpty
          ? null
          : _validatedPaymentUrl(rawPaymentUrl).toString();
      return PendingPaymentAttempt(
        paymentId: paymentId,
        planId: planId,
        idempotencyKey: idempotencyKey,
        paymentUrl: paymentUrl,
        createdAt: createdAt.toUtc(),
        returnTo: returnTo,
      );
    } catch (_) {
      await clearPendingPayment();
      return null;
    }
  }

  Future<void> clearPendingPayment() async {
    await _secureStorage?.delete(key: pendingStorageKey);
  }

  /// Public wrapper so callers outside this service (e.g. a plan-change
  /// request, which posts to a different endpoint than [createPaymentSession]
  /// but still needs a fresh backend idempotency key) can generate one
  /// without duplicating the format here.
  String newIdempotencyKey() => _newIdempotencyKey();

  /// Public wrapper around the same allow-listed-host check applied to every
  /// payment URL this service persists, so a caller building a
  /// [PaymentSession] from a different endpoint's response (a plan-change
  /// Paylink) cannot bypass it. Throws [PaymentException] (`invalid_payment_url`)
  /// for anything that isn't an exact `https://my-coolpay.com` URL.
  String validatePaymentUrl(String value) => _validatedPaymentUrl(value).toString();

  /// Public wrapper around this service's payment-status string parsing, so
  /// a caller building a [PaymentSession] from a different endpoint's
  /// response uses the same mapping as [createPaymentSession].
  PaymentStatus parsePaymentStatus(String? status) => _parsePaymentStatus(status);

  /// Persists a pending payment created by a request this service did not
  /// itself issue (currently: an immediate plan-change Paylink from `POST
  /// /subscriptions/current/modify/`), so it becomes resumable/verifiable
  /// via [getPendingPayment]/[verifyPayment] exactly like a purchase — both
  /// share the same single pending-checkout slot, which is correct since a
  /// user can only have one Paylink in flight at a time.
  Future<void> recordExternalPendingPayment({
    required String paymentId,
    required String planId,
    required String idempotencyKey,
    String? paymentUrl,
    String? returnTo,
  }) async {
    await _writePending(PendingPaymentAttempt(
      paymentId: paymentId,
      planId: planId,
      idempotencyKey: idempotencyKey,
      paymentUrl: paymentUrl,
      createdAt: DateTime.now().toUtc(),
      returnTo: returnTo,
    ));
  }

  Future<void> _writePending(PendingPaymentAttempt pending) async {
    await _secureStorage?.write(
      key: pendingStorageKey,
      value: jsonEncode(<String, dynamic>{
        'payment_id': pending.paymentId,
        'plan_id': pending.planId,
        'idempotency_key': pending.idempotencyKey,
        'payment_url': pending.paymentUrl,
        'created_at': pending.createdAt.toUtc().toIso8601String(),
        'return_to': PremiumNavigation.sanitizeReturnTo(pending.returnTo),
      }),
    );
  }

  Uri _validatedPaymentUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.toLowerCase() != 'my-coolpay.com' ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const PaymentException(
        'Invalid payment URL',
        code: 'invalid_payment_url',
      );
    }
    return uri;
  }

  void _validateIdentifier(String value, {required String code}) {
    if (!_safeIdentifier.hasMatch(value)) {
      throw PaymentException('Invalid payment identifier', code: code);
    }
  }

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    return 'checkout-${hex.join()}';
  }

  PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'succeeded':
      case 'success':
        return PaymentStatus.succeeded;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

class PaymentException implements Exception {
  final String message;
  final String? code;

  const PaymentException(this.message, {this.code});

  @override
  String toString() => message;
}

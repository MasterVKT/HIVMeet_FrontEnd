// lib/data/services/payment_service.dart

import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/premium.dart';

@singleton
class PaymentService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.mycoolpay.com/v1';

  PaymentService(this._dio);

  Future<MyCoolPayResult> initializePayment({
    required int amount,
    required String description,
    required String reference,
    required String callbackUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/payments/initialize',
        data: {
          'amount': amount,
          'currency': 'XOF',
          'description': description,
          'reference': reference,
          'callback_url': callbackUrl,
          'channels': ['MOBILE_MONEY', 'CARD'],
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.mycoolpayApiKey}',
            'Content-Type': 'application/json',
          },
        ),
      );

      return MyCoolPayResult.fromJson(response.data);
    } catch (e) {
      throw PaymentException('Erreur lors de l\'initialisation du paiement');
    }
  }

  Future<MyCoolPayStatus> checkPaymentStatus(String reference) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/payments/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.mycoolpayApiKey}',
          },
        ),
      );

      return MyCoolPayStatus.fromJson(response.data);
    } catch (e) {
      throw PaymentException('Erreur lors de la vérification du paiement');
    }
  }

  Future<PaymentSession> createPaymentSession({
    required String planId,
    required String userId,
  }) async {
    final response = await _dio.post(
      '${AppConstants.mycoolpayBaseUrl}/payment-sessions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.mycoolpayApiKey}',
        },
      ),
      data: {
        'plan_id': planId,
        'user_id': userId,
        'success_url': '${AppConstants.hivmeetAppScheme}://payment/success',
        'cancel_url': '${AppConstants.hivmeetAppScheme}://payment/cancel',
      },
    );

    return PaymentSession(
      sessionId: response.data['session_id'],
      paymentUrl: response.data['payment_url'],
      expiresAt: DateTime.parse(response.data['expires_at']),
    );
  }

  Future<PaymentResult> verifyPayment(String sessionId) async {
    final response = await _dio.get(
      '${AppConstants.mycoolpayBaseUrl}/payment-sessions/$sessionId/verify',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AppConstants.mycoolpayApiKey}',
        },
      ),
    );

    return PaymentResult(
      status: _parsePaymentStatus(response.data['status']),
      subscriptionId: response.data['subscription_id'],
      activatedAt: response.data['activated_at'] != null
          ? DateTime.parse(response.data['activated_at'])
          : null,
      featuresUnlocked:
          List<String>.from(response.data['features_unlocked'] ?? []),
    );
  }

  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
        return PaymentStatus.pending;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }
}

class MyCoolPayResult {
  final String paymentUrl;
  final String reference;
  final String accessCode;

  MyCoolPayResult({
    required this.paymentUrl,
    required this.reference,
    required this.accessCode,
  });

  factory MyCoolPayResult.fromJson(Map<String, dynamic> json) {
    return MyCoolPayResult(
      paymentUrl: json['payment_url'],
      reference: json['reference'],
      accessCode: json['access_code'],
    );
  }
}

class MyCoolPayStatus {
  final String status;
  final int amount;
  final String reference;
  final DateTime? paidAt;

  MyCoolPayStatus({
    required this.status,
    required this.amount,
    required this.reference,
    this.paidAt,
  });

  factory MyCoolPayStatus.fromJson(Map<String, dynamic> json) {
    return MyCoolPayStatus(
      status: json['status'],
      amount: json['amount'],
      reference: json['reference'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
}

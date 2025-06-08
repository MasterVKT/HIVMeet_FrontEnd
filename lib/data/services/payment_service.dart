// lib/data/services/payment_service.dart

import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/config/constants.dart';

@singleton
class PaymentService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.mycoolpay.com/v1';

  PaymentService(this._dio);

  Future<PaymentResult> initializePayment({
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

      return PaymentResult.fromJson(response.data);
    } catch (e) {
      throw PaymentException('Erreur lors de l\'initialisation du paiement');
    }
  }

  Future<PaymentStatus> checkPaymentStatus(String reference) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/payments/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.mycoolpayApiKey}',
          },
        ),
      );

      return PaymentStatus.fromJson(response.data);
    } catch (e) {
      throw PaymentException('Erreur lors de la vérification du paiement');
    }
  }
}

class PaymentResult {
  final String paymentUrl;
  final String reference;
  final String accessCode;

  PaymentResult({
    required this.paymentUrl,
    required this.reference,
    required this.accessCode,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentUrl: json['payment_url'],
      reference: json['reference'],
      accessCode: json['access_code'],
    );
  }
}

class PaymentStatus {
  final String status;
  final int amount;
  final String reference;
  final DateTime? paidAt;

  PaymentStatus({
    required this.status,
    required this.amount,
    required this.reference,
    this.paidAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
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
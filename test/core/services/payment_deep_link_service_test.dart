import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/services/payment_deep_link_service.dart';

void main() {
  test('accepts only the exact hosted-payment return contract', () {
    expect(
      PaymentDeepLinkService.parse(
        Uri.parse('hivmeet://payment/result?status=success'),
      ),
      PaymentReturnKind.success,
    );
    expect(
      PaymentDeepLinkService.parse(
        Uri.parse('hivmeet://payment/result?status=cancelled'),
      ),
      PaymentReturnKind.cancelled,
    );
    expect(
      PaymentDeepLinkService.parse(
        Uri.parse('hivmeet://payment/result?status=failed'),
      ),
      PaymentReturnKind.failed,
    );
  });

  test('rejects extra fields, credentials, fragments and foreign routes', () {
    final invalid = <String>[
      'https://payment/result?status=success',
      'hivmeet://evil/result?status=success',
      'hivmeet://payment/result?status=success&fulfilled=true',
      'hivmeet://user@payment/result?status=success',
      'hivmeet://payment/result?status=success#fragment',
      'hivmeet://payment/result?status=unknown',
    ];

    for (final value in invalid) {
      expect(PaymentDeepLinkService.parse(Uri.parse(value)), isNull);
    }
  });
}

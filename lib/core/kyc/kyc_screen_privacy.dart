import 'package:flutter/services.dart';

/// Enables Android FLAG_SECURE while a KYC view is mounted.
/// iOS intentionally receives a no-op: the page still obscures itself when
/// backgrounded, but the platform does not provide an equivalent public API.
class KycScreenPrivacy {
  static const MethodChannel _channel = MethodChannel('hivmeet/kyc_privacy');

  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
    } on MissingPluginException {
      // Unsupported platforms retain the in-app lifecycle obscuring fallback.
    }
  }
}

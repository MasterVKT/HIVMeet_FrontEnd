import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Premium and currency preference keys stay aligned in FR and EN', () {
    final fr = _readTranslations('fr');
    final en = _readTranslations('en');

    final frPremium = (fr['premium'] as Map<String, dynamic>).keys.toSet();
    final enPremium = (en['premium'] as Map<String, dynamic>).keys.toSet();
    final frProfile = (fr['profile'] as Map<String, dynamic>).keys.toSet();
    final enProfile = (en['profile'] as Map<String, dynamic>).keys.toSet();

    expect(frPremium, enPremium);
    expect(frProfile, enProfile);
    expect(
        frPremium,
        containsAll(<String>{
          'monthly_equivalent',
          'annual_savings',
          'payment_configuration_incomplete',
          'rewind_locked_message',
          'payment_verifying_message',
          'payment_network_message',
          'payment_cancelled_message',
          'payment_failed_message',
          'payment_abandoned_message',
        }));
    expect(
        frProfile,
        containsAll(<String>{
          'currency_auto',
          'currency_xaf',
          'currency_eur',
          'currency_effective',
        }));
  });
}

Map<String, dynamic> _readTranslations(String language) {
  final raw = File('assets/translations/$language.json').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

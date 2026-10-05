import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';

void main() {
  test('only allows known local Premium return destinations', () {
    expect(
      PremiumNavigation.location(returnTo: '/likes-received'),
      '/premium?returnTo=%2Flikes-received',
    );
    expect(PremiumNavigation.sanitizeReturnTo('/discovery'), '/discovery');
    expect(PremiumNavigation.sanitizeReturnTo('/profile'), '/profile');
    expect(
      PremiumNavigation.sanitizeReturnTo('https://attacker.example'),
      isNull,
    );
    expect(PremiumNavigation.sanitizeReturnTo('/chat/secret'), isNull);
  });
}

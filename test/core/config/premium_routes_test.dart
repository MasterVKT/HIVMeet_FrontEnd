import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/routes.dart';

void main() {
  test('Premium has one canonical route and redirects the legacy route', () {
    expect(AppRoutes.premium, '/premium');
    expect(AppRoutes.legacySubscription, '/subscription');
    expect(
      AppRoutes.redirectLegacyPremium(AppRoutes.legacySubscription),
      AppRoutes.premium,
    );
    expect(AppRoutes.redirectLegacyPremium(AppRoutes.premium), isNull);
  });
}

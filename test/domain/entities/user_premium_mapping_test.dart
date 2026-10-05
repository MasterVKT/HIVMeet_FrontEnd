import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/user.dart';

void main() {
  test('maps authoritative snake_case Premium fields from Django', () {
    final user = User.fromJson({
      'id': 'user-id',
      'email': 'user@example.test',
      'display_name': 'Test user',
      'is_verified': true,
      'is_premium': true,
      'premium_until': DateTime.now()
          .toUtc()
          .add(const Duration(days: 30))
          .toIso8601String(),
      'last_active': '2026-09-13T08:00:00Z',
      'date_joined': '2026-01-01T08:00:00Z',
      'updated_at': '2026-09-13T08:00:00Z',
    });

    expect(user.displayName, 'Test user');
    expect(user.isVerified, isTrue);
    expect(user.isPremiumActive, isTrue);
  });

  test('a Django refresh overrides stale cached premium values', () {
    final user = User.fromJson({
      'id': 'user-id',
      'email': 'user@example.test',
      'displayName': 'Cached name',
      'display_name': 'Server name',
      'isVerified': false,
      'is_verified': true,
      'isPremium': false,
      'is_premium': true,
      'premiumUntil': null,
      'premium_until': '2030-01-02T03:04:05Z',
      'lastActive': '2026-01-01T00:00:00Z',
      'last_active': '2026-01-02T00:00:00Z',
      'isEmailVerified': true,
      'notificationSettings': const <String, dynamic>{},
      'blockedUserIds': const <String>['cached-user'],
      'blocked_user_ids': const <String>['server-user'],
      'createdAt': '2025-01-01T00:00:00Z',
      'date_joined': '2025-01-02T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-02T00:00:00Z',
    });

    expect(user.displayName, 'Server name');
    expect(user.isVerified, isTrue);
    expect(user.isPremium, isTrue);
    expect(user.premiumUntil, DateTime.parse('2030-01-02T03:04:05Z'));
    expect(user.blockedUserIds, const ['server-user']);
  });
}

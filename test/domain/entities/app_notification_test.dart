import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';

void main() {
  group('AppNotification.fromBackendJson type mapping', () {
    // Regression test: the backend sends snake_case `type` values
    // (notifications/payloads.py, matching/signals.py), but
    // `AppNotificationType.values.byName(...)` expects Dart's camelCase enum
    // names. Only `'like'` happened to match both — every other type fell
    // back to `system` and silently dropped out of any count filtering by
    // type (e.g. the Matches tab badge).
    const cases = {
      'new_match': AppNotificationType.newMatch,
      'new_message': AppNotificationType.newMessage,
      'message_read': AppNotificationType.messageRead,
      'like': AppNotificationType.like,
      'super_like': AppNotificationType.superLike,
      'subscription_expiring': AppNotificationType.subscriptionExpiring,
      'report_resolved': AppNotificationType.reportResolved,
    };

    cases.forEach((backendType, expected) {
      test('maps "$backendType" to $expected', () {
        final notification = AppNotification.fromBackendJson({
          'id': 'n1',
          'type': backendType,
          'title': 't',
          'body': 'b',
          'created_at': '2026-09-18T10:00:00Z',
          'is_read': false,
        });

        expect(notification.type, expected);
      });
    });

    test('falls back to system for an unknown or missing type', () {
      final notification = AppNotification.fromBackendJson({
        'id': 'n2',
        'type': 'something_new_the_client_does_not_know',
        'title': 't',
        'body': 'b',
        'created_at': '2026-09-18T10:00:00Z',
      });

      expect(notification.type, AppNotificationType.system);
    });
  });

  group('AppNotification.fromJson (local store round-trip)', () {
    test('round-trips every type through toJson/fromJson unchanged', () {
      for (final type in AppNotificationType.values) {
        final original = AppNotification(
          id: 'n3',
          type: type,
          title: 't',
          body: 'b',
          createdAt: DateTime.utc(2026, 9, 18, 10),
        );

        final restored = AppNotification.fromJson(original.toJson());

        expect(restored.type, type);
      }
    });
  });
}

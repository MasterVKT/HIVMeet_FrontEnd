import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/notifications/notification_read_policy.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';

void main() {
  group('NotificationReadPolicy.shouldMarkReadOnTap', () {
    test('keeps a Premium read receipt unread when it opens its chat', () {
      expect(
        NotificationReadPolicy.shouldMarkReadOnTap(
          AppNotificationType.messageRead,
        ),
        isFalse,
      );
    });

    test('acknowledges only a new-message notification when opening a chat',
        () {
      expect(
        NotificationReadPolicy.shouldMarkReadOnTap(
          AppNotificationType.newMessage,
        ),
        isTrue,
      );
      expect(
        NotificationReadPolicy.shouldMarkReadOnTap(
          AppNotificationType.newMatch,
        ),
        isFalse,
      );
    });
  });
}

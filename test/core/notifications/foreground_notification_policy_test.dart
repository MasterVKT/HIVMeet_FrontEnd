import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/notifications/foreground_notification_policy.dart';

void main() {
  group('ForegroundNotificationPolicy', () {
    test('suppresses only a new message for the exact open conversation', () {
      expect(
        ForegroundNotificationPolicy.shouldSuppress(
          data: const {
            'type': 'new_message',
            'conversation_id': 'conversation-1',
          },
          activeConversationId: 'conversation-1',
        ),
        isTrue,
      );
    });

    test('keeps the popup on the conversations list and another conversation',
        () {
      const data = {
        'type': 'new_message',
        'conversation_id': 'conversation-1',
      };

      expect(
        ForegroundNotificationPolicy.shouldSuppress(
          data: data,
          activeConversationId: null,
        ),
        isFalse,
      );
      expect(
        ForegroundNotificationPolicy.shouldSuppress(
          data: data,
          activeConversationId: 'conversation-2',
        ),
        isFalse,
      );
    });

    test('never hides a read receipt or another notification type', () {
      for (final type in const ['like', 'message_read']) {
        expect(
          ForegroundNotificationPolicy.shouldSuppress(
            data: {'type': type, 'conversation_id': 'conversation-1'},
            activeConversationId: 'conversation-1',
          ),
          isFalse,
        );
      }
    });
  });
}

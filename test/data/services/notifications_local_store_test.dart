import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/services/notifications_local_store.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppNotification _notification(String id) => AppNotification(
      id: id,
      type: AppNotificationType.newMessage,
      title: 'Title',
      body: 'Body',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps every notification when simultaneous writes occur', () async {
    final store = NotificationsLocalStore();

    await Future.wait([
      store.add(_notification('notification-1')),
      store.add(_notification('notification-2')),
    ]);

    final saved = await store.load();

    expect(
      saved.map((notification) => notification.id),
      containsAll(['notification-1', 'notification-2']),
    );
  });

  test('preserves read state when a duplicate arrives from a second channel',
      () async {
    final store = NotificationsLocalStore();

    await store.add(_notification('notification-1'));
    await store.markRead('notification-1');
    await store.add(_notification('notification-1'));

    expect((await store.load()).single.isRead, isTrue);
  });
}

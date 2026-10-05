import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/data/datasources/remote/notification_api.dart';
import 'package:hivmeet/data/services/notifications_local_store.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_event.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

class MockMessageRepository extends Mock implements MessageRepository {}

class MockNotificationApi extends Mock implements NotificationApi {}

Stream<NotificationsLoaded> _loadedStates(NotificationsBloc bloc) => bloc.stream
    .where((state) => state is NotificationsLoaded)
    .cast<NotificationsLoaded>();

void main() {
  late NotificationsBloc bloc;
  late RealtimeEventBus realtimeBus;
  late MockNotificationApi notificationApi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    realtimeBus = RealtimeEventBus();
    notificationApi = MockNotificationApi();
    when(() => notificationApi.getNotifications())
        .thenAnswer((_) async => const []);
    when(() => notificationApi.markAsRead(any())).thenAnswer((_) async {});
    when(() => notificationApi.markAllAsRead()).thenAnswer((_) async => 0);
    when(() => notificationApi.deleteNotification(any()))
        .thenAnswer((_) async {});
    when(() => notificationApi.deleteAllNotifications())
        .thenAnswer((_) async => 0);
    bloc = NotificationsBloc(
      store: NotificationsLocalStore(),
      matchRepository: MockMatchRepository(),
      messageRepository: MockMessageRepository(),
      realtimeBus: realtimeBus,
      notificationApi: notificationApi,
    );
  });

  tearDown(() async {
    await bloc.close();
    realtimeBus.dispose();
  });

  test(
      'un message WebSocket incrémente puis le marquage de la conversation vide le badge',
      () async {
    final newMessageState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 1);

    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      fromUserId: 'sender-1',
      messageId: 'message-1',
      preview: 'Bonjour',
    )));

    final loaded = await newMessageState;
    expect(loaded.notifications, hasLength(1));
    expect(loaded.notifications.single.id, 'message_message-1');
    expect(loaded.notifications.single.isRead, isFalse);
    expect(loaded.notifications.single.data['message_id'], 'message-1');
    expect(loaded.notifications.single.data['from_user_id'], 'sender-1');

    final readState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 0);
    bloc.add(const ConversationNotificationsRead('conversation-1'));

    final read = await readState;
    expect(read.notifications.single.isRead, isTrue);
  });

  test('marquer toutes les notifications comme lues supprime le badge',
      () async {
    final loadedState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 1);
    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-1',
    )));
    await loadedState;

    final readState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 0);
    bloc.add(const MarkAllNotificationsRead());

    expect((await readState).notifications.single.isRead, isTrue);
  });

  test('deux messages distincts gardent chacun leur notification', () async {
    final loadedState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 2);

    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-1',
    ));
    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-2',
    ));

    final loaded = await loadedState;
    expect(
      loaded.notifications.map((notification) => notification.id),
      containsAll(<String>['message_message-1', 'message_message-2']),
    );
    expect(
      loaded.notifications
          .map((notification) => notification.data['message_id']),
      containsAll(<String>['message-1', 'message-2']),
    );
  });

  test('un ancien payload sans message_id utilise un repli stable', () async {
    final loadedState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 1);

    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-legacy',
    )));

    final loaded = await loadedState;
    expect(loaded.notifications.single.id, 'message_conversation-legacy');
    expect(loaded.notifications.single.data.containsKey('message_id'), isFalse);
  });

  test('la notification canonique remplace le doublon legacy du même message',
      () async {
    const notificationId = '8b1a9953-c461-4f36-9c2b-2a2f9c379f10';
    final legacyLoaded =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 1);
    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      preview: 'Bonjour',
    )));
    await legacyLoaded;

    final canonicalLoaded = _loadedStates(bloc).firstWhere(
      (state) =>
          state.notifications.length == 1 &&
          state.notifications.single.id == notificationId,
    );
    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      notificationId: notificationId,
      senderName: 'Marie',
      preview: 'Bonjour',
    )));

    final loaded = await canonicalLoaded;
    expect(loaded.unreadCount, 1);
    expect(loaded.notifications.single.title, 'Marie');
    expect(loaded.notifications.single.data['message_id'], 'message-1');
  });

  test('un like conserve l UUID backend pour le marquage REST', () async {
    const notificationId = '8b1a9953-c461-4f36-9c2b-2a2f9c379f10';
    final loadedState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 1);

    bloc.add(const RealtimeNotificationReceived(RealtimeEvent(
      type: RealtimeEventType.likeReceived,
      source: RealtimeSource.websocket,
      fromUserId: 'liker-1',
      notificationId: notificationId,
    )));

    final loaded = await loadedState;
    expect(loaded.notifications.single.id, notificationId);
    expect(
      loaded.notifications.single.data['notification_id'],
      notificationId,
    );

    final readState =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 0);
    bloc.add(const MarkNotificationRead(notificationId));
    expect((await readState).notifications.single.isRead, isTrue);
    verify(() => notificationApi.markAsRead(notificationId)).called(1);
  });

  test('l ouverture de conversation laisse non lue l alerte Premium de lecture',
      () async {
    const alertId = '8b1a9953-c461-4f36-9c2b-2a2f9c379f10';
    final initial = _loadedStates(bloc).firstWhere(
      (state) => state.notifications.length == 2,
    );
    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.newMessage,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      messageId: 'message-1',
    ));
    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.messageReadAlert,
      source: RealtimeSource.websocket,
      conversationId: 'conversation-1',
      fromUserId: 'reader-1',
      readerName: 'Reader',
      messageId: 'message-1',
      messageCount: 2,
      notificationId: alertId,
    ));
    await initial;

    final afterOpening = _loadedStates(bloc).firstWhere(
      (state) =>
          state.unreadCount == 1 &&
          state.notifications.any(
            (notification) =>
                notification.id == alertId && !notification.isRead,
          ),
    );
    bloc.add(const ConversationNotificationsRead('conversation-1'));

    final state = await afterOpening;
    final alert = state.notifications.singleWhere(
      (notification) => notification.id == alertId,
    );
    expect(alert.type, AppNotificationType.messageRead);
    expect(alert.data['message_count'], 2);
    expect(alert.isRead, isFalse);
  });

  test('le badge utilise le total non lu autoritatif du serveur', () async {
    when(() => notificationApi.getUnreadCount()).thenAnswer((_) async => 7);
    final loaded =
        _loadedStates(bloc).firstWhere((state) => state.unreadCount == 7);

    bloc.add(const LoadNotifications());

    expect((await loaded).unreadCount, 7);
    verify(() => notificationApi.getUnreadCount()).called(1);
  });
}

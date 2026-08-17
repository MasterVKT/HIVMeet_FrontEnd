import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/data/services/notifications_local_store.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_event.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

class MockMessageRepository extends Mock implements MessageRepository {}

Stream<NotificationsLoaded> _loadedStates(NotificationsBloc bloc) => bloc.stream
    .where((state) => state is NotificationsLoaded)
    .cast<NotificationsLoaded>();

void main() {
  late NotificationsBloc bloc;
  late RealtimeEventBus realtimeBus;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    realtimeBus = RealtimeEventBus();
    bloc = NotificationsBloc(
      store: NotificationsLocalStore(),
      matchRepository: MockMatchRepository(),
      messageRepository: MockMessageRepository(),
      realtimeBus: realtimeBus,
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
}

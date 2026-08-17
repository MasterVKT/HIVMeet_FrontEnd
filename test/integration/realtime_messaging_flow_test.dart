// test/integration/realtime_messaging_flow_test.dart
//
// Test d'intégration bout-en-bout du temps réel messagerie : un faux serveur
// WebSocket alimente NotificationWebSocketService, qui publie sur le
// RealtimeEventBus réel, consommé simultanément par ConversationsBloc (liste)
// et UnreadCubit (badge) — les deux classes de production, pas des doublures.
//
// Note de portée : la couche FCM n'est pas exercée via le vrai plugin
// firebase_messaging ici (construire un `RemoteMessage` et initialiser
// `FirebaseMessaging` dans un test hors device est fragile et hors sujet :
// le mapping payload→RealtimeEvent de `NotificationService._publishRealtimeEvent`
// est un simple switch sur les mêmes clés déjà couvertes par
// `notification_websocket_service_test.dart`). On simule son effet en
// publiant directement un `RealtimeEvent(source: fcm)` sur le bus, ce qui
// suffit à exercer ce que ce test cible réellement : la convergence
// WS+FCM→bus→BLoCs, la déduplication, et l'absence de flash de chargement.

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/notification_websocket_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/message/delete_conversation.dart'
    as delete_conversation;
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/get_unread_count.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/presentation/blocs/unread/unread_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationService extends Mock implements AuthenticationService {}

class MockGetConversations extends Mock implements GetConversations {}

class MockGetUnreadCount extends Mock implements GetUnreadCount {}

class MockSendMessage extends Mock implements SendMessage {}

class MockMarkAsRead extends Mock implements MarkAsRead {}

class MockDeleteConversation extends Mock
    implements delete_conversation.DeleteConversation {}

Either<Failure, ConversationListPage> _rightPage(List<Conversation> items) {
  return Right(ConversationListPage(conversations: items, hasMore: false));
}

Conversation _conv({
  required String id,
  required int unread,
  DateTime? updatedAt,
  String content = 'Hello',
}) {
  return Conversation(
    id: id,
    participantIds: const ['me', 'other'],
    otherUserId: 'other',
    otherUserName: 'Other User',
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    unreadCount: unread,
    lastMessage: Message(
      id: 'msg_$id',
      conversationId: id,
      senderId: 'other',
      content: content,
      type: MessageType.text,
      createdAt: updatedAt ?? DateTime(2026, 1, 1),
      status: MessageStatus.sent,
    ),
  );
}

void main() {
  group(
      'Realtime messaging flow (WS + FCM -> bus -> ConversationsBloc/UnreadCubit)',
      () {
    late RealtimeEventBus bus;
    late MockAuthenticationService authService;
    // ConversationsBloc et UnreadCubit reçoivent chacun leur propre mock
    // (en production, ConversationsBloc utilise GetConversations et
    // UnreadCubit utilise GetUnreadCount — deux use cases distincts qui
    // partagent le même repository sous-jacent). Ici on les sépare pour
    // vérifier indépendamment que CHAQUE consommateur ne déclenche qu'un
    // seul appel réseau par rafale d'événements.
    late MockGetConversations getConversationsForList;
    late MockGetUnreadCount getUnreadCountForBadge;
    late MockSendMessage sendMessage;
    late MockMarkAsRead markAsRead;
    late MockDeleteConversation deleteConversation;
    late ConversationsBloc conversationsBloc;
    late UnreadCubit unreadCubit;
    late HttpServer wsServer;
    late NotificationWebSocketService notificationWs;

    setUp(() async {
      registerFallbackValue(GetConversationsParams.initial());
      registerFallbackValue(NoParams());

      bus = RealtimeEventBus(dedupeWindow: const Duration(milliseconds: 500));
      authService = MockAuthenticationService();
      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');

      getConversationsForList = MockGetConversations();
      getUnreadCountForBadge = MockGetUnreadCount();
      sendMessage = MockSendMessage();
      markAsRead = MockMarkAsRead();
      deleteConversation = MockDeleteConversation();

      conversationsBloc = ConversationsBloc(
        getConversations: getConversationsForList,
        sendMessage: sendMessage,
        markAsRead: markAsRead,
        deleteConversation: deleteConversation,
        realtimeBus: bus,
      );
      unreadCubit = UnreadCubit(
        getUnreadCount: getUnreadCountForBadge,
        realtimeBus: bus,
      );

      wsServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      notificationWs = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${wsServer.address.address}:${wsServer.port}',
      );
    });

    tearDown(() async {
      notificationWs.dispose();
      await wsServer.close(force: true);
      await conversationsBloc.close();
      await unreadCubit.close();
      bus.dispose();
    });

    test(
        'a new_message WS event patches the list optimistically (no loading flash), '
        'then reconciles with the server value, and updates the badge',
        () async {
      // Chargement initial : conv_1 sans non-lu, conv_2 avec 1 non-lu.
      final initial = [
        _conv(id: 'conv_1', unread: 0, updatedAt: DateTime(2026, 1, 1)),
        _conv(id: 'conv_2', unread: 1, updatedAt: DateTime(2026, 1, 2)),
      ];
      when(() => getConversationsForList(any()))
          .thenAnswer((_) async => _rightPage(initial));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(1));
      conversationsBloc.add(const LoadConversations());
      await conversationsBloc.stream
          .firstWhere((s) => s is ConversationsLoaded);
      await unreadCubit.refresh();
      expect(unreadCubit.state, 1);

      // Le serveur reçoit désormais un nouveau message sur conv_1 : la
      // réconciliation (débouncée) le reflétera avec unreadCount=2, aussi
      // bien pour la liste que pour le badge (deux consommateurs
      // indépendants du même bus, donc chacun reréconcilie).
      final updated = [
        _conv(
            id: 'conv_1',
            unread: 2,
            updatedAt: DateTime(2026, 1, 3),
            content: 'New message!'),
        _conv(id: 'conv_2', unread: 1, updatedAt: DateTime(2026, 1, 2)),
      ];
      when(() => getConversationsForList(any()))
          .thenAnswer((_) async => _rightPage(updated));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(3));

      final states = <ConversationsState>[];
      final sub = conversationsBloc.stream.listen(states.add);
      addTearDown(sub.cancel);

      // Un client WS notifications se connecte et reçoit l'événement.
      final wsSub = WebSocketTransformer().bind(wsServer).listen((socket) {
        socket.add(jsonEncode({
          'type': 'new_message',
          'conversation_id': 'conv_1',
          'from_user_id': 'other',
          'preview': 'New message!',
        }));
      });
      addTearDown(wsSub.cancel);
      await notificationWs.connect();

      // Patch optimiste quasi immédiat : conv_1 remonte en tête avec un
      // non-lu incrémenté, sans jamais passer par ConversationsLoading.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(states, isNot(contains(isA<ConversationsLoading>())));
      final optimisticState = conversationsBloc.state as ConversationsLoaded;
      expect(optimisticState.conversations.first.id, 'conv_1');
      expect(optimisticState.conversations.first.unreadCount, 1);

      // Réconciliation débouncée (600ms côté bloc) : le compte serveur
      // (2) fait autorité.
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      final reconciledState = conversationsBloc.state as ConversationsLoaded;
      final conv1 =
          reconciledState.conversations.firstWhere((c) => c.id == 'conv_1');
      expect(conv1.unreadCount, 2);

      // Le badge global suit lui aussi la valeur serveur (2 + 1 = 3).
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(unreadCubit.state, 3);
    });

    test(
        'the same message delivered via both WebSocket and FCM only triggers '
        'one reconciliation call per consumer (dedup)', () async {
      when(() => getConversationsForList(any())).thenAnswer(
          (_) async => _rightPage([_conv(id: 'conv_1', unread: 0)]));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(0));
      conversationsBloc.add(const LoadConversations());
      await conversationsBloc.stream
          .firstWhere((s) => s is ConversationsLoaded);
      clearInteractions(getConversationsForList);
      clearInteractions(getUnreadCountForBadge);
      when(() => getConversationsForList(any())).thenAnswer(
          (_) async => _rightPage([_conv(id: 'conv_1', unread: 1)]));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(1));

      // Le WebSocket livre l'événement en premier...
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv_1',
        fromUserId: 'other',
        preview: 'Hi',
      ));
      // ...puis le push FCM livre le même message quelques millisecondes
      // plus tard (chemin de livraison indépendant côté backend).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.fcm,
        conversationId: 'conv_1',
        fromUserId: 'other',
        preview: 'Hi',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));

      // Sans la déduplication au niveau du bus, chaque consommateur aurait
      // vu DEUX signaux (un par canal) et aurait donc réconcilié deux fois.
      verify(() => getConversationsForList(any())).called(1);
      verify(() => getUnreadCountForBadge(any())).called(1);
    });

    test(
        'conversationRead (published by ChatBloc after marking read) '
        'brings the badge back down', () async {
      when(() => getConversationsForList(any())).thenAnswer(
          (_) async => _rightPage([_conv(id: 'conv_1', unread: 3)]));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(3));
      await unreadCubit.refresh();
      expect(unreadCubit.state, 3);

      when(() => getConversationsForList(any())).thenAnswer(
          (_) async => _rightPage([_conv(id: 'conv_1', unread: 0)]));
      when(() => getUnreadCountForBadge(any()))
          .thenAnswer((_) async => const Right(0));

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.conversationRead,
        source: RealtimeSource.local,
        conversationId: 'conv_1',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(unreadCubit.state, 0);
    });
  });
}

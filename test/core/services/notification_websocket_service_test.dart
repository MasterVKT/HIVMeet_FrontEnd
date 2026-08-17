// test/core/services/notification_websocket_service_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/notification_websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationService extends Mock implements AuthenticationService {}

void main() {
  group('NotificationWebSocketService', () {
    late MockAuthenticationService authService;
    late RealtimeEventBus bus;

    setUp(() {
      authService = MockAuthenticationService();
      bus = RealtimeEventBus();
    });

    tearDown(() {
      bus.dispose();
    });

    test('does not connect when no access token is available', () async {
      when(() => authService.getAccessToken()).thenAnswer((_) async => null);
      final service = NotificationWebSocketService(authService, bus);
      addTearDown(service.dispose);

      await service.connect();

      expect(service.isConnected, isFalse);
    });

    test('parses new_match with flat keys', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen((socket) {
        socket.add(jsonEncode({
          'type': 'new_match',
          'match_id': 'match-1',
          'matched_user_id': 'user-2',
        }));
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      final received = bus.events.firstWhere(
        (event) => event.type == RealtimeEventType.newMatch,
      );
      await service.connect();

      final event = await received.timeout(const Duration(seconds: 2));
      expect(event.matchId, 'match-1');
      expect(event.fromUserId, 'user-2');
      expect(event.source, RealtimeSource.websocket);
    });

    test('parses like with string is_super field ignored, keeps fromUserId',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen((socket) {
        socket.add(jsonEncode({
          'type': 'like',
          'from_user_id': 'liker-1',
          'like_id': 'like-1',
          'is_super': 'false',
        }));
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      final received = bus.events.firstWhere(
        (event) => event.type == RealtimeEventType.likeReceived,
      );
      await service.connect();

      final event = await received.timeout(const Duration(seconds: 2));
      expect(event.fromUserId, 'liker-1');
    });

    test('parses new_message with its stable message_id', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen((socket) {
        socket.add(jsonEncode({
          'type': 'new_message',
          'conversation_id': 'conv-1',
          'message_id': 'message-1',
          'from_user_id': 'sender-1',
          'preview': 'Hello there',
        }));
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      final received = bus.events.firstWhere(
        (event) => event.type == RealtimeEventType.newMessage,
      );
      await service.connect();

      final event = await received.timeout(const Duration(seconds: 2));
      expect(event.conversationId, 'conv-1');
      expect(event.messageId, 'message-1');
      expect(event.fromUserId, 'sender-1');
      expect(event.preview, 'Hello there');
    });

    test('connect is idempotent while already connected', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen((_) {});
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      await service.connect();
      await service.connect();

      verify(() => authService.getAccessToken()).called(1);
    });

    test(
        'reconnects automatically after an unexpected disconnect, '
        'fetching a fresh token', () async {
      // Synchronisation par flux plutôt que par compteur + délai fixe : un
      // `expect(counter, ...)` juste après `await service.connect()` course
      // contre le serveur (le client peut considérer la socket ouverte
      // avant que le listener serveur n'ait incrémenté son propre état).
      final connections = StreamController<WebSocket>.broadcast();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen(connections.add);
      addTearDown(() async {
        await sub.cancel();
        await connections.close();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      final firstConnection =
          connections.stream.first.timeout(const Duration(seconds: 2));
      final secondConnection =
          connections.stream.skip(1).first.timeout(const Duration(seconds: 5));

      await service.connect();
      final socket = await firstConnection;

      // Coupure côté serveur, non voulue par le client.
      await socket.close();

      // Le premier backoff est de 1s ; le timeout ci-dessus laisse une
      // marge généreuse au-delà de ça.
      await secondConnection;

      verify(() => authService.getAccessToken())
          .called(greaterThanOrEqualTo(2));
    });

    test('disconnect() prevents any automatic reconnection', () async {
      final connections = StreamController<WebSocket>.broadcast();
      var connectionCount = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = WebSocketTransformer().bind(server).listen((socket) {
        connectionCount++;
        connections.add(socket);
      });
      addTearDown(() async {
        await sub.cancel();
        await connections.close();
        await server.close(force: true);
      });

      when(() => authService.getAccessToken()).thenAnswer((_) async => 'jwt');
      final service = NotificationWebSocketService(
        authService,
        bus,
        websocketUrl: 'ws://${server.address.address}:${server.port}',
      );
      addTearDown(service.dispose);

      final firstConnection =
          connections.stream.first.timeout(const Duration(seconds: 2));
      await service.connect();
      final socket = await firstConnection;
      expect(connectionCount, 1);

      service.disconnect();
      await socket.close();
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(connectionCount, 1,
          reason: 'An intentional disconnect must not trigger a reconnect');
    });
  });
}

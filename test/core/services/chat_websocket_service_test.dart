import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/services/chat_websocket_service.dart';

void main() {
  test('publishes message.read as a typed WebSocket event', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final websocketSubscription = WebSocketTransformer().bind(server).listen(
      (socket) {
        socket.add(jsonEncode({
          'type': 'message.read',
          'reader_id': 'reader-1',
          'message_ids': ['message-1'],
          'read_at': '2026-07-25T15:00:00.000000Z',
        }));
      },
    );
    final service = ChatWebSocketService(
      websocketUrl: 'ws://${server.address.address}:${server.port}',
    );
    addTearDown(() async {
      service.dispose();
      await websocketSubscription.cancel();
      await server.close(force: true);
    });

    final received = service.events.firstWhere(
      (event) => event.type == WsEventType.messageRead,
    );
    await service.connect(conversationId: 'conversation-1', token: 'jwt');

    final event = await received.timeout(const Duration(seconds: 2));
    expect(event.type, WsEventType.messageRead);
    expect(event.data['reader_id'], 'reader-1');
    expect(event.data['message_ids'], ['message-1']);
  });
}

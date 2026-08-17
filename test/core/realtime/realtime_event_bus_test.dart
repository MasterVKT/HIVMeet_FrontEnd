// test/core/realtime/realtime_event_bus_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';

void main() {
  group('RealtimeEventBus', () {
    late RealtimeEventBus bus;

    setUp(() {
      bus = RealtimeEventBus(dedupeWindow: const Duration(milliseconds: 50));
    });

    tearDown(() {
      bus.dispose();
    });

    test('publishes events to subscribers', () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMatch,
        source: RealtimeSource.websocket,
        matchId: 'match-1',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.type, RealtimeEventType.newMatch);
    });

    test(
        'deduplicates newMessage events for the same conversation within the window',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
      ));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.fcm,
        conversationId: 'conv-1',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1),
          reason: 'WS and FCM delivering the same new message should '
              'collapse into a single bus event');
    });

    test('does not deduplicate newMessage events for different conversations',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
      ));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-2',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
    });

    test('allows a newMessage event again after the dedupe window elapses',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
    });

    test(
        'does NOT deduplicate two distinct newMessage events with different messageIds in the same conversation',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      // Deux messages distincts de la même conversation, à moins de 2s
      // d'intervalle — ne doivent pas être supprimés car le messageId les
      // distingue.
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
        messageId: 'msg-aaa',
      ));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.fcm,
        conversationId: 'conv-1',
        messageId: 'msg-bbb',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2),
          reason: 'Two distinct messages (different messageIds) from the '
              'same conversation must not be deduplicated');
    });

    test(
        'deduplicates the same message (same messageId) arriving via WS and FCM',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'conv-1',
        messageId: 'msg-xyz',
      ));
      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.fcm,
        conversationId: 'conv-1',
        messageId: 'msg-xyz',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1),
          reason: 'The same message (same messageId) delivered via two '
              'channels should collapse into a single bus event');
    });

    test('never deduplicates events without a conversationId (e.g. newMatch)',
        () async {
      final received = <RealtimeEvent>[];
      final sub = bus.events.listen(received.add);
      addTearDown(sub.cancel);

      for (var i = 0; i < 3; i++) {
        bus.publish(const RealtimeEvent(
          type: RealtimeEventType.newMatch,
          source: RealtimeSource.websocket,
        ));
      }
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(3));
    });

    test('tracks the active conversation id', () {
      expect(bus.activeConversationId, isNull);
      bus.setActiveConversation('conv-42');
      expect(bus.activeConversationId, 'conv-42');
      bus.setActiveConversation(null);
      expect(bus.activeConversationId, isNull);
    });

    test('publishing after dispose does not throw', () {
      bus.dispose();
      expect(
        () => bus.publish(const RealtimeEvent(
          type: RealtimeEventType.newMatch,
          source: RealtimeSource.local,
        )),
        returnsNormally,
      );
    });
  });
}

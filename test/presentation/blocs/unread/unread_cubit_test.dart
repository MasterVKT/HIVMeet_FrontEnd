// test/presentation/blocs/unread/unread_cubit_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/message/get_unread_count.dart';
import 'package:hivmeet/presentation/blocs/unread/unread_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUnreadCount extends Mock implements GetUnreadCount {}

void main() {
  group('UnreadCubit', () {
    late MockGetUnreadCount mockGetUnreadCount;
    late RealtimeEventBus bus;
    late UnreadCubit cubit;

    setUp(() {
      mockGetUnreadCount = MockGetUnreadCount();
      bus = RealtimeEventBus();
      registerFallbackValue(NoParams());
    });

    tearDown(() {
      cubit.close();
      bus.dispose();
    });

    test('initial state is 0', () {
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);
      expect(cubit.state, 0);
    });

    test('refresh() emits the unread count from the server', () async {
      when(() => mockGetUnreadCount(any())).thenAnswer(
        (_) async => const Right(5),
      );
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      await cubit.refresh();

      expect(cubit.state, 5);
    });

    test('a newMessage bus event triggers a debounced refresh', () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(1));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.newMessage,
        source: RealtimeSource.websocket,
        conversationId: 'a',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(cubit.state, 1);
    });

    test('bursts of events only trigger a single network call (debounce)',
        () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(1));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      for (var i = 0; i < 5; i++) {
        bus.publish(RealtimeEvent(
          type: RealtimeEventType.newMessage,
          source: RealtimeSource.websocket,
          conversationId: 'conv-$i',
        ));
      }

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      verify(() => mockGetUnreadCount(any())).called(1);
    });

    test('conversationRead triggers a refresh', () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(0));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.conversationRead,
        source: RealtimeSource.local,
        conversationId: 'a',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(cubit.state, 0);
    });

    test('appResumed triggers a refresh', () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(7));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.appResumed,
        source: RealtimeSource.local,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(cubit.state, 7);
    });

    test('likeReceived does not trigger a refresh', () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(1));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.likeReceived,
        source: RealtimeSource.websocket,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 2000));
      verifyNever(() => mockGetUnreadCount(any()));
    });

    test('a failed refresh keeps the previous value', () async {
      when(() => mockGetUnreadCount(any()))
          .thenAnswer((_) async => const Right(4));
      cubit = UnreadCubit(getUnreadCount: mockGetUnreadCount, realtimeBus: bus);
      await cubit.refresh();
      expect(cubit.state, 4);

      when(() => mockGetUnreadCount(any())).thenAnswer(
        (_) async => const Left(NetworkFailure(message: 'network error')),
      );
      await cubit.refresh();

      expect(cubit.state, 4);
    });
  });
}

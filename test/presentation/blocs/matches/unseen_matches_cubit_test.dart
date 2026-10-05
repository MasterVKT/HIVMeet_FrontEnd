import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/match/get_unseen_match_count.dart';
import 'package:hivmeet/domain/usecases/match/mark_matches_seen.dart';
import 'package:hivmeet/presentation/blocs/matches/unseen_matches_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUnseenMatchCount extends Mock implements GetUnseenMatchCount {}

class MockMarkMatchesSeen extends Mock implements MarkMatchesSeen {}

void main() {
  group('UnseenMatchesCubit', () {
    late MockGetUnseenMatchCount getUnseenMatchCount;
    late MockMarkMatchesSeen markMatchesSeen;
    late RealtimeEventBus bus;
    late UnseenMatchesCubit cubit;

    setUp(() {
      getUnseenMatchCount = MockGetUnseenMatchCount();
      markMatchesSeen = MockMarkMatchesSeen();
      bus = RealtimeEventBus();
      registerFallbackValue(NoParams());
      registerFallbackValue(const MarkMatchesSeenParams(['match-1']));
      cubit = UnseenMatchesCubit(
        getUnseenMatchCount: getUnseenMatchCount,
        markMatchesSeen: markMatchesSeen,
        realtimeBus: bus,
      );
    });

    tearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    test('refresh uses the participant-specific count from the server',
        () async {
      when(() => getUnseenMatchCount(any())).thenAnswer(
        (_) async => const Right(3),
      );

      await cubit.refresh();

      expect(cubit.state, 3);
    });

    test('markSeen optimistically clears local rows then reconciles', () async {
      when(() => getUnseenMatchCount(any())).thenAnswer(
        (_) async => const Right(3),
      );
      when(() => markMatchesSeen(any())).thenAnswer(
        (_) async => const Right(1),
      );
      await cubit.refresh();

      await cubit.markSeen(const ['match-1', 'match-2'], 2);

      expect(cubit.state, 1);
      final captured = verify(() => markMatchesSeen(captureAny()))
          .captured
          .single as MarkMatchesSeenParams;
      expect(captured.matchIds, ['match-1', 'match-2']);
    });

    test('match removal reconciles the authoritative count', () async {
      when(() => getUnseenMatchCount(any())).thenAnswer(
        (_) async => const Right(0),
      );

      bus.publish(const RealtimeEvent(
        type: RealtimeEventType.matchRemoved,
        source: RealtimeSource.websocket,
        matchId: 'match-1',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 650));

      expect(cubit.state, 0);
      verify(() => getUnseenMatchCount(any())).called(1);
    });
  });
}

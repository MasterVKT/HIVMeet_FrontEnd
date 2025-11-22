// test/presentation/blocs/discovery/discovery_bloc_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late DiscoveryBloc bloc;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    bloc = DiscoveryBloc(matchRepository: mockRepository);

    // Register fallback values
    registerFallbackValue(const SearchFilters());
  });

  tearDown(() {
    bloc.close();
  });

  final tProfiles = [
    DiscoveryProfile.fromProfile(
      Profile.createBasic(id: 'user_1', displayName: 'Alice', age: 25),
    ),
    DiscoveryProfile.fromProfile(
      Profile.createBasic(id: 'user_2', displayName: 'Bob', age: 30),
    ),
    DiscoveryProfile.fromProfile(
      Profile.createBasic(id: 'user_3', displayName: 'Charlie', age: 28),
    ),
  ];

  final tDailyLimit = DailyLikeLimit(
    totalLikes: 100,
    remainingLikes: 50,
    resetsAt: DateTime.now().add(const Duration(hours: 12)),
  );

  group('DiscoveryBloc', () {
    test('initial state is DiscoveryInitial', () {
      expect(bloc.state, equals(DiscoveryInitial()));
    });

    group('LoadDiscoveryProfiles', () {
      test('should emit [DiscoveryLoading, DiscoveryLoaded] when successful',
          () async {
        // arrange
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            DiscoveryLoading(),
            isA<DiscoveryLoaded>()
                .having((s) => s.currentProfile.id, 'currentProfile', 'user_1')
                .having((s) => s.nextProfiles.length, 'nextProfiles', 2)
                .having((s) => s.canRewind, 'canRewind', false),
          ]),
        );

        // act
        bloc.add(const LoadDiscoveryProfiles());
      });

      test('should emit DiscoveryError when fails', () async {
        // arrange
        const tFailure = ServerFailure(message: 'Failed to load profiles');
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            DiscoveryLoading(),
            const DiscoveryError(message: 'Failed to load profiles'),
          ]),
        );

        // act
        bloc.add(const LoadDiscoveryProfiles());
      });

      test('should emit NoMoreProfiles when empty result', () async {
        // arrange
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Right([]));

        // act
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        expect(bloc.state, isA<NoMoreProfiles>());
      });

      test('should load dailyLimit in background', () async {
        // arrange
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // act
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 500));

        // assert
        final state = bloc.state as DiscoveryLoaded;
        expect(state.dailyLimit, isNotNull);
        expect(state.dailyLimit?.remainingLikes, 50);
      });
    });

    group('SwipeProfile - Like (Right)', () {
      test('should call likeProfile and move to next', () async {
        // arrange - load profiles first
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - swipe
        when(() => mockRepository.likeProfile(any()))
            .thenAnswer((_) async => const Right(SwipeResult(isMatch: false)));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>()
                .having((s) => s.direction, 'direction', SwipeDirection.right),
            isA<DiscoveryLoaded>()
                .having((s) => s.currentProfile.id, 'currentProfile', 'user_2')
                .having((s) => s.canRewind, 'canRewind', true),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.right));
      });

      test('should emit MatchFound when match occurs', () async {
        // arrange - load profiles
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - swipe with match
        when(() => mockRepository.likeProfile(any())).thenAnswer(
          (_) async => const Right(SwipeResult(isMatch: true, matchId: 'match_1')),
        );
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>(),
            isA<MatchFound>()
                .having((s) => s.matchedProfile.id, 'matchedProfile', 'user_1')
                .having((s) => s.matchId, 'matchId', 'match_1'),
            isA<DiscoveryLoaded>(),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.right));
      });

      test('should emit DailyLimitReached when limit reached', () async {
        // arrange - load profiles with limit reached
        final limitReached = DailyLikeLimit(
          totalLikes: 100,
          remainingLikes: 0,
          resetsAt: DateTime.now().add(const Duration(hours: 12)),
        );

        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(limitReached));

        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 500));

        // assert later
        expectLater(
          bloc.stream,
          emits(isA<DailyLimitReached>()
              .having((s) => s.limitInfo.hasReachedLimit, 'hasReachedLimit', true)),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.right));
      });
    });

    group('SwipeProfile - Dislike (Left)', () {
      test('should call dislikeProfile and move to next', () async {
        // arrange - load profiles
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - swipe left
        when(() => mockRepository.dislikeProfile(any()))
            .thenAnswer((_) async => const Right(null));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>()
                .having((s) => s.direction, 'direction', SwipeDirection.left),
            isA<DiscoveryLoaded>()
                .having((s) => s.currentProfile.id, 'currentProfile', 'user_2'),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.left));
      });
    });

    group('SwipeProfile - SuperLike (Up)', () {
      test('should call superLikeProfile and move to next', () async {
        // arrange - load profiles
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - swipe up
        when(() => mockRepository.superLikeProfile(any()))
            .thenAnswer((_) async => const Right(SwipeResult(isMatch: false)));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>()
                .having((s) => s.direction, 'direction', SwipeDirection.up),
            isA<DiscoveryLoaded>(),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.up));
      });
    });

    group('SwipeProfile - Error Handling', () {
      test('should emit DiscoveryError when like fails', () async {
        // arrange - load profiles
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - like fails
        const tFailure = NetworkFailure(message: 'Network error');
        when(() => mockRepository.likeProfile(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>(),
            const DiscoveryError(message: 'Erreur like'),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.right));
      });
    });

    group('RewindLastSwipe', () {
      test('should rewind to previous profile', () async {
        // arrange - load and swipe once
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockRepository.dislikeProfile(any()))
            .thenAnswer((_) async => const Right(null));
        bloc.add(const SwipeProfile(direction: SwipeDirection.left));
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - rewind
        when(() => mockRepository.rewindLastSwipe())
            .thenAnswer((_) async => const Right(null));

        // assert later
        expectLater(
          bloc.stream,
          emits(isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile', 'user_1')
              .having((s) => s.canRewind, 'canRewind', false)),
        );

        // act
        bloc.add(RewindLastSwipe());
      });

      test('should emit error when rewind fails', () async {
        // arrange - load and swipe
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockRepository.dislikeProfile(any()))
            .thenAnswer((_) async => const Right(null));
        bloc.add(const SwipeProfile(direction: SwipeDirection.left));
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - rewind fails
        const tFailure = ServerFailure(message: 'Rewind not allowed');
        when(() => mockRepository.rewindLastSwipe())
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emits(const DiscoveryError(message: 'Rewind not allowed')),
        );

        // act
        bloc.add(RewindLastSwipe());
      });

      test('should not rewind when at first profile', () async {
        // arrange - just load, don't swipe
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // Reset mock to track new calls
        reset(mockRepository);

        // act - try to rewind
        bloc.add(RewindLastSwipe());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should not call repository
        verifyNever(() => mockRepository.rewindLastSwipe());
      });
    });

    group('UpdateFilters', () {
      test('should update filters and reload profiles', () async {
        // arrange
        const tFilters = SearchFilters(
          minAge: 25,
          maxAge: 35,
          maxDistance: 50,
        );

        when(() => mockRepository.updateSearchFilters(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            DiscoveryLoading(),
            isA<DiscoveryLoaded>(),
          ]),
        );

        // act
        bloc.add(const UpdateFilters(filters: tFilters));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockRepository.updateSearchFilters(tFilters)).called(1);
        verify(() => mockRepository.getDiscoveryProfiles(limit: 20)).called(1);
      });

      test('should emit error when update fails', () async {
        // arrange
        const tFilters = SearchFilters();
        const tFailure = ServerFailure(message: 'Failed to update filters');

        when(() => mockRepository.updateSearchFilters(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emits(const DiscoveryError(message: 'Failed to update filters')),
        );

        // act
        bloc.add(const UpdateFilters(filters: tFilters));
      });
    });

    group('NoMoreProfiles', () {
      test('should emit NoMoreProfiles when all profiles swiped', () async {
        // arrange - load only 1 profile
        final singleProfile = [tProfiles.first];
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(singleProfile));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));
        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - swipe the only profile
        when(() => mockRepository.dislikeProfile(any()))
            .thenAnswer((_) async => const Right(null));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileSwiping>(),
            NoMoreProfiles(),
          ]),
        );

        // act
        bloc.add(const SwipeProfile(direction: SwipeDirection.left));
      });
    });

    group('LoadDailyLimit', () {
      test('should load and update dailyLimit in state', () async {
        // arrange - load profiles first
        when(() => mockRepository.getDiscoveryProfiles(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right(tProfiles));
        when(() => mockRepository.getDailyLikeLimit())
            .thenAnswer((_) async => Right(tDailyLimit));

        bloc.add(const LoadDiscoveryProfiles());
        await Future.delayed(const Duration(milliseconds: 500));

        // assert
        final state = bloc.state as DiscoveryLoaded;
        expect(state.dailyLimit, isNotNull);
        expect(state.dailyLimit?.totalLikes, 100);
        expect(state.dailyLimit?.remainingLikes, 50);
      });
    });
  });
}

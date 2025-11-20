// test/presentation/blocs/matches/matches_bloc_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/usecases/match/get_matches.dart';
import 'package:hivmeet/domain/usecases/match/delete_match.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received_count.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMatches extends Mock implements GetMatches {}

class MockDeleteMatch extends Mock implements DeleteMatch {}

class MockGetLikesReceived extends Mock implements GetLikesReceived {}

class MockGetLikesReceivedCount extends Mock implements GetLikesReceivedCount {}

void main() {
  late MatchesBloc bloc;
  late MockGetMatches mockGetMatches;
  late MockDeleteMatch mockDeleteMatch;
  late MockGetLikesReceived mockGetLikesReceived;
  late MockGetLikesReceivedCount mockGetLikesReceivedCount;

  setUp(() {
    mockGetMatches = MockGetMatches();
    mockDeleteMatch = MockDeleteMatch();
    mockGetLikesReceived = MockGetLikesReceived();
    mockGetLikesReceivedCount = MockGetLikesReceivedCount();

    bloc = MatchesBloc(
      getMatches: mockGetMatches,
      deleteMatch: mockDeleteMatch,
      getLikesReceived: mockGetLikesReceived,
      getLikesReceivedCount: mockGetLikesReceivedCount,
    );

    // Register fallback values
    registerFallbackValue(GetMatchesParams.initial());
    registerFallbackValue(const DeleteMatchParams(matchId: 'test'));
    registerFallbackValue(GetLikesReceivedParams.initial());
    registerFallbackValue(NoParams());
  });

  tearDown(() {
    bloc.close();
  });

  final tMatches = [
    Match(
      id: 'match_1',
      matchedProfile: Profile.createBasic(
        id: 'user_1',
        displayName: 'Alice',
        age: 25,
      ),
      matchedAt: DateTime(2024, 1, 20),
      isNew: true,
    ),
    Match(
      id: 'match_2',
      matchedProfile: Profile.createBasic(
        id: 'user_2',
        displayName: 'Bob',
        age: 30,
      ),
      matchedAt: DateTime(2024, 1, 19),
      isNew: false,
    ),
  ];

  group('MatchesBloc', () {
    test('initial state is MatchesInitial', () {
      expect(bloc.state, equals(MatchesInitial()));
    });

    group('LoadMatches', () {
      test('should emit [MatchesLoading, MatchesLoaded] when successful',
          () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(5));

        // assert later
        final expected = [
          MatchesLoading(),
          MatchesLoaded(
            matches: tMatches,
            allMatches: tMatches,
            hasMore: false, // 2 < 20
            newMatchesCount: 1, // Only match_1 is new
            likesReceivedCount: 5,
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(LoadMatches());
      });

      test('should count newMatches correctly', () async {
        // arrange
        final matchesWithNew = [
          Match(
            id: 'match_1',
            matchedProfile: Profile.createBasic(
              id: 'user_1',
              displayName: 'User 1',
              age: 25,
            ),
            matchedAt: DateTime.now(),
            isNew: true,
          ),
          Match(
            id: 'match_2',
            matchedProfile: Profile.createBasic(
              id: 'user_2',
              displayName: 'User 2',
              age: 26,
            ),
            matchedAt: DateTime.now(),
            isNew: true,
          ),
          Match(
            id: 'match_3',
            matchedProfile: Profile.createBasic(
              id: 'user_3',
              displayName: 'User 3',
              age: 27,
            ),
            matchedAt: DateTime.now(),
            isNew: false,
          ),
        ];

        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(matchesWithNew));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        // act
        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as MatchesLoaded;
        expect(state.newMatchesCount, 2);
      });

      test('should set hasMore=true when 20 matches returned', () async {
        // arrange
        final twentyMatches = List.generate(
          20,
          (i) => Match(
            id: 'match_$i',
            matchedProfile: Profile.createBasic(
              id: 'user_$i',
              displayName: 'User $i',
              age: 25,
            ),
            matchedAt: DateTime.now(),
            isNew: false,
          ),
        );

        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(twentyMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            MatchesLoading(),
            isA<MatchesLoaded>().having((s) => s.hasMore, 'hasMore', true),
          ]),
        );

        // act
        bloc.add(LoadMatches());
      });

      test('should load likesReceivedCount in parallel', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(10));

        // act
        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as MatchesLoaded;
        expect(state.likesReceivedCount, 10);
        verify(() => mockGetLikesReceivedCount(NoParams())).called(1);
      });

      test('should default to 0 if likesCount fails', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed')),
        );

        // act
        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as MatchesLoaded;
        expect(state.likesReceivedCount, 0);
      });

      test('should emit MatchesError when fails', () async {
        // arrange
        const tFailure = ServerFailure(message: 'Failed to load matches');
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            MatchesLoading(),
            const MatchesError(message: 'Failed to load matches'),
          ]),
        );

        // act
        bloc.add(LoadMatches());
      });

      test('should reset state when refresh=true', () async {
        // arrange - first load
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // act - refresh
        bloc.add(LoadMatches(refresh: true));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockGetMatches(GetMatchesParams.initial())).called(2);
      });
    });

    group('LoadMoreMatches', () {
      test('should load more matches with pagination', () async {
        // arrange - initial load
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more
        final moreMatches = [
          Match(
            id: 'match_3',
            matchedProfile: Profile.createBasic(
              id: 'user_3',
              displayName: 'Charlie',
              age: 28,
            ),
            matchedAt: DateTime(2024, 1, 18),
            isNew: false,
          ),
        ];
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(moreMatches));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<MatchesLoaded>()
                .having((s) => s.matches.length, 'length', 3)
                .having((s) => s.isLoadingMore, 'isLoadingMore', false),
          ]),
        );

        // act
        bloc.add(LoadMoreMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should use last match ID as cursor
        verify(() => mockGetMatches(any(
              that: isA<GetMatchesParams>().having(
                (p) => p.lastMatchId,
                'lastMatchId',
                'match_2',
              ),
            ))).called(1);
      });

      test('should not load more if already loading', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // Set isLoadingMore to true
        final currentState = bloc.state as MatchesLoaded;
        bloc.emit(currentState.copyWith(isLoadingMore: true));

        // Reset mock
        reset(mockGetMatches);

        // act
        bloc.add(LoadMoreMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should not call getMatches
        verifyNever(() => mockGetMatches(any()));
      });

      test('should emit error when loading more fails', () async {
        // arrange - initial load
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more fails
        const tFailure = NetworkFailure(message: 'No internet');
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<MatchesLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', false),
            const MatchesError(message: 'No internet'),
          ]),
        );

        // act
        bloc.add(LoadMoreMatches());
      });
    });

    group('DeleteMatch - Optimistic Update', () {
      test('should optimistically remove match from list', () async {
        // arrange - load matches
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockDeleteMatch(any()))
            .thenAnswer((_) async => const Right(null));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.matches.length, 'length', 1)
                .having(
                  (s) => s.matches.first.id,
                  'remaining match',
                  'match_2',
                ),
          ]),
        );

        // act
        bloc.add(const DeleteMatchEvent(matchId: 'match_1'));
      });

      test('should update newMatchesCount after delete', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockDeleteMatch(any()))
            .thenAnswer((_) async => const Right(null));

        // act - delete the new match
        bloc.add(const DeleteMatchEvent(matchId: 'match_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as MatchesLoaded;
        expect(state.newMatchesCount, 0); // Was 1, now 0
      });

      test('should call DeleteMatch use case', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockDeleteMatch(any()))
            .thenAnswer((_) async => const Right(null));

        // act
        bloc.add(const DeleteMatchEvent(matchId: 'match_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockDeleteMatch(
              const DeleteMatchParams(matchId: 'match_1'),
            )).called(1);
      });
    });

    group('DeleteMatch - Rollback', () {
      test('should rollback on failure', () async {
        // arrange - load matches
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - delete fails
        const tFailure = ServerFailure(message: 'Failed to delete');
        when(() => mockDeleteMatch(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.matches.length, 'optimistic', 1),
            isA<MatchesLoaded>()
                .having((s) => s.matches.length, 'rollback', 2),
            const MatchesError(message: 'Failed to delete'),
          ]),
        );

        // act
        bloc.add(const DeleteMatchEvent(matchId: 'match_1'));
      });
    });

    group('MarkMatchAsSeen', () {
      test('should mark match as seen locally', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.newMatchesCount, 'newCount', 0)
                .having(
                  (s) => s.matches
                      .firstWhere((m) => m.id == 'match_1')
                      .isNew,
                  'isNew',
                  false,
                ),
          ]),
        );

        // act
        bloc.add(const MarkMatchAsSeen(matchId: 'match_1'));
      });

      test('should not call any API', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // Reset all mocks
        reset(mockGetMatches);
        reset(mockDeleteMatch);
        reset(mockGetLikesReceived);
        reset(mockGetLikesReceivedCount);

        // act
        bloc.add(const MarkMatchAsSeen(matchId: 'match_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - no API calls
        verifyNever(() => mockGetMatches(any()));
        verifyNever(() => mockDeleteMatch(any()));
        verifyNever(() => mockGetLikesReceived(any()));
        verifyNever(() => mockGetLikesReceivedCount(any()));
      });
    });

    group('FilterMatches', () {
      test('should update currentFilter in state', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.currentFilter, 'filter', MatchFilter.newMatches),
          ]),
        );

        // act
        bloc.add(const FilterMatches(filter: MatchFilter.newMatches));
      });

      test('should preserve other state fields', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        final stateBefore = bloc.state as MatchesLoaded;

        // act
        bloc.add(const FilterMatches(filter: MatchFilter.newMatches));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final stateAfter = bloc.state as MatchesLoaded;
        expect(stateAfter.matches, stateBefore.matches);
        expect(stateAfter.allMatches, stateBefore.allMatches);
        expect(stateAfter.hasMore, stateBefore.hasMore);
        expect(stateAfter.newMatchesCount, stateBefore.newMatchesCount);
        expect(stateAfter.currentFilter, MatchFilter.newMatches);
      });
    });

    group('SearchMatches', () {
      test('should update searchQuery in state', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesLoaded>()
                .having((s) => s.searchQuery, 'query', 'alice'),
          ]),
        );

        // act
        bloc.add(const SearchMatches(query: 'alice'));
      });

      test('should preserve other state fields', () async {
        // arrange
        when(() => mockGetMatches(any()))
            .thenAnswer((_) async => Right(tMatches));
        when(() => mockGetLikesReceivedCount(any()))
            .thenAnswer((_) async => const Right(0));

        bloc.add(LoadMatches());
        await Future.delayed(const Duration(milliseconds: 100));

        final stateBefore = bloc.state as MatchesLoaded;

        // act
        bloc.add(const SearchMatches(query: 'test'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final stateAfter = bloc.state as MatchesLoaded;
        expect(stateAfter.matches, stateBefore.matches);
        expect(stateAfter.allMatches, stateBefore.allMatches);
        expect(stateAfter.searchQuery, 'test');
      });
    });

    group('LoadLikesReceived', () {
      test('should emit [LikesReceivedLoading, LikesReceivedLoaded]', () async {
        // arrange
        final profiles = [
          Profile.createBasic(id: 'user_1', displayName: 'User 1', age: 25),
          Profile.createBasic(id: 'user_2', displayName: 'User 2', age: 26),
        ];

        when(() => mockGetLikesReceived(any()))
            .thenAnswer((_) async => Right(profiles));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            LikesReceivedLoading(),
            LikesReceivedLoaded(
              profiles: profiles,
              hasMore: false,
            ),
          ]),
        );

        // act
        bloc.add(LoadLikesReceived());
      });

      test('should set hasMore=true when 20 profiles returned', () async {
        // arrange
        final twentyProfiles = List.generate(
          20,
          (i) => Profile.createBasic(
            id: 'user_$i',
            displayName: 'User $i',
            age: 25,
          ),
        );

        when(() => mockGetLikesReceived(any()))
            .thenAnswer((_) async => Right(twentyProfiles));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            LikesReceivedLoading(),
            isA<LikesReceivedLoaded>()
                .having((s) => s.hasMore, 'hasMore', true),
          ]),
        );

        // act
        bloc.add(LoadLikesReceived());
      });

      test('should emit MatchesError when fails', () async {
        // arrange
        const tFailure =
            ServerFailure(message: 'Failed to load likes received');
        when(() => mockGetLikesReceived(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            LikesReceivedLoading(),
            const MatchesError(message: 'Failed to load likes received'),
          ]),
        );

        // act
        bloc.add(LoadLikesReceived());
      });
    });
  });
}

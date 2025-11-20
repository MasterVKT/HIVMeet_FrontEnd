// test/domain/usecases/match/get_matches_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/get_matches.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late GetMatches usecase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    usecase = GetMatches(mockRepository);
  });

  group('GetMatches', () {
    final tMatches = [
      Match(
        id: '1',
        userId: 'user1',
        matchedUserId: 'user2',
        matchedAt: DateTime.now(),
        isNew: true,
      ),
      Match(
        id: '2',
        userId: 'user1',
        matchedUserId: 'user3',
        matchedAt: DateTime.now(),
        isNew: false,
      ),
    ];

    test('should get matches from repository with default params', () async {
      // arrange
      when(() => mockRepository.getMatches(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tMatches));

      // act
      final result = await usecase(GetMatchesParams.initial());

      // assert
      expect(result, Right(tMatches));
      verify(() => mockRepository.getMatches(limit: 20, lastMatchId: null)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should get matches with custom limit', () async {
      // arrange
      const tLimit = 10;
      when(() => mockRepository.getMatches(limit: tLimit))
          .thenAnswer((_) async => Right(tMatches));

      // act
      final result = await usecase(GetMatchesParams.initial(limit: tLimit));

      // assert
      expect(result, Right(tMatches));
      verify(() => mockRepository.getMatches(limit: tLimit, lastMatchId: null)).called(1);
    });

    test('should get matches with pagination cursor', () async {
      // arrange
      const tLastMatchId = 'match123';
      const tLimit = 20;
      when(() => mockRepository.getMatches(
            limit: tLimit,
            lastMatchId: tLastMatchId,
          )).thenAnswer((_) async => Right(tMatches));

      // act
      final params = GetMatchesParams(limit: tLimit, lastMatchId: tLastMatchId);
      final result = await usecase(params);

      // assert
      expect(result, Right(tMatches));
      verify(() => mockRepository.getMatches(
            limit: tLimit,
            lastMatchId: tLastMatchId,
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.getMatches(limit: any(named: 'limit')))
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await usecase(GetMatchesParams.initial());

      // assert
      expect(result, Left(ServerFailure()));
      verify(() => mockRepository.getMatches(limit: 20, lastMatchId: null)).called(1);
    });

    test('should return CacheFailure when offline and no cache', () async {
      // arrange
      when(() => mockRepository.getMatches(limit: any(named: 'limit')))
          .thenAnswer((_) async => Left(CacheFailure()));

      // act
      final result = await usecase(GetMatchesParams.initial());

      // assert
      expect(result, Left(CacheFailure()));
    });

    test('GetMatchesParams.nextPage should create params with lastMatchId', () {
      // arrange
      const initialParams = GetMatchesParams(limit: 20);
      const tLastMatchId = 'last_match_123';

      // act
      final nextParams = initialParams.nextPage(tLastMatchId);

      // assert
      expect(nextParams.limit, 20);
      expect(nextParams.lastMatchId, tLastMatchId);
    });
  });
}

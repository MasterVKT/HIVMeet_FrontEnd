// test/domain/usecases/match/delete_match_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/delete_match.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late DeleteMatch usecase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    usecase = DeleteMatch(mockRepository);
  });

  group('DeleteMatch', () {
    const tMatchId = 'match123';
    const tParams = DeleteMatchParams(matchId: tMatchId);

    test('should delete match from repository', () async {
      // arrange
      when(() => mockRepository.deleteMatch(any()))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.deleteMatch(tMatchId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should delete match with reason for analytics', () async {
      // arrange
      const tReason = 'not_interested';
      const tParamsWithReason = DeleteMatchParams(
        matchId: tMatchId,
        reason: tReason,
      );
      when(() => mockRepository.deleteMatch(any()))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParamsWithReason);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.deleteMatch(tMatchId)).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.deleteMatch(any()))
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Left(ServerFailure()));
      verify(() => mockRepository.deleteMatch(tMatchId)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // arrange
      when(() => mockRepository.deleteMatch(any()))
          .thenAnswer((_) async => Left(NetworkFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Left(NetworkFailure()));
    });
  });
}

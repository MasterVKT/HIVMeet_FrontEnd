// test/domain/usecases/match/rewind_swipe_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late RewindSwipe usecase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    usecase = RewindSwipe(mockRepository);
  });

  group('RewindSwipe', () {
    final tSwipeResult = SwipeResult(
      isMatch: false,
      matchId: null,
      profileRestored: DiscoveryProfile(
        id: 'restored_profile',
        name: 'Restored User',
        age: 26,
        photos: [],
        distance: 3.0,
      ),
    );

    test('should rewind last swipe via repository', () async {
      // arrange
      when(() => mockRepository.rewindLastSwipe())
          .thenAnswer((_) async => Right(tSwipeResult));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Right(tSwipeResult));
      verify(() => mockRepository.rewindLastSwipe()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return PremiumRequiredFailure when not premium', () async {
      // arrange
      when(() => mockRepository.rewindLastSwipe())
          .thenAnswer((_) async => Left(PremiumRequiredFailure()));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Left(PremiumRequiredFailure()));
      verify(() => mockRepository.rewindLastSwipe()).called(1);
    });

    test('should return DailyLimitReachedFailure when limit exhausted', () async {
      // arrange
      when(() => mockRepository.rewindLastSwipe())
          .thenAnswer((_) async => Left(DailyLimitReachedFailure()));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Left(DailyLimitReachedFailure()));
    });

    test('should return NoSwipeToRewindFailure when no swipe to rewind', () async {
      // arrange
      when(() => mockRepository.rewindLastSwipe())
          .thenAnswer((_) async => Left(NoSwipeToRewindFailure()));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Left(NoSwipeToRewindFailure()));
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.rewindLastSwipe())
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Left(ServerFailure()));
    });
  });
}

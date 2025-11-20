// test/domain/usecases/match/dislike_profile_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late DislikeProfile usecase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    usecase = DislikeProfile(mockRepository);
  });

  group('DislikeProfile', () {
    const tProfileId = 'profile123';
    const tParams = DislikeProfileParams(profileId: tProfileId);

    test('should dislike profile via repository', () async {
      // arrange
      when(() => mockRepository.dislikeProfile(any()))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.dislikeProfile(tProfileId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.dislikeProfile(any()))
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Left(ServerFailure()));
      verify(() => mockRepository.dislikeProfile(tProfileId)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // arrange
      when(() => mockRepository.dislikeProfile(any()))
          .thenAnswer((_) async => Left(NetworkFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Left(NetworkFailure()));
    });
  });
}

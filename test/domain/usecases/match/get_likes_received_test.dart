// test/domain/usecases/match/get_likes_received_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  late GetLikesReceived usecase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    usecase = GetLikesReceived(mockRepository);
  });

  group('GetLikesReceived', () {
    final tProfiles = [
      DiscoveryProfile(
        id: '1',
        name: 'Test User 1',
        age: 25,
        photos: [],
        distance: 5.0,
      ),
      DiscoveryProfile(
        id: '2',
        name: 'Test User 2',
        age: 28,
        photos: [],
        distance: 10.0,
      ),
    ];

    test('should get likes received from repository with default params', () async {
      // arrange
      when(() => mockRepository.getLikesReceived(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tProfiles));

      // act
      final result = await usecase(GetLikesReceivedParams.initial());

      // assert
      expect(result, Right(tProfiles));
      verify(() => mockRepository.getLikesReceived(limit: 20, lastProfileId: null)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should get likes received with custom limit', () async {
      // arrange
      const tLimit = 10;
      when(() => mockRepository.getLikesReceived(limit: tLimit))
          .thenAnswer((_) async => Right(tProfiles));

      // act
      final result = await usecase(GetLikesReceivedParams.initial(limit: tLimit));

      // assert
      expect(result, Right(tProfiles));
      verify(() => mockRepository.getLikesReceived(limit: tLimit, lastProfileId: null)).called(1);
    });

    test('should get likes received with pagination', () async {
      // arrange
      const tLastProfileId = 'profile123';
      const tLimit = 20;
      when(() => mockRepository.getLikesReceived(
            limit: tLimit,
            lastProfileId: tLastProfileId,
          )).thenAnswer((_) async => Right(tProfiles));

      // act
      final params = GetLikesReceivedParams(limit: tLimit, lastProfileId: tLastProfileId);
      final result = await usecase(params);

      // assert
      expect(result, Right(tProfiles));
      verify(() => mockRepository.getLikesReceived(
            limit: tLimit,
            lastProfileId: tLastProfileId,
          )).called(1);
    });

    test('should return PremiumRequiredFailure when not premium', () async {
      // arrange
      when(() => mockRepository.getLikesReceived(limit: any(named: 'limit')))
          .thenAnswer((_) async => Left(PremiumRequiredFailure()));

      // act
      final result = await usecase(GetLikesReceivedParams.initial());

      // assert
      expect(result, Left(PremiumRequiredFailure()));
      verify(() => mockRepository.getLikesReceived(limit: 20, lastProfileId: null)).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      when(() => mockRepository.getLikesReceived(limit: any(named: 'limit')))
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await usecase(GetLikesReceivedParams.initial());

      // assert
      expect(result, Left(ServerFailure()));
    });

    test('GetLikesReceivedParams.nextPage should create params with lastProfileId', () {
      // arrange
      const initialParams = GetLikesReceivedParams(limit: 20);
      const tLastProfileId = 'last_profile_123';

      // act
      final nextParams = initialParams.nextPage(tLastProfileId);

      // assert
      expect(nextParams.limit, 20);
      expect(nextParams.lastProfileId, tLastProfileId);
    });
  });
}

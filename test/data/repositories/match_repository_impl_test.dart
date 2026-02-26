// test/data/repositories/match_repository_impl_test.dart

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';

class MockMatchingApi extends Mock implements MatchingApi {}

void main() {
  late MatchRepositoryImpl repository;
  late MockMatchingApi mockApi;

  setUp(() {
    mockApi = MockMatchingApi();
    repository = MatchRepositoryImpl(mockApi);
  });

  group('MatchRepositoryImpl - getDiscoveryProfiles', () {
    final tResponseData = {
      'results': [
        {
          'user_id': 'profile1',
          'display_name': 'John Doe',
          'age': 30,
          'bio': 'Hello world',
          'city': 'Paris',
          'country': 'France',
          'main_photo_url': 'https://example.com/photo1.jpg',
          'other_photos': ['https://example.com/photo2.jpg'],
          'interests': ['music', 'travel'],
          'relationship_type': 'casual',
          'is_verified': true,
          'is_premium': false,
          'last_active': '2024-02-24T12:00:00Z',
          'compatibility_score': 85.0,
          'distance': 5.2,
        }
      ]
    };

    test('should return list of DiscoveryProfile when API call succeeds', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: tResponseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles.length, 1);
          expect(profiles[0].id, 'profile1');
          expect(profiles[0].displayName, 'John Doe');
          expect(profiles[0].age, 30);
          expect(profiles[0].bio, 'Hello world');
          expect(profiles[0].city, 'Paris');
          expect(profiles[0].isVerified, true);
          expect(profiles[0].isPremium, false);
          expect(profiles[0].compatibilityScore, 85.0);
          expect(profiles[0].distance, 5.2);
        },
      );
    });

    test('should handle alternative response field names (data)', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'data': tResponseData['results']
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles.length, 1);
        },
      );
    });

    test('should handle alternative response field names (profiles)', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'profiles': tResponseData['results']
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles.length, 1);
        },
      );
    });

    test('should handle photos as array of objects with is_main flag', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'results': [
            {
              'user_id': 'profile1',
              'display_name': 'John Doe',
              'age': 30,
              'bio': 'Hello',
              'city': 'Paris',
              'country': 'France',
              'photos': [
                {'photo_url': 'photo1.jpg', 'is_main': true},
                {'photo_url': 'photo2.jpg', 'is_main': false},
              ],
              'interests': ['music'],
              'relationship_type': 'casual',
              'is_verified': false,
              'is_premium': false,
              'last_active': '2024-02-24T12:00:00Z',
              'compatibility_score': 75.0,
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles[0].mainPhotoUrl, contains('photo1.jpg'));
          expect(profiles[0].otherPhotosUrls.length, 1);
        },
      );
    });

    test('should handle photos as simple string array', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'results': [
            {
              'user_id': 'profile1',
              'display_name': 'John Doe',
              'age': 30,
              'bio': 'Hello',
              'city': 'Paris',
              'country': 'France',
              'photos': ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
              'interests': ['music'],
              'relationship_type': 'casual',
              'is_verified': false,
              'is_premium': false,
              'last_active': '2024-02-24T12:00:00Z',
              'compatibility_score': 75.0,
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles[0].mainPhotoUrl, 'photo1.jpg');
          expect(profiles[0].otherPhotosUrls.length, 2);
          expect(profiles[0].otherPhotosUrls[0], 'photo2.jpg');
        },
      );
    });

    test('should handle relationship_types_sought as array', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'results': [
            {
              'user_id': 'profile1',
              'display_name': 'John Doe',
              'age': 30,
              'bio': 'Hello',
              'city': 'Paris',
              'country': 'France',
              'main_photo_url': 'photo.jpg',
              'other_photos': [],
              'interests': ['music'],
              'relationship_types_sought': ['casual', 'serious'],
              'is_verified': false,
              'is_premium': false,
              'last_active': '2024-02-24T12:00:00Z',
              'compatibility_score': 75.0,
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles[0].relationshipType, 'casual');
        },
      );
    });

    test('should handle missing optional fields with defaults', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'results': [
            {
              'user_id': 'profile1',
              'display_name': 'John Doe',
              'age': 30,
              'main_photo_url': 'photo.jpg',
              // Missing: bio, city, country, other_photos, interests, etc.
              'relationship_type': 'casual',
              'is_verified': false,
              'is_premium': false,
              'last_active': '2024-02-24T12:00:00Z',
              'compatibility_score': 75.0,
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (profiles) {
          expect(profiles[0].bio, '');
          expect(profiles[0].city, '');
          expect(profiles[0].country, '');
          expect(profiles[0].otherPhotosUrls, isEmpty);
          expect(profiles[0].interests, isEmpty);
        },
      );
    });

    test('should return ServerFailure when API throws ServerException', () async {
      // arrange
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenThrow(ServerException(message: 'Server error'));

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (profiles) => fail('Should return Left'),
      );
    });

    test('should return ServerFailure on network error', () async {
      // arrange
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/discovery/profiles'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // act
      final result = await repository.getDiscoveryProfiles();

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (profiles) => fail('Should return Left'),
      );
    });

    test('should use custom limit parameter', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {'results': []},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/profiles'),
      );
      when(() => mockApi.getDiscoveryProfiles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      await repository.getDiscoveryProfiles(limit: 10);

      // assert
      verify(() => mockApi.getDiscoveryProfiles(
            page: 1,
            pageSize: 10,
          )).called(1);
    });
  });

  group('MatchRepositoryImpl - likeProfile', () {
    test('should return SwipeResult with isMatch=false when no match', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'result': 'like',
          'daily_likes_remaining': 45,
          'super_likes_remaining': 1,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/like'),
      );
      when(() => mockApi.likeProfile(profileId: any(named: 'profileId')))
          .thenAnswer((_) async => tResponse);

      // act
      final result = await repository.likeProfile('profile123');

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, false);
          expect(swipeResult.matchId, null);
          expect(swipeResult.remainingLikes, 45);
          expect(swipeResult.remainingSuperLikes, 1);
        },
      );
    });

    test('should return SwipeResult with isMatch=true and matchId on match', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'result': 'match',
          'match_id': 'match123',
          'daily_likes_remaining': 44,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/like'),
      );
      when(() => mockApi.likeProfile(profileId: any(named: 'profileId')))
          .thenAnswer((_) async => tResponse);

      // act
      final result = await repository.likeProfile('profile123');

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, true);
          expect(swipeResult.matchId, 'match123');
          expect(swipeResult.remainingLikes, 44);
        },
      );
    });

    test('should return ServerFailure when API throws ServerException', () async {
      // arrange
      when(() => mockApi.likeProfile(profileId: any(named: 'profileId')))
          .thenThrow(ServerException(message: 'Daily limit reached'));

      // act
      final result = await repository.likeProfile('profile123');

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Daily limit reached');
        },
        (swipeResult) => fail('Should return Left'),
      );
    });
  });

  group('MatchRepositoryImpl - superLikeProfile', () {
    test('should return SwipeResult with match on super like match', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'result': 'match',
          'match_id': 'match456',
          'super_likes_remaining': 0,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/superlike'),
      );
      when(() => mockApi.superLikeProfile(profileId: any(named: 'profileId')))
          .thenAnswer((_) async => tResponse);

      // act
      final result = await repository.superLikeProfile('profile123');

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, true);
          expect(swipeResult.matchId, 'match456');
          expect(swipeResult.remainingSuperLikes, 0);
        },
      );
    });

    test('should return ServerFailure on error', () async {
      // arrange
      when(() => mockApi.superLikeProfile(profileId: any(named: 'profileId')))
          .thenThrow(Exception('Network error'));

      // act
      final result = await repository.superLikeProfile('profile123');

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (swipeResult) => fail('Should return Left'),
      );
    });
  });

  group('MatchRepositoryImpl - dislikeProfile', () {
    test('should return SwipeResult with isMatch=false', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'daily_likes_remaining': 45,
          'super_likes_remaining': 1,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/dislike'),
      );
      when(() => mockApi.dislikeProfile(profileId: any(named: 'profileId')))
          .thenAnswer((_) async => tResponse);

      // act
      final result = await repository.dislikeProfile('profile123');

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, false);
          expect(swipeResult.remainingLikes, 45);
          expect(swipeResult.remainingSuperLikes, 1);
        },
      );
    });

    test('should handle null data in response', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/dislike'),
      );
      when(() => mockApi.dislikeProfile(profileId: any(named: 'profileId')))
          .thenAnswer((_) async => tResponse);

      // act
      final result = await repository.dislikeProfile('profile123');

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, false);
          expect(swipeResult.remainingLikes, null);
        },
      );
    });
  });

  group('MatchRepositoryImpl - rewindLastSwipe', () {
    test('should return SwipeResult on success', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/rewind'),
      );
      when(() => mockApi.rewindLastSwipe()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.rewindLastSwipe();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (swipeResult) {
          expect(swipeResult.isMatch, false);
          expect(swipeResult.matchId, null);
        },
      );
    });

    test('should return ServerFailure on error', () async {
      // arrange
      when(() => mockApi.rewindLastSwipe())
          .thenThrow(ServerException(message: 'No swipe to rewind'));

      // act
      final result = await repository.rewindLastSwipe();

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (swipeResult) => fail('Should return Left'),
      );
    });
  });

  group('MatchRepositoryImpl - getDailyLikeLimit', () {
    test('should return DailyLikeLimit from premium status', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'daily_likes_used': 10,
          'daily_likes_limit': 50,
          'daily_likes_reset_at': '2024-02-25T00:00:00Z',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
      );
      when(() => mockApi.getPremiumStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDailyLikeLimit();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (limit) {
          expect(limit.remainingLikes, 40);
          expect(limit.totalLikes, 50);
          expect(limit.resetAt, isA<DateTime>());
        },
      );
    });

    test('should use defaults when reset_at is missing', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'daily_likes_used': 5,
          'daily_likes_limit': 50,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
      );
      when(() => mockApi.getPremiumStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDailyLikeLimit();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (limit) {
          expect(limit.remainingLikes, 45);
          expect(limit.totalLikes, 50);
          expect(limit.resetAt.day, DateTime.now().day + 1);
        },
      );
    });

    test('should return ServerFailure when data is null', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
      );
      when(() => mockApi.getPremiumStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getDailyLikeLimit();

      // assert
      expect(result.isLeft(), true);
    });
  });

  group('MatchRepositoryImpl - getSuperLikesRemaining', () {
    test('should return super likes count', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {'super_likes_remaining': 3},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
      );
      when(() => mockApi.getPremiumStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getSuperLikesRemaining();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 3),
      );
    });

    test('should return 0 when super_likes_remaining is null', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
      );
      when(() => mockApi.getPremiumStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getSuperLikesRemaining();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 0),
      );
    });
  });

  group('MatchRepositoryImpl - activateBoost', () {
    test('should return BoostStatus on success', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'is_active': true,
          'activated_at': '2024-02-24T12:00:00Z',
          'ends_at': '2024-02-24T13:00:00Z',
          'boosts_remaining': 2,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/boost/activate'),
      );
      when(() => mockApi.activateBoost()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.activateBoost();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (boost) {
          expect(boost.isActive, true);
          expect(boost.activatedAt, isA<DateTime>());
          expect(boost.endsAt, isA<DateTime>());
          expect(boost.boostsRemaining, 2);
        },
      );
    });
  });

  group('MatchRepositoryImpl - getBoostStatus', () {
    test('should return BoostStatus', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'is_active': false,
          'boosts_remaining': 3,
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/boost/status'),
      );
      when(() => mockApi.getBoostStatus()).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getBoostStatus();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (boost) {
          expect(boost.isActive, false);
          expect(boost.boostsRemaining, 3);
        },
      );
    });
  });

  group('MatchRepositoryImpl - updateSearchFilters', () {
    test('should call API with correct parameters', () async {
      // arrange
      final tFilters = SearchPreferences(
        minAge: 25,
        maxAge: 35,
        maxDistance: 50.0,
        interestedIn: const ['male'],
        relationshipTypes: const ['casual'],
        showVerifiedOnly: true,
        showOnlineOnly: false,
      );
      final tResponse = Response<Map<String, dynamic>>(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/filters'),
      );
      when(() => mockApi.updateDiscoveryFilters(
            ageMin: any(named: 'ageMin'),
            ageMax: any(named: 'ageMax'),
            distanceMaxKm: any(named: 'distanceMaxKm'),
            genders: any(named: 'genders'),
            relationshipTypes: any(named: 'relationshipTypes'),
            verifiedOnly: any(named: 'verifiedOnly'),
            onlineOnly: any(named: 'onlineOnly'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.updateSearchFilters(tFilters);

      // assert
      expect(result.isRight(), true);
      verify(() => mockApi.updateDiscoveryFilters(
            ageMin: 25,
            ageMax: 35,
            distanceMaxKm: 50,
            genders: ['male'],
            relationshipTypes: ['casual'],
            verifiedOnly: true,
            onlineOnly: false,
          )).called(1);
    });

    test('should return ServerFailure on error', () async {
      // arrange
      final tFilters = SearchPreferences(
        minAge: 25,
        maxAge: 35,
        maxDistance: 50.0,
        interestedIn: const ['male'],
        relationshipTypes: const ['casual'],
      );
      when(() => mockApi.updateDiscoveryFilters(
            ageMin: any(named: 'ageMin'),
            ageMax: any(named: 'ageMax'),
            distanceMaxKm: any(named: 'distanceMaxKm'),
            genders: any(named: 'genders'),
            relationshipTypes: any(named: 'relationshipTypes'),
            verifiedOnly: any(named: 'verifiedOnly'),
            onlineOnly: any(named: 'onlineOnly'),
          )).thenThrow(Exception('Network error'));

      // act
      final result = await repository.updateSearchFilters(tFilters);

      // assert
      expect(result.isLeft(), true);
    });
  });

  group('MatchRepositoryImpl - getLikesReceivedCount', () {
    test('should extract count from response', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'count': 15,
          'results': [],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/likes-received/'),
      );
      when(() => mockApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getLikesReceivedCount();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 15),
      );
    });

    test('should extract count from pagination object', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'pagination': {'total': 20},
          'results': [],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/likes-received/'),
      );
      when(() => mockApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getLikesReceivedCount();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 20),
      );
    });

    test('should fallback to results array length when no count field', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {
          'results': [1, 2, 3, 4, 5],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/likes-received/'),
      );
      when(() => mockApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getLikesReceivedCount();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 5),
      );
    });

    test('should return 0 when no count information available', () async {
      // arrange
      final tResponse = Response<Map<String, dynamic>>(
        data: {},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/likes-received/'),
      );
      when(() => mockApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await repository.getLikesReceivedCount();

      // assert
      result.fold(
        (failure) => fail('Should return Right'),
        (count) => expect(count, 0),
      );
    });
  });
}

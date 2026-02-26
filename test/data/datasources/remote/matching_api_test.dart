// test/data/datasources/remote/matching_api_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MatchingApi matchingApi;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    matchingApi = MatchingApi(mockApiClient);
  });

  group('MatchingApi - getDiscoveryProfiles', () {
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
            'main_photo_url': 'photo1.jpg',
            'other_photos': [],
            'interests': ['music', 'travel'],
            'relationship_type': 'casual',
            'is_verified': true,
            'is_premium': false,
            'last_active': '2024-02-24T12:00:00Z',
            'compatibility_score': 85.0,
          }
        ]
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/profiles'),
    );

    test('should make GET request to /discovery/profiles with default params', () async {
      // arrange
      when(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getDiscoveryProfiles();

      // assert
      verify(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: {'page': 1, 'page_size': 20},
          )).called(1);
    });

    test('should make GET request with custom page and pageSize', () async {
      // arrange
      when(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getDiscoveryProfiles(page: 2, pageSize: 10);

      // assert
      verify(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: {'page': 2, 'page_size': 10},
          )).called(1);
    });

    test('should include filters in query parameters when provided', () async {
      // arrange
      final tFilters = {
        'age_min': 25,
        'age_max': 35,
        'distance_max_km': 50,
      };
      when(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getDiscoveryProfiles(filters: tFilters);

      // assert
      verify(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: {
              'page': 1,
              'page_size': 20,
              'age_min': 25,
              'age_max': 35,
              'distance_max_km': 50,
            },
          )).called(1);
    });

    test('should return response with data', () async {
      // arrange
      when(() => mockApiClient.get(
            '/discovery/profiles',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      final result = await matchingApi.getDiscoveryProfiles();

      // assert
      expect(result.data, tResponse.data);
      expect(result.statusCode, 200);
    });
  });

  group('MatchingApi - likeProfile', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'result': 'like',
        'daily_likes_remaining': 45,
        'super_likes_remaining': 1,
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/interactions/like'),
    );

    test('should make POST request to /discovery/interactions/like', () async {
      // arrange
      when(() => mockApiClient.post(
            '/discovery/interactions/like',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.likeProfile(profileId: 'profile123');

      // assert
      verify(() => mockApiClient.post(
            '/discovery/interactions/like',
            data: {'target_user_id': 'profile123'},
          )).called(1);
    });

    test('should include message in request when provided', () async {
      // arrange
      when(() => mockApiClient.post(
            '/discovery/interactions/like',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.likeProfile(
        profileId: 'profile123',
        message: 'Hello!',
      );

      // assert
      verify(() => mockApiClient.post(
            '/discovery/interactions/like',
            data: {
              'target_user_id': 'profile123',
              'message': 'Hello!',
            },
          )).called(1);
    });
  });

  group('MatchingApi - dislikeProfile', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {'success': true},
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/interactions/dislike'),
    );

    test('should make POST request to /discovery/interactions/dislike', () async {
      // arrange
      when(() => mockApiClient.post(
            '/discovery/interactions/dislike',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.dislikeProfile(profileId: 'profile123');

      // assert
      verify(() => mockApiClient.post(
            '/discovery/interactions/dislike',
            data: {'target_user_id': 'profile123'},
          )).called(1);
    });

    test('should include reason when provided', () async {
      // arrange
      when(() => mockApiClient.post(
            '/discovery/interactions/dislike',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.dislikeProfile(
        profileId: 'profile123',
        reason: 'not_interested',
      );

      // assert
      verify(() => mockApiClient.post(
            '/discovery/interactions/dislike',
            data: {
              'target_user_id': 'profile123',
              'reason': 'not_interested',
            },
          )).called(1);
    });
  });

  group('MatchingApi - superLikeProfile', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'result': 'match',
        'match_id': 'match123',
        'super_likes_remaining': 0,
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/interactions/superlike'),
    );

    test('should make POST request to /discovery/interactions/superlike', () async {
      // arrange
      when(() => mockApiClient.post(
            '/discovery/interactions/superlike',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.superLikeProfile(profileId: 'profile123');

      // assert
      verify(() => mockApiClient.post(
            '/discovery/interactions/superlike',
            data: {'target_user_id': 'profile123'},
          )).called(1);
    });
  });

  group('MatchingApi - rewindLastSwipe', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {'success': true},
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/interactions/rewind'),
    );

    test('should make POST request to /discovery/interactions/rewind', () async {
      // arrange
      when(() => mockApiClient.post('/discovery/interactions/rewind'))
          .thenAnswer((_) async => tResponse);

      // act
      await matchingApi.rewindLastSwipe();

      // assert
      verify(() => mockApiClient.post('/discovery/interactions/rewind')).called(1);
    });
  });

  group('MatchingApi - getMatches', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'results': [
          {
            'id': 'match1',
            'matched_user_id': 'user123',
            'created_at': '2024-02-24T12:00:00Z',
          }
        ]
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/matches/'),
    );

    test('should make GET request to /matches/ with default params', () async {
      // arrange
      when(() => mockApiClient.get(
            '/matches/',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getMatches();

      // assert
      verify(() => mockApiClient.get(
            '/matches/',
            queryParameters: {'page': 1, 'page_size': 20},
          )).called(1);
    });
  });

  group('MatchingApi - updateDiscoveryFilters', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {'success': true},
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/filters'),
    );

    test('should make PUT request to /discovery/filters with all params', () async {
      // arrange
      when(() => mockApiClient.put(
            '/discovery/filters',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.updateDiscoveryFilters(
        ageMin: 25,
        ageMax: 35,
        distanceMaxKm: 50,
        genders: ['male', 'female'],
        relationshipTypes: ['casual', 'serious'],
        verifiedOnly: true,
        onlineOnly: false,
      );

      // assert
      verify(() => mockApiClient.put(
            '/discovery/filters',
            data: {
              'age_min': 25,
              'age_max': 35,
              'distance_max_km': 50,
              'genders': ['male', 'female'],
              'relationship_types': ['casual', 'serious'],
              'verified_only': true,
              'online_only': false,
            },
          )).called(1);
    });

    test('should only include provided parameters', () async {
      // arrange
      when(() => mockApiClient.put(
            '/discovery/filters',
            data: any(named: 'data'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.updateDiscoveryFilters(
        ageMin: 25,
        distanceMaxKm: 50,
      );

      // assert
      verify(() => mockApiClient.put(
            '/discovery/filters',
            data: {
              'age_min': 25,
              'distance_max_km': 50,
            },
          )).called(1);
    });
  });

  group('MatchingApi - getLikedMeProfiles', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'results': [
          {
            'user_id': 'profile1',
            'display_name': 'Jane Doe',
            'age': 28,
          }
        ]
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/interactions/liked-me'),
    );

    test('should make GET request to /discovery/interactions/liked-me', () async {
      // arrange
      when(() => mockApiClient.get(
            '/discovery/interactions/liked-me',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getLikedMeProfiles();

      // assert
      verify(() => mockApiClient.get(
            '/discovery/interactions/liked-me',
            queryParameters: {'page': 1, 'page_size': 20},
          )).called(1);
    });
  });

  group('MatchingApi - getPremiumStatus', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'is_premium': true,
        'daily_likes_used': 10,
        'daily_likes_limit': 50,
        'super_likes_remaining': 3,
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/user-profiles/premium-status/'),
    );

    test('should make GET request to /user-profiles/premium-status/', () async {
      // arrange
      when(() => mockApiClient.get('/user-profiles/premium-status/'))
          .thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getPremiumStatus();

      // assert
      verify(() => mockApiClient.get('/user-profiles/premium-status/')).called(1);
    });
  });

  group('MatchingApi - activateBoost', () {
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

    test('should make POST request to /discovery/boost/activate', () async {
      // arrange
      when(() => mockApiClient.post('/discovery/boost/activate'))
          .thenAnswer((_) async => tResponse);

      // act
      await matchingApi.activateBoost();

      // assert
      verify(() => mockApiClient.post('/discovery/boost/activate')).called(1);
    });
  });

  group('MatchingApi - getBoostStatus', () {
    final tResponse = Response<Map<String, dynamic>>(
      data: {
        'is_active': false,
        'boosts_remaining': 3,
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '/discovery/boost/status'),
    );

    test('should make GET request to /discovery/boost/status', () async {
      // arrange
      when(() => mockApiClient.get('/discovery/boost/status'))
          .thenAnswer((_) async => tResponse);

      // act
      await matchingApi.getBoostStatus();

      // assert
      verify(() => mockApiClient.get('/discovery/boost/status')).called(1);
    });
  });
}

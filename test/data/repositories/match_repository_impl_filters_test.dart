import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchingApi extends Mock implements MatchingApi {}

void main() {
  late MockMatchingApi mockMatchingApi;
  late MatchRepositoryImpl repository;

  setUp(() {
    mockMatchingApi = MockMatchingApi();
    repository = MatchRepositoryImpl(mockMatchingApi);
  });

  group('MatchRepositoryImpl discovery filters', () {
    test(
        'maps GET /discovery/filters/get response payload with nested filters object',
        () async {
      when(() => mockMatchingApi.getDiscoveryFilters()).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'status': 'success',
            'filters': {
              'age_min': 21,
              'age_max': 38,
              'distance_max_km': 35,
              'genders': ['female', 'non_binary'],
              'relationship_types': ['long_term', 'casual'],
              'verified_only': true,
              'online_only': true,
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/discovery/filters/get'),
        ),
      );

      final result = await repository.getSearchFilters();

      expect(result.isRight(), isTrue);
      final prefs = result.getOrElse(
        () => const SearchPreferences(
          minAge: 18,
          maxAge: 99,
          maxDistance: 25,
          interestedIn: [],
          relationshipTypes: [],
        ),
      );
      expect(prefs.minAge, 21);
      expect(prefs.maxAge, 38);
      expect(prefs.maxDistance, 35);
      expect(prefs.interestedIn, ['female', 'non_binary']);
      expect(prefs.relationshipTypes, ['long_term', 'casual']);
      expect(prefs.showVerifiedOnly, isTrue);
      expect(prefs.showOnlineOnly, isTrue);
    });

    test('maps GET /discovery/filters/get when payload is flat', () async {
      when(() => mockMatchingApi.getDiscoveryFilters()).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'age_min': 18,
            'age_max': 99,
            'distance_max_km': 25,
            'genders': <String>[],
            'relationship_types': <String>[],
            'verified_only': false,
            'online_only': false,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/discovery/filters/get'),
        ),
      );

      final result = await repository.getSearchFilters();

      expect(result.isRight(), isTrue);
      final prefs = result.getOrElse(
        () => const SearchPreferences(
          minAge: 0,
          maxAge: 0,
          maxDistance: 0,
          interestedIn: [],
          relationshipTypes: [],
        ),
      );
      expect(prefs.minAge, 18);
      expect(prefs.maxAge, 99);
      expect(prefs.maxDistance, 25);
      expect(prefs.interestedIn, isEmpty);
      expect(prefs.relationshipTypes, isEmpty);
    });

    test('sends full contract payload to updateDiscoveryFilters', () async {
      const filters = SearchPreferences(
        minAge: 24,
        maxAge: 39,
        maxDistance: 47,
        interestedIn: ['male', 'trans_male'],
        relationshipTypes: ['friendship', 'short_term'],
        showVerifiedOnly: true,
        showOnlineOnly: true,
      );

      when(
        () => mockMatchingApi.updateDiscoveryFilters(
          ageMin: any(named: 'ageMin'),
          ageMax: any(named: 'ageMax'),
          distanceMaxKm: any(named: 'distanceMaxKm'),
          genders: any(named: 'genders'),
          relationshipTypes: any(named: 'relationshipTypes'),
          verifiedOnly: any(named: 'verifiedOnly'),
          onlineOnly: any(named: 'onlineOnly'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {'status': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/discovery/filters'),
        ),
      );

      final result = await repository.updateSearchFilters(filters);

      expect(result.isRight(), isTrue);
      verify(
        () => mockMatchingApi.updateDiscoveryFilters(
          ageMin: 24,
          ageMax: 39,
          distanceMaxKm: 47,
          genders: const ['male', 'trans_male'],
          relationshipTypes: const ['friendship', 'short_term'],
          verifiedOnly: true,
          onlineOnly: true,
        ),
      ).called(1);
    });
  });
}

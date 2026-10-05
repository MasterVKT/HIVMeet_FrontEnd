// Garde de non-régression pour LOG-11 : une réponse `results: []` valide ne
// doit jamais être traitée comme une erreur. Le défaut venait d'une liste
// JSON non castée (`dynamic`) passée à `.map().toList()`, qui produisait un
// `List<dynamic>` au lieu du `List<DiscoveryProfile>` attendu et levait une
// TypeError interceptée par le `catch` générique — reproductible même avec
// zéro élément.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchingApi extends Mock implements MatchingApi {}

void main() {
  late MockMatchingApi mockMatchingApi;
  late MatchRepositoryImpl repository;

  setUp(() {
    mockMatchingApi = MockMatchingApi();
    repository = MatchRepositoryImpl(mockMatchingApi);
  });

  group('MatchRepositoryImpl.getLikesReceived', () {
    test('an empty results list resolves as a successful empty page', () async {
      when(() => mockMatchingApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'count': 0,
            'next': null,
            'previous': null,
            'results': <dynamic>[],
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/user-profiles/likes-received/'),
        ),
      );

      final result = await repository.getLikesReceived();

      expect(result.isRight(), isTrue,
          reason: 'A valid empty page must not surface as a Failure');
      expect(result.getOrElse(() => const []), isEmpty);
    });

    test('a non-empty results list maps every profile', () async {
      when(() => mockMatchingApi.getLikesReceived(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const {
            'count': 2,
            'results': [
              {
                'id': 'p1',
                'display_name': 'A',
                'age': 30,
                'main_photo_url': '',
                'city': 'Paris',
              },
              {
                'id': 'p2',
                'display_name': 'B',
                'age': 25,
                'main_photo_url': '',
                'city': 'Lyon',
              },
            ],
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/user-profiles/likes-received/'),
        ),
      );

      final result = await repository.getLikesReceived();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => const []), hasLength(2));
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseUrl =
      String.fromEnvironment('DISCOVERY_TEST_BASE_URL', defaultValue: '');
  const accessToken =
      String.fromEnvironment('DISCOVERY_TEST_ACCESS_TOKEN', defaultValue: '');

  final shouldSkip = baseUrl.isEmpty || accessToken.isEmpty;

  group('Discovery filters backend contract API', () {
    test('PUT and GET filters follow contract deterministically', () async {
      if (shouldSkip) {
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      const payload = {
        'age_min': 25,
        'age_max': 40,
        'distance_max_km': 50,
        'genders': <String>['all'],
        'relationship_types': <String>['all'],
        'verified_only': true,
        'online_only': false,
      };

      final putResponse =
          await dio.put('/api/v1/discovery/filters', data: payload);
      expect(putResponse.statusCode, anyOf(200, 201));
      expect(putResponse.data['status'], equals('success'));
      expect(putResponse.data['filters'], isA<Map<String, dynamic>>());
      expect((putResponse.data['filters']['genders'] as List), isEmpty);
      expect(
          (putResponse.data['filters']['relationship_types'] as List), isEmpty);

      final getResponse = await dio.get('/api/v1/discovery/filters/get');
      expect(getResponse.statusCode, equals(200));
      expect(getResponse.data['status'], equals('success'));

      final filters = getResponse.data['filters'] as Map<String, dynamic>;
      expect(filters['age_min'], equals(25));
      expect(filters['age_max'], equals(40));
      expect(filters['distance_max_km'], equals(50));
      expect(filters['verified_only'], isTrue);
      expect(filters['online_only'], isFalse);
      expect(filters['genders'], isA<List>());
      expect(filters['relationship_types'], isA<List>());
    },
        skip: shouldSkip
            ? 'Set DISCOVERY_TEST_BASE_URL and DISCOVERY_TEST_ACCESS_TOKEN to run real backend contract tests.'
            : false);
  });
}

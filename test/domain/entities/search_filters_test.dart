import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';

void main() {
  group('SearchFilters', () {
    test('normalizes all tokens to empty arrays', () {
      const filters = SearchFilters(
        minAge: 25,
        maxAge: 40,
        maxDistance: 50,
        genders: ['all'],
        relationshipTypes: ['all'],
        verifiedOnly: true,
        onlineOnly: true,
      );

      final normalized = filters.normalized();

      expect(normalized.genders, isEmpty);
      expect(normalized.relationshipTypes, isEmpty);
      expect(normalized.verifiedOnly, isTrue);
      expect(normalized.onlineOnly, isTrue);
    });

    test('validates age and distance boundaries', () {
      const invalidAge =
          SearchFilters(minAge: 100, maxAge: 99, maxDistance: 10);
      const invalidDistance =
          SearchFilters(minAge: 18, maxAge: 30, maxDistance: 101);

      expect(invalidAge.validate(), isNotNull);
      expect(invalidDistance.validate(), isNotNull);
    });

    test('converts to SearchPreferences with backend defaults', () {
      const filters = SearchFilters();

      final preferences = filters.toSearchPreferences();

      expect(
        preferences,
        const SearchPreferences(
          minAge: 18,
          maxAge: 99,
          maxDistance: 50,
          interestedIn: <String>[],
          relationshipTypes: <String>[],
          showVerifiedOnly: false,
          showOnlineOnly: false,
        ),
      );
    });

    test('round-trips from SearchPreferences', () {
      const prefs = SearchPreferences(
        minAge: 19,
        maxAge: 33,
        maxDistance: 42,
        interestedIn: <String>['male', 'non_binary'],
        relationshipTypes: <String>['friendship', 'casual'],
        showVerifiedOnly: true,
        showOnlineOnly: true,
      );

      final filters = SearchFilters.fromSearchPreferences(prefs);

      expect(filters.minAge, 19);
      expect(filters.maxAge, 33);
      expect(filters.maxDistance, 42);
      expect(filters.genders, <String>['male', 'non_binary']);
      expect(filters.relationshipTypes, <String>['friendship', 'casual']);
      expect(filters.verifiedOnly, isTrue);
      expect(filters.onlineOnly, isTrue);
    });

    test('validates minimum distance and age ordering', () {
      const invalidDistance =
          SearchFilters(minAge: 18, maxAge: 25, maxDistance: 4);
      const invalidOrder =
          SearchFilters(minAge: 30, maxAge: 20, maxDistance: 10);

      expect(invalidDistance.validate(), contains('distance_max_km'));
      expect(invalidOrder.validate(), contains('age_min'));
    });
  });
}

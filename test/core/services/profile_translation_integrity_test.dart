import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profile localization is valid UTF-8 and complete in French and English',
      () async {
    const profileKeys = <String>[
      'gender_locked_subtitle',
      'gender_confirmation_title',
      'gender_confirmation_required',
      'location_search_country',
      'location_search_city',
      'location_no_country_results',
      'location_no_city_results',
    ];
    const repairedFrenchKeys = <String>[
      'use_device_location',
      'use_device_location_subtitle',
      'manual_location',
      'location_country_required',
      'location_city_required',
      'location_permission_denied',
      'location_permission_denied_forever',
      'photos_reordered',
      'same_city',
    ];

    for (final locale in <String>['fr', 'en']) {
      final source =
          await rootBundle.loadString('assets/translations/$locale.json');
      final data = jsonDecode(source) as Map<String, dynamic>;
      final profile = data['profile'] as Map<String, dynamic>;
      final gender = data['gender'] as Map<String, dynamic>;

      for (final key in profileKeys) {
        expect(profile[key], isA<String>(), reason: '$locale profile.$key');
      }
      expect(gender['male'], isA<String>());
      expect(gender['female'], isA<String>());

      _assertNoEncodingMarkers(data);

      if (locale == 'fr') {
        for (final key in repairedFrenchKeys) {
          expect(profile[key], isNot(contains('?')), reason: 'profile.$key');
        }
      }
    }
  });
}

void _assertNoEncodingMarkers(Object? value) {
  const replacement = 0xfffd;
  const latinCapitalAWithTilde = 0x00c3;
  const latinSmallAWithCircumflex = 0x00e2;
  if (value is Map) {
    for (final child in value.values) {
      _assertNoEncodingMarkers(child);
    }
    return;
  }
  if (value is List) {
    for (final child in value) {
      _assertNoEncodingMarkers(child);
    }
    return;
  }
  if (value is String) {
    expect(value.runes, isNot(contains(replacement)));
    expect(value.runes, isNot(contains(latinCapitalAWithTilde)));
    // Valid French text can contain \u00e2, but the mojibake prefix U+00E2 U+20AC
    // is never a valid translation sequence in this catalogue.
    expect(
      value.runes.toList(),
      isNot(containsAllInOrder(<int>[latinSmallAWithCircumflex, 0x20ac])),
    );
  }
}

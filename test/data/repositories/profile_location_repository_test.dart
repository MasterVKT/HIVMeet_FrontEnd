import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/data/datasources/remote/profile_api.dart';
import 'package:hivmeet/data/datasources/remote/settings_api.dart';
import 'package:hivmeet/data/repositories/profile_repository_impl.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:mocktail/mocktail.dart';

class _ProfileApi extends Mock implements ProfileApi {}

class _SettingsApi extends Mock implements SettingsApi {}

class _AuthApi extends Mock implements AuthApi {}

Response<Map<String, dynamic>> _response(Map<String, dynamic> data) => Response(
    data: data, statusCode: 200, requestOptions: RequestOptions(path: 'test'));

void main() {
  late _ProfileApi api;
  late ProfileRepositoryImpl repository;

  setUp(() {
    api = _ProfileApi();
    repository = ProfileRepositoryImpl(api, _SettingsApi(), _AuthApi());
  });

  test('maps paginated country and dependent city catalogues', () async {
    when(() => api.getLocationCountries(query: any(named: 'query'))).thenAnswer(
      (_) async => _response({
        'results': [
          {
            'code': 'CM',
            'label': 'Cameroun',
            'catalog_version': 'geonames-2026-09'
          },
        ],
      }),
    );
    when(() => api.getLocationCities(
        countryCode: 'CM', query: any(named: 'query'))).thenAnswer(
      (_) async => _response({
        'results': [
          {
            'geonames_id': 2220957,
            'name': 'Douala',
            'country_code': 'CM',
            'country_name': 'Cameroun'
          },
        ],
      }),
    );

    final countries = await repository.getLocationCountries();
    final cities =
        await repository.getLocationCities(countryCode: 'CM', query: 'dou');

    expect(countries.getOrElse(() => const []).single.label, 'Cameroun');
    expect(cities.getOrElse(() => const []).single.id, 2220957);
  });

  test('sends manual locations only to the dedicated endpoint', () async {
    when(() => api.updateProfileLocation(any())).thenAnswer(
      (_) async => _response({
        'id': 'profile-id',
        'user_id': 'user-id',
        'city': 'Douala',
        'country': 'Cameroon',
        'geo_city_id': 2220957,
        'location_enabled': false,
        'location_mode': 'manual',
        'photos': <dynamic>[],
      }),
    );

    final result = await repository.updateProfileLocation(
      const ProfileLocationUpdate.manual(cityId: 2220957),
    );

    expect(result.isRight(), true);
    expect(
        verify(() => api.updateProfileLocation(captureAny())).captured.single,
        {'location_enabled': false, 'city_id': 2220957});
  });

  test('uses the atomic profile and location endpoint for profile edits',
      () async {
    when(
      () => api.updateProfileAndLocation(
        profile: any(named: 'profile'),
        location: any(named: 'location'),
      ),
    ).thenAnswer(
      (_) async => _response({
        'id': 'profile-id',
        'user_id': 'user-id',
        'bio': 'Updated biography',
        'city': 'Douala',
        'country': 'Cameroon',
        'geo_city_id': 2220957,
        'location_enabled': false,
        'location_mode': 'manual',
        'gender_confirmation_required': true,
        'photos': <dynamic>[],
      }),
    );

    final result = await repository.updateProfile(
      bio: 'Updated biography',
      locationUpdate: const ProfileLocationUpdate.manual(cityId: 2220957),
    );

    expect(result.isRight(), true);
    final invocation = verify(
      () => api.updateProfileAndLocation(
        profile: captureAny(named: 'profile'),
        location: captureAny(named: 'location'),
      ),
    ).captured;
    expect(invocation[0], {'bio': 'Updated biography'});
    expect(invocation[1], {'location_enabled': false, 'city_id': 2220957});
    expect(result.getOrElse(() => throw StateError('missing profile'))
        .genderConfirmationRequired, isTrue);
    verifyNever(() => api.updateProfile(any()));
  });
}

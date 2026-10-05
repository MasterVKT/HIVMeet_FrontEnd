import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/data/datasources/remote/profile_api.dart';
import 'package:hivmeet/data/datasources/remote/settings_api.dart';
import 'package:hivmeet/data/repositories/profile_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileApi extends Mock implements ProfileApi {}

class MockSettingsApi extends Mock implements SettingsApi {}

class MockAuthApi extends Mock implements AuthApi {}

Response<Map<String, dynamic>> _profileResponse({
  required String preferredCurrency,
  required String effectiveCurrency,
}) {
  return Response<Map<String, dynamic>>(
    data: {
      'id': 'profile-id',
      'user_id': 'user-id',
      'display_name': 'Test',
      'birth_date': '1990-01-01',
      'country': 'Cameroun',
      'preferred_currency': preferredCurrency,
      'effective_currency': effectiveCurrency,
      'photos': <dynamic>[],
    },
    statusCode: 200,
    requestOptions: RequestOptions(path: '/user-profiles/me/'),
  );
}

void main() {
  late MockProfileApi profileApi;
  late ProfileRepositoryImpl repository;

  setUp(() {
    profileApi = MockProfileApi();
    repository = ProfileRepositoryImpl(
      profileApi,
      MockSettingsApi(),
      MockAuthApi(),
    );
  });

  test('maps the stored and effective subscription currencies', () async {
    when(() => profileApi.getCurrentProfile()).thenAnswer(
      (_) async => _profileResponse(
        preferredCurrency: 'AUTO',
        effectiveCurrency: 'XAF',
      ),
    );

    final result = await repository.getCurrentUserProfile();

    result.fold(
      (failure) => fail(failure.message),
      (profile) {
        expect(profile.preferredCurrency, 'AUTO');
        expect(profile.effectiveCurrency, 'XAF');
      },
    );
  });

  test('sends only the selected preference and refreshes the profile',
      () async {
    when(() => profileApi.updateProfile(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/user-profiles/me/'),
      ),
    );
    when(() => profileApi.getCurrentProfile()).thenAnswer(
      (_) async => _profileResponse(
        preferredCurrency: 'EUR',
        effectiveCurrency: 'EUR',
      ),
    );

    final result = await repository.updateProfile(preferredCurrency: 'EUR');

    expect(result.isRight(), true);
    final payload = verify(() => profileApi.updateProfile(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(payload, {'preferred_currency': 'EUR'});
  });
}

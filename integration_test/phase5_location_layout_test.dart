import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/presentation/widgets/profile/location_catalog_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class _ProfileRepository extends Mock implements ProfileRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the manual GeoNames picker on a mobile device',
      (tester) async {
    final services = GetIt.instance;
    if (services.isRegistered<LocalizationService>()) {
      await services.unregister<LocalizationService>();
    }
    final localization = LocalizationService();
    services.registerSingleton<LocalizationService>(localization);
    await localization.initialize('fr');
    addTearDown(() async => services.unregister<LocalizationService>());

    final repository = _ProfileRepository();
    when(() => repository.getLocationCountries(query: any(named: 'query')))
        .thenAnswer(
      (_) async =>
          const Right<Failure, List<LocationCountry>>(<LocationCountry>[
        LocationCountry(
          code: 'CM',
          label: 'Cameroun',
          catalogVersion: 'geonames-2026-09',
        ),
      ]),
    );
    when(
      () => repository.getLocationCities(
        countryCode: any(named: 'countryCode'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => const Right<Failure, List<LocationCity>>(<LocationCity>[
        LocationCity(
          id: 2220957,
          name: 'Douala',
          countryCode: 'CM',
          countryName: 'Cameroun',
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Localisation')),
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LocationCatalogPicker(
                repository: repository,
                onCityChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    expect(find.text('Cameroun'), findsOneWidget);

    await tester.tap(find.text('Cameroun'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Douala'), findsOneWidget);

    await tester.tap(find.text('Douala'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun pays trouv?.'), findsNothing);
    expect(find.text('Aucune ville trouv?e.'), findsNothing);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('PHASE5_CAPTURE')) {
      await Future<void>.delayed(const Duration(seconds: 120));
    }
  });
}

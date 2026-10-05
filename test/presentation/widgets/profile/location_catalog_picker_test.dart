import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/presentation/widgets/profile/location_catalog_picker.dart';
import 'package:mocktail/mocktail.dart';

class _ProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _ProfileRepository repository;

  setUpAll(() async {
    final services = GetIt.instance;
    if (services.isRegistered<LocalizationService>()) {
      await services.unregister<LocalizationService>();
    }
    final localization = LocalizationService();
    services.registerSingleton<LocalizationService>(localization);
    await localization.initialize('en');
  });

  tearDownAll(() async {
    await GetIt.instance.unregister<LocalizationService>();
  });

  setUp(() {
    repository = _ProfileRepository();
    when(() => repository.getLocationCountries(query: any(named: 'query')))
        .thenAnswer(
      (_) async =>
          const Right<Failure, List<LocationCountry>>(<LocationCountry>[
        LocationCountry(
          code: 'CM',
          label: 'Cameroon',
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
          countryName: 'Cameroon',
        ),
      ]),
    );
  });

  testWidgets('selects a city from the dependent catalog without overflow',
      (tester) async {
    LocationCity? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: LocationCatalogPicker(
                repository: repository,
                onCityChanged: (city) => selected = city,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    expect(find.text('Cameroon'), findsOneWidget);

    await tester.tap(find.text('Cameroon'));
    await tester.pump();
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pump();
    expect(find.text('Douala'), findsOneWidget);

    await tester.tap(find.text('Douala'));
    await tester.pump();

    expect(selected?.id, 2220957);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a localized retry after a country catalogue failure',
      (tester) async {
    var attempts = 0;
    when(() => repository.getLocationCountries(query: any(named: 'query')))
        .thenAnswer((_) async {
      attempts += 1;
      if (attempts == 1) {
        return const Left<Failure, List<LocationCountry>>(
          ServerFailure(message: 'catalogue unavailable'),
        );
      }
      return const Right<Failure, List<LocationCountry>>(<LocationCountry>[
        LocationCountry(
          code: 'CM',
          label: 'Cameroon',
          catalogVersion: 'geonames-2026-09',
        ),
      ]);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationCatalogPicker(
            repository: repository,
            onCityChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Cameroon'), findsOneWidget);
  });

  testWidgets('stays within a narrow layout at large text scale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: LocationCatalogPicker(
              repository: repository,
              onCityChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

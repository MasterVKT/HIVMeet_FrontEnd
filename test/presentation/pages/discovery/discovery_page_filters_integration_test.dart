import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/pages/discovery/discovery_page.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryBloc extends Mock implements DiscoveryBloc {}

void main() {
  late MockDiscoveryBloc mockDiscoveryBloc;

  setUpAll(() {
    registerFallbackValue(const LoadDiscoveryProfiles());
  });

  final profile = DiscoveryProfile(
    id: 'profile-1',
    displayName: 'Taylor',
    age: 29,
    mainPhotoUrl: 'https://example.com/profile.jpg',
    otherPhotosUrls: const [],
    bio: 'bio',
    city: 'Paris',
    country: 'France',
    distance: 5,
    interests: const ['music'],
    relationshipType: 'long_term',
    relationshipTypesSought: const ['long_term'],
    isVerified: true,
    isPremium: false,
    lastActive: DateTime(2026, 1, 1),
    compatibilityScore: 0,
  );

  final loadedState = DiscoveryLoaded(
    currentProfile: profile,
    nextProfiles: const [],
    canRewind: false,
  );

  setUp(() {
    mockDiscoveryBloc = MockDiscoveryBloc();

    when(() => mockDiscoveryBloc.state).thenReturn(loadedState);
    when(() => mockDiscoveryBloc.stream)
        .thenAnswer((_) => const Stream<DiscoveryState>.empty());
    when(() => mockDiscoveryBloc.add(any())).thenReturn(null);
    when(() => mockDiscoveryBloc.getCurrentSearchFilters()).thenAnswer(
      (_) async => const SearchPreferences(
        minAge: 23,
        maxAge: 36,
        maxDistance: 45,
        interestedIn: ['female'],
        relationshipTypes: ['long_term'],
        showVerifiedOnly: true,
        showOnlineOnly: true,
      ),
    );

    if (!getIt.isRegistered<LocalizationService>()) {
      getIt.registerSingleton<LocalizationService>(LocalizationService());
    }

    if (getIt.isRegistered<DiscoveryBloc>()) {
      getIt.unregister<DiscoveryBloc>();
    }
    getIt.registerFactory<DiscoveryBloc>(() => mockDiscoveryBloc);
  });

  tearDown(() async {
    if (getIt.isRegistered<DiscoveryBloc>()) {
      getIt.unregister<DiscoveryBloc>();
    }
  });

  testWidgets('filter icon preloads current saved filters before opening modal',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoveryPage(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => mockDiscoveryBloc.getCurrentSearchFilters()).called(1);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('applying filters dispatches UpdateFilters event',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoveryPage(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final verification = verify(
      () => mockDiscoveryBloc.add(captureAny(that: isA<UpdateFilters>())),
    );
    final UpdateFilters event = verification.captured.single as UpdateFilters;

    expect(event.filters.minAge, 23);
    expect(event.filters.maxAge, 36);
    expect(event.filters.maxDistance, 45);
    expect(event.filters.genders, ['female']);
    expect(event.filters.relationshipTypes, ['long_term']);
    expect(event.filters.verifiedOnly, isTrue);
    expect(event.filters.onlineOnly, isTrue);
  });
}

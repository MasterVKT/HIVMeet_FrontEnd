// test/presentation/pages/discovery/discovery_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/pages/discovery/discovery_page.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryBloc extends Mock implements DiscoveryBloc {}

void main() {
  group('DiscoveryPage', () {
    late MockDiscoveryBloc mockDiscoveryBloc;

    setUp(() {
      mockDiscoveryBloc = MockDiscoveryBloc();
    });

    testWidgets('should display loading widget when state is DiscoveryLoading',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockDiscoveryBloc.state).thenReturn(DiscoveryLoading());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (context) => mockDiscoveryBloc,
            child: const DiscoveryPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Chargement des profils...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error widget when state is DiscoveryError',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockDiscoveryBloc.state)
          .thenReturn(const DiscoveryError(message: 'Test error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (context) => mockDiscoveryBloc,
            child: const DiscoveryPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('should display no more profiles when state is NoMoreProfiles',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockDiscoveryBloc.state).thenReturn(NoMoreProfiles());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (context) => mockDiscoveryBloc,
            child: const DiscoveryPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Plus de profils'), findsOneWidget);
      expect(find.text('Ajuster les filtres'), findsOneWidget);
    });

    testWidgets(
        'should display discovery content when state is DiscoveryLoaded',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = DiscoveryProfile(
        id: '1',
        displayName: 'Test User',
        age: 25,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [],
        bio: 'Test bio',
        city: 'Paris',
        country: 'France',
        distance: 5.0,
        interests: ['Musique', 'Sport'],
        relationshipType: 'any',
        isVerified: true,
        isPremium: false,
        lastActive: DateTime.now(),
        compatibilityScore: 85.0,
      );

      when(() => mockDiscoveryBloc.state).thenReturn(
        DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (context) => mockDiscoveryBloc,
            child: const DiscoveryPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Test User, 25'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
    });

    testWidgets(
        'should display daily limit reached when state is DailyLimitReached',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = DiscoveryProfile(
        id: '1',
        displayName: 'Test User',
        age: 25,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [],
        bio: 'Test bio',
        city: 'Paris',
        country: 'France',
        distance: 5.0,
        interests: ['Musique'],
        relationshipType: 'any',
        isVerified: true,
        isPremium: false,
        lastActive: DateTime.now(),
        compatibilityScore: 0.0,
      );

      final dailyLimit = DailyLikeLimit(
        remainingLikes: 0,
        totalLikes: 10,
        resetAt: DateTime.now().add(const Duration(hours: 1)),
      );

      when(() => mockDiscoveryBloc.state).thenReturn(
        DailyLimitReached(
          previousState: DiscoveryLoaded(
            currentProfile: mockProfile,
            nextProfiles: [],
            canRewind: false,
          ),
          limitInfo: dailyLimit,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DiscoveryBloc>(
            create: (context) => mockDiscoveryBloc,
            child: const DiscoveryPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Limite quotidienne atteinte'), findsOneWidget);
      expect(find.text('Passer à Premium'), findsOneWidget);
    });
  });
}

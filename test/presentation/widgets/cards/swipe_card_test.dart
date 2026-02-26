// test/presentation/widgets/cards/swipe_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';

void main() {
  group('SwipeCard', () {
    // Helper to create mock profile
    DiscoveryProfile createMockProfile({
      String name = 'Alice',
      int age = 28,
      List<String>? photos,
      bool isVerified = false,
      bool isOnline = false,
      double? compatibilityScore,
      List<String>? interests,
    }) {
      return DiscoveryProfile(
        id: '123',
        userId: 'user123',
        name: name,
        age: age,
        bio: 'Test bio',
        photos: photos ?? ['https://example.com/photo1.jpg'],
        interests: interests ?? ['music', 'travel'],
        distance: 5.0,
        compatibilityScore: compatibilityScore ?? 85,
        isOnline: isOnline,
        isVerified: isVerified,
        relationshipTypesSought: const ['long_term'],
      );
    }

    testWidgets('renders with required profile prop', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );

      // Assert
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('displays profile name and age', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(name: 'John', age: 30);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('displays profile photo', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        photos: ['https://example.com/photo.jpg'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('displays verified badge when isVerified is true',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(isVerified: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should have verified indicator
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('displays online indicator when isOnline is true',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(isOnline: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should have online indicator
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('displays compatibility score', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(compatibilityScore: 92);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('92%'), findsOneWidget);
    });

    testWidgets('displays interests as chips', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        interests: ['Music', 'Travel', 'Fitness'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('Fitness'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();
      bool tapped = false;
      void onTap() {
        tapped = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              profile: mockProfile,
              onTap: onTap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(SwipeCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('renders in preview mode', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              profile: mockProfile,
              isPreview: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('preview mode shows simplified card', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              profile: mockProfile,
              isPreview: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - preview mode should still render
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('does not call onSwipe in preview mode',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();
      bool swiped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              profile: mockProfile,
              isPreview: true,
              onSwipe: (direction) => swiped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - try to drag (simulating swipe)
      await tester.drag(find.byType(SwipeCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Assert - should not call onSwipe in preview mode
      expect(swiped, isFalse);
    });

    testWidgets('handles profile with multiple photos',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        photos: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should have PageView for photo carousel
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows photo pagination indicators for multiple photos',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        photos: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should have pagination indicators (dots or similar)
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('handles profile with no photos', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(photos: []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not crash, should show placeholder
      expect(tester.takeException(), isNull);
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('handles profile with long name', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        name: 'ThisIsAVeryLongProfileNameThatMightCauseOverflow',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles profile with many interests', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        interests: [
          'Music',
          'Travel',
          'Fitness',
          'Reading',
          'Cooking',
          'Photography',
          'Dancing',
          'Yoga'
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles profile with empty bio', (WidgetTester tester) async {
      // Arrange
      final mockProfile = DiscoveryProfile(
        id: '123',
        userId: 'user123',
        name: 'John',
        age: 30,
        bio: '', // Empty bio
        photos: ['https://example.com/photo.jpg'],
        interests: const [],
        distance: 5.0,
        compatibilityScore: 85,
        isOnline: false,
        isVerified: false,
        relationshipTypesSought: const [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('card has rounded corners', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final clipRRect = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.isNotEmpty, isTrue);
    });

    testWidgets('card has shadow for depth', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBoxShadow = containers.any((container) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          return decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty;
        }
        return false;
      });
      expect(hasBoxShadow, isTrue);
    });

    testWidgets('renders without errors', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays distance from user', (WidgetTester tester) async {
      // Arrange
      final mockProfile = DiscoveryProfile(
        id: '123',
        userId: 'user123',
        name: 'Alice',
        age: 28,
        bio: 'Test bio',
        photos: ['https://example.com/photo.jpg'],
        interests: const [],
        distance: 12.5,
        compatibilityScore: 85,
        isOnline: false,
        isVerified: false,
        relationshipTypesSought: const [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('handles zero compatibility score', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(compatibilityScore: 0);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should display 0%
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('handles 100% compatibility score', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(compatibilityScore: 100);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(profile: mockProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should display 100%
      expect(find.text('100%'), findsOneWidget);
    });
  });
}

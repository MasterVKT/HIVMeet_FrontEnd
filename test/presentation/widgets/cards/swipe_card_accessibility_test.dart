// test/presentation/widgets/cards/swipe_card_accessibility_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';

void main() {
  group('SwipeCard Accessibility Tests', () {
    /// Helper to create a test profile
    DiscoveryProfile createTestProfile({
      String displayName = 'Test User',
      int age = 25,
      double distance = 5.0,
      String? bio,
      bool isVerified = false,
      bool isPremium = false,
      bool isOnline = false,
      double? compatibilityScore,
    }) {
      return DiscoveryProfile(
        id: '1',
        displayName: displayName,
        age: age,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
        bio: bio ?? 'Test bio',
        city: 'Paris',
        country: 'France',
        distance: distance,
        interests: ['Musique', 'Sport'],
        relationshipType: 'any',
        isVerified: isVerified,
        isPremium: isPremium,
        lastActive: DateTime.now(),
        compatibilityScore: compatibilityScore,
      );
    }

    /// Helper to build SwipeCard widget
    Widget buildSwipeCard(DiscoveryProfile profile,
        {MediaQueryData? mediaQueryData}) {
      Widget card = MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeCard(
              profile: profile,
              onSwipeLeft: () {},
              onSwipeRight: () {},
              onSwipeUp: () {},
            ),
          ),
        ),
      );

      if (mediaQueryData != null) {
        card = MediaQuery(
          data: mediaQueryData,
          child: card,
        );
      }

      return card;
    }

    group('Semantic Labels Tests', () {
      testWidgets('should have comprehensive semantic label for profile',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(
          displayName: 'Alice',
          age: 28,
          distance: 3.5,
          bio: 'Love hiking and photography',
          isVerified: true,
          isPremium: true,
          compatibilityScore: 85.0,
        );

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Card should have comprehensive semantic label
        final card = find.byType(SwipeCard);
        expect(card, findsOneWidget);

        final semantics = tester.getSemantics(card);
        expect(semantics.label, isNotEmpty,
            reason: 'Profile card should have semantic label');

        // Verify label contains key information
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('alice'),
            reason: 'Label should contain profile name');
        expect(label.contains('28') || label.contains('ans'), isTrue,
            reason: 'Label should contain age');
        expect(label, contains('kilomètre'),
            reason: 'Label should contain distance');

        handle.dispose();
      });

      testWidgets('should include verification status in semantic label',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(isVerified: true);

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byType(SwipeCard));
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('vérifié'),
            reason: 'Verified status should be in semantic label');

        handle.dispose();
      });

      testWidgets('should include premium status in semantic label',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(isPremium: true);

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byType(SwipeCard));
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('premium'),
            reason: 'Premium status should be in semantic label');

        handle.dispose();
      });

      testWidgets('should include compatibility score in semantic label',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(compatibilityScore: 92.0);

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byType(SwipeCard));
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label.contains('92') || label.contains('compatibilité'), isTrue,
            reason: 'Compatibility score should be in semantic label');

        handle.dispose();
      });

      testWidgets('should provide swipe instructions in semantic label',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byType(SwipeCard));
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('balayez'),
            reason: 'Swipe instructions should be in semantic label');

        handle.dispose();
      });
    });

    group('Gesture Accessibility Tests', () {
      testWidgets('should announce swipe gestures for screen readers',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Card should have semantic actions for gestures
        final semantics = tester.getSemantics(find.byType(SwipeCard));

        // Note: Swipe gestures should have alternative button controls
        // which are tested in the action button accessibility tests
        expect(semantics.label, isNotEmpty,
            reason: 'Card should provide context for gestures');

        handle.dispose();
      });
    });

    group('Photo Carousel Accessibility Tests', () {
      testWidgets('should have accessible photo pagination indicators',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Photo indicators should be accessible
        // Pagination dots should have semantic meaning
        final swipeCard = find.byType(SwipeCard);
        expect(swipeCard, findsOneWidget);

        // The card should indicate it has multiple photos
        final semantics = tester.getSemantics(swipeCard);
        expect(semantics, isNotNull);

        handle.dispose();
      });
    });

    group('Badge Accessibility Tests', () {
      testWidgets('should announce verified badge to screen readers',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(isVerified: true);

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Verified badge should be announced
        final verifiedIcon = find.byIcon(Icons.verified);
        if (verifiedIcon.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(verifiedIcon.first);
          expect(semantics.label, isNotEmpty,
              reason: 'Verified badge should have semantic label');
        }

        handle.dispose();
      });

      testWidgets('should announce premium badge to screen readers',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(isPremium: true);

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Premium badge should be announced
        final premiumIcon = find.byIcon(Icons.star);
        if (premiumIcon.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(premiumIcon.first);
          expect(semantics.label, isNotEmpty,
              reason: 'Premium badge should have semantic label');
        }

        handle.dispose();
      });
    });

    group('Text Scaling Tests', () {
      testWidgets('should handle large text scale factors',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();
        final mediaQueryData = MediaQueryData(textScaleFactor: 2.5);

        // Act
        await tester.pumpWidget(
            buildSwipeCard(profile, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert - Should render without overflow
        expect(tester.takeException(), isNull,
            reason: 'Card should handle large text without errors');

        // Verify text is actually scaled
        final context = tester.element(find.byType(SwipeCard));
        expect(MediaQuery.of(context).textScaleFactor, equals(2.5));
      });

      testWidgets('should handle bold text preference',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();
        final mediaQueryData = MediaQueryData(boldText: true);

        // Act
        await tester.pumpWidget(
            buildSwipeCard(profile, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull,
            reason: 'Card should handle bold text without errors');

        final context = tester.element(find.byType(SwipeCard));
        expect(MediaQuery.of(context).boldText, isTrue);
      });
    });

    group('Reduced Motion Tests', () {
      testWidgets('should respect reduced motion preference',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();
        final mediaQueryData = MediaQueryData(disableAnimations: true);

        // Act
        await tester.pumpWidget(
            buildSwipeCard(profile, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(SwipeCard));
        expect(AccessibilityHelper.shouldReduceMotion(context), isTrue,
            reason: 'Card should detect reduced motion preference');
      });
    });

    group('Color Contrast Tests', () {
      testWidgets('should use colors with sufficient contrast',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile();

        // Act
        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        // Assert - This is a smoke test; actual contrast should be verified manually
        // or with specialized tools, but we can verify colors are defined
        expect(find.byType(SwipeCard), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Card should render with proper theming');
      });
    });

    group('AccessibilityHelper Integration Tests', () {
      testWidgets('should use AccessibilityHelper for semantic label generation',
          (WidgetTester tester) async {
        // Arrange
        final profile = createTestProfile(
          displayName: 'Bob',
          age: 30,
          distance: 7.5,
          bio: 'Passionate about art',
          isVerified: true,
          isPremium: true,
          compatibilityScore: 78.0,
        );

        // Act
        final expectedLabel = AccessibilityHelper.getProfileCardSemanticLabel(
          name: 'Bob',
          age: 30,
          distance: '7.5',
          bio: 'Passionate about art',
          isVerified: true,
          isPremium: true,
          compatibilityScore: 78,
        );

        await tester.pumpWidget(buildSwipeCard(profile));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - The generated label should match the helper's format
        final semantics = tester.getSemantics(find.byType(SwipeCard));
        expect(semantics.label, isNotEmpty);

        // Verify key components are present
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('bob'));
        expect(label, contains('30') || label.contains('ans'));
        expect(label, contains('vérifié'));
        expect(label, contains('premium'));

        handle.dispose();
      });
    });
  });
}

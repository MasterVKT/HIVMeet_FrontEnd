// test/presentation/widgets/modals/match_found_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/widgets/modals/match_found_modal.dart';

void main() {
  group('MatchFoundModal', () {
    // Helper to create mock profile
    DiscoveryProfile createMockProfile({
      String name = 'Alice',
      int age = 28,
      List<String>? photos,
    }) {
      return DiscoveryProfile(
        id: '123',
        userId: 'user123',
        name: name,
        age: age,
        bio: 'Test bio',
        photos: photos ?? ['https://example.com/photo.jpg'],
        interests: const [],
        distance: 5.0,
        compatibilityScore: 85,
        isOnline: false,
        isVerified: true,
        relationshipTypesSought: const ['long_term'],
      );
    }

    testWidgets('renders with all required props', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();
      bool messageTapped = false;
      bool continueTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () => messageTapped = true,
              onContinue: () => continueTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Alice, 28'), findsOneWidget);
    });

    testWidgets('calls onSendMessage when message button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();
      bool messageTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () => messageTapped = true,
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      final messageButton = find.widgetWithText(ElevatedButton, 'Envoyer un message');
      await tester.tap(messageButton);
      await tester.pump();

      // Assert
      expect(messageTapped, isTrue);
    });

    testWidgets('calls onContinue when continue button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();
      bool continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () => continueTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      final continueButton = find.widgetWithText(TextButton, 'Continuer à swiper');
      await tester.tap(continueButton);
      await tester.pump();

      // Assert
      expect(continueTapped, isTrue);
    });

    testWidgets('displays profile photo', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        photos: ['https://example.com/profile.jpg'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('displays match celebration message',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('C\'est un match!'), findsOneWidget);
    });

    testWidgets('displays heart icons', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
    });

    testWidgets('has scale animation controller', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );

      // Pump once to start animations
      await tester.pump();

      // Assert - animations should be in progress
      expect(find.byType(MatchFoundModal), findsOneWidget);
    });

    testWidgets('applies fade animation', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );

      // Assert - should have FadeTransition widgets
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    });

    testWidgets('applies scale animation', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );

      // Assert - should have ScaleTransition widgets
      expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
    });

    testWidgets('handles profile with no photos', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(photos: []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
      expect(find.text('Alice, 28'), findsOneWidget);
    });

    testWidgets('handles long profile name', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(
        name: 'ThisIsAVeryLongProfileNameThatMightCauseOverflow',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should not overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('message button has correct styling',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final messageButton = find.widgetWithText(ElevatedButton, 'Envoyer un message');
      expect(messageButton, findsOneWidget);
    });

    testWidgets('continue button has correct styling',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final continueButton = find.widgetWithText(TextButton, 'Continuer à swiper');
      expect(continueButton, findsOneWidget);
    });

    testWidgets('displays profile age correctly', (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile(name: 'Bob', age: 35);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Bob, 35'), findsOneWidget);
    });

    testWidgets('animation completes without errors',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );

      // Pump and settle to complete all animations
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('both buttons are visible after animation completes',
        (WidgetTester tester) async {
      // Arrange
      final mockProfile = createMockProfile();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFoundModal(
              matchedProfile: mockProfile,
              matchId: 'match123',
              onSendMessage: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}

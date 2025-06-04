// test/presentation/widgets/cards/hiv_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/presentation/widgets/cards/hiv_card.dart';
import 'package:hivmeet/core/theme/app_colors.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('HIVCard', () {
    testWidgets('displays child widget', (WidgetTester tester) async {
      const testText = 'Test Content';
      
      await tester.pumpWidget(
        createTestableWidget(
          const HIVCard(
            child: Text(testText),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('applies custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(24.0);
      
      await tester.pumpWidget(
        createTestableWidget(
          const HIVCard(
            padding: customPadding,
            child: Text('Test'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      expect(container.padding, customPadding);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVCard(
            onTap: () => wasTapped = true,
            child: const Text('Tap me'),
          ),
        ),
      );

      await tester.tap(find.byType(HIVCard));
      expect(wasTapped, isTrue);
    });

    testWidgets('applies custom background color', (WidgetTester tester) async {
      const testColor = Colors.blue;
      
      await tester.pumpWidget(
        createTestableWidget(
          const HIVCard(
            backgroundColor: testColor,
            child: Text('Test'),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(HIVCard),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, testColor);
    });
  });

  group('ProfileCard', () {
    const testImageUrl = 'https://example.com/image.jpg';
    const testName = 'John';
    const testAge = 25;
    const testCity = 'Paris';

    testWidgets('displays user information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          ProfileCard(
            imageUrl: testImageUrl,
            name: testName,
            age: testAge,
            city: testCity,
          ),
        ),
      );

      expect(find.text('$testName, $testAge'), findsOneWidget);
      expect(find.text(testCity), findsOneWidget);
    });

    testWidgets('shows verified badge when verified', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const ProfileCard(
            imageUrl: testImageUrl,
            name: testName,
            age: testAge,
            isVerified: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows premium badge when premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const ProfileCard(
            imageUrl: testImageUrl,
            name: testName,
            age: testAge,
            isPremium: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('hides city when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const ProfileCard(
            imageUrl: testImageUrl,
            name: testName,
            age: testAge,
            city: null,
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('shows placeholder on image error', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const ProfileCard(
            imageUrl: 'invalid_url',
            name: testName,
            age: testAge,
          ),
        ),
      );

      // Wait for image loading to fail
      await tester.pump();
      
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('MatchCard', () {
    const testImageUrl = 'https://example.com/avatar.jpg';
    const testName = 'Jane';
    const testMessage = 'Hello there!';
    final testTime = DateTime.now().subtract(const Duration(hours: 2));

    testWidgets('displays match information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            lastMessage: testMessage,
            lastMessageTime: testTime,
          ),
        ),
      );

      expect(find.text(testName), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('shows online indicator when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            isOnline: true,
          ),
        ),
      );

      // Look for the online indicator (green dot)
      final onlineIndicator = find.byWidgetPredicate(
        (widget) => widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.mint,
      );

      expect(onlineIndicator, findsOneWidget);
    });

    testWidgets('shows unread indicator when has unread messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            hasUnreadMessage: true,
          ),
        ),
      );

      // Look for the unread indicator (primary color dot)
      final unreadIndicator = find.byWidgetPredicate(
        (widget) => widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.primary,
      );

      expect(unreadIndicator, findsOneWidget);
    });

    testWidgets('formats time correctly', (WidgetTester tester) async {
      // Test hours ago
      await tester.pumpWidget(
        createTestableWidget(
          MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ),
      );

      expect(find.text('2h'), findsOneWidget);

      // Test minutes ago
      await tester.pumpWidget(
        createTestableWidget(
          MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ),
      );
      
      await tester.pump();
      expect(find.text('30m'), findsOneWidget);

      // Test days ago
      await tester.pumpWidget(
        createTestableWidget(
          MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ),
      );
      
      await tester.pump();
      expect(find.text('3j'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        createTestableWidget(
          MatchCard(
            imageUrl: testImageUrl,
            name: testName,
            onTap: () => wasTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(MatchCard));
      expect(wasTapped, isTrue);
    });
  });
}
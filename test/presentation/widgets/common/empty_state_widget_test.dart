// test/presentation/widgets/common/empty_state_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/widgets/common/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders with all required props', (WidgetTester tester) async {
      // Arrange
      const testIcon = Icons.favorite_border;
      const testTitle = 'No Profiles Found';
      const testMessage = 'Adjust your filters to see more profiles';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: testIcon,
              title: testTitle,
              message: testMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('displays icon with gradient background',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.favorite_border),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      expect(decoration.shape, BoxShape.circle);
      expect(container.constraints?.maxWidth, 140);
      expect(container.constraints?.maxHeight, 140);
    });

    testWidgets('icon has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
            ),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_border));
      expect(icon.size, 70);
      expect(icon.color, AppColors.primaryPurple);
    });

    testWidgets('hides action button when not provided',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows action button when actionText and onAction provided',
        (WidgetTester tester) async {
      // Arrange
      const actionText = 'Adjust Filters';
      bool actionTapped = false;
      void onAction() {
        actionTapped = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
              actionText: actionText,
              onAction: onAction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text(actionText), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('calls onAction when action button is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool actionTapped = false;
      void onAction() {
        actionTapped = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
              actionText: 'Take Action',
              onAction: onAction,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(actionTapped, isTrue);
    });

    testWidgets('hides button when only actionText is provided (no onAction)',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
              actionText: 'Action Text',
              // onAction not provided
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('hides button when only onAction is provided (no actionText)',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
              onAction: () {}, // actionText not provided
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('action button has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Test Title',
              message: 'Test Message',
              actionText: 'Action',
              onAction: () {},
            ),
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style;
      expect(style?.backgroundColor?.resolve({}), AppColors.primaryPurple);
      expect(style?.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      // Arrange
      const testTitle = 'Empty State Title';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: testTitle,
              message: 'Test Message',
            ),
          ),
        ),
      );

      // Assert
      final titleText = tester.widget<Text>(find.text(testTitle));
      expect(titleText.textAlign, TextAlign.center);
      expect(titleText.style?.fontSize, 26);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.style?.color, AppColors.charcoal);
    });

    testWidgets('message has correct styling', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'This is the empty state message';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: testMessage,
            ),
          ),
        ),
      );

      // Assert
      final messageText = tester.widget<Text>(find.text(testMessage));
      expect(messageText.textAlign, TextAlign.center);
      expect(messageText.style?.fontSize, 16);
      expect(messageText.style?.color, AppColors.slate);
      expect(messageText.style?.height, 1.6);
    });

    testWidgets('message has max width constraint', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: 'Message',
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Message'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 320);
    });

    testWidgets('centers content on screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: 'Message',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('content is scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: 'Message',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('handles long title text', (WidgetTester tester) async {
      // Arrange
      const longTitle =
          'This is a very long title that might wrap to multiple lines';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: longTitle,
              message: 'Message',
            ),
          ),
        ),
      );

      // Assert - should not overflow
      expect(find.text(longTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles long message text', (WidgetTester tester) async {
      // Arrange
      const longMessage =
          'This is a very long message that might wrap to multiple lines and should still display correctly without any overflow or layout issues';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: longMessage,
            ),
          ),
        ),
      );

      // Assert - should not overflow
      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has correct spacing between elements',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Title',
              message: 'Message',
              actionText: 'Action',
              onAction: () {},
            ),
          ),
        ),
      );

      // Assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(
        sizedBoxes.any((box) => box.height == 32),
        isTrue,
        reason: 'Should have 32px spacing after icon',
      );
      expect(
        sizedBoxes.any((box) => box.height == 16),
        isTrue,
        reason: 'Should have 16px spacing after title',
      );
      expect(
        sizedBoxes.any((box) => box.height == 40),
        isTrue,
        reason: 'Should have 40px spacing before button',
      );
    });
  });
}

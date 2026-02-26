// test/presentation/widgets/common/error_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/widgets/common/error_widget.dart' as custom;

void main() {
  group('ErrorWidget', () {
    testWidgets('renders with required error message', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Unable to load profiles';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text('Oops!'), findsOneWidget);
    });

    testWidgets('displays default error icon when not specified',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: 'Error occurred'),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, Icons.error_outline);
      expect(icon.size, 80);
      expect(icon.color, AppColors.error);
    });

    testWidgets('displays custom icon when specified', (WidgetTester tester) async {
      // Arrange
      const customIcon = Icons.wifi_off;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Network error',
              icon: customIcon,
            ),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, customIcon);
    });

    testWidgets('hides retry button when onRetry is null',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: 'Error occurred'),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided',
        (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;
      void onRetry() {
        retryTapped = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Error occurred',
              onRetry: onRetry,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool retryTapped = false;
      void onRetry() {
        retryTapped = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Error occurred',
              onRetry: onRetry,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(retryTapped, isTrue);
    });

    testWidgets('retry button has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Error occurred',
              onRetry: () {},
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

    testWidgets('centers content on screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: 'Error'),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('handles long error messages', (WidgetTester tester) async {
      // Arrange
      const longMessage =
          'This is a very long error message that might wrap to multiple lines and should still display correctly without overflow';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: longMessage),
          ),
        ),
      );

      // Assert - should not overflow
      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('message has correct text styling', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Test error message';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      final text = tester.widget<Text>(find.text(testMessage));
      expect(text.textAlign, TextAlign.center);
      expect(text.style?.fontSize, 16);
      expect(text.style?.color, AppColors.slate);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: 'Error'),
          ),
        ),
      );

      // Assert
      final titleText = tester.widget<Text>(find.text('Oops!'));
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.style?.color, AppColors.charcoal);
    });

    testWidgets('has correct spacing between elements',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Error',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(
        sizedBoxes.any((box) => box.height == 24),
        isTrue,
        reason: 'Should have 24px spacing after icon',
      );
      expect(
        sizedBoxes.any((box) => box.height == 16),
        isTrue,
        reason: 'Should have 16px spacing after title',
      );
      expect(
        sizedBoxes.any((box) => box.height == 32),
        isTrue,
        reason: 'Should have 32px spacing before button',
      );
    });

    testWidgets('content is scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: 'Error'),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('handles empty message gracefully', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(message: ''),
          ),
        ),
      );

      // Assert - should still render icon and title
      expect(find.text('Oops!'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

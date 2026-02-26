// test/presentation/widgets/common/loading_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/widgets/common/loading_widget.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('renders with required message', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Loading profiles...';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator with correct color',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      // Assert
      final progressIndicator =
          tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(
        progressIndicator.valueColor?.value,
        AppColors.primaryPurple,
      );
      expect(progressIndicator.strokeWidth, 3);
    });

    testWidgets('uses default size when not specified',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 50.0);
      expect(sizedBox.height, 50.0);
    });

    testWidgets('uses custom size when specified', (WidgetTester tester) async {
      // Arrange
      const customSize = 80.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(
              message: 'Loading...',
              size: customSize,
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, customSize);
      expect(sizedBox.height, customSize);
    });

    testWidgets('centers content on screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('displays message with correct styling',
        (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Please wait...';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      final text = tester.widget<Text>(find.text(testMessage));
      expect(text.textAlign, TextAlign.center);
      expect(text.style?.fontSize, 16);
      expect(text.style?.color, AppColors.slate);
    });

    testWidgets('handles long message text', (WidgetTester tester) async {
      // Arrange
      const longMessage =
          'This is a very long loading message that might wrap to multiple lines';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: longMessage),
          ),
        ),
      );

      // Assert - should not overflow
      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty message', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: ''),
          ),
        ),
      );

      // Assert - should still render CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has correct spacing between indicator and message',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      // Assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(
        sizedBoxes.any((box) => box.height == 16),
        isTrue,
        reason: 'Should have 16px spacing between indicator and message',
      );
    });
  });
}

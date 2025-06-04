// test/presentation/widgets/buttons/hiv_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/presentation/widgets/buttons/hiv_button.dart';
import 'package:hivmeet/core/theme/app_colors.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('HIVButton', () {
    testWidgets('displays label correctly', (WidgetTester tester) async {
      const testLabel = 'Test Button';
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVButton(
            label: testLabel,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text(testLabel), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVButton(
            label: 'Test',
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(HIVButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          HIVButton(
            label: 'Test',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const HIVButton(
            label: 'Test',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byType(HIVButton),
          matching: find.byType(ElevatedButton),
        ),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('shows icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          HIVButton(
            label: 'Test',
            onPressed: () {},
            icon: Icons.favorite,
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    group('Button Types', () {
      testWidgets('primary button has correct styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Primary',
              onPressed: () {},
              type: HIVButtonType.primary,
            ),
          ),
        );

        final buttonWidget = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(ElevatedButton),
          ),
        );

        // Test gradient background
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
      });

      testWidgets('secondary button has correct styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Secondary',
              onPressed: () {},
              type: HIVButtonType.secondary,
            ),
          ),
        );

        await tester.pump();

        final outlinedButton = tester.widget<OutlinedButton>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(OutlinedButton),
          ),
        );

        expect(outlinedButton, isNotNull);
      });

      testWidgets('text button has correct styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Text',
              onPressed: () {},
              type: HIVButtonType.text,
            ),
          ),
        );

        final textButton = tester.widget<TextButton>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(TextButton),
          ),
        );

        expect(textButton, isNotNull);
      });
    });

    group('Button Sizes', () {
      testWidgets('small button has correct height', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Small',
              onPressed: () {},
              size: HIVButtonSize.small,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.minHeight, 36);
      });

      testWidgets('medium button has correct height', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Medium',
              onPressed: () {},
              size: HIVButtonSize.medium,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.minHeight, 48);
      });

      testWidgets('large button has correct height', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            HIVButton(
              label: 'Large',
              onPressed: () {},
              size: HIVButtonSize.large,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(HIVButton),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.minHeight, 56);
      });
    });

    testWidgets('fullWidth expands to container width', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          SizedBox(
            width: 300,
            child: HIVButton(
              label: 'Full Width',
              onPressed: () {},
              fullWidth: true,
            ),
          ),
        ),
      );

      final button = tester.getSize(find.byType(HIVButton));
      expect(button.width, 300);
    });
  });

  group('HIVIconButton', () {
    testWidgets('displays icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          HIVIconButton(
            icon: Icons.favorite,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows tooltip when provided', (WidgetTester tester) async {
      const tooltipText = 'Like';
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVIconButton(
            icon: Icons.favorite,
            onPressed: () {},
            tooltip: tooltipText,
          ),
        ),
      );

      await tester.longPress(find.byType(HIVIconButton));
      await tester.pump();

      expect(find.text(tooltipText), findsOneWidget);
    });

    testWidgets('applies custom color', (WidgetTester tester) async {
      const testColor = Colors.red;
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVIconButton(
            icon: Icons.favorite,
            onPressed: () {},
            color: testColor,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, testColor);
    });
  });

  group('HIVGradientButton', () {
    testWidgets('applies custom gradient', (WidgetTester tester) async {
      const testGradient = LinearGradient(
        colors: [Colors.red, Colors.blue],
      );
      
      await tester.pumpWidget(
        createTestableWidget(
          HIVGradientButton(
            label: 'Gradient',
            onPressed: () {},
            gradient: testGradient,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(HIVGradientButton),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, testGradient);
    });
  });
}
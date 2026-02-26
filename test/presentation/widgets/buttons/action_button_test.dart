// test/presentation/widgets/buttons/action_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/widgets/buttons/action_button.dart';

void main() {
  group('ActionButton', () {
    testWidgets('renders with required props', (WidgetTester tester) async {
      // Arrange
      const testIcon = Icons.favorite;
      const testColor = Colors.red;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: testIcon,
              color: testColor,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;
      void onPressed() {
        pressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: onPressed,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ActionButton));
      await tester.pump();

      // Assert
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled (null onPressed)',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      // Act - try to tap
      await tester.tap(find.byType(ActionButton));
      await tester.pump();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses default size when not specified',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 50);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('uses custom size when specified', (WidgetTester tester) async {
      // Arrange
      const customSize = 70.0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, customSize);
      expect(container.constraints?.maxHeight, customSize);
    });

    testWidgets('displays with full opacity when enabled',
        (WidgetTester tester) async {
      // Arrange
      const testColor = Colors.red;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: testColor,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, testColor);
    });

    testWidgets('displays with reduced opacity when disabled',
        (WidgetTester tester) async {
      // Arrange
      const testColor = Colors.red;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: testColor,
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, testColor.withOpacity(0.5));
    });

    testWidgets('has shadow when enabled', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('has no shadow when disabled', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('hides premium badge when isPremium is false',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              isPremium: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows premium badge when isPremium is true',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              isPremium: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('premium badge has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              isPremium: true,
            ),
          ),
        ),
      );

      // Assert
      final starIcon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(starIcon.size, 8);
      expect(starIcon.color, Colors.white);

      final badgeContainer = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.star),
          matching: find.byType(Container),
        ).first,
      );
      expect(badgeContainer.constraints?.maxWidth, 16);
      expect(badgeContainer.constraints?.maxHeight, 16);

      final decoration = badgeContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.warning);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('displays tooltip when provided', (WidgetTester tester) async {
      // Arrange
      const tooltipText = 'Like this profile';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              tooltip: tooltipText,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, tooltipText);
    });

    testWidgets('has semantic label from semanticLabel prop',
        (WidgetTester tester) async {
      // Arrange
      const semanticLabel = 'Like button';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      // Assert
      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.label, contains(semanticLabel));
    });

    testWidgets('semantic label falls back to tooltip when not provided',
        (WidgetTester tester) async {
      // Arrange
      const tooltipText = 'Like this profile';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              tooltip: tooltipText,
              // semanticLabel not provided
            ),
          ),
        ),
      );

      // Assert
      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.label, contains(tooltipText));
    });

    testWidgets('has button semantics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('semantic enabled flag reflects onPressed state',
        (WidgetTester tester) async {
      // Test enabled state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      var semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);

      // Test disabled state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: null, // Disabled
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('has premium hint in semantics when isPremium is true',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              isPremium: true,
            ),
          ),
        ),
      );

      // Assert
      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.hint, contains('premium'));
    });

    testWidgets('icon has correct size relative to button size',
        (WidgetTester tester) async {
      // Arrange
      const buttonSize = 60.0;
      const expectedIconSize = buttonSize * 0.4; // 24.0

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
              size: buttonSize,
            ),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.size, expectedIconSize);
    });

    testWidgets('icon is white color', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, Colors.white);
    });

    testWidgets('button shape is circular', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });
}

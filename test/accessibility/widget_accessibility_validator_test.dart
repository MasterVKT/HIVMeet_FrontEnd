// test/accessibility/widget_accessibility_validator_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';
import 'package:hivmeet/presentation/widgets/buttons/action_button.dart';

/// Widget-level accessibility validation tests
/// These tests validate that individual widgets meet accessibility standards
void main() {
  group('Widget Accessibility Validation Tests', () {
    /// Helper function to validate a widget's accessibility
    Future<AccessibilityValidationResult> validateWidgetAccessibility(
      WidgetTester tester,
      Widget widget, {
      bool checkTouchTargets = true,
      bool checkSemantics = true,
      bool checkContrast = false,
    }) async {
      final result = AccessibilityValidationResult();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      final SemanticsHandle? handle =
          checkSemantics ? tester.ensureSemantics() : null;

      try {
        // Check touch target sizes
        if (checkTouchTargets) {
          final widgetSize = tester.getSize(find.byWidget(widget));
          final meetsMinSize = AccessibilityHelper.meetsMinTouchTarget(
            widgetSize.width,
            widgetSize.height,
          );

          result.touchTargetValid = meetsMinSize;
          result.touchTargetSize = widgetSize;

          if (!meetsMinSize) {
            result.addIssue(
                'Touch target too small: ${widgetSize.width}x${widgetSize.height}. Minimum: 44x44dp');
          }
        }

        // Check semantic labels
        if (checkSemantics) {
          try {
            final semantics = tester.getSemantics(find.byWidget(widget));
            result.hasSemanticLabel = semantics.label != null &&
                (semantics.label?.isNotEmpty ?? false);

            if (!result.hasSemanticLabel) {
              result.addIssue('Widget missing semantic label');
            }

            result.isFocusable =
                semantics.hasFlag(SemanticsFlag.isFocusable) ||
                    semantics.hasFlag(SemanticsFlag.isButton);

            result.hasEnabledState =
                semantics.hasFlag(SemanticsFlag.hasEnabledState);
          } catch (e) {
            result.addIssue('Failed to get semantics: $e');
          }
        }
      } finally {
        handle?.dispose();
      }

      return result;
    }

    group('Action Button Accessibility', () {
      testWidgets('should have adequate touch target size',
          (WidgetTester tester) async {
        // Arrange
        final button = ActionButton(
          icon: Icons.favorite,
          color: Colors.red,
          size: 44.0, // Minimum size
          onPressed: () {},
        );

        // Act
        final result = await validateWidgetAccessibility(tester, button);

        // Assert
        expect(result.touchTargetValid, isTrue,
            reason:
                'Action button should meet minimum touch target size: ${result.issues.join(', ')}');
        expect(result.touchTargetSize!.width,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize));
        expect(result.touchTargetSize!.height,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize));
      });

      testWidgets('should have semantic label', (WidgetTester tester) async {
        // Arrange
        final button = ActionButton(
          icon: Icons.favorite,
          label: 'Like',
          color: Colors.red,
          size: 48.0,
          onPressed: () {},
        );

        // Act
        final result = await validateWidgetAccessibility(tester, button);

        // Assert
        expect(result.hasSemanticLabel, isTrue,
            reason: 'Action button should have semantic label');
      });

      testWidgets('should be focusable for keyboard navigation',
          (WidgetTester tester) async {
        // Arrange
        final button = ActionButton(
          icon: Icons.favorite,
          color: Colors.red,
          size: 48.0,
          onPressed: () {},
        );

        // Act
        final result = await validateWidgetAccessibility(tester, button);

        // Assert
        expect(result.isFocusable, isTrue,
            reason: 'Action button should be focusable');
      });

      testWidgets('should indicate disabled state in semantics',
          (WidgetTester tester) async {
        // Arrange - Disabled button
        final button = ActionButton(
          icon: Icons.favorite,
          color: Colors.red,
          size: 48.0,
          onPressed: null, // Disabled
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: button,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byWidget(button));
        expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue,
            reason: 'Button should have enabled state flag');

        handle.dispose();
      });
    });

    group('Text Widget Accessibility', () {
      testWidgets('should handle large text scale factors',
          (WidgetTester tester) async {
        // Arrange
        const testText = 'Hello, World!';
        final textWidget = const Text(testText);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 3.0),
              child: Scaffold(
                body: textWidget,
              ),
            ),
          ),
        );

        // Assert - Should render without overflow
        expect(tester.takeException(), isNull,
            reason: 'Text should handle large scale factors without errors');
        expect(find.text(testText), findsOneWidget);
      });

      testWidgets('should respect bold text preference',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(boldText: true),
              child: const Scaffold(
                body: Text('Bold Text Test'),
              ),
            ),
          ),
        );

        // Assert
        expect(tester.takeException(), isNull,
            reason: 'Text should handle bold text preference');
      });
    });

    group('Interactive Widget Accessibility', () {
      testWidgets('should have tap action for interactive elements',
          (WidgetTester tester) async {
        // Arrange
        final button = ElevatedButton(
          onPressed: () {},
          child: const Text('Click Me'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: button,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byWidget(button));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue,
            reason: 'Interactive button should have tap action');

        handle.dispose();
      });

      testWidgets('should exclude decorative images from semantics',
          (WidgetTester tester) async {
        // Arrange - Decorative image (no semantic value)
        final decorativeImage = Image.asset(
          'assets/images/decoration.png',
          semanticLabel: '', // Empty label = decorative
          errorBuilder: (context, error, stackTrace) => Container(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: decorativeImage,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Decorative images should be excluded from semantics tree
        final semantics = tester.getSemantics(find.byWidget(decorativeImage));
        expect(semantics.label, anyOf(isEmpty, isNull),
            reason: 'Decorative images should have empty semantic label');

        handle.dispose();
      });

      testWidgets('should provide meaningful labels for informative images',
          (WidgetTester tester) async {
        // Arrange - Informative image
        final informativeImage = Image.asset(
          'assets/images/profile.png',
          semanticLabel: 'User profile photo',
          errorBuilder: (context, error, stackTrace) => Container(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: informativeImage,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byWidget(informativeImage));
        expect(semantics.label, isNotEmpty,
            reason: 'Informative images should have meaningful labels');
        expect(semantics.label, contains('profile'),
            reason: 'Label should describe the image');

        handle.dispose();
      });
    });

    group('Form Field Accessibility', () {
      testWidgets('should associate labels with form fields',
          (WidgetTester tester) async {
        // Arrange
        final textField = TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: textField,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Label should be accessible
        final semantics = tester.getSemantics(find.byWidget(textField));
        expect(semantics.label, contains('Email'),
            reason: 'Form field should have accessible label');

        handle.dispose();
      });

      testWidgets('should indicate required fields', (WidgetTester tester) async {
        // Arrange
        final requiredField = TextField(
          decoration: InputDecoration(
            labelText: 'Password *',
            hintText: 'Required field',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: requiredField,
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final semantics = tester.getSemantics(find.byWidget(requiredField));
        // Required indicator should be in label or hint
        final hasRequiredIndicator =
            (semantics.label?.contains('*') ?? false) ||
                (semantics.hint?.contains('Required') ?? false);
        expect(hasRequiredIndicator, isTrue,
            reason: 'Required fields should be indicated accessibly');

        handle.dispose();
      });
    });

    group('Navigation Accessibility', () {
      testWidgets('should have semantic hierarchy for navigation',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Discovery'),
              ),
              body: Column(
                children: [
                  const Text('Profile List',
                      style: TextStyle(fontSize: 24)),
                  ListTile(
                    title: const Text('Profile 1'),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('Profile 2'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Navigation should have proper semantic structure
        expect(find.text('Discovery'), findsOneWidget);
        expect(find.text('Profile List'), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(2));

        handle.dispose();
      });
    });
  });
}

/// Result of accessibility validation
class AccessibilityValidationResult {
  bool touchTargetValid = false;
  Size? touchTargetSize;
  bool hasSemanticLabel = false;
  bool isFocusable = false;
  bool hasEnabledState = false;
  List<String> issues = [];

  void addIssue(String issue) {
    issues.add(issue);
  }

  bool get isValid =>
      touchTargetValid && hasSemanticLabel && issues.isEmpty;

  @override
  String toString() {
    return '''
Accessibility Validation Result:
  Touch Target: ${touchTargetValid ? '✓' : '✗'} ${touchTargetSize != null ? '(${touchTargetSize!.width}x${touchTargetSize!.height})' : ''}
  Semantic Label: ${hasSemanticLabel ? '✓' : '✗'}
  Focusable: ${isFocusable ? '✓' : '✗'}
  Enabled State: ${hasEnabledState ? '✓' : '✗'}
  Issues: ${issues.isEmpty ? 'None' : issues.join(', ')}
''';
  }
}

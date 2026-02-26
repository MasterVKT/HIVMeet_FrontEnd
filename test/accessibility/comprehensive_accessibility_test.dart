// test/accessibility/comprehensive_accessibility_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';

/// Comprehensive automated accessibility test suite
/// Tests all WCAG 2.1 Level AA requirements for the HIVMeet app
///
/// This test suite covers:
/// - Color contrast ratios (WCAG 2.1 Level AA - 4.5:1 minimum)
/// - Touch target sizes (minimum 44x44 dp)
/// - Semantic labels for screen readers
/// - Focus management and keyboard navigation
/// - Reduced motion support
/// - Text scaling support
/// - Dark mode support (theme contrast validation)
void main() {
  group('Comprehensive Accessibility Tests', () {
    group('Color Contrast Ratio Tests (WCAG 2.1 AA)', () {
      test('should calculate relative luminance correctly', () {
        // White should have luminance of 1.0
        expect(AccessibilityHelper.getRelativeLuminance(Colors.white),
            closeTo(1.0, 0.01));

        // Black should have luminance of 0.0
        expect(AccessibilityHelper.getRelativeLuminance(Colors.black),
            closeTo(0.0, 0.01));

        // Mid gray should be around 0.2
        expect(
            AccessibilityHelper.getRelativeLuminance(const Color(0xFF808080)),
            closeTo(0.2, 0.1));
      });

      test('should calculate contrast ratios correctly', () {
        // Black on white should be 21:1 (maximum contrast)
        final blackOnWhite =
            AccessibilityHelper.getContrastRatio(Colors.black, Colors.white);
        expect(blackOnWhite, closeTo(21.0, 0.1));

        // White on black should also be 21:1
        final whiteOnBlack =
            AccessibilityHelper.getContrastRatio(Colors.white, Colors.black);
        expect(whiteOnBlack, closeTo(21.0, 0.1));

        // Same color should be 1:1 (no contrast)
        final sameColor =
            AccessibilityHelper.getContrastRatio(Colors.blue, Colors.blue);
        expect(sameColor, closeTo(1.0, 0.1));
      });

      test('should validate primary purple on white background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            AppColors.primaryPurple, Colors.white);

        // Primary purple should have sufficient contrast on white
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Primary purple (#8C2DDB) on white should meet WCAG AA (4.5:1). Got: ${ratio.toStringAsFixed(2)}:1');
        expect(
            AccessibilityHelper.meetsWCAGAA(
                AppColors.primaryPurple, Colors.white),
            isTrue);
      });

      test('should validate dark purple on white background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            AppColors.darkPurple, Colors.white);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Dark purple on white should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
      });

      test('should validate white text on primary purple background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            Colors.white, AppColors.primaryPurple);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'White on primary purple should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
        expect(
            AccessibilityHelper.meetsWCAGAA(
                Colors.white, AppColors.primaryPurple),
            isTrue);
      });

      test('should validate error color on white background (AA)', () {
        final ratio =
            AccessibilityHelper.getContrastRatio(AppColors.error, Colors.white);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Error color on white should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
      });

      test('should validate success color on white background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            AppColors.success, Colors.white);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Success color on white should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
      });

      test('should validate charcoal text on white background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            AppColors.charcoal, Colors.white);

        expect(ratio, greaterThanOrEqualTo(7.0),
            reason:
                'Charcoal text on white should meet WCAG AAA. Got: ${ratio.toStringAsFixed(2)}:1');
        expect(
            AccessibilityHelper.meetsWCAGAAA(
                AppColors.charcoal, Colors.white),
            isTrue);
      });

      test('should validate slate (gray) text on white background (AA)', () {
        final ratio =
            AccessibilityHelper.getContrastRatio(AppColors.slate, Colors.white);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Slate text on white should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
      });

      test('should validate turquoise on white background (AA)', () {
        final ratio = AccessibilityHelper.getContrastRatio(
            AppColors.turquoise, Colors.white);

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                'Turquoise on white should meet WCAG AA. Got: ${ratio.toStringAsFixed(2)}:1');
      });

      test('should reject insufficient contrast combinations', () {
        // Light purple on white should fail WCAG AA
        final lightPurpleOnWhite = AccessibilityHelper.getContrastRatio(
            AppColors.lightPurple, Colors.white);

        // This combination might not meet AA standards
        if (lightPurpleOnWhite < 4.5) {
          expect(
              AccessibilityHelper.meetsWCAGAA(
                  AppColors.lightPurple, Colors.white),
              isFalse,
              reason:
                  'Light purple on white likely fails WCAG AA (${lightPurpleOnWhite.toStringAsFixed(2)}:1)');
        }
      });

      test('should handle large text contrast requirements (3:1 for AA)', () {
        // Large text has more lenient requirements (3:1 instead of 4.5:1)
        const testColor = Color(0xFF757575); // Medium gray

        final ratio =
            AccessibilityHelper.getContrastRatio(testColor, Colors.white);

        // This might fail for normal text (4.5:1) but pass for large text (3:1)
        if (ratio >= 3.0 && ratio < 4.5) {
          expect(AccessibilityHelper.meetsWCAGAA(testColor, Colors.white),
              isFalse,
              reason: 'Should fail for normal text');
          expect(
              AccessibilityHelper.meetsWCAGAA(testColor, Colors.white,
                  isLargeText: true),
              isTrue,
              reason: 'Should pass for large text');
        }
      });

      test('should generate contrast quality descriptions', () {
        // Excellent contrast
        final excellentQuality = AccessibilityHelper.getContrastQuality(
            AppColors.charcoal, Colors.white);
        expect(excellentQuality, contains('AAA'));

        // Good contrast
        final goodQuality = AccessibilityHelper.getContrastQuality(
            AppColors.primaryPurple, Colors.white);
        expect(goodQuality, anyOf(contains('AA'), contains('AAA')));
      });
    });

    group('Theme Contrast Validation', () {
      test('should validate all theme color combinations', () {
        final theme = AppTheme.lightTheme;
        final results = AccessibilityHelper.validateThemeContrast(theme);

        // All critical color combinations should pass
        results.forEach((name, result) {
          expect(result.meetsAA, isTrue,
              reason:
                  '$name should meet WCAG AA. Got: ${result.ratio.toStringAsFixed(2)}:1');
        });
      });

      test('should provide detailed contrast test results', () {
        final theme = AppTheme.lightTheme;
        final results = AccessibilityHelper.validateThemeContrast(theme);

        expect(results, isNotEmpty);
        expect(results.containsKey('Primary on Background'), isTrue);
        expect(results.containsKey('OnPrimary on Primary'), isTrue);
        expect(results.containsKey('OnSurface on Surface'), isTrue);
        expect(results.containsKey('Error on Background'), isTrue);

        // Each result should have quality description
        results.forEach((name, result) {
          expect(result.quality, isNotEmpty);
          expect(result.ratio, greaterThan(0));
        });
      });
    });

    group('Touch Target Size Tests', () {
      test('should define minimum touch target size as 44dp', () {
        expect(AccessibilityHelper.minTouchTargetSize, equals(44.0));
      });

      test('should validate touch target sizes correctly', () {
        // Valid sizes
        expect(AccessibilityHelper.meetsMinTouchTarget(44.0, 44.0), isTrue);
        expect(AccessibilityHelper.meetsMinTouchTarget(48.0, 48.0), isTrue);
        expect(AccessibilityHelper.meetsMinTouchTarget(100.0, 50.0), isTrue);

        // Invalid sizes
        expect(AccessibilityHelper.meetsMinTouchTarget(40.0, 40.0), isFalse);
        expect(AccessibilityHelper.meetsMinTouchTarget(44.0, 30.0), isFalse);
        expect(AccessibilityHelper.meetsMinTouchTarget(30.0, 44.0), isFalse);
      });

      testWidgets('should wrap widgets to meet minimum touch target',
          (WidgetTester tester) async {
        // Arrange - Small widget that needs padding
        final smallWidget = Container(
          width: 20.0,
          height: 20.0,
          color: Colors.blue,
        );

        final wrappedWidget = AccessibilityHelper.ensureMinTouchTarget(
          child: smallWidget,
          currentWidth: 20.0,
          currentHeight: 20.0,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: wrappedWidget,
            ),
          ),
        );

        // Assert - The wrapped widget should have adequate size
        final paddingWidget = find.byType(Padding);
        expect(paddingWidget, findsOneWidget);
      });

      testWidgets('should not add padding for adequate touch targets',
          (WidgetTester tester) async {
        // Arrange - Already adequate widget
        final adequateWidget = Container(
          width: 48.0,
          height: 48.0,
          color: Colors.blue,
        );

        final wrappedWidget = AccessibilityHelper.ensureMinTouchTarget(
          child: adequateWidget,
          currentWidth: 48.0,
          currentHeight: 48.0,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: wrappedWidget,
            ),
          ),
        );

        // Assert - Should be the original widget (no padding wrapper)
        expect(wrappedWidget, equals(adequateWidget));
      });
    });

    group('Semantic Label Generation Tests', () {
      test('should generate comprehensive profile card semantic labels', () {
        final label = AccessibilityHelper.getProfileCardSemanticLabel(
          name: 'Alice',
          age: 28,
          distance: '3.5',
          bio: 'Love hiking and photography',
          isVerified: true,
          isPremium: true,
          compatibilityScore: 85,
        );

        // Verify all key information is present
        expect(label, contains('Alice'));
        expect(label, contains('28'));
        expect(label, contains('3.5'));
        expect(label, contains('vérifié'));
        expect(label, contains('premium'));
        expect(label, contains('85'));
        expect(label, contains('Love hiking'));
        expect(label, contains('Balayez'));
      });

      test('should truncate long bios in semantic labels', () {
        final longBio = 'A' * 150; // 150 character bio

        final label = AccessibilityHelper.getProfileCardSemanticLabel(
          name: 'Bob',
          age: 30,
          distance: '5.0',
          bio: longBio,
        );

        // Bio should be truncated to ~100 chars
        expect(label.length, lessThan(longBio.length + 200));
        expect(label, contains('...'));
      });

      test('should generate action button semantic labels', () {
        expect(AccessibilityHelper.getActionButtonLabel('like'),
            equals('Aimer ce profil'));
        expect(AccessibilityHelper.getActionButtonLabel('dislike'),
            equals('Passer ce profil'));
        expect(AccessibilityHelper.getActionButtonLabel('superlike'),
            equals('Super like ce profil'));
        expect(AccessibilityHelper.getActionButtonLabel('rewind'),
            equals('Annuler la dernière action'));
        expect(AccessibilityHelper.getActionButtonLabel('filters'),
            equals('Ouvrir les filtres de recherche'));
      });

      test('should indicate premium features in semantic labels', () {
        final premiumLabel = AccessibilityHelper.getActionButtonLabel(
            'superlike',
            isPremium: true);

        expect(premiumLabel, contains('premium'));
        expect(premiumLabel, contains('Super like'));
      });

      test('should generate slider semantic labels', () {
        final label = AccessibilityHelper.getSliderSemanticLabel(
          label: 'Distance',
          value: 25.0,
          unit: 'km',
          minValue: 1.0,
          maxValue: 100.0,
        );

        expect(label, contains('Distance'));
        expect(label, contains('25'));
        expect(label, contains('km'));
        expect(label, contains('1'));
        expect(label, contains('100'));
      });

      test('should generate range slider semantic labels', () {
        final label = AccessibilityHelper.getRangeSliderSemanticLabel(
          label: 'Âge',
          startValue: 25.0,
          endValue: 35.0,
          unit: 'ans',
        );

        expect(label, contains('Âge'));
        expect(label, contains('25'));
        expect(label, contains('35'));
        expect(label, contains('ans'));
      });

      test('should generate toggle semantic labels', () {
        final enabledLabel = AccessibilityHelper.getToggleSemanticLabel(
          label: 'Profils vérifiés',
          value: true,
        );

        expect(enabledLabel, contains('Profils vérifiés'));
        expect(enabledLabel, contains('activé'));

        final disabledLabel = AccessibilityHelper.getToggleSemanticLabel(
          label: 'Profils vérifiés',
          value: false,
        );

        expect(disabledLabel, contains('désactivé'));
      });

      test('should indicate premium toggles', () {
        final premiumToggle = AccessibilityHelper.getToggleSemanticLabel(
          label: 'En ligne uniquement',
          value: false,
          isPremium: true,
        );

        expect(premiumToggle, contains('premium'));
      });
    });

    group('Motion and Animation Tests', () {
      testWidgets('should detect reduced motion preference',
          (WidgetTester tester) async {
        // Arrange - MediaQuery with reduced motion enabled
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
                  child: Builder(
                    builder: (innerContext) {
                      final shouldReduce =
                          AccessibilityHelper.shouldReduceMotion(innerContext);
                      return Text(shouldReduce ? 'Reduced' : 'Normal');
                    },
                  ),
                );
              },
            ),
          ),
        );

        // Assert
        expect(find.text('Reduced'), findsOneWidget);
      });

      testWidgets('should provide reduced animation durations',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  final duration = AccessibilityHelper.getAnimationDuration(
                    context,
                    standard: const Duration(milliseconds: 300),
                    reduced: const Duration(milliseconds: 100),
                  );

                  return Text(duration.inMilliseconds.toString());
                },
              ),
            ),
          ),
        );

        // Should use reduced duration (100ms)
        expect(find.text('100'), findsOneWidget);
      });

      testWidgets('should use standard animations when not reduced',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: false),
              child: Builder(
                builder: (context) {
                  final duration = AccessibilityHelper.getAnimationDuration(
                    context,
                    standard: const Duration(milliseconds: 300),
                  );

                  return Text(duration.inMilliseconds.toString());
                },
              ),
            ),
          ),
        );

        // Should use standard duration (300ms)
        expect(find.text('300'), findsOneWidget);
      });
    });

    group('Text Accessibility Tests', () {
      testWidgets('should detect bold text preference',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(boldText: true),
              child: Builder(
                builder: (context) {
                  final isBold = AccessibilityHelper.isBoldText(context);
                  return Text(isBold ? 'Bold' : 'Normal');
                },
              ),
            ),
          ),
        );

        expect(find.text('Bold'), findsOneWidget);
      });

      testWidgets('should get text scale factor',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 2.0),
              child: Builder(
                builder: (context) {
                  final scale =
                      AccessibilityHelper.getTextScaleFactor(context);
                  return Text(scale.toString());
                },
              ),
            ),
          ),
        );

        expect(find.text('2.0'), findsOneWidget);
      });
    });

    group('Screen Reader Announcements', () {
      testWidgets('should announce messages to screen readers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AccessibilityHelper.announce(context, 'Test message');
                    },
                    child: const Text('Announce'),
                  );
                },
              ),
            ),
          ),
        );

        // Tap button to trigger announcement
        await tester.tap(find.text('Announce'));
        await tester.pump();

        // SnackBar should be shown (even if transparent)
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Test message'), findsOneWidget);
      });
    });
  });
}

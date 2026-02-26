# Accessibility Testing Guide

## Overview

This directory contains automated accessibility tests for the HIVMeet app, ensuring compliance with WCAG 2.1 Level AA standards. These tests validate color contrast ratios, touch target sizes, semantic labels, keyboard navigation, and screen reader support.

## Test Structure

```
test/accessibility/
├── comprehensive_accessibility_test.dart    # Core accessibility tests
├── widget_accessibility_validator_test.dart # Widget-level validation
├── README.md                               # This file
└── run_accessibility_tests.sh              # Test runner script
```

## Test Coverage

### 1. Color Contrast Ratio Tests (WCAG 2.1 AA)

**File**: `comprehensive_accessibility_test.dart`

**What is tested:**
- Relative luminance calculation for all colors
- Contrast ratios between foreground and background colors
- WCAG AA compliance (4.5:1 for normal text, 3:1 for large text)
- WCAG AAA compliance (7:1 for normal text, 4.5:1 for large text)
- Theme color combination validation

**WCAG Requirements:**
- Normal text: Minimum 4.5:1 contrast ratio
- Large text (18pt+ or 14pt+ bold): Minimum 3:1 contrast ratio
- UI components and graphics: Minimum 3:1 contrast ratio

**Example:**
```dart
test('should validate primary purple on white background (AA)', () {
  final ratio = AccessibilityHelper.getContrastRatio(
      AppColors.primaryPurple, Colors.white);

  expect(ratio, greaterThanOrEqualTo(4.5));
});
```

**Tested Color Combinations:**
- Primary purple on white: ✓
- Dark purple on white: ✓
- White on primary purple: ✓
- Error color on white: ✓
- Success color on white: ✓
- Charcoal text on white: ✓ (AAA)
- Slate text on white: ✓
- Turquoise on white: ✓

### 2. Touch Target Size Tests

**File**: `comprehensive_accessibility_test.dart`, `widget_accessibility_validator_test.dart`

**What is tested:**
- Minimum touch target size (44x44 dp per WCAG/iOS HIG)
- Touch target validation for all interactive elements
- Automatic padding to meet minimum sizes

**WCAG Requirements:**
- All interactive elements must be at least 44x44 dp
- Adjacent targets should have adequate spacing

**Example:**
```dart
test('should have minimum 44x44 dp touch targets', () {
  expect(AccessibilityHelper.minTouchTargetSize, equals(44.0));
  expect(AccessibilityHelper.meetsMinTouchTarget(44.0, 44.0), isTrue);
});
```

### 3. Semantic Labels Tests

**File**: `comprehensive_accessibility_test.dart`

**What is tested:**
- Semantic label generation for profile cards
- Action button labels (like, dislike, super like, rewind)
- Slider and range slider labels
- Toggle switch labels with state (enabled/disabled)
- Premium feature indicators in labels

**Screen Reader Compatibility:**
- TalkBack (Android)
- VoiceOver (iOS)

**Example:**
```dart
test('should generate comprehensive profile card semantic labels', () {
  final label = AccessibilityHelper.getProfileCardSemanticLabel(
    name: 'Alice',
    age: 28,
    distance: '3.5',
    isVerified: true,
  );

  expect(label, contains('Alice'));
  expect(label, contains('vérifié'));
});
```

### 4. Keyboard Navigation Tests

**File**: `widget_accessibility_validator_test.dart`

**What is tested:**
- Focusable elements for keyboard navigation
- Tab order and focus management
- Tap actions for interactive elements

**Example:**
```dart
testWidgets('should be focusable for keyboard navigation', () {
  final semantics = tester.getSemantics(find.byWidget(button));
  expect(semantics.hasFlag(SemanticsFlag.isFocusable), isTrue);
});
```

### 5. Screen Reader Support Tests

**File**: Discovery page and widget accessibility tests

**What is tested:**
- Proper semantics tree structure
- Enabled/disabled state announcements
- Premium feature announcements
- Daily limit context for screen readers
- Error and empty state announcements

### 6. Reduced Motion Tests

**File**: `comprehensive_accessibility_test.dart`

**What is tested:**
- Detection of reduced motion preference
- Animation duration adjustment (300ms → 100ms)
- Respect for system accessibility settings

**Example:**
```dart
testWidgets('should respect reduced motion preference', () {
  final duration = AccessibilityHelper.getAnimationDuration(
    context,
    standard: Duration(milliseconds: 300),
    reduced: Duration(milliseconds: 100),
  );
  // Duration should be 100ms when reduced motion is enabled
});
```

### 7. Text Scaling Tests

**File**: `comprehensive_accessibility_test.dart`, widget tests

**What is tested:**
- Support for text scale factors up to 3.0x
- Bold text preference handling
- Layout stability with large text

**Example:**
```dart
testWidgets('should handle large text scale factors', () {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaleFactor: 3.0),
      child: widget,
    ),
  );
  expect(tester.takeException(), isNull); // No overflow errors
});
```

## Running Accessibility Tests

### Run All Accessibility Tests

```bash
# From project root
flutter test test/accessibility/

# With coverage
flutter test test/accessibility/ --coverage
```

### Run Specific Test Files

```bash
# Comprehensive tests
flutter test test/accessibility/comprehensive_accessibility_test.dart

# Widget validation tests
flutter test test/accessibility/widget_accessibility_validator_test.dart
```

### Run with Helper Script

```bash
# Make script executable (first time only)
chmod +x test/accessibility/run_accessibility_tests.sh

# Run all tests
./test/accessibility/run_accessibility_tests.sh

# Run with verbose output
./test/accessibility/run_accessibility_tests.sh --verbose

# Run with coverage
./test/accessibility/run_accessibility_tests.sh --coverage
```

## Interpreting Test Results

### ✅ Passing Tests

All accessibility requirements met:
- ✓ Color contrast ratios meet WCAG AA (4.5:1+)
- ✓ Touch targets are at least 44x44 dp
- ✓ Semantic labels present and descriptive
- ✓ Screen reader compatible
- ✓ Keyboard navigable

### ❌ Failing Tests

**Common Issues:**

1. **Insufficient Contrast**
   ```
   Expected: <4.5>
   Actual: <3.2>

   Solution: Use darker/lighter colors or adjust opacity
   ```

2. **Touch Target Too Small**
   ```
   Touch target too small: 40.0x40.0. Minimum: 44x44dp

   Solution: Increase widget size or add padding
   ```

3. **Missing Semantic Label**
   ```
   Widget missing semantic label

   Solution: Add Semantics widget or semanticLabel property
   ```

## Accessibility Helper Utilities

### Color Contrast Calculation

```dart
// Calculate contrast ratio
final ratio = AccessibilityHelper.getContrastRatio(
  AppColors.primaryPurple,
  Colors.white,
);

// Check WCAG AA compliance
final meetsAA = AccessibilityHelper.meetsWCAGAA(
  foreground: AppColors.primaryPurple,
  background: Colors.white,
);

// Get quality description
final quality = AccessibilityHelper.getContrastQuality(
  AppColors.primaryPurple,
  Colors.white,
);
// Returns: "Good (AA)" or "Excellent (AAA)"
```

### Touch Target Validation

```dart
// Check if size meets minimum
final isValid = AccessibilityHelper.meetsMinTouchTarget(48.0, 48.0);

// Automatically add padding if needed
final wrappedWidget = AccessibilityHelper.ensureMinTouchTarget(
  child: smallWidget,
  currentWidth: 32.0,
  currentHeight: 32.0,
);
```

### Semantic Label Generation

```dart
// Profile card label
final profileLabel = AccessibilityHelper.getProfileCardSemanticLabel(
  name: 'Alice',
  age: 28,
  distance: '3.5',
  bio: 'Love hiking',
  isVerified: true,
  isPremium: true,
  compatibilityScore: 85,
);

// Action button label
final buttonLabel = AccessibilityHelper.getActionButtonLabel('like');
// Returns: "Aimer ce profil"

// Premium feature label
final premiumLabel = AccessibilityHelper.getActionButtonLabel(
  'superlike',
  isPremium: true,
);
// Returns: "Super like ce profil (fonctionnalité premium)"
```

### Animation Preferences

```dart
// Check if motion should be reduced
if (AccessibilityHelper.shouldReduceMotion(context)) {
  // Use shorter or no animations
}

// Get appropriate animation duration
final duration = AccessibilityHelper.getAnimationDuration(
  context,
  standard: Duration(milliseconds: 300),
  reduced: Duration(milliseconds: 100),
);
```

## Manual Accessibility Testing

Automated tests catch many issues, but manual testing is still essential:

### TalkBack (Android)

1. Enable TalkBack: Settings → Accessibility → TalkBack
2. Navigate using swipe gestures
3. Verify all elements are announced clearly
4. Check action descriptions are meaningful

### VoiceOver (iOS)

1. Enable VoiceOver: Settings → Accessibility → VoiceOver
2. Use two-finger swipe to read all content
3. Verify rotor actions work correctly
4. Check element ordering makes sense

### Color Contrast Analyzer

Use external tools for visual verification:
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Colour Contrast Analyser (CCA)](https://www.tpgi.com/color-contrast-checker/)

### Reduced Motion

1. Enable Reduce Motion: Settings → Accessibility → Motion
2. Verify animations are simplified or removed
3. Check essential information still conveyed

### Large Text

1. Increase text size: Settings → Display → Font Size (Maximum)
2. Verify UI doesn't overflow or break
3. Check all text remains readable

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run accessibility tests
        run: flutter test test/accessibility/

      - name: Generate coverage report
        run: |
          flutter test test/accessibility/ --coverage
          genhtml coverage/lcov.info -o coverage/html
```

## Accessibility Checklist

Before marking a feature as complete, verify:

- [ ] All text has minimum 4.5:1 contrast ratio
- [ ] All interactive elements are at least 44x44 dp
- [ ] All widgets have semantic labels
- [ ] Screen reader navigation is logical
- [ ] Keyboard navigation works (where applicable)
- [ ] Reduced motion is respected
- [ ] Text scaling up to 200% doesn't break layout
- [ ] Error messages are accessible
- [ ] Empty states are accessible
- [ ] Premium features are announced as such

## Resources

### WCAG 2.1 Guidelines
- [WCAG 2.1 Overview](https://www.w3.org/WAI/WCAG21/quickref/)
- [Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Touch Target Size](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)

### Flutter Accessibility
- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Semantics Widget](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)

### Platform Guidelines
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android Accessibility Guidelines](https://developer.android.com/guide/topics/ui/accessibility)

## Support

For questions or issues with accessibility tests:
1. Check this README for guidance
2. Review existing test files for examples
3. Consult WCAG 2.1 documentation
4. Test manually with screen readers

## Contributing

When adding new UI components:
1. Create corresponding accessibility tests
2. Verify all automated tests pass
3. Perform manual screen reader testing
4. Document any accessibility considerations
5. Update this README if adding new test patterns

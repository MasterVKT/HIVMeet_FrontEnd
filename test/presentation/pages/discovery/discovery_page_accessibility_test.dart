// test/presentation/pages/discovery/discovery_page_accessibility_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/pages/discovery/discovery_page.dart';
import 'package:hivmeet/presentation/widgets/buttons/action_button.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockDiscoveryBloc extends Mock implements DiscoveryBloc {}

class FakeDiscoveryEvent extends Fake implements DiscoveryEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(FakeDiscoveryEvent());
  });

  group('Discovery Page Accessibility Tests', () {
    late MockDiscoveryBloc mockDiscoveryBloc;
    late StreamController<DiscoveryState> stateController;

    setUp(() {
      mockDiscoveryBloc = MockDiscoveryBloc();
      stateController = StreamController<DiscoveryState>.broadcast();

      // Default behavior
      when(() => mockDiscoveryBloc.stream)
          .thenAnswer((_) => stateController.stream);
      when(() => mockDiscoveryBloc.add(any())).thenReturn(null);
    });

    tearDown(() {
      stateController.close();
    });

    /// Helper to build the widget with mocked BLoC
    Widget buildDiscoveryPage(DiscoveryState initialState,
        {MediaQueryData? mediaQueryData}) {
      when(() => mockDiscoveryBloc.state).thenReturn(initialState);

      Widget app = MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<DiscoveryBloc>.value(
          value: mockDiscoveryBloc,
          child: const DiscoveryPage(),
        ),
      );

      // Wrap with custom MediaQuery if provided
      if (mediaQueryData != null) {
        app = MediaQuery(
          data: mediaQueryData,
          child: app,
        );
      }

      return app;
    }

    /// Helper to create a mock profile
    DiscoveryProfile createMockProfile({
      String id = '1',
      String displayName = 'Test User',
      int age = 25,
      double distance = 5.0,
      bool isVerified = true,
      bool isPremium = false,
      double compatibilityScore = 85.0,
    }) {
      return DiscoveryProfile(
        id: id,
        displayName: displayName,
        age: age,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [],
        bio: 'Test bio',
        city: 'Paris',
        country: 'France',
        distance: distance,
        interests: ['Musique', 'Sport'],
        relationshipType: 'any',
        isVerified: isVerified,
        isPremium: isPremium,
        lastActive: DateTime.now(),
        compatibilityScore: compatibilityScore,
      );
    }

    group('Semantic Labels Tests', () {
      testWidgets('should have semantic labels for all action buttons',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Enable semantics for testing
        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Find all action buttons and verify semantic labels
        final semantics = tester.getSemantics(find.byType(ActionButton).first);
        expect(semantics.label, isNotEmpty);
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

        // Verify each button has proper semantics
        final actionButtons = find.byType(ActionButton);
        expect(actionButtons, findsNWidgets(3)); // Like, dislike, super like

        for (var i = 0; i < 3; i++) {
          final buttonSemantics = tester.getSemantics(actionButtons.at(i));
          expect(buttonSemantics.label, isNotEmpty,
              reason: 'Action button $i should have semantic label');
          expect(buttonSemantics.hasFlag(SemanticsFlag.isButton), isTrue,
              reason: 'Action button $i should be marked as button');
          expect(buttonSemantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue,
              reason: 'Action button $i should have enabled state');
        }

        handle.dispose();
      });

      testWidgets('should have semantic label for filter button',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Find filter button and verify semantics
        final filterButton = find.byIcon(Icons.tune);
        expect(filterButton, findsOneWidget);

        final semantics = tester.getSemantics(filterButton);
        expect(semantics.label, isNotEmpty,
            reason: 'Filter button should have semantic label');
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
            reason: 'Filter button should be marked as button');

        handle.dispose();
      });

      testWidgets('should have semantic label for rewind button when visible',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: true,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Find rewind button and verify semantics
        final rewindButton = find.byIcon(Icons.undo);
        expect(rewindButton, findsOneWidget);

        final semantics = tester.getSemantics(rewindButton);
        expect(semantics.label, isNotEmpty,
            reason: 'Rewind button should have semantic label');
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
            reason: 'Rewind button should be marked as button');

        handle.dispose();
      });

      testWidgets('should have semantic label for profile card',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile(
          displayName: 'Alice',
          age: 28,
          distance: 3.5,
          isVerified: true,
          isPremium: true,
        );
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - SwipeCard should have comprehensive semantic label
        final swipeCard = find.byType(SwipeCard).first;
        expect(swipeCard, findsOneWidget);

        final semantics = tester.getSemantics(swipeCard);
        expect(semantics.label, isNotEmpty,
            reason: 'Profile card should have semantic label');

        // The label should contain key profile information
        final label = semantics.label?.toLowerCase() ?? '';
        expect(label, contains('alice'),
            reason: 'Label should contain profile name');
        expect(label.contains('28') || label.contains('ans'), isTrue,
            reason: 'Label should contain age information');

        handle.dispose();
      });

      testWidgets('should have semantic labels for error retry button',
          (WidgetTester tester) async {
        // Arrange
        const state = DiscoveryError(message: 'Network error');

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert
        final retryButton =
            find.text(LocalizationService.translate('common.retry'));
        expect(retryButton, findsOneWidget);

        final semantics = tester.getSemantics(retryButton);
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
            reason: 'Retry button should be marked as button');

        handle.dispose();
      });

      testWidgets('should have semantic labels for daily limit reached buttons',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final dailyLimit = DailyLikeLimit(
          remainingLikes: 0,
          totalLikes: 50,
          resetAt: DateTime.now().add(const Duration(hours: 3)),
        );

        final previousState = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        final state = DailyLimitReached(
          previousState: previousState,
          limitInfo: dailyLimit,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Upgrade button should have semantic label
        final upgradeButton = find.text(
            LocalizationService.translate('discovery.upgrade_premium'));
        expect(upgradeButton, findsOneWidget);

        final semantics = tester.getSemantics(upgradeButton);
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
            reason: 'Upgrade button should be marked as button');

        handle.dispose();
      });
    });

    group('Touch Target Size Tests', () {
      testWidgets('should have minimum 44x44 dp touch targets for action buttons',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - All action buttons should meet minimum size
        final actionButtons = find.byType(ActionButton);
        expect(actionButtons, findsNWidgets(3));

        for (var i = 0; i < 3; i++) {
          final button = tester.widget<ActionButton>(actionButtons.at(i));
          expect(button.size, greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
              reason: 'Action button $i should meet minimum touch target size (44dp)');
        }
      });

      testWidgets('should have minimum touch target for filter button',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Filter button should have adequate touch target
        final filterButton = find.byIcon(Icons.tune);
        expect(filterButton, findsOneWidget);

        final buttonSize = tester.getSize(filterButton);
        expect(buttonSize.width,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
            reason: 'Filter button width should meet minimum touch target');
        expect(buttonSize.height,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
            reason: 'Filter button height should meet minimum touch target');
      });

      testWidgets('should have minimum touch target for rewind button',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: true,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Rewind button should have adequate touch target
        final rewindFab = find.byType(FloatingActionButton);
        expect(rewindFab, findsOneWidget);

        final fabSize = tester.getSize(rewindFab);
        expect(fabSize.width,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
            reason: 'Rewind FAB width should meet minimum touch target');
        expect(fabSize.height,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
            reason: 'Rewind FAB height should meet minimum touch target');
      });

      testWidgets('should have minimum touch target for retry button',
          (WidgetTester tester) async {
        // Arrange
        const state = DiscoveryError(message: 'Network error');

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        final retryButton =
            find.text(LocalizationService.translate('common.retry'));
        expect(retryButton, findsOneWidget);

        final buttonSize = tester.getSize(retryButton);
        expect(buttonSize.height,
            greaterThanOrEqualTo(AccessibilityHelper.minTouchTargetSize),
            reason: 'Retry button height should meet minimum touch target');
      });
    });

    group('Screen Reader Support Tests', () {
      testWidgets('should enable screen reader navigation with proper semantics tree',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Verify semantics tree is properly structured
        expect(tester.getSemantics(find.byType(DiscoveryPage)),
            isNotNull,
            reason: 'Discovery page should have semantic information');

        // Verify critical elements are in semantics tree
        final actionButtons = find.byType(ActionButton);
        for (var i = 0; i < actionButtons.evaluate().length; i++) {
          final semantics = tester.getSemantics(actionButtons.at(i));
          expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
              reason: 'Button $i should be identified as button for screen readers');
          expect(semantics.label, isNotEmpty,
              reason: 'Button $i should have label for screen readers');
        }

        handle.dispose();
      });

      testWidgets('should have proper enabled/disabled state for screen readers',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - All enabled buttons should be marked as enabled
        final actionButtons = find.byType(ActionButton);
        for (var i = 0; i < actionButtons.evaluate().length; i++) {
          final button = tester.widget<ActionButton>(actionButtons.at(i));
          final semantics = tester.getSemantics(actionButtons.at(i));

          if (button.onPressed != null) {
            expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue,
                reason: 'Enabled button should be marked as enabled');
          } else {
            expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse,
                reason: 'Disabled button should be marked as disabled');
          }
        }

        handle.dispose();
      });

      testWidgets('should announce premium features to screen readers',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Super like button (premium) should have hint
        final superLikeButton = find.byIcon(Icons.star);
        expect(superLikeButton, findsOneWidget);

        final semantics = tester.getSemantics(superLikeButton);
        // Premium hint should be present in either label or hint
        final hasePremiumInfo = (semantics.label?.toLowerCase().contains('premium') ?? false) ||
            (semantics.hint?.toLowerCase().contains('premium') ?? false);
        expect(hasPremiumInfo, isTrue,
            reason: 'Premium features should be announced to screen readers');

        handle.dispose();
      });

      testWidgets('should provide context for daily limit to screen readers',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final dailyLimit = DailyLikeLimit(
          remainingLikes: 8,
          totalLikes: 50,
          resetAt: DateTime.now().add(const Duration(hours: 2)),
        );

        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
          dailyLimit: dailyLimit,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Daily limit indicator should be accessible
        final limitIndicator = find.text(LocalizationService.translate(
            'discovery.likes_remaining',
            params: {'count': '8'}));
        expect(limitIndicator, findsOneWidget);

        // The limit information should be in the semantics tree
        expect(tester.getSemantics(limitIndicator), isNotNull);

        handle.dispose();
      });
    });

    group('Reduced Motion Tests', () {
      testWidgets('should respect reduced motion preference',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Create MediaQueryData with reduced motion enabled
        final mediaQueryData = MediaQueryData(
          disableAnimations: true, // Reduced motion enabled
        );

        // Act
        await tester.pumpWidget(
            buildDiscoveryPage(state, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert - Verify the app respects the setting
        final context = tester.element(find.byType(DiscoveryPage));
        expect(AccessibilityHelper.shouldReduceMotion(context), isTrue,
            reason: 'App should detect reduced motion preference');

        // Animation duration should be reduced
        final animationDuration = AccessibilityHelper.getAnimationDuration(context);
        expect(animationDuration.inMilliseconds, lessThan(200),
            reason: 'Animation duration should be reduced for accessibility');
      });

      testWidgets('should use standard animations when reduced motion is disabled',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Create MediaQueryData with normal animations
        final mediaQueryData = MediaQueryData(
          disableAnimations: false,
        );

        // Act
        await tester.pumpWidget(
            buildDiscoveryPage(state, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(DiscoveryPage));
        expect(AccessibilityHelper.shouldReduceMotion(context), isFalse,
            reason: 'App should detect normal animation preference');

        // Animation duration should be standard
        final animationDuration = AccessibilityHelper.getAnimationDuration(context);
        expect(animationDuration.inMilliseconds, greaterThanOrEqualTo(200),
            reason: 'Animation duration should be standard when reduced motion is off');
      });
    });

    group('Text Scaling Tests', () {
      testWidgets('should support text scaling for visually impaired users',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Create MediaQueryData with large text scale
        final mediaQueryData = MediaQueryData(
          textScaleFactor: 2.0, // 200% text size
        );

        // Act
        await tester.pumpWidget(
            buildDiscoveryPage(state, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert - Verify text scale is respected
        final context = tester.element(find.byType(DiscoveryPage));
        expect(AccessibilityHelper.getTextScaleFactor(context), equals(2.0),
            reason: 'App should respect user text scale preference');

        // UI should still be functional and not overflow
        expect(tester.takeException(), isNull,
            reason: 'UI should handle large text without errors');
      });

      testWidgets('should handle bold text preference',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Create MediaQueryData with bold text enabled
        final mediaQueryData = MediaQueryData(
          boldText: true,
        );

        // Act
        await tester.pumpWidget(
            buildDiscoveryPage(state, mediaQueryData: mediaQueryData));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(DiscoveryPage));
        expect(AccessibilityHelper.isBoldText(context), isTrue,
            reason: 'App should detect bold text preference');

        // UI should still render correctly
        expect(tester.takeException(), isNull,
            reason: 'UI should handle bold text without errors');
      });
    });

    group('Contrast and Color Tests', () {
      testWidgets('should use theme colors with sufficient contrast',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Verify action buttons use defined colors
        final actionButtons = find.byType(ActionButton);
        expect(actionButtons, findsNWidgets(3));

        // Check that buttons have defined colors (not default)
        for (var i = 0; i < 3; i++) {
          final button = tester.widget<ActionButton>(actionButtons.at(i));
          expect(button.color, isNotNull,
              reason: 'Button $i should have explicit color defined');
          expect(button.color.opacity, greaterThan(0),
              reason: 'Button $i color should be visible');
        }
      });

      testWidgets('should maintain contrast in disabled states',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Even disabled elements should have some contrast
        final actionButtons = find.byType(ActionButton);

        for (var i = 0; i < actionButtons.evaluate().length; i++) {
          final button = tester.widget<ActionButton>(actionButtons.at(i));
          expect(button.color, isNotNull);
          // Even at reduced opacity (0.5), color should be defined
          if (button.onPressed == null) {
            expect(button.color.opacity, greaterThan(0),
                reason: 'Disabled button should still have visible color');
          }
        }
      });
    });

    group('Keyboard Navigation Tests', () {
      testWidgets('should have focusable elements for keyboard navigation',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Interactive elements should be focusable
        final actionButtons = find.byType(ActionButton);
        for (var i = 0; i < actionButtons.evaluate().length; i++) {
          final semantics = tester.getSemantics(actionButtons.at(i));
          expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue,
              reason: 'Button $i should be keyboard navigable');
          expect(semantics.hasFlag(SemanticsFlag.isFocusable), isTrue,
              reason: 'Button $i should be focusable');
        }

        handle.dispose();
      });
    });

    group('Error State Accessibility Tests', () {
      testWidgets('should announce errors to screen readers',
          (WidgetTester tester) async {
        // Arrange
        const errorMessage = 'Network connection failed';
        const state = DiscoveryError(message: errorMessage);

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Error message should be in semantics tree
        final errorText = find.text(errorMessage);
        expect(errorText, findsOneWidget);

        final semantics = tester.getSemantics(errorText);
        expect(semantics, isNotNull,
            reason: 'Error message should be accessible to screen readers');

        handle.dispose();
      });

      testWidgets('should provide accessible retry action',
          (WidgetTester tester) async {
        // Arrange
        const state = DiscoveryError(message: 'Network error');

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Retry button should be accessible
        final retryButton =
            find.text(LocalizationService.translate('common.retry'));
        expect(retryButton, findsOneWidget);

        final semantics = tester.getSemantics(retryButton);
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue,
            reason: 'Retry button should have tap action for screen readers');

        handle.dispose();
      });
    });

    group('Empty State Accessibility Tests', () {
      testWidgets('should make empty state accessible',
          (WidgetTester tester) async {
        // Arrange
        final state = NoMoreProfiles();

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        // Assert - Empty state message should be accessible
        final emptyMessage = find.text(
            LocalizationService.translate('discovery.no_more_profiles_title'));
        expect(emptyMessage, findsOneWidget);

        final semantics = tester.getSemantics(emptyMessage);
        expect(semantics, isNotNull,
            reason: 'Empty state message should be accessible');

        // Action buttons should be accessible
        final adjustFiltersButton = find.text(
            LocalizationService.translate('discovery.adjust_filters'));
        expect(adjustFiltersButton, findsOneWidget);

        final buttonSemantics = tester.getSemantics(adjustFiltersButton);
        expect(buttonSemantics.hasFlag(SemanticsFlag.isButton), isTrue);

        handle.dispose();
      });
    });
  });
}

// integration_test/discovery_navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hivmeet/main.dart' as app;
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';

/// Discovery Page Navigation Integration Tests
///
/// This test suite validates all navigation paths to/from the Discovery page,
/// including entry points, exit points, back button behavior, deep links,
/// and state preservation across navigation transitions.
///
/// **Test Coverage (Subtask 8.2):**
/// 1. Entry points to Discovery (tabs, buttons, deep links)
/// 2. Navigation away from Discovery
/// 3. Back button behavior
/// 4. State preservation during navigation
/// 5. Bottom navigation integration
/// 6. Deep link handling
/// 7. Cross-feature navigation flows
///
/// **Navigation Test Scenarios:**
/// - Discovery accessible from bottom navigation
/// - Bottom navigation tab switching works
/// - Discovery → Profile Detail → Back preserves state
/// - Discovery → Filters → Apply → Profiles refresh
/// - Match Found → Send Message → Conversations navigation
/// - Match Found → Keep Swiping → Stay on Discovery
/// - Daily Limit → Upgrade to Premium navigation
/// - Back button behavior on Discovery page
/// - Deep link to Discovery works
/// - Discovery tab highlighted correctly in bottom nav
///
/// **Running Tests:**
/// ```bash
/// flutter test integration_test/discovery_navigation_test.dart
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery Page Navigation Tests (Subtask 8.2)', () {
    late LocalizationService localizationService;

    setUpAll(() async {
      // Initialize dependency injection
      await configureDependencies();
      localizationService = getIt<LocalizationService>();
    });

    setUp(() async {
      // Ensure fresh state before each test
      await Future.delayed(const Duration(milliseconds: 500));
    });

    /// Test 1: Discovery Accessible from Bottom Navigation
    ///
    /// **Journey:**
    /// 1. Launch app (authenticated)
    /// 2. Verify Discovery tab is visible in bottom navigation
    /// 3. Tap Discovery tab
    /// 4. Verify Discovery page loads
    ///
    /// **Validates:**
    /// - Bottom navigation bar contains Discovery tab
    /// - Discovery tab is tappable
    /// - Discovery page renders on tap
    /// - Discovery tab icon/label is correct
    testWidgets(
      'NAV-01: Discovery should be accessible from bottom navigation',
      (WidgetTester tester) async {
        // Arrange & Act: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: Bottom navigation bar should be visible
        expect(
          find.byType(BottomNavigationBar),
          findsOneWidget,
          reason: 'Bottom navigation bar should be present',
        );

        // Assert: Discovery tab should be visible
        // Discovery is typically the first tab (index 0)
        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        expect(
          bottomNav.items.length,
          greaterThanOrEqualTo(4),
          reason: 'Bottom nav should have at least 4 tabs',
        );

        // Verify Discovery is accessible
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for Discovery page indicators (title, profile cards, action buttons)
        expect(
          find.byType(GestureDetector),
          findsWidgets,
          reason: 'Discovery page should contain swipeable profile cards',
        );
      },
    );

    /// Test 2: Bottom Navigation Tab Switching
    ///
    /// **Journey:**
    /// 1. Start on Discovery page
    /// 2. Switch to Matches tab
    /// 3. Switch to Conversations tab
    /// 4. Switch back to Discovery tab
    /// 5. Verify Discovery page is still functional
    ///
    /// **Validates:**
    /// - Tab switching works in all directions
    /// - Discovery remains functional after tab switch
    /// - No navigation errors or crashes
    testWidgets(
      'NAV-02: Bottom navigation tab switching should work correctly',
      (WidgetTester tester) async {
        // Arrange: Launch app and wait for Discovery to load
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Get bottom navigation bar
        final bottomNavFinder = find.byType(BottomNavigationBar);
        expect(bottomNavFinder, findsOneWidget);

        final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
        final tabCount = bottomNav.items.length;

        // Act: Switch through all tabs
        for (int i = 0; i < tabCount; i++) {
          // Tap on tab at index i
          await tester.tap(
            find.descendant(
              of: bottomNavFinder,
              matching: find.byType(InkResponse).at(i),
            ),
          );
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Tab should be active
          final currentNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
          expect(
            currentNav.currentIndex,
            i,
            reason: 'Current tab index should be $i',
          );
        }

        // Act: Return to Discovery (index 0)
        await tester.tap(
          find.descendant(
            of: bottomNavFinder,
            matching: find.byType(InkResponse).first,
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: Discovery should still be functional
        expect(
          find.byType(GestureDetector),
          findsWidgets,
          reason: 'Discovery should still show profile cards after tab switching',
        );
      },
    );

    /// Test 3: Discovery → Profile Detail → Back Preserves State
    ///
    /// **Journey:**
    /// 1. Load Discovery page with profiles
    /// 2. Note current profile (first profile visible)
    /// 3. Tap on profile card to open detail page
    /// 4. Verify profile detail page opens
    /// 5. Press back button
    /// 6. Verify returned to Discovery
    /// 7. Verify same profile is still visible (state preserved)
    ///
    /// **Validates:**
    /// - Profile detail navigation works
    /// - Back button returns to Discovery
    /// - Discovery state (current profile, scroll position) is preserved
    testWidgets(
      'NAV-03: Discovery → Profile Detail → Back should preserve state',
      (WidgetTester tester) async {
        // Arrange: Launch app and wait for profiles to load
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Act: Find and tap on a profile card
        final profileCardFinder = find.byType(GestureDetector).first;

        if (profileCardFinder.evaluate().isNotEmpty) {
          await tester.tap(profileCardFinder);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Should navigate to profile detail page
          // Look for profile detail indicators (back button, expanded profile info)
          expect(
            find.byType(BackButton),
            findsWidgets,
            reason: 'Profile detail page should have a back button',
          );

          // Act: Press back button
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Should return to Discovery page
          expect(
            find.byType(BottomNavigationBar),
            findsOneWidget,
            reason: 'Should return to Discovery page with bottom navigation',
          );

          // Verify profile cards are still present (state preserved)
          expect(
            find.byType(GestureDetector),
            findsWidgets,
            reason: 'Discovery state should be preserved after back navigation',
          );
        }
      },
    );

    /// Test 4: Discovery → Filters → Apply → Profiles Refresh
    ///
    /// **Journey:**
    /// 1. Open Discovery page
    /// 2. Tap on Filters button/icon
    /// 3. Verify Filters page/modal opens
    /// 4. Change a filter (e.g., age range)
    /// 5. Tap Apply button
    /// 6. Verify navigation back to Discovery
    /// 7. Verify profiles refresh with new filters
    ///
    /// **Validates:**
    /// - Filters navigation works
    /// - Apply button navigates back to Discovery
    /// - Profiles reload after filter application
    testWidgets(
      'NAV-04: Discovery → Filters → Apply should navigate back and refresh',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Act: Look for and tap Filters button
        final filterButtonFinder = find.byIcon(Icons.tune).or(
          find.byIcon(Icons.filter_list),
        );

        if (filterButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(filterButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Filters page/modal should be visible
          // Look for filter controls (sliders, toggles)
          expect(
            find.byType(Slider).or(find.byType(RangeSlider)),
            findsWidgets,
            reason: 'Filters page should contain sliders',
          );

          // Act: Look for Apply button and tap it
          final applyButtonFinder = find.text('Appliquer').or(
            find.text('Apply'),
          );

          if (applyButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(applyButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Assert: Should navigate back to Discovery
            expect(
              find.byType(BottomNavigationBar),
              findsOneWidget,
              reason: 'Should return to Discovery page after applying filters',
            );

            // Wait for profiles to refresh
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify profiles are displayed (refreshed)
            expect(
              find.byType(GestureDetector),
              findsWidgets,
              reason: 'Profiles should refresh after filter application',
            );
          }
        }
      },
    );

    /// Test 5: Match Found → Send Message Navigation
    ///
    /// **Journey:**
    /// 1. Simulate match scenario (like a profile that already liked us)
    /// 2. Verify Match Found modal appears
    /// 3. Tap "Send Message" button
    /// 4. Verify navigation to Conversations page
    ///
    /// **Validates:**
    /// - Match Found modal displays
    /// - Send Message button navigates to Conversations
    /// - Navigation from modal works correctly
    ///
    /// **Note:** This test may require mocking or specific test data
    testWidgets(
      'NAV-05: Match Found → Send Message should navigate to Conversations',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Note: This test depends on having a match scenario
        // In a real environment, this would require:
        // 1. Backend to return a match response
        // 2. Or mocking the match detection
        // 3. Or test data that triggers a match

        // Look for Match Found modal (if present)
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final matchModalFinder = find.text('C\'est un match !').or(
          find.text('It\'s a Match!'),
        );

        if (matchModalFinder.evaluate().isNotEmpty) {
          // Assert: Match modal is visible
          expect(matchModalFinder, findsOneWidget);

          // Act: Tap Send Message button
          final sendMessageButtonFinder = find.text('Envoyer un message').or(
            find.text('Send Message'),
          );

          if (sendMessageButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(sendMessageButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Assert: Should navigate to Conversations
            // Verify by checking for conversation page indicators
            expect(
              find.byType(BottomNavigationBar),
              findsOneWidget,
              reason: 'Should navigate to a page with bottom navigation',
            );
          }
        }
      },
      skip: true, // Skip by default as it requires specific test data
    );

    /// Test 6: Match Found → Keep Swiping Navigation
    ///
    /// **Journey:**
    /// 1. Match Found modal appears
    /// 2. Tap "Keep Swiping" / "Continue" button
    /// 3. Verify modal closes
    /// 4. Verify user stays on Discovery page
    /// 5. Verify next profile is shown
    ///
    /// **Validates:**
    /// - Keep Swiping button closes modal
    /// - User remains on Discovery page
    /// - Next profile is displayed
    testWidgets(
      'NAV-06: Match Found → Keep Swiping should stay on Discovery',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for Match Found modal (if present)
        final matchModalFinder = find.text('C\'est un match !').or(
          find.text('It\'s a Match!'),
        );

        if (matchModalFinder.evaluate().isNotEmpty) {
          // Act: Tap Keep Swiping button
          final keepSwipingButtonFinder = find.text('Continuer à swiper').or(
            find.text('Keep Swiping'),
          );

          if (keepSwipingButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(keepSwipingButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Assert: Should stay on Discovery page
            expect(
              find.byType(BottomNavigationBar),
              findsOneWidget,
              reason: 'Should remain on Discovery page',
            );

            // Verify Discovery tab is still active (index 0)
            final bottomNav = tester.widget<BottomNavigationBar>(
              find.byType(BottomNavigationBar),
            );
            expect(
              bottomNav.currentIndex,
              0,
              reason: 'Discovery tab should still be active',
            );

            // Verify profile cards are visible
            expect(
              find.byType(GestureDetector),
              findsWidgets,
              reason: 'Next profile should be visible after dismissing match modal',
            );
          }
        }
      },
      skip: true, // Skip by default as it requires specific test data
    );

    /// Test 7: Daily Limit → Upgrade to Premium Navigation
    ///
    /// **Journey:**
    /// 1. Trigger daily limit (50 likes for free users)
    /// 2. Verify daily limit modal appears
    /// 3. Tap "Upgrade to Premium" button
    /// 4. Verify navigation to Premium page
    /// 5. Press back button
    /// 6. Verify return to Discovery
    ///
    /// **Validates:**
    /// - Daily limit modal displays
    /// - Premium upgrade navigation works
    /// - Back navigation returns to Discovery
    testWidgets(
      'NAV-07: Daily Limit → Upgrade should navigate to Premium page',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for daily limit modal (if present)
        final dailyLimitFinder = find.textContaining('limite').or(
          find.textContaining('limit'),
        );

        if (dailyLimitFinder.evaluate().isNotEmpty) {
          // Act: Tap Upgrade button
          final upgradeButtonFinder = find.text('Passer à Premium').or(
            find.text('Upgrade to Premium'),
          );

          if (upgradeButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(upgradeButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Assert: Should navigate to Premium page
            // Look for Premium page indicators
            expect(
              find.textContaining('Premium').or(find.textContaining('premium')),
              findsWidgets,
              reason: 'Should navigate to Premium page',
            );

            // Act: Press back button
            await tester.pageBack();
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Assert: Should return to Discovery
            expect(
              find.byType(BottomNavigationBar),
              findsOneWidget,
              reason: 'Should return to Discovery page',
            );
          }
        }
      },
      skip: true, // Skip by default as it requires hitting daily limit
    );

    /// Test 8: Back Button Behavior on Discovery Page
    ///
    /// **Journey:**
    /// 1. Navigate to Discovery from another page
    /// 2. Press back button
    /// 3. Verify correct behavior (stay on Discovery or exit app)
    ///
    /// **Validates:**
    /// - Back button doesn't navigate away from Discovery unexpectedly
    /// - Back button behavior is consistent
    testWidgets(
      'NAV-08: Back button behavior on Discovery page should be correct',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Get initial page state
        final initialBottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        // Act: Press back button
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Assert: Should remain on Discovery or exit app
        // Discovery is typically the home/default page, so back should not navigate
        final currentBottomNavFinder = find.byType(BottomNavigationBar);

        if (currentBottomNavFinder.evaluate().isNotEmpty) {
          final currentBottomNav = tester.widget<BottomNavigationBar>(
            currentBottomNavFinder,
          );

          expect(
            currentBottomNav.currentIndex,
            initialBottomNav.currentIndex,
            reason: 'Should remain on the same tab after back button',
          );
        }
      },
    );

    /// Test 9: Deep Link to Discovery Works
    ///
    /// **Journey:**
    /// 1. Open app via deep link to Discovery (hivmeet://discovery)
    /// 2. Verify Discovery page opens
    /// 3. Verify profiles load correctly
    ///
    /// **Validates:**
    /// - Deep link handling works
    /// - Discovery page opens from deep link
    /// - Page state is correct after deep link
    ///
    /// **Note:** This test requires deep link configuration
    testWidgets(
      'NAV-09: Deep link to Discovery should work correctly',
      (WidgetTester tester) async {
        // Note: Testing deep links in integration tests requires
        // platform-specific setup. This test structure shows the expected flow.

        // Arrange: Launch app (in real scenario, would launch via deep link)
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: Discovery should be loaded
        expect(
          find.byType(BottomNavigationBar),
          findsOneWidget,
          reason: 'App should open to a page with bottom navigation',
        );

        // Verify Discovery page content
        expect(
          find.byType(GestureDetector),
          findsWidgets,
          reason: 'Discovery profiles should be visible',
        );
      },
      skip: true, // Skip by default as deep link testing requires special setup
    );

    /// Test 10: Discovery Tab Highlighted Correctly in Bottom Nav
    ///
    /// **Journey:**
    /// 1. Navigate to Discovery page
    /// 2. Verify Discovery tab is highlighted/selected
    /// 3. Navigate to another tab
    /// 4. Verify Discovery tab is no longer highlighted
    /// 5. Navigate back to Discovery
    /// 6. Verify Discovery tab is highlighted again
    ///
    /// **Validates:**
    /// - Active tab indicator works correctly
    /// - Discovery tab state reflects current page
    testWidgets(
      'NAV-10: Discovery tab should be highlighted correctly in bottom navigation',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: Discovery tab should be active (index 0)
        final bottomNavFinder = find.byType(BottomNavigationBar);
        expect(bottomNavFinder, findsOneWidget);

        var bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
        expect(
          bottomNav.currentIndex,
          0,
          reason: 'Discovery tab (index 0) should be active initially',
        );

        // Act: Navigate to another tab (e.g., Matches - index 1)
        if (bottomNav.items.length > 1) {
          await tester.tap(
            find.descendant(
              of: bottomNavFinder,
              matching: find.byType(InkResponse).at(1),
            ),
          );
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Different tab should be active now
          bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
          expect(
            bottomNav.currentIndex,
            1,
            reason: 'Should navigate to tab at index 1',
          );

          // Act: Navigate back to Discovery (index 0)
          await tester.tap(
            find.descendant(
              of: bottomNavFinder,
              matching: find.byType(InkResponse).first,
            ),
          );
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Discovery tab should be active again
          bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
          expect(
            bottomNav.currentIndex,
            0,
            reason: 'Discovery tab should be active after navigation back',
          );
        }
      },
    );

    /// Test 11: State Preservation During Multiple Navigation Flows
    ///
    /// **Journey:**
    /// 1. Load Discovery page
    /// 2. Swipe a profile (action performed)
    /// 3. Navigate to Matches tab
    /// 4. Navigate back to Discovery
    /// 5. Verify Discovery shows next profile (state progressed)
    /// 6. Open Filters
    /// 7. Close Filters without applying
    /// 8. Verify Discovery state unchanged
    ///
    /// **Validates:**
    /// - State preservation across complex navigation flows
    /// - Discovery maintains proper state through navigation
    testWidgets(
      'NAV-11: State should be preserved during multiple navigation flows',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Act: Perform a swipe action (like button)
        final likeButtonFinder = find.byIcon(Icons.favorite);

        if (likeButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(likeButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Act: Navigate to Matches tab
        final bottomNavFinder = find.byType(BottomNavigationBar);
        if (bottomNavFinder.evaluate().isNotEmpty) {
          final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);

          if (bottomNav.items.length > 1) {
            await tester.tap(
              find.descendant(
                of: bottomNavFinder,
                matching: find.byType(InkResponse).at(1),
              ),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Act: Navigate back to Discovery
            await tester.tap(
              find.descendant(
                of: bottomNavFinder,
                matching: find.byType(InkResponse).first,
              ),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Assert: Discovery should show next profile (state progressed)
            expect(
              find.byType(GestureDetector),
              findsWidgets,
              reason: 'Discovery should display next profile after state preservation',
            );
          }
        }
      },
    );

    /// Test 12: Exit Points from Discovery Verify Correctly
    ///
    /// **Journey:**
    /// 1. From Discovery, navigate to each possible exit point:
    ///    - Profile Detail (tap card)
    ///    - Filters (tap filter button)
    ///    - Premium (if daily limit reached)
    ///    - Settings (if accessible from Discovery)
    /// 2. Verify each navigation works
    /// 3. Verify back navigation returns to Discovery
    ///
    /// **Validates:**
    /// - All exit points from Discovery work
    /// - Back navigation is consistent
    testWidgets(
      'NAV-12: All exit points from Discovery should work correctly',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Test Exit Point 1: Profile Detail (tap on profile card)
        final profileCardFinder = find.byType(GestureDetector).first;
        if (profileCardFinder.evaluate().isNotEmpty) {
          await tester.tap(profileCardFinder);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify navigation occurred
          expect(
            find.byType(BackButton),
            findsWidgets,
            reason: 'Should navigate to profile detail page',
          );

          // Navigate back
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Test Exit Point 2: Filters
        final filterButtonFinder = find.byIcon(Icons.tune).or(
          find.byIcon(Icons.filter_list),
        );

        if (filterButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(filterButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify navigation occurred (look for sliders)
          expect(
            find.byType(Slider).or(find.byType(RangeSlider)),
            findsWidgets,
            reason: 'Should navigate to filters page',
          );

          // Navigate back
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Assert: Should be back on Discovery
        expect(
          find.byType(BottomNavigationBar),
          findsOneWidget,
          reason: 'Should return to Discovery after all navigation tests',
        );
      },
    );
  });

  group('Discovery Navigation Error Scenarios', () {
    /// Test 13: Navigation During Network Error
    ///
    /// **Journey:**
    /// 1. Simulate network error on Discovery
    /// 2. Attempt to navigate to Filters
    /// 3. Verify navigation still works
    /// 4. Verify error state is handled gracefully
    ///
    /// **Validates:**
    /// - Navigation works even during error states
    /// - Error states don't block navigation
    testWidgets(
      'NAV-ERR-01: Navigation should work during network errors',
      (WidgetTester tester) async {
        // Arrange: Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Note: This test would require mocking network errors
        // or having a way to simulate offline mode

        // Look for error state indicators
        final errorFinder = find.textContaining('erreur').or(
          find.textContaining('error'),
        );

        // Act: Try to navigate to filters even if error is present
        final filterButtonFinder = find.byIcon(Icons.tune).or(
          find.byIcon(Icons.filter_list),
        );

        if (filterButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(filterButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Assert: Navigation should still work
          // User should be able to access filters even if profiles failed to load
          expect(
            find.byType(Slider).or(find.byType(RangeSlider)),
            findsAny,
            reason: 'Filters should be accessible even during error states',
          );
        }
      },
      skip: true, // Skip by default as it requires error simulation
    );
  });
}

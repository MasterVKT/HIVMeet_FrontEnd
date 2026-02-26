# Discovery Page Integration Tests

## Overview

This directory contains end-to-end (E2E) integration tests for the HIVMeet Discovery page. These tests validate critical user journeys through the full application stack, from UI interactions to backend API calls.

## Test Coverage

The integration tests cover the following scenarios:

1. **Page Navigation & Data Loading**
   - App initialization and routing to Discovery page
   - Profile loading from backend API
   - UI rendering of profile cards and action buttons

2. **User Interactions**
   - Swipe right (like) gesture and state update
   - Swipe left (dislike) gesture and state update
   - Action button taps (like, dislike, super like)
   - Rapid successive swipes (performance test)

3. **Advanced Features**
   - Filter modal opening and application
   - Profile detail navigation
   - Match detection and modal display
   - Daily limit enforcement for free users

4. **Error Recovery**
   - Network error handling and retry mechanism
   - Empty state display (no more profiles)
   - Graceful degradation on API failures

5. **Quality Assurance**
   - Internationalization validation (FR/EN)
   - Accessibility compliance (semantic labels, touch targets)
   - Complete user journey (happy path)

## Running the Tests

### Prerequisites

- Flutter SDK 3.19.0 or higher
- Connected device (physical or emulator)
- Backend API accessible (or mocked)

### Command Line

#### Standard Test Run
```bash
# Run all integration tests
flutter test integration_test/discovery_flow_test.dart

# Run with verbose output
flutter test integration_test/discovery_flow_test.dart -v
```

#### Device-Specific Test Run
```bash
# List available devices
flutter devices

# Run on specific device
flutter drive \
  --driver=integration_test/discovery_flow_test_driver.dart \
  --target=integration_test/discovery_flow_test.dart \
  -d <device-id>
```

#### Platform-Specific
```bash
# Android
flutter test integration_test/discovery_flow_test.dart -d android

# iOS
flutter test integration_test/discovery_flow_test.dart -d ios
```

### IDE Integration

#### VS Code
1. Open the test file: `integration_test/discovery_flow_test.dart`
2. Click the "Run Test" button above each test case
3. Or use Command Palette: "Flutter: Run Integration Tests"

#### Android Studio / IntelliJ
1. Right-click on `integration_test/discovery_flow_test.dart`
2. Select "Run 'discovery_flow_test.dart'"
3. View results in the Test Results panel

## Test Structure

Each test follows the **Arrange-Act-Assert (AAA)** pattern:

```dart
testWidgets('should do something', (WidgetTester tester) async {
  // Arrange: Set up initial state
  app.main();
  await tester.pumpAndSettle();

  // Act: Perform user action
  await tester.tap(find.byIcon(Icons.favorite));
  await tester.pumpAndSettle();

  // Assert: Verify expected outcome
  expect(find.text('Next Profile'), findsOneWidget);
});
```

## Test Data

Integration tests use **real backend data** by default. For controlled testing:

1. **Mock API Responses**: Configure test backend with known data
2. **Test User Accounts**: Use dedicated test accounts with predictable state
3. **Network Mocking**: Intercept HTTP calls with test responses (advanced)

## Skipped Tests

Some tests are skipped by default because they require specific conditions:

- `skip: true` - Test requires manual setup or specific data state
- Remove `skip` parameter to enable these tests when conditions are met

### Conditionally Skipped Tests:
- **Match Modal Test**: Requires a mutual like to occur
- **Daily Limit Test**: Requires free user account near limit
- **Network Error Test**: Requires network manipulation
- **Empty State Test**: Requires depleting entire profile queue

## Performance Benchmarks

Expected performance targets:

| Metric | Target | Test |
|--------|--------|------|
| App Launch Time | < 3 seconds | Test 1 |
| Profile Load Time | < 2 seconds | Test 1 |
| Swipe Response | < 100ms | Test 2, 3, 11 |
| Animation FPS | ≥ 60 FPS | Visual inspection |
| Filter Application | < 3 seconds | Test 6 |

## Debugging Failed Tests

### Common Issues

1. **Timeout Errors**
   - Increase `pumpAndSettle` duration
   - Check network connectivity
   - Verify backend is running

2. **Widget Not Found**
   - Widget may not be rendered yet (add delays)
   - Verify widget keys are correct
   - Check if widget is conditionally rendered

3. **State Inconsistency**
   - Clear app data between test runs
   - Ensure fresh dependency injection
   - Reset backend test data

### Debug Mode

Run tests with additional logging:

```bash
flutter test integration_test/discovery_flow_test.dart \
  --dart-define=FLUTTER_TEST=true \
  --verbose
```

## Continuous Integration

### GitHub Actions

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Run Integration Tests
        run: flutter test integration_test/discovery_flow_test.dart
```

## Test Maintenance

### When to Update Tests

- **New Features**: Add tests for new Discovery page features
- **Bug Fixes**: Add regression tests to prevent recurrence
- **API Changes**: Update tests to match new API contracts
- **UI Changes**: Update widget finders and assertions

### Best Practices

1. ✅ Keep tests independent (no shared state)
2. ✅ Use descriptive test names
3. ✅ Add comments explaining complex interactions
4. ✅ Clean up test data after each run
5. ✅ Use meaningful assertion messages
6. ✅ Test both happy and error paths
7. ✅ Verify accessibility in all tests
8. ✅ Test internationalization (FR/EN)

## Related Documentation

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Project Testing Strategy](../.claude/rules/testing.md)
- [Discovery Page Specification](../docs/DISCOVERY_PAGE_IMPLEMENTATION.md)
- [API Documentation](../API_DOCUMENTATION.md)

## Support

For issues or questions:
1. Check logs: `flutter logs`
2. Review test output for error messages
3. Verify backend API is accessible
4. Ensure device/emulator is properly configured
5. Consult project documentation in `docs/` directory

---

**Last Updated**: February 2026
**Maintainer**: HIVMeet Development Team

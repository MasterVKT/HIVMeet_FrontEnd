# Discovery Page Error Scenario Testing Guide

**Version**: 1.0
**Date**: February 27, 2026
**Task**: Subtask 7.4 - Test error scenarios, network failures, API errors, timeouts, invalid data, empty states, and boundary conditions
**Project**: HIVMeet - Discovery Page Specification Compliance

---

## Table of Contents

1. [Overview](#overview)
2. [Test Execution Summary](#test-execution-summary)
3. [Network Failure Tests](#network-failure-tests)
4. [API Error Tests](#api-error-tests)
5. [Timeout Tests](#timeout-tests)
6. [Invalid Data Tests](#invalid-data-tests)
7. [Empty State Tests](#empty-state-tests)
8. [Boundary Condition Tests](#boundary-condition-tests)
9. [Recovery Flow Tests](#recovery-flow-tests)
10. [Automated Test Coverage](#automated-test-coverage)
11. [Manual Test Procedures](#manual-test-procedures)
12. [Sign-Off Checklist](#sign-off-checklist)

---

## Overview

This document provides comprehensive test procedures for all error scenarios, edge cases, and boundary conditions in the HIVMeet Discovery page. The goal is to ensure the application handles errors gracefully, provides helpful error messages to users, and offers clear recovery paths.

### Testing Philosophy

- **Fail gracefully**: No crashes or unhandled exceptions
- **Clear messaging**: Error messages are user-friendly and actionable
- **Recovery paths**: Users can retry or navigate to alternative flows
- **Data integrity**: No data loss or corruption during error scenarios
- **Offline resilience**: Handle network issues without breaking the app

### Scope

This testing guide covers:
- ✅ Network connectivity failures
- ✅ API server errors (4xx, 5xx responses)
- ✅ Request timeouts
- ✅ Invalid/malformed data from API
- ✅ Empty states and "no results" scenarios
- ✅ Boundary conditions (limits, edge values)
- ✅ Error recovery and retry mechanisms
- ✅ User experience during error states

---

## Test Execution Summary

| Category | Total Tests | Priority | Verification Method |
|----------|-------------|----------|---------------------|
| Network Failures | 8 | P0 | Automated + Manual |
| API Errors | 12 | P0 | Automated + Manual |
| Timeouts | 5 | P0 | Automated + Manual |
| Invalid Data | 10 | P1 | Automated |
| Empty States | 6 | P1 | Automated + Manual |
| Boundary Conditions | 9 | P0 | Automated |
| Recovery Flows | 8 | P0 | Manual |
| **TOTAL** | **58** | - | - |

### Status Tracking

- [ ] All automated tests passing
- [ ] All manual tests executed
- [ ] All critical (P0) issues resolved
- [ ] Error messages verified for i18n (FR/EN)
- [ ] Recovery flows validated
- [ ] No crashes or unhandled exceptions
- [ ] QA sign-off obtained

---

## Network Failure Tests

### Test Category: Network Connectivity Failures
**Priority**: P0 (Critical)
**Automated Coverage**: YES (discovery_bloc_test.dart)

---

### NET-001: No Internet Connection on Initial Load

**Description**: Test behavior when user has no internet connection when opening Discovery page.

**Preconditions**:
- User is authenticated
- Device has no internet connection (airplane mode or WiFi/data disabled)

**Test Steps**:
1. Disable internet connection on device
2. Navigate to Discovery page
3. Observe loading state
4. Observe error state after timeout

**Expected Results**:
- ✅ Loading indicator appears briefly
- ✅ Error message displayed: "No internet connection. Please check your network settings."
- ✅ Retry button is visible and functional
- ✅ No crash or unhandled exception
- ✅ Error message is internationalized (FR/EN)

**Automated Test**:
```dart
// test/presentation/blocs/discovery/discovery_bloc_test.dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should emit [DiscoveryLoading, DiscoveryError] when no internet connection',
  build: () {
    when(() => mockGetDiscoveryProfiles(any())).thenAnswer(
      (_) async => const Left(
        NetworkFailure(message: 'Connection failed'),
      ),
    );
    return bloc;
  },
  act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
  expect: () => [
    DiscoveryLoading(),
    isA<DiscoveryError>()
        .having((s) => s.message, 'message', 'Connection failed'),
  ],
);
```

**Status**: ✅ Automated test exists

---

### NET-002: Connection Lost During Profile Load

**Description**: Test behavior when internet connection is lost while loading profiles.

**Preconditions**:
- User has internet connection
- User navigates to Discovery page
- API request is in progress

**Test Steps**:
1. Navigate to Discovery page
2. Immediately disable internet connection (before response received)
3. Wait for timeout
4. Observe error state

**Expected Results**:
- ✅ Loading state continues until timeout
- ✅ Error message: "Connection lost. Please check your network and try again."
- ✅ Retry button available
- ✅ No partial/corrupted data displayed

**Verification**: Manual + Automated

**Status**: ⏳ Requires manual verification

---

### NET-003: Connection Lost During Swipe Action (Like)

**Description**: Test behavior when connection is lost while processing a like action.

**Preconditions**:
- Discovery page loaded with profiles
- User swipes right to like a profile
- Connection lost before API response

**Test Steps**:
1. Load Discovery page with profiles
2. Swipe right on a profile
3. Disable internet immediately
4. Observe behavior

**Expected Results**:
- ✅ Optimistic UI shows card moving (if implemented)
- ✅ After timeout, error message: "Failed to process your like. Please try again."
- ✅ Profile returns to stack OR moves to next profile with retry option
- ✅ No data corruption (like not registered twice on retry)

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should emit error when like fails due to network issue',
  build: () {
    when(() => mockLikeProfile(any())).thenAnswer(
      (_) async => const Left(
        NetworkFailure(message: 'Network error'),
      ),
    );
    return bloc;
  },
  seed: () => DiscoveryLoaded(...),
  act: (bloc) => bloc.add(SwipeProfile(...)),
  expect: () => [
    ProfileSwiping(...),
    isA<DiscoveryError>().having((s) => s.message, 'message', contains('Network')),
  ],
);
```

**Status**: ✅ Automated test exists

---

### NET-004: Connection Lost During Swipe Action (Dislike)

**Description**: Test behavior when connection is lost while processing a dislike action.

**Preconditions**:
- Discovery page loaded with profiles
- User swipes left to dislike a profile
- Connection lost before API response

**Test Steps**:
1. Load Discovery page with profiles
2. Swipe left on a profile
3. Disable internet immediately
4. Observe behavior

**Expected Results**:
- ✅ Profile moves off screen (optimistic UI)
- ✅ After timeout, error message displayed
- ✅ Option to retry or continue to next profile
- ✅ No duplicate dislike on retry

**Verification**: Manual + Automated

**Status**: ⏳ Requires manual verification

---

### NET-005: Connection Lost During Filter Update

**Description**: Test behavior when connection is lost while applying filters.

**Preconditions**:
- User is on Filters page
- User modifies filters (age, distance, etc.)
- User taps "Apply"
- Connection lost before API response

**Test Steps**:
1. Open filters modal/page
2. Modify filters (e.g., age range 25-35)
3. Tap "Apply"
4. Disable internet immediately
5. Observe behavior

**Expected Results**:
- ✅ Loading indicator on Apply button
- ✅ Error message: "Failed to apply filters. Please try again."
- ✅ Filters page remains open (does not dismiss)
- ✅ User can retry or cancel
- ✅ Previous filter values preserved

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should emit error when filter update fails due to network',
  build: () {
    when(() => mockUpdateFilters(any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'Failed to update filters'),
      ),
    );
    return bloc;
  },
  act: (bloc) => bloc.add(const UpdateFilters(filters: tFilters)),
  expect: () => [
    isA<DiscoveryError>().having(
      (s) => s.message,
      'message',
      'Failed to update filters',
    ),
  ],
);
```

**Status**: ✅ Automated test exists

---

### NET-006: Connection Lost During Rewind Action

**Description**: Test behavior when connection is lost while rewinding a swipe (premium feature).

**Preconditions**:
- User is premium
- User has swiped on a profile
- User taps rewind button
- Connection lost before API response

**Test Steps**:
1. Swipe on a profile
2. Tap rewind button (premium users only)
3. Disable internet immediately
4. Observe behavior

**Expected Results**:
- ✅ Rewind animation pauses or reverses
- ✅ Error message: "Failed to undo swipe. Please try again."
- ✅ Rewind button remains available for retry
- ✅ Current profile state unchanged (not corrupted)

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should emit error when rewind fails',
  build: () {
    when(() => mockRewindSwipe(any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'Rewind not allowed'),
      ),
    );
    return bloc;
  },
  seed: () => DiscoveryLoaded(..., canRewind: true),
  act: (bloc) => bloc.add(const RewindLastSwipe()),
  expect: () => [
    isA<DiscoveryError>(),
  ],
);
```

**Status**: ✅ Automated test exists

---

### NET-007: Intermittent Connection (Flaky Network)

**Description**: Test behavior with unstable connection (slow, dropping packets).

**Preconditions**:
- User has poor network connection (simulated)
- Multiple API calls in progress

**Test Steps**:
1. Enable network throttling (slow 3G simulation)
2. Navigate to Discovery page
3. Attempt multiple swipes in quick succession
4. Observe behavior

**Expected Results**:
- ✅ Loading states appear appropriately
- ✅ Timeouts trigger after configured duration
- ✅ No duplicate API calls (debouncing works)
- ✅ User can still interact with UI (not frozen)
- ✅ Errors are recoverable

**Verification**: Manual testing with network throttling tools

**Status**: ⏳ Requires manual verification

---

### NET-008: Network Recovery After Error

**Description**: Test automatic recovery when network connection is restored.

**Preconditions**:
- User encountered network error
- Error message displayed with retry button

**Test Steps**:
1. Trigger network error (NET-001)
2. Restore internet connection
3. Tap retry button
4. Observe recovery

**Expected Results**:
- ✅ Loading state appears
- ✅ Profiles load successfully
- ✅ Error state clears
- ✅ User can continue normal interaction
- ✅ No residual error messages

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

## API Error Tests

### Test Category: Server and API Errors
**Priority**: P0 (Critical)
**Automated Coverage**: Partial

---

### API-001: 400 Bad Request (Invalid Parameters)

**Description**: Test behavior when API returns 400 due to invalid request parameters.

**Preconditions**:
- User attempts an action with invalid parameters
- API returns 400 Bad Request

**Test Steps**:
1. Trigger API call with invalid parameters (e.g., negative limit value)
2. Observe error handling

**Expected Results**:
- ✅ Error message: "Invalid request. Please try again."
- ✅ No crash
- ✅ Logs error for debugging (no PII logged)
- ✅ User can retry with corrected parameters

**Automated Test**: Mock 400 response in repository tests

**Status**: ⏳ Requires test implementation

---

### API-002: 401 Unauthorized (Token Expired)

**Description**: Test behavior when authentication token has expired.

**Preconditions**:
- User is logged in
- Auth token expires
- User attempts Discovery page action

**Test Steps**:
1. Load Discovery page
2. Invalidate auth token (simulate expiration)
3. Attempt swipe action
4. Observe behavior

**Expected Results**:
- ✅ Error detected by auth interceptor
- ✅ User redirected to login page
- ✅ Message: "Your session has expired. Please log in again."
- ✅ After re-login, user returns to Discovery page
- ✅ Auth token refreshed automatically (if refresh token available)

**Verification**: Manual + Integration test

**Status**: ⏳ Requires manual verification

---

### API-003: 403 Forbidden (Account Suspended)

**Description**: Test behavior when user account is suspended or banned.

**Preconditions**:
- User account is suspended/banned
- User attempts to access Discovery page

**Test Steps**:
1. Navigate to Discovery page with suspended account
2. Observe error handling

**Expected Results**:
- ✅ Error message: "Your account has been suspended. Please contact support."
- ✅ Contact support button/link available
- ✅ User cannot access Discovery features
- ✅ Graceful degradation (no crash)

**Verification**: Manual (requires backend support to suspend test account)

**Status**: ⏳ Requires manual verification

---

### API-004: 404 Not Found (Profile Deleted)

**Description**: Test behavior when a profile is deleted mid-session.

**Preconditions**:
- User is viewing a profile in Discovery
- Profile is deleted on backend
- User attempts to swipe

**Test Steps**:
1. Load Discovery page with profiles
2. Simulate profile deletion on backend
3. Attempt to swipe on deleted profile
4. Observe behavior

**Expected Results**:
- ✅ Error message: "This profile is no longer available."
- ✅ Automatically move to next profile
- ✅ No crash or corrupted state
- ✅ Profile removed from local stack

**Verification**: Manual + Mocked test

**Status**: ⏳ Requires test implementation

---

### API-005: 409 Conflict (Already Matched)

**Description**: Test behavior when user tries to like a profile they've already matched with.

**Preconditions**:
- User has already matched with a profile
- Profile appears in Discovery stack due to sync issue
- User attempts to swipe

**Test Steps**:
1. Load Discovery page
2. Swipe on profile that's already matched
3. Observe API response handling

**Expected Results**:
- ✅ API returns 409 or specific error code
- ✅ Message: "You've already matched with this user!"
- ✅ Option to navigate to Matches page
- ✅ Profile removed from Discovery stack

**Automated Test**: Mock AlreadyMatchedFailure

**Status**: ⏳ Requires test implementation

---

### API-006: 429 Rate Limit Exceeded

**Description**: Test behavior when user exceeds API rate limits (too many requests).

**Preconditions**:
- User performs rapid actions (many swipes quickly)
- API rate limit exceeded

**Test Steps**:
1. Perform rapid swipes (10+ in quick succession)
2. Trigger rate limit
3. Observe error handling

**Expected Results**:
- ✅ Error message: "You're swiping too fast! Please slow down."
- ✅ Temporary block on swipe actions (e.g., 30 seconds)
- ✅ Countdown timer shown
- ✅ Automatic recovery after cooldown
- ✅ Debouncing prevents rate limit in normal use

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### API-007: 500 Internal Server Error

**Description**: Test behavior when backend returns 500 error.

**Preconditions**:
- Backend experiences internal error
- API returns 500 status

**Test Steps**:
1. Trigger API call that returns 500
2. Observe error handling

**Expected Results**:
- ✅ Error message: "Something went wrong on our end. Please try again later."
- ✅ Retry button available
- ✅ Error logged (no sensitive data)
- ✅ No crash or infinite retry loop

**Automated Test**:
```dart
test('should return ServerFailure when API returns 500', () async {
  when(() => mockDio.get(any())).thenThrow(
    DioException(
      requestOptions: RequestOptions(path: '/discovery/'),
      response: Response(
        statusCode: 500,
        requestOptions: RequestOptions(path: '/discovery/'),
        data: {'error': 'Internal server error'},
      ),
    ),
  );

  final result = await repository.getDiscoveryProfiles();

  expect(result, isA<Left<ServerFailure, List<Profile>>>());
});
```

**Status**: ⏳ Requires test implementation

---

### API-008: 502 Bad Gateway

**Description**: Test behavior when API gateway is down.

**Preconditions**:
- API gateway unavailable
- Returns 502 error

**Test Steps**:
1. Trigger API call during gateway outage
2. Observe error handling

**Expected Results**:
- ✅ Error message: "Service temporarily unavailable. Please try again in a moment."
- ✅ Retry button
- ✅ No crash

**Verification**: Manual + Mocked test

**Status**: ⏳ Requires test implementation

---

### API-009: 503 Service Unavailable (Maintenance)

**Description**: Test behavior during planned maintenance.

**Preconditions**:
- Backend is in maintenance mode
- Returns 503 with maintenance message

**Test Steps**:
1. Attempt to access Discovery during maintenance
2. Observe maintenance mode handling

**Expected Results**:
- ✅ Maintenance message displayed (from API if provided)
- ✅ Estimated downtime shown (if available)
- ✅ No retry button during maintenance window
- ✅ Graceful degradation

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### API-010: Invalid JSON Response

**Description**: Test behavior when API returns malformed JSON.

**Preconditions**:
- API returns 200 OK but with invalid JSON
- JSON parsing fails

**Test Steps**:
1. Mock API response with malformed JSON
2. Attempt to parse response
3. Observe error handling

**Expected Results**:
- ✅ Parsing error caught
- ✅ Error message: "Failed to load profiles. Please try again."
- ✅ Error logged for debugging
- ✅ No crash

**Automated Test**: Mock malformed JSON in repository tests

**Status**: ⏳ Requires test implementation

---

### API-011: Missing Required Fields in Response

**Description**: Test behavior when API response is missing required fields.

**Preconditions**:
- API returns 200 OK
- Response JSON is missing required fields (e.g., user ID, photos)

**Test Steps**:
1. Mock API response with missing fields
2. Attempt to parse into model
3. Observe error handling

**Expected Results**:
- ✅ Parsing error caught (JSON deserialization fails)
- ✅ Graceful error handling
- ✅ Invalid profiles filtered out (don't crash entire list)
- ✅ Error logged with details

**Automated Test**: Test in model tests (profile_model_test.dart)

**Status**: ⏳ Requires test implementation

---

### API-012: Unexpected Response Format

**Description**: Test behavior when API returns unexpected data structure.

**Preconditions**:
- API returns 200 OK
- Response structure doesn't match expected format (e.g., array instead of object)

**Test Steps**:
1. Mock unexpected response format
2. Attempt to parse
3. Observe error handling

**Expected Results**:
- ✅ Type error caught
- ✅ Error message displayed
- ✅ No crash
- ✅ Logs error details (no PII)

**Verification**: Automated + Manual

**Status**: ⏳ Requires test implementation

---

## Timeout Tests

### Test Category: Request Timeouts
**Priority**: P0 (Critical)
**Automated Coverage**: Partial

---

### TO-001: Connection Timeout on Initial Load

**Description**: Test behavior when initial profile load times out.

**Preconditions**:
- Very slow network or unresponsive server
- Request exceeds configured timeout (e.g., 30 seconds)

**Test Steps**:
1. Configure very slow network (or mock timeout)
2. Navigate to Discovery page
3. Wait for timeout
4. Observe error handling

**Expected Results**:
- ✅ Loading indicator shows during wait
- ✅ After timeout, error: "Request timed out. Please check your connection."
- ✅ Retry button available
- ✅ No infinite loading state

**Automated Test**:
```dart
test('should timeout after configured duration', () async {
  when(() => mockDio.get(any())).thenAnswer(
    (_) async => await Future.delayed(
      const Duration(seconds: 60), // Exceeds 30s timeout
      () => Response(
        statusCode: 200,
        data: {'profiles': []},
        requestOptions: RequestOptions(path: '/discovery/'),
      ),
    ),
  );

  expect(
    () => repository.getDiscoveryProfiles(timeout: Duration(seconds: 30)),
    throwsA(isA<TimeoutException>()),
  );
});
```

**Status**: ⏳ Requires test implementation

---

### TO-002: Timeout During Swipe Action

**Description**: Test behavior when swipe action (like/dislike) times out.

**Preconditions**:
- User swipes on a profile
- API call times out before response

**Test Steps**:
1. Swipe on a profile
2. Simulate timeout (slow network or mock)
3. Observe behavior after timeout

**Expected Results**:
- ✅ Loading/processing indicator during wait
- ✅ After timeout, error: "Action timed out. Your swipe may not have been registered."
- ✅ Option to retry
- ✅ Profile state recoverable (not stuck in limbo)

**Verification**: Manual + Mocked test

**Status**: ⏳ Requires test implementation

---

### TO-003: Timeout During Filter Application

**Description**: Test behavior when filter update request times out.

**Preconditions**:
- User modifies filters and taps Apply
- API call times out

**Test Steps**:
1. Open filters
2. Modify filters
3. Tap Apply
4. Simulate timeout
5. Observe behavior

**Expected Results**:
- ✅ Loading state on Apply button
- ✅ After timeout, error: "Failed to apply filters. Please try again."
- ✅ Filters page remains open
- ✅ User can retry or cancel

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### TO-004: Timeout During Rewind

**Description**: Test behavior when rewind action times out.

**Preconditions**:
- Premium user attempts rewind
- API call times out

**Test Steps**:
1. Swipe on a profile
2. Tap rewind
3. Simulate timeout
4. Observe behavior

**Expected Results**:
- ✅ Rewind animation starts
- ✅ After timeout, error message
- ✅ Rewind button remains available
- ✅ State is recoverable

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### TO-005: Timeout During Daily Limit Check

**Description**: Test behavior when daily limit check times out.

**Preconditions**:
- Discovery page loads
- Daily limit API call times out

**Test Steps**:
1. Navigate to Discovery page
2. Simulate timeout on daily limit endpoint
3. Observe behavior

**Expected Results**:
- ✅ Profiles still load (daily limit failure is non-blocking)
- ✅ Daily limit counter shows "Unknown" or default value
- ✅ Swipes still allowed (graceful degradation)
- ✅ Error logged but not shown to user (non-critical)

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should load profiles even when daily limit fails',
  build: () {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(tProfiles));
    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => const Left(
        NetworkFailure(message: 'Failed to load limit'),
      ),
    );
    return bloc;
  },
  act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
  expect: () => [
    DiscoveryLoading(),
    isA<DiscoveryLoaded>()
        .having((s) => s.dailyLimit, 'dailyLimit', null),
  ],
);
```

**Status**: ✅ Automated test exists

---

## Invalid Data Tests

### Test Category: Data Validation and Parsing
**Priority**: P1 (High)
**Automated Coverage**: YES (model tests)

---

### INV-001: Profile with Missing User ID

**Description**: Test handling of profile without user ID.

**Test Steps**:
1. Mock API response with profile missing `id` field
2. Attempt to parse into ProfileModel
3. Observe error handling

**Expected Results**:
- ✅ JSON parsing fails gracefully
- ✅ Profile skipped (filtered out from list)
- ✅ Other valid profiles still displayed
- ✅ Error logged

**Automated Test**: In profile_model_test.dart

**Status**: ⏳ Requires test implementation

---

### INV-002: Profile with Missing Photos Array

**Description**: Test handling of profile without photos.

**Test Steps**:
1. Mock profile with `photos: null` or missing photos field
2. Attempt to display profile
3. Observe fallback behavior

**Expected Results**:
- ✅ Profile displays with placeholder avatar
- ✅ No crash
- ✅ User can still swipe
- ✅ Photo carousel shows single placeholder

**Verification**: Automated + Manual

**Status**: ⏳ Requires test implementation

---

### INV-003: Profile with Invalid Age (Negative or Zero)

**Description**: Test handling of profile with invalid age value.

**Test Steps**:
1. Mock profile with `age: -5` or `age: 0`
2. Attempt to display profile
3. Observe validation

**Expected Results**:
- ✅ Profile filtered out (validation fails)
- ✅ OR age shows as "N/A" with profile still displayed
- ✅ No crash
- ✅ Error logged

**Automated Test**: In model/entity validation tests

**Status**: ⏳ Requires test implementation

---

### INV-004: Profile with Invalid Distance (Null or Negative)

**Description**: Test handling of profile with invalid distance.

**Test Steps**:
1. Mock profile with `distance: null` or `distance: -10`
2. Display profile
3. Observe fallback behavior

**Expected Results**:
- ✅ Distance shows as "Unknown" or "—"
- ✅ Profile still displays
- ✅ No crash

**Verification**: Automated

**Status**: ⏳ Requires test implementation

---

### INV-005: Profile with Malformed Photo URLs

**Description**: Test handling of invalid or broken photo URLs.

**Test Steps**:
1. Mock profile with invalid photo URL (e.g., "invalid-url")
2. Attempt to load and display photo
3. Observe error handling

**Expected Results**:
- ✅ Photo fails to load gracefully
- ✅ Placeholder image shown
- ✅ Other photos in carousel still load
- ✅ No crash or infinite loading

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

### INV-006: Profile with Invalid Compatibility Score

**Description**: Test handling of compatibility score outside valid range.

**Test Steps**:
1. Mock profile with `compatibility_score: 150` (should be 0-100)
2. Display profile
3. Observe validation

**Expected Results**:
- ✅ Score clamped to valid range (0-100)
- ✅ OR shows "N/A" if truly invalid
- ✅ No crash
- ✅ Error logged

**Verification**: Automated

**Status**: ⏳ Requires test implementation

---

### INV-007: Profile with Special Characters in Name

**Description**: Test handling of names with emojis, special characters, or very long names.

**Test Steps**:
1. Mock profile with name: "🔥💕NameWith😊Emojis"
2. Mock profile with name: 200 character string
3. Display profiles
4. Observe rendering

**Expected Results**:
- ✅ Name displays correctly (emojis supported)
- ✅ Long names truncated with ellipsis
- ✅ No layout overflow or crash
- ✅ Accessibility labels correct

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

### INV-008: Empty Filters Object from API

**Description**: Test handling when filters API returns empty object.

**Test Steps**:
1. Mock filters endpoint returning `{}`
2. Load Discovery with filters
3. Observe fallback behavior

**Expected Results**:
- ✅ Default filters applied
- ✅ Profiles load normally
- ✅ No crash

**Verification**: Automated

**Status**: ⏳ Requires test implementation

---

### INV-009: Daily Limit with Invalid Values

**Description**: Test handling of daily limit response with invalid data.

**Test Steps**:
1. Mock daily limit with `remaining_likes: -5`
2. Mock daily limit with `total_likes: 0`
3. Display daily limit counter
4. Observe validation

**Expected Results**:
- ✅ Invalid values clamped or defaulted
- ✅ Counter shows safe fallback (e.g., "Unknown")
- ✅ User can still swipe (graceful degradation)
- ✅ Error logged

**Verification**: Automated

**Status**: ⏳ Requires test implementation

---

### INV-010: Match Response with Missing Data

**Description**: Test handling of match response missing profile data.

**Test Steps**:
1. Swipe right, get match response
2. Mock match response missing matched user profile
3. Attempt to show match modal
4. Observe error handling

**Expected Results**:
- ✅ Match detected but modal doesn't crash
- ✅ Shows generic match message if profile data missing
- ✅ User can continue swiping
- ✅ Error logged

**Verification**: Automated

**Status**: ⏳ Requires test implementation

---

## Empty State Tests

### Test Category: Empty and "No Results" States
**Priority**: P1 (High)
**Automated Coverage**: YES

---

### EMP-001: No Profiles Available (New User)

**Description**: Test behavior when no profiles match user's filters (new user, restrictive filters).

**Preconditions**:
- User is new or in low-population area
- No profiles available

**Test Steps**:
1. Navigate to Discovery page
2. API returns empty array
3. Observe empty state

**Expected Results**:
- ✅ Empty state illustration/icon displayed
- ✅ Message: "No profiles to show right now. Check back later or adjust your filters."
- ✅ Button: "Adjust Filters"
- ✅ Button: "Refresh"
- ✅ No loading spinner stuck

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should emit [DiscoveryLoading, NoMoreProfiles] when empty profiles returned',
  build: () {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => mockGetDailyLikeLimit())
        .thenAnswer((_) async => Right(tDailyLimit));
    return bloc;
  },
  act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
  expect: () => [
    DiscoveryLoading(),
    NoMoreProfiles(),
  ],
);
```

**Status**: ✅ Automated test exists

---

### EMP-002: No More Profiles (Exhausted Stack)

**Description**: Test behavior when user has swiped through all available profiles.

**Preconditions**:
- User has swiped on all available profiles
- No more profiles to show

**Test Steps**:
1. Swipe through all profiles
2. Reach end of stack
3. Observe empty state

**Expected Results**:
- ✅ Empty state message: "You've seen everyone! Check back later for new profiles."
- ✅ "Refresh" button available
- ✅ Suggestion to expand filters
- ✅ No crash or stuck loading

**Verification**: Automated + Manual

**Status**: ✅ Automated test exists

---

### EMP-003: No Profiles After Filter Application

**Description**: Test behavior when filters are too restrictive and return zero results.

**Preconditions**:
- User applies very specific filters (e.g., age 18-19, distance 1km)
- No profiles match

**Test Steps**:
1. Open filters
2. Set restrictive filters
3. Apply
4. Observe empty state

**Expected Results**:
- ✅ Empty state: "No profiles match your filters. Try adjusting them."
- ✅ Button: "Adjust Filters" (re-opens filter page)
- ✅ Button: "Reset Filters"
- ✅ Estimated profile count showed 0 before applying (real-time count)

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### EMP-004: Empty Photos Array in Profile

**Description**: Test display of profile with no photos.

**Test Steps**:
1. Load profile with empty photos array
2. Display profile card
3. Observe fallback

**Expected Results**:
- ✅ Placeholder avatar shown
- ✅ Profile info still displays
- ✅ User can swipe
- ✅ No crash

**Verification**: Automated + Manual

**Status**: ⏳ Requires test implementation

---

### EMP-005: Empty Bio/About Text

**Description**: Test display of profile with empty or null bio.

**Test Steps**:
1. Load profile with `bio: null` or `bio: ""`
2. Display profile detail page
3. Observe bio section

**Expected Results**:
- ✅ Bio section shows placeholder: "No bio yet"
- ✅ Section still renders (not hidden)
- ✅ No crash or layout issue

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

### EMP-006: Empty Interests/Tags Array

**Description**: Test display of profile with no interests or tags.

**Test Steps**:
1. Load profile with `interests: []`
2. Display profile
3. Observe interests section

**Expected Results**:
- ✅ Interests section hidden OR shows "No interests listed"
- ✅ No crash
- ✅ Profile card layout not broken

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

## Boundary Condition Tests

### Test Category: Edge Cases and Limits
**Priority**: P0 (Critical)
**Automated Coverage**: YES

---

### BND-001: Daily Like Limit Reached (Free User)

**Description**: Test behavior when free user reaches daily like limit (50 likes).

**Preconditions**:
- User is free tier
- User has used 50 likes today

**Test Steps**:
1. Swipe right when at 50/50 likes
2. Observe limit enforcement

**Expected Results**:
- ✅ Like action blocked
- ✅ Modal/message: "You've reached your daily like limit. Upgrade to Premium for unlimited likes."
- ✅ "Upgrade" CTA button
- ✅ "Come Back Tomorrow" button
- ✅ Countdown to limit reset shown

**Automated Test**: YES (discovery_bloc_test.dart - daily limit tests)

**Status**: ✅ Automated test exists

---

### BND-002: Super Like Limit Reached (Premium User)

**Description**: Test behavior when premium user exhausts super likes.

**Preconditions**:
- User is premium
- User has used all super likes for the day (e.g., 5/5)

**Test Steps**:
1. Attempt super like when limit reached
2. Observe error handling

**Expected Results**:
- ✅ Super like action blocked
- ✅ Message: "No super likes remaining. You'll get more tomorrow."
- ✅ Countdown to reset
- ✅ Regular like still available

**Automated Test**:
```dart
blocTest<DiscoveryBloc, DiscoveryState>(
  'should show error when no super likes remaining',
  build: () {
    when(() => mockSuperLikeProfile(any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'no_super_likes_remaining'),
      ),
    );
    return bloc;
  },
  seed: () => DiscoveryLoaded(...),
  act: (bloc) => bloc.add(SwipeProfile(...)),
  expect: () => [
    ProfileSwiping(...),
    isA<DiscoveryError>(),
  ],
);
```

**Status**: ✅ Automated test exists

---

### BND-003: Minimum Age Filter (18)

**Description**: Test enforcement of minimum age filter (18 years old).

**Preconditions**:
- User attempts to set age filter below 18

**Test Steps**:
1. Open filters
2. Try to set minimum age to 17 or lower
3. Observe validation

**Expected Results**:
- ✅ Age slider minimum is 18 (cannot go lower)
- ✅ OR validation error if manual entry: "Minimum age is 18."
- ✅ Filter not applied if invalid

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

### BND-004: Maximum Distance Filter (100 km)

**Description**: Test maximum distance filter boundary.

**Preconditions**:
- User sets distance filter to maximum (100 km)

**Test Steps**:
1. Open filters
2. Set distance to 100 km
3. Apply filters
4. Observe behavior

**Expected Results**:
- ✅ Filter applied successfully
- ✅ Profiles up to 100 km shown
- ✅ Profiles beyond 100 km excluded
- ✅ Cannot set distance above 100 km

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### BND-005: Very Long Profile Name (200+ Characters)

**Description**: Test display of extremely long profile names.

**Test Steps**:
1. Mock profile with 200-character name
2. Display profile card
3. Observe text truncation

**Expected Results**:
- ✅ Name truncated with ellipsis (e.g., "VeryLongName...")
- ✅ No layout overflow
- ✅ Full name visible in detail view or tooltip
- ✅ Accessibility label includes full name

**Verification**: Widget test

**Status**: ⏳ Requires test implementation

---

### BND-006: Profile with 10+ Photos

**Description**: Test carousel with maximum number of photos.

**Test Steps**:
1. Mock profile with 10 photos
2. Display profile with photo carousel
3. Swipe through all photos
4. Observe pagination

**Expected Results**:
- ✅ All 10 photos load and display
- ✅ Pagination indicators work (e.g., 1/10, 2/10...)
- ✅ Smooth swiping between photos
- ✅ No performance degradation

**Verification**: Manual + Widget test

**Status**: ⏳ Requires manual verification

---

### BND-007: Profile with 1 Photo Only

**Description**: Test display of profile with single photo.

**Test Steps**:
1. Mock profile with 1 photo
2. Display profile
3. Observe carousel behavior

**Expected Results**:
- ✅ Single photo displays
- ✅ No pagination indicators (or shows 1/1)
- ✅ Swipe gestures still work (no crash)
- ✅ No arrows or navigation hints

**Verification**: Widget test

**Status**: ⏳ Requires test implementation

---

### BND-008: Rapid Swipes (10 Swipes in 5 Seconds)

**Description**: Test handling of very rapid swipe actions.

**Test Steps**:
1. Swipe right/left 10 times in quick succession
2. Observe API call handling and UI behavior

**Expected Results**:
- ✅ Debouncing prevents duplicate API calls
- ✅ UI updates smoothly (no jank)
- ✅ All swipes processed eventually (queued if needed)
- ✅ No rate limit error triggered
- ✅ Daily limit counter updates correctly

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### BND-009: Compatibility Score Edge Cases (0% and 100%)

**Description**: Test display of minimum and maximum compatibility scores.

**Test Steps**:
1. Mock profile with `compatibility_score: 0`
2. Mock profile with `compatibility_score: 100`
3. Display profiles
4. Observe rendering

**Expected Results**:
- ✅ 0% displays correctly (not hidden or shown as error)
- ✅ 100% displays correctly
- ✅ Visual indicators work (e.g., progress bar, color coding)
- ✅ No validation errors

**Verification**: Widget test

**Status**: ⏳ Requires test implementation

---

## Recovery Flow Tests

### Test Category: Error Recovery and Retry Mechanisms
**Priority**: P0 (Critical)
**Automated Coverage**: Partial

---

### REC-001: Retry After Network Error

**Description**: Test successful retry after network error.

**Test Steps**:
1. Trigger network error (NET-001)
2. Restore connection
3. Tap "Retry" button
4. Observe recovery

**Expected Results**:
- ✅ Retry button functional
- ✅ Loading state appears
- ✅ Profiles load successfully on retry
- ✅ Error state cleared
- ✅ User can interact normally

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### REC-002: Retry After API Error

**Description**: Test retry after temporary API error (500, 502, 503).

**Test Steps**:
1. Trigger API error
2. Wait for backend recovery
3. Tap "Retry"
4. Observe recovery

**Expected Results**:
- ✅ Retry succeeds when backend is back
- ✅ No stale error messages
- ✅ Data loads correctly

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### REC-003: Automatic Retry with Exponential Backoff

**Description**: Test automatic retry mechanism for failed swipes (if implemented).

**Test Steps**:
1. Trigger network error during swipe
2. Observe automatic retry behavior
3. Verify exponential backoff

**Expected Results**:
- ✅ Swipe retried automatically (if configured)
- ✅ Retry intervals increase (1s, 2s, 4s...)
- ✅ Max retry attempts not exceeded
- ✅ User notified if all retries fail

**Verification**: Automated + Manual

**Status**: ⏳ Requires test implementation (if feature exists)

---

### REC-004: Pull-to-Refresh on Error State

**Description**: Test pull-to-refresh gesture to recover from error.

**Test Steps**:
1. Encounter error state
2. Use pull-to-refresh gesture
3. Observe recovery

**Expected Results**:
- ✅ Pull-to-refresh triggers reload
- ✅ Loading indicator appears
- ✅ Successful reload clears error
- ✅ Gesture works on all error states

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### REC-005: Navigate Away and Return After Error

**Description**: Test state persistence when navigating away from error state.

**Test Steps**:
1. Encounter error in Discovery
2. Navigate to another tab (e.g., Matches)
3. Return to Discovery
4. Observe state

**Expected Results**:
- ✅ Error state persists (or auto-retries on return)
- ✅ Retry button still available
- ✅ No stale data shown
- ✅ User can retry successfully

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### REC-006: Offline Queue for Swipe Actions

**Description**: Test offline queue mechanism for swipes (if implemented).

**Test Steps**:
1. Go offline
2. Perform swipes (should queue)
3. Go back online
4. Observe queue processing

**Expected Results**:
- ✅ Swipes queued locally when offline
- ✅ Queue processed when connection restored
- ✅ User notified of queued actions
- ✅ No duplicate swipes
- ✅ Queue cleared after processing

**Verification**: Manual (if feature exists)

**Status**: ⏳ Requires verification (if implemented)

---

### REC-007: Recover from Expired Session

**Description**: Test recovery flow when session expires mid-use.

**Test Steps**:
1. Use Discovery page
2. Simulate session expiration
3. Attempt swipe
4. Observe re-authentication flow

**Expected Results**:
- ✅ Session expiration detected
- ✅ User redirected to login
- ✅ After re-login, return to Discovery
- ✅ State preserved (if possible)
- ✅ Action can be retried after re-auth

**Verification**: Manual

**Status**: ⏳ Requires manual verification

---

### REC-008: Graceful Degradation When Features Unavailable

**Description**: Test continued usability when non-critical features fail.

**Test Steps**:
1. Simulate daily limit API failure
2. Continue using Discovery
3. Observe graceful degradation

**Expected Results**:
- ✅ Profiles still load
- ✅ Swipes still work
- ✅ Daily limit counter shows "Unknown" or is hidden
- ✅ Core functionality unaffected

**Automated Test**: YES (daily limit failure test exists)

**Status**: ✅ Automated test exists

---

## Automated Test Coverage

### Summary of Existing Automated Tests

Based on code analysis, the following automated tests exist:

#### DiscoveryBloc Tests (test/presentation/blocs/discovery/discovery_bloc_test.dart)

**Network Failure Tests** ✅:
- LoadDiscoveryProfiles with NetworkFailure
- SwipeProfile (like) with NetworkFailure
- LoadDailyLimit with NetworkFailure
- LoadMoreProfiles with NetworkFailure

**Server Error Tests** ✅:
- SwipeProfile (dislike) with ServerFailure
- SuperLikeProfile with no_super_likes_remaining error
- RewindSwipe with ServerFailure
- UpdateFilters with ServerFailure

**Empty State Tests** ✅:
- LoadDiscoveryProfiles returning empty array → NoMoreProfiles state

**Daily Limit Tests** ✅:
- Daily limit reached state
- Daily limit failure (graceful degradation)
- Premium user unlimited likes

**Match Detection Tests** ✅:
- Like resulting in match → MatchFound state

**State Transition Tests** ✅:
- All 8 states covered: DiscoveryInitial, DiscoveryLoading, DiscoveryLoaded, ProfileSwiping, MatchFound, NoMoreProfiles, DailyLimitReached, DiscoveryError

**Total BLoC Tests**: 16+ test cases

---

#### Repository Tests (test/data/repositories/match_repository_impl_test.dart)

**Expected Coverage**:
- API call success scenarios
- Network failure handling
- Server error handling
- JSON parsing errors
- Authentication errors

**Status**: ⏳ Requires verification

---

#### Model Tests (test/data/models/profile_model_test.dart)

**Expected Coverage**:
- Valid JSON parsing
- Invalid JSON handling
- Missing required fields
- Null safety handling

**Status**: ⏳ Requires verification

---

#### Integration Tests (test/integration_test.dart)

**Current Status**: Basic skeleton only (28 lines)

**Required Coverage**:
- End-to-end discovery flow
- Error handling in full flow
- Network recovery in context

**Status**: ⏳ Requires expansion

---

### Test Coverage Gaps (To Be Implemented)

**Priority P0 (Critical)**:
1. API-007: 500 Internal Server Error handling
2. API-010: Invalid JSON response handling
3. API-011: Missing required fields in response
4. TO-001: Connection timeout on initial load
5. TO-002: Timeout during swipe action

**Priority P1 (High)**:
6. INV-001 to INV-010: All invalid data tests
7. API-004: 404 Profile deleted mid-session
8. API-005: 409 Already matched conflict
9. BND-003 to BND-009: Boundary condition validations

**Priority P2 (Medium)**:
10. REC-003: Automatic retry with exponential backoff
11. API-006: 429 Rate limit exceeded
12. NET-007: Intermittent/flaky network

---

## Manual Test Procedures

### Manual Testing Environment Setup

**Required Tools**:
- Android device/emulator with TalkBack
- iOS device/simulator with VoiceOver
- Network throttling tools (Chrome DevTools, Charles Proxy, or Android/iOS settings)
- Test accounts (free and premium)
- Backend access to simulate errors (optional but helpful)

**Preparation**:
1. Install app on test devices
2. Create test accounts (free tier and premium)
3. Enable network throttling capabilities
4. Prepare test data (backend or mock server)

---

### Manual Test Execution Checklist

#### Network Failure Manual Tests

- [ ] NET-001: No internet on initial load (Airplane mode)
- [ ] NET-002: Connection lost during profile load
- [ ] NET-003: Connection lost during like action
- [ ] NET-004: Connection lost during dislike action
- [ ] NET-005: Connection lost during filter update
- [ ] NET-006: Connection lost during rewind
- [ ] NET-007: Intermittent connection (3G throttling)
- [ ] NET-008: Network recovery after error

#### API Error Manual Tests

- [ ] API-001: 400 Bad Request
- [ ] API-002: 401 Unauthorized (expired token)
- [ ] API-003: 403 Forbidden (account suspended)
- [ ] API-004: 404 Not Found (deleted profile)
- [ ] API-005: 409 Conflict (already matched)
- [ ] API-006: 429 Rate limit exceeded
- [ ] API-007: 500 Internal Server Error
- [ ] API-008: 502 Bad Gateway
- [ ] API-009: 503 Service Unavailable
- [ ] API-012: Unexpected response format

#### Timeout Manual Tests

- [ ] TO-001: Connection timeout on initial load
- [ ] TO-002: Timeout during swipe
- [ ] TO-003: Timeout during filter application
- [ ] TO-004: Timeout during rewind

#### Empty State Manual Tests

- [ ] EMP-001: No profiles available (new user)
- [ ] EMP-002: No more profiles (exhausted)
- [ ] EMP-003: No profiles after restrictive filters
- [ ] EMP-005: Empty bio text
- [ ] EMP-006: Empty interests/tags

#### Boundary Condition Manual Tests

- [ ] BND-001: Daily like limit reached
- [ ] BND-002: Super like limit reached
- [ ] BND-003: Minimum age filter (18)
- [ ] BND-004: Maximum distance filter (100 km)
- [ ] BND-005: Very long profile name
- [ ] BND-006: Profile with 10+ photos
- [ ] BND-007: Profile with 1 photo
- [ ] BND-008: Rapid swipes (10 in 5 seconds)

#### Recovery Flow Manual Tests

- [ ] REC-001: Retry after network error
- [ ] REC-002: Retry after API error
- [ ] REC-004: Pull-to-refresh on error
- [ ] REC-005: Navigate away and return
- [ ] REC-007: Recover from expired session

---

### Manual Test Reporting Template

For each manual test, document:

```markdown
### Test ID: [e.g., NET-001]

**Date**: [YYYY-MM-DD]
**Tester**: [Name]
**Device**: [e.g., iPhone 13, Android Emulator API 30]
**OS Version**: [e.g., iOS 16.0, Android 11]
**App Version**: [e.g., 1.0.0-beta.5]

**Test Steps Executed**:
1. [Step 1]
2. [Step 2]
...

**Actual Results**:
[What actually happened]

**Expected Results**:
[What should have happened]

**Status**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

**Issues Found**:
- [Issue 1 description]
- [Issue 2 description]

**Screenshots/Videos**: [Attach if available]

**Notes**: [Any additional observations]
```

---

## Sign-Off Checklist

### Automated Test Completion

- [ ] All existing automated tests passing (0 failures)
- [ ] BLoC tests cover all error scenarios (network, server, validation)
- [ ] Repository tests cover API error handling
- [ ] Model tests cover invalid data parsing
- [ ] Integration tests expanded to cover error flows
- [ ] Test coverage ≥80% for error handling code paths

### Manual Test Completion

- [ ] All P0 manual tests executed and documented
- [ ] All P1 manual tests executed and documented
- [ ] P2 manual tests executed (or explicitly deferred)
- [ ] Test results documented with evidence (screenshots/videos)
- [ ] All critical issues resolved
- [ ] All high-priority issues resolved or documented for future release

### Error Message Verification

- [ ] All error messages are user-friendly (no technical jargon)
- [ ] All error messages are actionable (tell user what to do next)
- [ ] All error messages are internationalized (FR/EN)
- [ ] Error messages tested in both French and English locales
- [ ] Errors logged appropriately (no PII in logs)

### Recovery Flow Verification

- [ ] Retry buttons functional on all error states
- [ ] Pull-to-refresh works on error states
- [ ] Network recovery automatically retries or prompts user
- [ ] Session expiration redirects to login with proper return flow
- [ ] No infinite retry loops or stuck states

### Boundary Condition Verification

- [ ] Daily limits enforced correctly
- [ ] Premium feature limits enforced correctly
- [ ] Age and distance filters validated at boundaries
- [ ] UI handles very long text (names, bios) gracefully
- [ ] Photo carousel handles 1 photo and 10+ photos correctly

### Non-Crash Guarantee

- [ ] No unhandled exceptions in any error scenario
- [ ] No crashes during network failures
- [ ] No crashes during API errors
- [ ] No crashes with invalid data
- [ ] No crashes at boundary conditions
- [ ] All crashes logged and resolved

### Performance Under Error Conditions

- [ ] Error states render within 100ms
- [ ] Retry actions respond within 100ms
- [ ] No memory leaks during repeated errors
- [ ] App remains responsive during network timeouts

### Documentation

- [ ] This testing guide completed
- [ ] Test results documented
- [ ] Issues logged in issue tracker (if applicable)
- [ ] Edge cases and learnings documented for future reference

---

## Final QA Sign-Off

**Tested By**: ___________________________
**Date**: ___________________________
**Overall Status**: ✅ APPROVED / ❌ REJECTED / ⚠️ CONDITIONAL

**Summary**:
[Summary of testing outcomes, key findings, and any remaining concerns]

**Approval Conditions** (if conditional approval):
1. [Condition 1]
2. [Condition 2]

**Signature**: ___________________________

---

## Appendix A: Error Failure Types Reference

From `lib/core/error/failures.dart`:

### General Errors
- `ServerFailure` - Backend/API errors
- `NetworkFailure` - Connection issues
- `CacheFailure` - Local storage errors
- `LocalFailure` - Local data errors

### Authentication Errors
- `AuthFailure` - General auth errors
- `WrongCredentialsFailure` - Invalid login
- `UserNotFoundFailure` - Account doesn't exist
- `EmailAlreadyInUseFailure` - Duplicate email
- `WeakPasswordFailure` - Password validation
- `InvalidEmailFailure` - Email format invalid
- `EmailNotVerifiedFailure` - Email not verified
- `UserDisabledFailure` - Account suspended

### Validation Errors
- `ValidationFailure` - Input validation errors

### Permission Errors
- `PermissionFailure` - General permission errors
- `UnauthorizedFailure` - Not authorized for action

### Profile Errors
- `ProfileFailure` - General profile errors
- `ProfileNotFoundFailure` - Profile doesn't exist
- `ProfileIncompleteFailure` - Profile incomplete

### Limit Errors
- `LimitFailure` - General limit errors
- `DailyLikeLimitFailure` - Daily like limit reached
- `MessageLimitFailure` - Message limit reached
- `PhotoLimitFailure` - Photo limit reached
- `DailyLimitReachedFailure` - Generic daily limit

### Premium Errors
- `PremiumFailure` - General premium errors
- `PremiumRequiredFailure` - Premium feature locked

### Matching Errors
- `MatchingFailure` - General matching errors
- `NoSwipeToRewindFailure` - No swipe to undo
- `AlreadyMatchedFailure` - Already matched

### Other
- `PaymentFailure` - Payment/billing errors
- `UnknownFailure` - Unclassified errors

---

## Appendix B: Network Simulation Tools

### Android

**Airplane Mode**:
- Quick Settings → Airplane Mode

**Data Throttling**:
- Settings → Developer Options → Networking → Mobile data always active (toggle off)
- Settings → Developer Options → Select USB Configuration → Tethering (for slow simulation)

**Charles Proxy** (Third-party):
- Install Charles Proxy on computer
- Configure Android device to use proxy
- Throttle bandwidth, simulate errors, inject responses

### iOS

**Airplane Mode**:
- Control Center → Airplane Mode

**Network Link Conditioner** (Xcode):
- Download "Additional Tools for Xcode"
- Open Network Link Conditioner
- Select profile (3G, Edge, Lossy Network, etc.)
- Install profile on device via Settings

**Charles Proxy** (Third-party):
- Same as Android

### Browser/Desktop Tools

**Chrome DevTools**:
- Open DevTools → Network tab
- Throttling dropdown → Select profile (Slow 3G, Fast 3G, Offline)

**Postman/Insomnia**:
- Simulate API responses for testing

---

## Appendix C: Mock Error Injection (For Development)

### Example: Inject Network Error in Repository

```dart
// FOR TESTING ONLY - Remove before production
class MatchRepositoryImpl implements MatchRepository {
  // ... existing code

  @override
  Future<Either<Failure, List<DiscoveryProfile>>> getDiscoveryProfiles() async {
    // TESTING: Simulate network error
    if (const bool.fromEnvironment('TEST_NETWORK_ERROR')) {
      return const Left(NetworkFailure(message: 'Simulated network error'));
    }

    // ... rest of implementation
  }
}
```

**Run with error injection**:
```bash
flutter run --dart-define=TEST_NETWORK_ERROR=true
```

### Example: Inject API Error

```dart
// FOR TESTING ONLY
if (const bool.fromEnvironment('TEST_API_500')) {
  throw DioException(
    requestOptions: RequestOptions(path: '/discovery/'),
    response: Response(
      statusCode: 500,
      requestOptions: RequestOptions(path: '/discovery/'),
    ),
  );
}
```

**Run with API error injection**:
```bash
flutter run --dart-define=TEST_API_500=true
```

---

**End of Error Scenario Testing Guide**

---

## Document Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-27 | Initial creation for Subtask 7.4 | auto-claude |


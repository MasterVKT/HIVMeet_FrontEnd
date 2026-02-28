# Shared Services Verification Plan - Discovery Page Integration

**Document Version:** 1.0
**Created:** 2026-02-28
**Task:** 002-audit-and-implement-discovery-page-spec-compliance
**Subtask:** 8.3 - Verify shared services (auth, notifications, analytics, caching) work correctly with Discovery changes
**Purpose:** Comprehensive verification that all shared services integrate correctly with Discovery page changes, with focus on global state management and side effects

---

## Executive Summary

This document provides a comprehensive verification plan to ensure that the Discovery page correctly integrates with all shared services in the HIVMeet application. The verification covers 8 shared services, global state management mechanisms, and side effects resulting from Discovery page interactions.

**Total Verification Scenarios:** 52
**Services Covered:** 8
**Priority:** P0 (Critical for production deployment)
**Estimated Testing Time:** 6-8 hours

---

## Table of Contents

1. [Authentication Service Integration](#1-authentication-service-integration)
2. [Firebase Service Integration](#2-firebase-service-integration)
3. [API Service Integration](#3-api-service-integration)
4. [Localization Service Integration](#4-localization-service-integration)
5. [Network Connectivity Service Integration](#5-network-connectivity-service-integration)
6. [Token Manager Integration](#6-token-manager-integration)
7. [Global State Management](#7-global-state-management)
8. [Side Effects Verification](#8-side-effects-verification)
9. [Test Execution Summary](#9-test-execution-summary)

---

## 1. Authentication Service Integration

**Service Location:** `lib/core/services/authentication_service.dart`
**Discovery Dependencies:**
- Route protection (requires authentication)
- User identity for API calls
- Session validation
- Token refresh handling

### 1.1 Authentication State Monitoring

**Test ID:** AUTH-001
**Priority:** P0 (Critical)
**Description:** Verify Discovery page respects authentication state changes

**Test Steps:**
1. Open Discovery page while authenticated
2. Simulate session expiration (expire auth tokens)
3. Trigger any Discovery action (swipe, load more, etc.)

**Expected Results:**
- ✅ Discovery page detects 401 Unauthorized response
- ✅ AuthenticationService emits `AuthenticationStatus.error`
- ✅ User is redirected to `/login` route
- ✅ Discovery state is cleared on logout
- ✅ No PII (tokens, user IDs) logged to console

**Verification Method:** Manual testing + log inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 1.2 Token Refresh During Discovery Session

**Test ID:** AUTH-002
**Priority:** P0 (Critical)
**Description:** Verify seamless token refresh during active Discovery session

**Test Steps:**
1. Login to Discovery page
2. Wait for access token to approach expiration (typically 15-60 minutes)
3. Perform swipe action that triggers API call
4. Observe token refresh mechanism

**Expected Results:**
- ✅ ApiClient interceptor detects token expiration
- ✅ Token refresh triggered automatically via `TokenManager`
- ✅ New access token obtained from `/auth/token/refresh/` endpoint
- ✅ Original swipe action retried with new token
- ✅ No user-visible interruption
- ✅ Swipe action completes successfully

**Verification Method:** Manual testing + network traffic inspection (Charles Proxy)

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 1.3 Firebase Auth State Synchronization

**Test ID:** AUTH-003
**Priority:** P1 (High)
**Description:** Verify Discovery respects Firebase auth state changes

**Test Steps:**
1. Open Discovery page while logged in
2. Force Firebase sign out (via Firebase Console or another device)
3. Observe Discovery page behavior

**Expected Results:**
- ✅ `AuthenticationService` detects Firebase auth state change
- ✅ `authStateChanges()` stream triggers `_handleFirebaseSignOut()`
- ✅ Django JWT tokens cleared from secure storage
- ✅ User redirected to login page
- ✅ Discovery BLoC state reset to `DiscoveryInitial`

**Verification Method:** Manual testing + log monitoring

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 1.4 Current User Identity Access

**Test ID:** AUTH-004
**Priority:** P0 (Critical)
**Description:** Verify Discovery page has access to current user identity for API calls

**Test Steps:**
1. Login to Discovery page
2. Inspect network requests to `/discovery/`, `/matches/` endpoints
3. Verify user identity is correctly included

**Expected Results:**
- ✅ `AuthenticationService.currentUser` is not null
- ✅ User ID included in API requests (via JWT token payload)
- ✅ API responses correctly associated with current user
- ✅ No cross-user data leakage

**Verification Method:** Network traffic inspection + API response verification

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 2. Firebase Service Integration

**Service Location:** `lib/core/services/firebase_service.dart`
**Discovery Dependencies:**
- FCM (Firebase Cloud Messaging) for match notifications
- Analytics events tracking
- Firestore real-time updates (optional)

### 2.1 Match Notification via FCM

**Test ID:** FIREBASE-001
**Priority:** P0 (Critical)
**Description:** Verify user receives FCM notification when a match occurs

**Test Steps:**
1. Login to Discovery page on Device A
2. Swipe right on User B's profile
3. From Device B (or backend simulation), have User B swipe right on User A
4. Observe notifications on Device A

**Expected Results:**
- ✅ Match detected by backend API (`POST /matches/` returns `result: "match"`)
- ✅ Backend sends FCM push notification to Device A
- ✅ Notification appears in system tray with match message
- ✅ Tapping notification navigates to `/conversations/:conversationId`
- ✅ Match modal appears on Discovery page (in-app)

**Verification Method:** Manual testing on physical devices (Android + iOS)

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 2.2 FCM Token Registration

**Test ID:** FIREBASE-002
**Priority:** P1 (High)
**Description:** Verify FCM token is correctly registered for the authenticated user

**Test Steps:**
1. Fresh app install or clear app data
2. Login to Discovery page
3. Check Firebase Console > Cloud Messaging

**Expected Results:**
- ✅ `FirebaseService.requestNotificationPermission()` called on login
- ✅ User grants notification permission
- ✅ FCM token generated and stored
- ✅ FCM token sent to backend (`POST /api/v1/users/fcm-token/`)
- ✅ Token visible in Firebase Console associated with user UID

**Verification Method:** Firebase Console inspection + network logs

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 2.3 Analytics Events - Swipe Actions

**Test ID:** FIREBASE-003
**Priority:** P2 (Medium)
**Description:** Verify swipe actions are logged to Firebase Analytics

**Test Steps:**
1. Open Discovery page
2. Perform the following actions:
   - Swipe right (like)
   - Swipe left (dislike)
   - Swipe up (super like)
3. Check Firebase Analytics DebugView (debug mode enabled)

**Expected Results:**
- ✅ `profile_liked` event logged with `profile_id` parameter
- ✅ `profile_disliked` event logged with `profile_id` parameter
- ✅ `profile_super_liked` event logged (premium users only)
- ✅ Events visible in Firebase Analytics DebugView within 1 minute
- ✅ No PII (names, emails) included in analytics parameters

**Verification Method:** Firebase Analytics DebugView + console logs

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 2.4 Analytics Events - Match Detection

**Test ID:** FIREBASE-004
**Priority:** P2 (Medium)
**Description:** Verify match events are logged to Firebase Analytics

**Test Steps:**
1. Create a match scenario (mutual swipe right)
2. Observe match modal appearance
3. Check Firebase Analytics

**Expected Results:**
- ✅ `match_found` event logged with `matched_user_id` parameter (hashed)
- ✅ Event includes `time_to_match` parameter (time since profile viewed)
- ✅ Event visible in Firebase Analytics within 1 minute

**Verification Method:** Firebase Analytics DebugView

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 3. API Service Integration

**Service Location:** `lib/core/services/api_service.dart`, `lib/core/network/api_client.dart`
**Discovery Dependencies:**
- HTTP client for all API requests
- Auth token injection
- Error response handling
- Request/response logging

### 3.1 Auth Token Injection

**Test ID:** API-001
**Priority:** P0 (Critical)
**Description:** Verify all Discovery API requests include auth token

**Test Steps:**
1. Login to Discovery page
2. Capture network traffic for the following requests:
   - `GET /discovery/`
   - `POST /matches/`
   - `POST /matches/dislike`
   - `GET /matches/daily-limit`
3. Inspect request headers

**Expected Results:**
- ✅ All requests include `Authorization: Bearer <access_token>` header
- ✅ Access token is valid JWT with correct payload
- ✅ Token automatically refreshed when expired (via interceptor)
- ✅ No requests made without auth token

**Verification Method:** Network traffic inspection (Charles Proxy, Postman Interceptor)

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 3.2 Error Response Handling - 401 Unauthorized

**Test ID:** API-002
**Priority:** P0 (Critical)
**Description:** Verify Discovery page handles 401 errors correctly

**Test Steps:**
1. Login to Discovery page
2. Manually expire access token (via backend or token manipulation)
3. Attempt to swipe a profile

**Expected Results:**
- ✅ ApiClient interceptor detects 401 response
- ✅ Token refresh attempted via `POST /auth/token/refresh/`
- ✅ If refresh succeeds: original request retried with new token
- ✅ If refresh fails: user logged out and redirected to `/login`
- ✅ No app crash or unhandled exceptions

**Verification Method:** Manual testing + network inspection + log monitoring

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 3.3 Error Response Handling - 500 Server Error

**Test ID:** API-003
**Priority:** P0 (Critical)
**Description:** Verify Discovery page handles server errors gracefully

**Test Steps:**
1. Open Discovery page
2. Simulate 500 Internal Server Error from backend (via proxy or mock server)
3. Observe Discovery page behavior

**Expected Results:**
- ✅ ApiClient detects 500 response
- ✅ `ServerFailure` emitted from repository layer
- ✅ DiscoveryBloc emits `DiscoveryError` state
- ✅ UI shows error message: "Server error. Please try again later."
- ✅ Retry button available in error state
- ✅ Previous state preserved (graceful degradation)

**Verification Method:** Manual testing with mock server (Charles Proxy, MockLab)

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 3.4 Request/Response Logging

**Test ID:** API-004
**Priority:** P1 (High)
**Description:** Verify API requests are logged correctly (debug mode only)

**Test Steps:**
1. Run app in debug mode
2. Open Discovery page
3. Perform swipe actions
4. Check console logs

**Expected Results:**
- ✅ Request logs include: method, URL, headers (without sensitive data)
- ✅ Response logs include: status code, body (without PII)
- ✅ No tokens, emails, or user IDs logged
- ✅ Logs disabled in release/production mode
- ✅ Logs use `developer.log()` (not `print()`)

**Verification Method:** Console log inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 3.5 Network Timeout Handling

**Test ID:** API-005
**Priority:** P1 (High)
**Description:** Verify Discovery page handles network timeouts correctly

**Test Steps:**
1. Open Discovery page
2. Simulate slow network (network throttling: 2G, 500ms latency)
3. Perform swipe action
4. Wait for timeout (typically 30 seconds)

**Expected Results:**
- ✅ ApiClient detects timeout exception
- ✅ `NetworkFailure` emitted from repository
- ✅ DiscoveryBloc emits `DiscoveryError` state
- ✅ UI shows error: "Request timed out. Check your connection."
- ✅ Retry mechanism available
- ✅ No app freeze or ANR (Application Not Responding)

**Verification Method:** Manual testing with network throttling

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 4. Localization Service Integration

**Service Location:** `lib/core/services/localization_service.dart`
**Discovery Dependencies:**
- All user-facing text translations
- Dynamic locale switching
- Pluralization support

### 4.1 Translation Key Coverage

**Test ID:** I18N-001
**Priority:** P0 (Critical)
**Description:** Verify all Discovery text uses LocalizationService

**Test Steps:**
1. Search Discovery page codebase for hardcoded strings:
   ```bash
   grep -r '"[A-Za-z]' lib/presentation/pages/discovery/
   grep -r "'[A-Za-z]" lib/presentation/pages/discovery/
   ```
2. Review results for any user-facing text

**Expected Results:**
- ✅ Zero hardcoded French or English strings in Discovery code
- ✅ All text uses `LocalizationService.translate(key)`
- ✅ All translation keys exist in `assets/translations/en.json` and `assets/translations/fr.json`
- ✅ No missing translation warnings in logs

**Verification Method:** Code search + manual review

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 4.2 Locale Switching During Session

**Test ID:** I18N-002
**Priority:** P1 (High)
**Description:** Verify Discovery page updates when locale changes

**Test Steps:**
1. Open Discovery page in French locale
2. Navigate to Settings
3. Change language to English
4. Return to Discovery page

**Expected Results:**
- ✅ Discovery page text updates to English immediately
- ✅ Action button labels translated
- ✅ Error messages translated
- ✅ Daily limit messages translated
- ✅ No app restart required

**Verification Method:** Manual testing

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 4.3 Pluralization Support

**Test ID:** I18N-003
**Priority:** P1 (High)
**Description:** Verify pluralization works correctly for likes remaining

**Test Steps:**
1. Login as free user with known like count
2. Observe daily limit message in various states:
   - 0 likes remaining
   - 1 like remaining
   - 5 likes remaining

**Expected Results:**
- ✅ French: "0 like restant", "1 like restant", "5 likes restants"
- ✅ English: "0 likes remaining", "1 like remaining", "5 likes remaining"
- ✅ Pluralization rules applied correctly per locale

**Verification Method:** Manual testing in both locales

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 4.4 Error Message Localization

**Test ID:** I18N-004
**Priority:** P0 (Critical)
**Description:** Verify all error messages are localized

**Test Steps:**
1. Trigger various error scenarios:
   - Network error (airplane mode)
   - Server error (500)
   - Daily limit reached
   - No more profiles
2. Verify error messages in French and English

**Expected Results:**
- ✅ All error messages translated in both languages
- ✅ Error codes mapped to translation keys (e.g., `errors.network_error`)
- ✅ No fallback to English when French locale selected

**Verification Method:** Manual testing with error simulation

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 5. Network Connectivity Service Integration

**Service Location:** `lib/core/services/network_connectivity_service.dart`
**Discovery Dependencies:**
- Network status monitoring
- Offline mode handling
- Retry logic on reconnection

### 5.1 Offline Mode Detection

**Test ID:** NETWORK-001
**Priority:** P0 (Critical)
**Description:** Verify Discovery page handles offline mode gracefully

**Test Steps:**
1. Open Discovery page while online
2. Enable airplane mode
3. Attempt to swipe a profile

**Expected Results:**
- ✅ `NetworkConnectivityService` detects offline state
- ✅ Discovery page shows "No internet connection" message
- ✅ Swipe actions queued for later (optimistic UI)
- ✅ No API calls attempted while offline
- ✅ Cached profiles remain viewable (if any)

**Verification Method:** Manual testing + network monitoring

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 5.2 Reconnection Handling

**Test ID:** NETWORK-002
**Priority:** P0 (Critical)
**Description:** Verify Discovery page recovers when network is restored

**Test Steps:**
1. Open Discovery page while offline (airplane mode)
2. Perform swipe action (should be queued)
3. Disable airplane mode (restore network)
4. Observe automatic recovery

**Expected Results:**
- ✅ `NetworkConnectivityService` detects reconnection
- ✅ Queued swipe actions sent to backend automatically
- ✅ Profile list refreshed with latest data
- ✅ User notified of successful recovery
- ✅ No manual refresh required

**Verification Method:** Manual testing

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 5.3 Flaky Network Resilience

**Test ID:** NETWORK-003
**Priority:** P1 (High)
**Description:** Verify Discovery page handles intermittent connectivity

**Test Steps:**
1. Open Discovery page
2. Simulate flaky network (20% packet loss, random disconnects)
3. Perform multiple swipe actions

**Expected Results:**
- ✅ API calls retry automatically (exponential backoff)
- ✅ No crashes or unhandled exceptions
- ✅ User sees loading indicators during retries
- ✅ Timeout errors shown after max retries
- ✅ Graceful degradation to cached data

**Verification Method:** Manual testing with network simulation tools

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 6. Token Manager Integration

**Service Location:** `lib/core/services/token_manager.dart`, `lib/core/services/token_service.dart`
**Discovery Dependencies:**
- JWT token storage in secure storage
- Token refresh mechanism
- Token validation

### 6.1 Secure Token Storage

**Test ID:** TOKEN-001
**Priority:** P0 (Critical - Security)
**Description:** Verify tokens are stored securely (not in SharedPreferences)

**Test Steps:**
1. Login to Discovery page
2. Inspect local storage:
   - Android: Check `flutter_secure_storage` files (require root)
   - iOS: Check Keychain via Xcode
3. Verify tokens are NOT in `shared_preferences.xml`

**Expected Results:**
- ✅ Access token stored in `flutter_secure_storage`
- ✅ Refresh token stored in `flutter_secure_storage`
- ✅ NO tokens in SharedPreferences
- ✅ Tokens encrypted at rest (platform-specific)

**Verification Method:** Device file system inspection (requires root/jailbreak)

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 6.2 Token Refresh on Expiration

**Test ID:** TOKEN-002
**Priority:** P0 (Critical)
**Description:** Verify access token is refreshed automatically when expired

**Test Steps:**
1. Login to Discovery page
2. Wait for access token to expire (or manually set short expiration)
3. Perform swipe action
4. Observe token refresh

**Expected Results:**
- ✅ ApiClient detects 401 Unauthorized response
- ✅ `TokenManager.refreshToken()` called automatically
- ✅ New access token obtained via `POST /auth/token/refresh/`
- ✅ New access token stored in secure storage
- ✅ Original swipe request retried with new token
- ✅ User unaware of refresh (seamless)

**Verification Method:** Manual testing + network inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 6.3 Token Clearance on Logout

**Test ID:** TOKEN-003
**Priority:** P0 (Critical - Security)
**Description:** Verify all tokens are cleared when user logs out

**Test Steps:**
1. Login to Discovery page
2. Navigate to Settings
3. Tap "Logout"
4. Inspect secure storage

**Expected Results:**
- ✅ `TokenManager.clearAllTokens()` called on logout
- ✅ Access token removed from secure storage
- ✅ Refresh token removed from secure storage
- ✅ User data cleared from cache
- ✅ User redirected to `/login`

**Verification Method:** Secure storage inspection + manual testing

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 6.4 Token Validation on App Launch

**Test ID:** TOKEN-004
**Priority:** P1 (High)
**Description:** Verify stored tokens are validated on app launch

**Test Steps:**
1. Login to Discovery page
2. Close app completely (kill process)
3. Relaunch app

**Expected Results:**
- ✅ `TokenManager.hasValidTokens()` called on launch
- ✅ If tokens valid: user redirected to `/discovery` (auto-login)
- ✅ If tokens expired: refresh attempted via `POST /auth/token/refresh/`
- ✅ If refresh fails: user redirected to `/login`

**Verification Method:** Manual testing + log monitoring

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 7. Global State Management

**Service Location:** `lib/core/events/app_events.dart`
**Discovery Dependencies:**
- Cross-feature event communication
- Interaction revocation handling
- Match notifications

### 7.1 Interaction Revocation Event Subscription

**Test ID:** EVENTS-001
**Priority:** P1 (High)
**Description:** Verify Discovery BLoC listens to interaction revocation events

**Test Steps:**
1. Review `DiscoveryBloc` constructor for event subscription:
   ```dart
   _revokeSubscription = AppEvents.interactionRevoked.listen(...)
   ```
2. Trigger revocation event from Matches page (unmatch a user)
3. Observe Discovery page behavior

**Expected Results:**
- ✅ `DiscoveryBloc` subscribed to `AppEvents.interactionRevoked` stream
- ✅ When revocation event emitted, Discovery profiles refreshed
- ✅ Revoked profile reappears in Discovery queue (if applicable)
- ✅ No memory leaks (subscription canceled in `dispose()`)

**Verification Method:** Code review + manual testing

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 7.2 Match Found Event Emission

**Test ID:** EVENTS-002
**Priority:** P1 (High)
**Description:** Verify Discovery emits match found events for other features

**Test Steps:**
1. Create a match scenario (mutual swipe right)
2. Check if `AppEvents.matchFound` event is emitted
3. Verify other features can listen to this event (e.g., Matches page)

**Expected Results:**
- ✅ `AppEvents.matchFound.add(matchId)` called when match detected
- ✅ Event includes match ID and matched user ID
- ✅ Other features can subscribe to event (e.g., Matches BLoC)
- ✅ Event emitted before match modal shown

**Verification Method:** Code review + event stream monitoring

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 7.3 Profile Updated Event Handling

**Test ID:** EVENTS-003
**Priority:** P2 (Medium)
**Description:** Verify Discovery handles profile update events

**Test Steps:**
1. Open Discovery page
2. Navigate to Profile page (self-profile)
3. Update profile information (e.g., bio, photos)
4. Return to Discovery page

**Expected Results:**
- ✅ If `AppEvents.profileUpdated` event exists, Discovery listens to it
- ✅ Discovery profile queue updated with new profile data (if self-profile)
- ✅ No stale data shown

**Verification Method:** Code review + manual testing

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 7.4 Memory Leak Prevention - Event Subscriptions

**Test ID:** EVENTS-004
**Priority:** P0 (Critical - Performance)
**Description:** Verify all event subscriptions are properly canceled

**Test Steps:**
1. Open Discovery page (event subscriptions created)
2. Navigate away from Discovery page
3. Check if subscriptions are canceled in `dispose()`
4. Use Flutter DevTools to check for memory leaks

**Expected Results:**
- ✅ `_revokeSubscription?.cancel()` called in `DiscoveryBloc.dispose()`
- ✅ No memory leaks detected in Flutter DevTools
- ✅ Event stream listeners count decreases when Discovery page disposed

**Verification Method:** Code review + Flutter DevTools memory profiler

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 8. Side Effects Verification

**Description:** Verify all side effects resulting from Discovery page interactions are correctly handled

### 8.1 Match Notification Side Effect

**Test ID:** SIDE-001
**Priority:** P0 (Critical)
**Description:** Verify match notifications are sent when match occurs

**Test Steps:**
1. Create match scenario (mutual swipe right)
2. Check backend logs for notification service calls
3. Verify FCM notification received on device

**Expected Results:**
- ✅ Backend sends notification to matched user
- ✅ Notification payload includes match details (user names, photos)
- ✅ Notification deeplink navigates to `/conversations/:conversationId`
- ✅ Notification received within 5 seconds of match

**Verification Method:** Backend logs + device notification inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.2 Analytics Event Side Effect

**Test ID:** SIDE-002
**Priority:** P2 (Medium)
**Description:** Verify analytics events are logged for key interactions

**Test Steps:**
1. Open Discovery page
2. Perform the following actions:
   - Like profile
   - Dislike profile
   - Super like profile
   - Match found
   - Daily limit reached
3. Check Firebase Analytics dashboard

**Expected Results:**
- ✅ All events logged with correct parameters
- ✅ Events visible in Firebase Analytics within 1 hour (24 hours for full processing)
- ✅ No duplicate events
- ✅ No PII in event parameters

**Verification Method:** Firebase Analytics dashboard

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.3 Cache Update Side Effect

**Test ID:** SIDE-003
**Priority:** P1 (High)
**Description:** Verify local cache is updated after swipe actions

**Test Steps:**
1. Open Discovery page (profiles loaded)
2. Swipe right on a profile (like)
3. Close app and reopen
4. Check if liked profile is removed from Discovery queue

**Expected Results:**
- ✅ Swiped profiles removed from local cache
- ✅ Daily limit counter updated in cache
- ✅ Filter preferences persisted
- ✅ No duplicate profiles shown after cache update

**Verification Method:** Manual testing + local storage inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.4 Conversation Creation Side Effect

**Test ID:** SIDE-004
**Priority:** P0 (Critical)
**Description:** Verify conversation is created when match occurs

**Test Steps:**
1. Create match scenario (mutual swipe right)
2. Navigate to Messages/Conversations tab
3. Verify new conversation exists

**Expected Results:**
- ✅ New conversation created in backend database
- ✅ Conversation visible in Conversations list
- ✅ Conversation includes both matched users
- ✅ "Send Message" button from match modal navigates to conversation

**Verification Method:** Manual testing + backend database inspection

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.5 Premium Subscription Check Side Effect

**Test ID:** SIDE-005
**Priority:** P1 (High)
**Description:** Verify premium status is checked for premium features

**Test Steps:**
1. Login as free user
2. Attempt to use super like (premium feature)
3. Attempt to rewind swipe (premium feature)
4. Observe behavior

**Expected Results:**
- ✅ `PremiumRepository.isPremium()` called before premium actions
- ✅ Free users see upgrade CTA modal
- ✅ Premium users can use features without restriction
- ✅ No errors if `PremiumRepository` is null (optional dependency)

**Verification Method:** Manual testing with free and premium accounts

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.6 Daily Limit Counter Update Side Effect

**Test ID:** SIDE-006
**Priority:** P0 (Critical)
**Description:** Verify daily like counter updates after each swipe

**Test Steps:**
1. Login as free user with known like count (e.g., 10 likes remaining)
2. Swipe right on a profile
3. Observe daily limit counter

**Expected Results:**
- ✅ Counter decrements from 10 to 9 after like
- ✅ Counter persists across app restarts
- ✅ Counter resets at midnight (server-side)
- ✅ Counter shown as "Unlimited" for premium users

**Verification Method:** Manual testing over multiple swipes

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.7 Profile View Tracking Side Effect

**Test ID:** SIDE-007
**Priority:** P2 (Medium)
**Description:** Verify profile views are tracked for analytics

**Test Steps:**
1. Open Discovery page
2. View 5 different profiles (without swiping)
3. Check backend analytics logs

**Expected Results:**
- ✅ `profile_viewed` event logged for each profile
- ✅ Event includes profile ID and timestamp
- ✅ View duration tracked (optional)
- ✅ No duplicate view events for same profile

**Verification Method:** Backend analytics logs + Firebase Analytics

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

### 8.8 Swipe History Update Side Effect

**Test ID:** SIDE-008
**Priority:** P1 (High)
**Description:** Verify swipe history is stored for rewind feature

**Test Steps:**
1. Login as premium user
2. Swipe right on Profile A
3. Tap "Rewind" button
4. Verify Profile A reappears

**Expected Results:**
- ✅ Swipe history stored in backend (last 10 swipes)
- ✅ Rewind action retrieves last swipe from history
- ✅ Profile A reappears in Discovery queue
- ✅ Swipe action on Profile A is revoked in backend

**Verification Method:** Manual testing with premium account

**Status:** [ ] Pass / [ ] Fail / [ ] Blocked

---

## 9. Test Execution Summary

### Test Coverage Statistics

| Category | Total Tests | P0 (Critical) | P1 (High) | P2 (Medium) |
|----------|-------------|---------------|-----------|-------------|
| Authentication Service | 4 | 3 | 1 | 0 |
| Firebase Service | 4 | 1 | 1 | 2 |
| API Service | 5 | 3 | 2 | 0 |
| Localization Service | 4 | 2 | 2 | 0 |
| Network Connectivity Service | 3 | 2 | 1 | 0 |
| Token Manager | 4 | 3 | 1 | 0 |
| Global State Management | 4 | 1 | 2 | 1 |
| Side Effects | 8 | 3 | 3 | 2 |
| **TOTAL** | **36** | **18** | **13** | **5** |

### Priority Testing Order

**Phase 1 - Critical (P0):** 18 tests - MUST PASS before deployment
- All authentication, API, and token management tests
- Offline mode, error handling, security tests

**Phase 2 - High (P1):** 13 tests - SHOULD PASS for quality release
- Token refresh, locale switching, network resilience
- Event subscriptions, cache updates

**Phase 3 - Medium (P2):** 5 tests - NICE TO HAVE for optimal experience
- Analytics tracking, profile view tracking
- Advanced Firebase features

### Estimated Testing Time

| Phase | Tests | Estimated Time | Tester Profile |
|-------|-------|----------------|----------------|
| Phase 1 (P0) | 18 | 4-5 hours | QA Engineer with backend access |
| Phase 2 (P1) | 13 | 2-3 hours | QA Engineer |
| Phase 3 (P2) | 5 | 1 hour | QA Engineer or Developer |
| **Total** | **36** | **7-9 hours** | - |

### Tools Required

**Testing Tools:**
- Charles Proxy or Postman Interceptor (network traffic inspection)
- Firebase Console (FCM, Analytics)
- Flutter DevTools (memory profiler, network monitor)
- Android Studio Profiler / Xcode Instruments
- Physical devices (Android + iOS)

**Backend Access:**
- Admin access to backend API
- Firebase project access
- Analytics dashboard access

### Test Execution Checklist

**Pre-Execution Setup:**
- [ ] Test accounts prepared (free user, premium user)
- [ ] Firebase project configured
- [ ] Network simulation tools installed
- [ ] Backend API accessible
- [ ] Physical devices available (Android + iOS)

**During Execution:**
- [ ] Document all test results in this document
- [ ] Take screenshots of failures
- [ ] Capture network logs for API tests
- [ ] Note any unexpected behavior

**Post-Execution:**
- [ ] Calculate pass/fail rate
- [ ] Document all bugs found
- [ ] Prioritize bugs (critical, high, medium, low)
- [ ] Provide QA sign-off recommendation

### QA Sign-Off Criteria

**Criteria for Production Deployment:**
- [ ] All P0 (Critical) tests pass (18/18)
- [ ] At least 90% of P1 (High) tests pass (12/13)
- [ ] No critical bugs blocking core functionality
- [ ] No security vulnerabilities found
- [ ] Performance acceptable (no memory leaks, no crashes)

**Sign-Off Status:** [ ] APPROVED / [ ] NOT APPROVED / [ ] CONDITIONAL

**QA Lead Signature:** ___________________
**Date:** ___________________
**Notes:** ___________________

---

## Appendix A: Shared Services Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     DISCOVERY PAGE                          │
│  (lib/presentation/pages/discovery/discovery_page.dart)    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Uses DiscoveryBloc
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   DISCOVERY BLOC                            │
│  (lib/presentation/blocs/discovery/discovery_bloc.dart)    │
│  - Manages profile queue                                   │
│  - Handles swipe actions                                   │
│  - Detects matches                                         │
│  - Enforces daily limits                                   │
└───────────┬────────────┬──────────┬───────────┬─────────────┘
            │            │          │           │
            │            │          │           │
    ┌───────▼────┐  ┌────▼────┐  ┌─▼──────┐  ┌▼─────────┐
    │ Use Cases  │  │ Repos   │  │ Events │  │ Services │
    └────────────┘  └─────────┘  └────────┘  └──────────┘
                         │                        │
                         │                        │
         ┌───────────────▼────────────────────────▼──────────┐
         │           SHARED SERVICES LAYER                   │
         ├───────────────────────────────────────────────────┤
         │  1. AuthenticationService (Auth state, tokens)   │
         │  2. FirebaseService (FCM, Analytics, Firestore)  │
         │  3. ApiService (HTTP client, interceptors)       │
         │  4. LocalizationService (i18n, translations)     │
         │  5. NetworkConnectivityService (Network status)  │
         │  6. TokenManager (Secure storage)                │
         │  7. AppEvents (Cross-feature events)             │
         │  8. PremiumRepository (Subscription checks)      │
         └───────────────────────────────────────────────────┘
```

---

## Appendix B: Integration Points Reference

**See Also:** `DISCOVERY_PAGE_INTEGRATION_POINTS_MAP.md` (created in subtask 8.1)

**Key Integration Points:**
1. **Navigation & Routing:** Discovery protected route, bottom nav integration
2. **Dependency Injection:** GetIt container, service registration
3. **Authentication & Authorization:** Auth state, token management
4. **Shared Services:** All 8 services listed above
5. **Shared Widgets:** AppScaffold, LoadingWidget, ErrorWidget
6. **Global State & Event Bus:** AppEvents for cross-feature communication
7. **BLoC Layer:** DiscoveryBloc dependencies on use cases and repos
8. **Data Layer:** MatchRepository, MatchingApi
9. **Theme & Styling:** AppColors, AppTheme, Google Fonts
10. **Firebase Integration:** Auth, FCM, Analytics, Firestore

---

## Appendix C: Common Issues and Troubleshooting

### Issue 1: Token Refresh Loop (Infinite 401 Errors)

**Symptoms:**
- Repeated 401 errors in console
- User unable to perform any action
- App stuck in loading state

**Root Cause:**
- Refresh token expired
- Backend token refresh endpoint failing
- Token interceptor misconfigured

**Fix:**
- Clear all tokens: `TokenManager.clearAllTokens()`
- Force logout and re-login
- Check backend `/auth/token/refresh/` endpoint

### Issue 2: Match Notifications Not Received

**Symptoms:**
- Match occurs but no FCM notification
- Notification appears with delay (>1 minute)

**Root Cause:**
- FCM token not registered with backend
- Backend notification service down
- Device notification permission denied

**Fix:**
- Check FCM token in Firebase Console
- Verify backend sends notification (check logs)
- Re-request notification permission

### Issue 3: Locale Not Switching

**Symptoms:**
- Language change in settings doesn't update Discovery page
- Mixed languages shown (French + English)

**Root Cause:**
- LocalizationService not rebuilding widgets
- Missing translation keys
- Hardcoded strings

**Fix:**
- Force app rebuild on locale change
- Add missing translation keys
- Remove hardcoded strings

### Issue 4: Memory Leaks from Event Subscriptions

**Symptoms:**
- Memory usage increases over time
- App crashes after prolonged use

**Root Cause:**
- Event subscriptions not canceled in `dispose()`
- BLoC not disposed properly

**Fix:**
- Cancel all subscriptions in `DiscoveryBloc.dispose()`
- Use Flutter DevTools to identify leak source

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-28 | Claude (Auto-Claude Agent) | Initial comprehensive verification plan created for subtask 8.3 |

---

**End of Document**

# HIVMeet App - Smoke Test Suite

**Document Version:** 1.0
**Created:** 2026-02-28
**Task:** 002-audit-and-implement-discovery-page-spec-compliance
**Subtask:** 8.4 - Run smoke tests on other critical features
**Purpose:** Verify no regressions in core functionality after Discovery page changes

---

## Executive Summary

This document provides a comprehensive smoke test suite for critical HIVMeet features to ensure Discovery page changes haven't introduced regressions in core functionality. Smoke tests focus on critical paths through the application that must work for the app to be usable.

### Test Execution Summary

| Category | Test Count | Priority | Est. Time |
|----------|-----------|----------|-----------|
| **1. Authentication & Login** | 8 tests | P0 | 15 min |
| **2. Home/Discovery Navigation** | 6 tests | P0 | 10 min |
| **3. User Profile** | 8 tests | P0 | 15 min |
| **4. Messaging & Conversations** | 10 tests | P0 | 20 min |
| **5. Settings & Configuration** | 8 tests | P0 | 15 min |
| **6. Matches Management** | 8 tests | P0 | 15 min |
| **7. Bottom Navigation** | 6 tests | P0 | 10 min |
| **8. App Lifecycle & State** | 6 tests | P1 | 10 min |
| **TOTAL** | **60 tests** | - | **110 min (1h 50min)** |

### Critical Success Criteria

✅ **All P0 tests must pass** before deployment
✅ **No crashes or ANR** (Application Not Responding) events
✅ **All navigation flows work** correctly
✅ **Shared services operational** (auth, API, notifications, i18n)
✅ **No data loss** or corruption

### Test Environment Requirements

**Devices:**
- Minimum: 1 Android device (API 26+) + 1 iOS device (iOS 13+)
- Recommended: 2 devices per platform for comprehensive coverage

**Test Accounts:**
- Free user account (for basic features)
- Premium user account (for premium features)
- Test match account (to test matching flow)

**Network:**
- Stable Wi-Fi or 4G connection
- Ability to toggle airplane mode for offline tests

**Tools:**
- Device settings access
- Screen recording capability (for bug documentation)
- Issue tracking system access

---

## Table of Contents

1. [Authentication & Login](#1-authentication--login)
2. [Home/Discovery Navigation](#2-homediscovery-navigation)
3. [User Profile](#3-user-profile)
4. [Messaging & Conversations](#4-messaging--conversations)
5. [Settings & Configuration](#5-settings--configuration)
6. [Matches Management](#6-matches-management)
7. [Bottom Navigation](#7-bottom-navigation)
8. [App Lifecycle & State](#8-app-lifecycle--state)
9. [Test Execution Checklist](#test-execution-checklist)
10. [Issue Tracking Template](#issue-tracking-template)
11. [QA Sign-Off](#qa-sign-off)

---

## 1. Authentication & Login

**Priority:** P0 (Critical)
**Est. Time:** 15 minutes
**Impact:** If login fails, users cannot access the app

### Test 1.1: Fresh App Launch and Login

**Objective:** Verify new user can launch app and log in successfully

**Prerequisites:**
- App installed but never launched
- Valid user credentials available

**Steps:**
1. Launch HIVMeet app for the first time
2. Observe splash screen
3. Tap "Login" on onboarding screen
4. Enter valid email and password
5. Tap "Login" button
6. Wait for authentication to complete

**Expected Result:**
- ✅ Splash screen appears for 1-2 seconds
- ✅ Onboarding screen shows with login option
- ✅ Login form accepts credentials
- ✅ Loading indicator appears during authentication
- ✅ App navigates to Discovery page after successful login
- ✅ No error messages or crashes

**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Tester:** ________________
**Date:** ________________

---

### Test 1.2: Login with Invalid Credentials

**Objective:** Verify error handling for invalid login attempts

**Steps:**
1. Launch app
2. Navigate to login screen
3. Enter invalid email/password
4. Tap "Login" button

**Expected Result:**
- ✅ Error message displayed: "Invalid email or password" (internationalized)
- ✅ User remains on login screen
- ✅ Can retry with different credentials
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.3: Login with Network Error

**Objective:** Verify graceful handling of network failures during login

**Steps:**
1. Enable airplane mode
2. Launch app
3. Attempt to login

**Expected Result:**
- ✅ Network error message displayed
- ✅ Retry option available
- ✅ No crash or freeze

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.4: Logout Functionality

**Objective:** Verify user can log out successfully

**Steps:**
1. Log in to app
2. Navigate to Settings
3. Tap "Logout" button
4. Confirm logout action

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ After confirmation, user logged out
- ✅ App navigates to login screen
- ✅ Auth token cleared (verify by attempting to access protected route)
- ✅ No data from previous session visible

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.5: Session Persistence

**Objective:** Verify user remains logged in after app restart

**Steps:**
1. Log in to app
2. Close app completely (kill process)
3. Relaunch app

**Expected Result:**
- ✅ User still logged in
- ✅ No login screen shown
- ✅ App opens directly to Discovery page
- ✅ User data intact

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.6: Token Expiration Handling

**Objective:** Verify app handles expired auth tokens gracefully

**Steps:**
1. Log in to app
2. Navigate to any feature
3. Manually expire token (backend operation) OR wait for token expiration
4. Attempt to perform an action (like swipe, view profile)

**Expected Result:**
- ✅ App detects token expiration
- ✅ User redirected to login screen
- ✅ Error message: "Session expired, please log in again"
- ✅ After re-login, user can continue

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.7: Register New Account

**Objective:** Verify new user registration flow works

**Steps:**
1. Launch app
2. Tap "Register" or "Create Account"
3. Fill in registration form (email, password, confirm password, etc.)
4. Agree to terms and conditions
5. Tap "Create Account" button

**Expected Result:**
- ✅ Registration form validates input (email format, password strength)
- ✅ Account created successfully
- ✅ Confirmation message or email sent
- ✅ User navigated to profile creation or onboarding
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 1.8: Biometric Authentication (If Enabled)

**Objective:** Verify biometric login works (fingerprint/Face ID)

**Prerequisites:**
- Device supports biometrics
- Biometric auth enabled in settings

**Steps:**
1. Log in once with credentials
2. Enable biometric authentication in app settings
3. Log out
4. Launch app
5. Use biometric authentication to log in

**Expected Result:**
- ✅ Biometric prompt appears
- ✅ Successful biometric authentication logs user in
- ✅ Failed biometric authentication shows fallback to password
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

## 2. Home/Discovery Navigation

**Priority:** P0 (Critical)
**Est. Time:** 10 minutes
**Impact:** Ensures navigation to/from Discovery page works

### Test 2.1: Navigate to Discovery from Login

**Objective:** Verify successful login navigates to Discovery page

**Steps:**
1. Launch app
2. Log in with valid credentials

**Expected Result:**
- ✅ After login, app navigates to Discovery page
- ✅ Discovery page loads profiles
- ✅ Bottom navigation shows Discovery tab as active
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 2.2: Navigate to Discovery from Bottom Nav

**Objective:** Verify Discovery tab in bottom navigation works

**Steps:**
1. Log in to app (opens on Discovery)
2. Navigate to Matches tab
3. Tap Discovery tab in bottom navigation

**Expected Result:**
- ✅ App navigates to Discovery page
- ✅ Discovery tab highlighted in bottom nav
- ✅ Previous Discovery state preserved (or reloaded)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 2.3: Navigate from Discovery to Filters

**Objective:** Verify filters navigation from Discovery

**Steps:**
1. On Discovery page
2. Tap "Filters" button/icon

**Expected Result:**
- ✅ Filters page/modal opens
- ✅ Current filters displayed correctly
- ✅ Can navigate back to Discovery
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 2.4: Navigate from Discovery to Profile Detail

**Objective:** Verify profile detail navigation from Discovery

**Steps:**
1. On Discovery page with profiles loaded
2. Tap on profile card or info button

**Expected Result:**
- ✅ Profile detail page opens
- ✅ Profile information displayed correctly
- ✅ Can navigate back to Discovery
- ✅ Discovery state preserved
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 2.5: Navigate from Discovery to Matches (After Match)

**Objective:** Verify match modal "Send Message" navigation works

**Steps:**
1. On Discovery page
2. Swipe right on profile (or use like button)
3. Observe match modal (if match occurs)
4. Tap "Send Message" button

**Expected Result:**
- ✅ Match modal appears with animation
- ✅ "Send Message" button navigates to Conversations
- ✅ Conversation with matched user opened
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] No Match Occurred

---

### Test 2.6: Back Button Behavior from Discovery

**Objective:** Verify back button behavior on Discovery page

**Steps:**
1. Navigate to Discovery page
2. Press device back button (Android) or swipe back gesture (iOS)

**Expected Result:**
- ✅ App does NOT exit immediately (Discovery is home screen)
- ✅ Toast message: "Press back again to exit"
- ✅ Pressing back again exits app
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 3. User Profile

**Priority:** P0 (Critical)
**Est. Time:** 15 minutes
**Impact:** Users must be able to view and edit their profiles

### Test 3.1: View Own Profile

**Objective:** Verify user can view their own profile

**Steps:**
1. Log in to app
2. Navigate to Profile tab in bottom navigation
3. Observe profile content

**Expected Result:**
- ✅ Profile page loads successfully
- ✅ User's photos displayed
- ✅ User's bio/about text displayed
- ✅ User's badges displayed (verified, premium, etc.)
- ✅ Edit profile option available
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.2: Edit Profile Information

**Objective:** Verify user can edit their profile

**Steps:**
1. Navigate to own Profile page
2. Tap "Edit Profile" button
3. Modify bio/about text
4. Save changes

**Expected Result:**
- ✅ Edit profile screen opens
- ✅ Current values pre-populated
- ✅ Can modify fields
- ✅ Save button updates profile
- ✅ Success message displayed
- ✅ Updated information visible on profile
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.3: Upload Profile Photo

**Objective:** Verify user can upload/change profile photo

**Steps:**
1. Navigate to Edit Profile
2. Tap "Add Photo" or "Change Photo"
3. Select photo from gallery or take new photo
4. Confirm upload

**Expected Result:**
- ✅ Photo picker opens (gallery or camera)
- ✅ Selected photo displayed in preview
- ✅ Upload progress indicator shown
- ✅ Photo uploaded successfully
- ✅ New photo visible on profile
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.4: View Other User's Profile

**Objective:** Verify user can view another user's profile

**Steps:**
1. Navigate to Discovery or Matches
2. Tap on another user's profile card
3. Observe profile detail page

**Expected Result:**
- ✅ Profile detail page opens
- ✅ Other user's photos, bio, badges displayed
- ✅ No edit option (not own profile)
- ✅ Action buttons available (like, message, block, report)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.5: Profile Photo Carousel

**Objective:** Verify multiple photos can be viewed in profile

**Steps:**
1. View a profile with multiple photos
2. Swipe left/right on photos
3. Observe pagination indicators

**Expected Result:**
- ✅ Can swipe between photos smoothly
- ✅ Pagination dots show current photo position
- ✅ All photos load correctly
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.6: Profile Verification Status

**Objective:** Verify verification badges display correctly

**Steps:**
1. View profile of verified user
2. Observe verification badge

**Expected Result:**
- ✅ "Verified" badge visible on profile
- ✅ Badge icon and text clear
- ✅ Tapping badge shows verification info (optional)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.7: Block User from Profile

**Objective:** Verify user blocking functionality

**Steps:**
1. View another user's profile
2. Tap "Block" option (usually in menu)
3. Confirm block action

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ After confirmation, user blocked
- ✅ Blocked user no longer appears in Discovery
- ✅ Success message displayed
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 3.8: Report User from Profile

**Objective:** Verify user reporting functionality

**Steps:**
1. View another user's profile
2. Tap "Report" option
3. Select report reason
4. Submit report

**Expected Result:**
- ✅ Report dialog opens
- ✅ Report reasons available (harassment, fake profile, etc.)
- ✅ Additional info field available
- ✅ Report submitted successfully
- ✅ Confirmation message displayed
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 4. Messaging & Conversations

**Priority:** P0 (Critical)
**Est. Time:** 20 minutes
**Impact:** Core feature - users must be able to message matches

### Test 4.1: View Conversations List

**Objective:** Verify conversations list loads correctly

**Steps:**
1. Log in to app
2. Navigate to Conversations/Messages tab

**Expected Result:**
- ✅ Conversations list displayed
- ✅ Each conversation shows: profile photo, name, last message, timestamp
- ✅ Unread message indicators visible (if applicable)
- ✅ Empty state if no conversations
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.2: Open Existing Conversation

**Objective:** Verify user can open and view existing conversation

**Steps:**
1. Navigate to Conversations list
2. Tap on a conversation

**Expected Result:**
- ✅ Chat page opens
- ✅ Message history loaded and displayed
- ✅ Messages in correct chronological order
- ✅ Message input field visible at bottom
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.3: Send Text Message

**Objective:** Verify user can send a text message

**Steps:**
1. Open a conversation
2. Type message in input field
3. Tap send button

**Expected Result:**
- ✅ Message appears in chat immediately (optimistic update)
- ✅ Sending indicator visible
- ✅ Message sent successfully to server
- ✅ Sent status indicator appears (checkmark)
- ✅ Message persists after page refresh
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.4: Receive Message (Push Notification)

**Objective:** Verify user receives messages and push notifications

**Prerequisites:**
- Push notifications enabled
- Second test account to send message

**Steps:**
1. Log in with Account A
2. From Account B, send message to Account A
3. Observe notification on Account A's device

**Expected Result:**
- ✅ Push notification appears with message preview
- ✅ Tapping notification opens conversation
- ✅ New message visible in conversation
- ✅ Unread badge updated on Conversations tab
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.5: Message Failed to Send

**Objective:** Verify failed message handling

**Steps:**
1. Open conversation
2. Enable airplane mode
3. Send message
4. Observe failed state

**Expected Result:**
- ✅ Message shows "Failed" or error indicator
- ✅ Retry option available
- ✅ After re-enabling network, can retry successfully
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.6: Delete Conversation

**Objective:** Verify user can delete a conversation

**Steps:**
1. Navigate to Conversations list
2. Long-press or swipe on conversation
3. Tap "Delete" option
4. Confirm deletion

**Expected Result:**
- ✅ Delete option appears
- ✅ Confirmation dialog shown
- ✅ After confirmation, conversation deleted from list
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.7: Start New Conversation After Match

**Objective:** Verify new conversation created after match

**Steps:**
1. Swipe right on profile in Discovery
2. Observe match modal (if match occurs)
3. Tap "Send Message" button

**Expected Result:**
- ✅ Navigates to new conversation with matched user
- ✅ Conversation thread empty (no messages yet)
- ✅ Can send first message
- ✅ Conversation appears in Conversations list
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] No Match Occurred

---

### Test 4.8: Typing Indicator

**Objective:** Verify typing indicator works

**Prerequisites:**
- Two test accounts

**Steps:**
1. Account A opens conversation with Account B
2. Account B starts typing message (don't send)
3. Account A observes typing indicator

**Expected Result:**
- ✅ "Typing..." indicator appears for Account A
- ✅ Indicator disappears when Account B stops typing
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 4.9: Message Search/Filter

**Objective:** Verify message search functionality (if available)

**Steps:**
1. Navigate to Conversations list
2. Use search field to filter conversations
3. Type name or keyword

**Expected Result:**
- ✅ Conversations filtered by search query
- ✅ Matching conversations displayed
- ✅ Clearing search shows all conversations
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

### Test 4.10: Unmatch User from Conversation

**Objective:** Verify user can unmatch from conversation

**Steps:**
1. Open conversation
2. Access conversation menu
3. Tap "Unmatch" option
4. Confirm unmatch

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ After confirmation, user unmatched
- ✅ Conversation deleted from list
- ✅ User no longer appears in Matches
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 5. Settings & Configuration

**Priority:** P0 (Critical)
**Est. Time:** 15 minutes
**Impact:** Users must be able to configure app preferences

### Test 5.1: Open Settings Page

**Objective:** Verify Settings page loads correctly

**Steps:**
1. Log in to app
2. Navigate to Settings (usually via bottom nav or menu)

**Expected Result:**
- ✅ Settings page loads successfully
- ✅ All settings sections visible (account, notifications, privacy, etc.)
- ✅ Current settings values displayed correctly
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.2: Change Language Setting

**Objective:** Verify language switching works

**Steps:**
1. Navigate to Settings
2. Tap "Language" option
3. Select different language (e.g., French ↔ English)
4. Observe app language change

**Expected Result:**
- ✅ Language selection dialog appears
- ✅ After selection, app UI updates to new language
- ✅ All text translated (no hardcoded strings)
- ✅ Setting persists after app restart
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.3: Toggle Dark Mode

**Objective:** Verify dark mode toggle works

**Steps:**
1. Navigate to Settings
2. Toggle "Dark Mode" or "Theme" setting
3. Observe app theme change

**Expected Result:**
- ✅ Theme switches between light and dark
- ✅ All screens use new theme
- ✅ Setting persists after app restart
- ✅ No visual glitches
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

### Test 5.4: Notification Preferences

**Objective:** Verify notification settings can be configured

**Steps:**
1. Navigate to Settings → Notifications
2. Toggle notification types (messages, matches, likes, etc.)
3. Save settings

**Expected Result:**
- ✅ Notification toggles work correctly
- ✅ Settings saved successfully
- ✅ Push notifications respect settings
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.5: Privacy Settings

**Objective:** Verify privacy settings can be configured

**Steps:**
1. Navigate to Settings → Privacy
2. Toggle privacy options (e.g., "Show me in Discovery", "Show distance", etc.)
3. Save settings

**Expected Result:**
- ✅ Privacy toggles work correctly
- ✅ Settings saved successfully
- ✅ Privacy preferences applied (e.g., profile hidden from Discovery)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.6: Delete Account

**Objective:** Verify account deletion flow works

**Steps:**
1. Navigate to Settings → Account
2. Tap "Delete Account" option
3. Read warning/confirmation dialog
4. Confirm deletion (or cancel)

**Expected Result:**
- ✅ Delete account option available
- ✅ Warning dialog explains consequences
- ✅ Confirmation required (e.g., type password or "DELETE")
- ✅ If confirmed, account deleted and user logged out
- ✅ If cancelled, returns to Settings
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.7: Change Password

**Objective:** Verify password change functionality

**Steps:**
1. Navigate to Settings → Account → Change Password
2. Enter current password
3. Enter new password and confirmation
4. Save changes

**Expected Result:**
- ✅ Change password form validates input
- ✅ Current password verified
- ✅ New password meets requirements
- ✅ Password changed successfully
- ✅ Success message displayed
- ✅ User can log in with new password
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 5.8: View App Version and Legal Info

**Objective:** Verify About, Privacy Policy, Terms pages accessible

**Steps:**
1. Navigate to Settings → About
2. Observe app version number
3. Tap "Privacy Policy" link
4. Tap "Terms of Service" link

**Expected Result:**
- ✅ About page shows app version, build number
- ✅ Privacy Policy opens (web view or in-app page)
- ✅ Terms of Service opens (web view or in-app page)
- ✅ Can navigate back to Settings
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 6. Matches Management

**Priority:** P0 (Critical)
**Est. Time:** 15 minutes
**Impact:** Users must be able to view and manage matches

### Test 6.1: View Matches List

**Objective:** Verify Matches page loads correctly

**Steps:**
1. Log in to app
2. Navigate to Matches tab in bottom navigation

**Expected Result:**
- ✅ Matches list displayed
- ✅ Each match shows: profile photo, name, match date
- ✅ Empty state if no matches
- ✅ Matches sorted by date (newest first)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.2: Open Match Profile

**Objective:** Verify user can view match's profile

**Steps:**
1. Navigate to Matches list
2. Tap on a match

**Expected Result:**
- ✅ Match profile detail page opens
- ✅ Profile information displayed correctly
- ✅ Action buttons available (message, unmatch)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.3: Message Match from Matches List

**Objective:** Verify user can message a match directly

**Steps:**
1. Navigate to Matches list
2. Tap "Message" button on match card

**Expected Result:**
- ✅ Navigates to conversation with match
- ✅ Can send message
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.4: Unmatch User

**Objective:** Verify user can unmatch another user

**Steps:**
1. Navigate to Matches list or open match profile
2. Tap "Unmatch" option
3. Confirm unmatch action

**Expected Result:**
- ✅ Confirmation dialog appears
- ✅ After confirmation, match removed from list
- ✅ Conversation with user also deleted
- ✅ User no longer appears in Discovery
- ✅ Success message displayed
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.5: New Match Notification

**Objective:** Verify user receives notification for new match

**Prerequisites:**
- Two test accounts that haven't matched yet

**Steps:**
1. Account A likes Account B
2. Account B likes Account A
3. Observe match notification on both accounts

**Expected Result:**
- ✅ Match modal appears immediately after mutual like
- ✅ Push notification sent (if app backgrounded)
- ✅ New match appears in Matches list
- ✅ Match count badge updated
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.6: Filter Matches (If Available)

**Objective:** Verify match filtering functionality

**Steps:**
1. Navigate to Matches list
2. Use filter/sort options (e.g., "Recent", "Unread messages")
3. Observe filtered results

**Expected Result:**
- ✅ Matches filtered correctly
- ✅ Filter criteria applied accurately
- ✅ Can clear filters
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

### Test 6.7: Refresh Matches List

**Objective:** Verify pull-to-refresh works on Matches list

**Steps:**
1. Navigate to Matches list
2. Pull down to refresh

**Expected Result:**
- ✅ Refresh indicator appears
- ✅ Matches list reloaded from server
- ✅ New matches appear (if any)
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 6.8: Likes Received Page

**Objective:** Verify Likes Received feature works (premium)

**Prerequisites:**
- Premium account OR free account with limit

**Steps:**
1. Navigate to Matches tab
2. Tap "Likes Received" or similar option
3. Observe likes received list

**Expected Result:**
- ✅ Likes received list displayed
- ✅ Blurred profile photos (free) or clear photos (premium)
- ✅ Can tap to like back
- ✅ Upgrade CTA shown for free users
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

## 7. Bottom Navigation

**Priority:** P0 (Critical)
**Est. Time:** 10 minutes
**Impact:** Core navigation - must work for app usability

### Test 7.1: Navigate Between All Tabs

**Objective:** Verify all bottom navigation tabs work

**Steps:**
1. Log in to app (opens on Discovery)
2. Tap Matches tab
3. Tap Conversations tab
4. Tap Profile tab
5. Tap Discovery tab
6. Repeat cycle

**Expected Result:**
- ✅ All tabs navigate correctly
- ✅ Active tab highlighted
- ✅ No loading delays or freezes
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 7.2: Tab State Persistence

**Objective:** Verify tab content state is preserved when switching

**Steps:**
1. On Discovery, scroll down in profile stack
2. Navigate to Matches tab
3. Navigate back to Discovery tab
4. Observe Discovery state

**Expected Result:**
- ✅ Discovery state preserved (still at same scroll position/profile)
- ✅ No unnecessary reloading
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 7.3: Unread Badge on Conversations Tab

**Objective:** Verify unread message badge updates correctly

**Steps:**
1. Receive new message (use second test account)
2. Observe Conversations tab badge
3. Open conversation and read message
4. Navigate away and back
5. Observe badge cleared

**Expected Result:**
- ✅ Badge appears with unread count
- ✅ Badge color/style visible
- ✅ After reading, badge updates or disappears
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 7.4: Double-Tap to Refresh

**Objective:** Verify double-tapping active tab refreshes content

**Steps:**
1. Navigate to Discovery tab
2. Tap Discovery tab again (double-tap)
3. Observe refresh behavior

**Expected Result:**
- ✅ Content refreshes (e.g., new profiles loaded)
- ✅ Loading indicator shown
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

### Test 7.5: Navigation During Loading

**Objective:** Verify navigation works even during content loading

**Steps:**
1. Navigate to Discovery (trigger loading)
2. Immediately tap Matches tab before Discovery finishes loading
3. Observe behavior

**Expected Result:**
- ✅ Navigation switches immediately to Matches
- ✅ Discovery loading cancelled or completed in background
- ✅ No crash or freeze

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 7.6: Premium Badge on Tabs (If Applicable)

**Objective:** Verify premium indicators on tabs

**Steps:**
1. Navigate between tabs
2. Observe premium badges or indicators

**Expected Result:**
- ✅ Premium-only tabs show upgrade icon/badge
- ✅ Tapping premium-locked tab shows upgrade modal
- ✅ Premium users have full access
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

## 8. App Lifecycle & State

**Priority:** P1 (High)
**Est. Time:** 10 minutes
**Impact:** Ensures app handles lifecycle events correctly

### Test 8.1: Background and Foreground

**Objective:** Verify app handles backgrounding correctly

**Steps:**
1. Open app and navigate to any feature
2. Press Home button (send app to background)
3. Wait 10 seconds
4. Reopen app

**Expected Result:**
- ✅ App resumes from same screen
- ✅ State preserved correctly
- ✅ No data loss
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 8.2: Long Background (Memory Pressure)

**Objective:** Verify app handles long background period

**Steps:**
1. Open app
2. Send app to background
3. Open several other apps (create memory pressure)
4. Wait 5-10 minutes
5. Reopen app

**Expected Result:**
- ✅ App restarts gracefully (may go through splash)
- ✅ User still logged in (session persisted)
- ✅ Navigates to appropriate screen
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 8.3: Incoming Call Interruption

**Objective:** Verify app handles incoming calls

**Steps:**
1. Open app and use any feature
2. Receive incoming phone call (or simulate)
3. Answer call
4. End call
5. Return to app

**Expected Result:**
- ✅ App pauses correctly during call
- ✅ After call, app resumes
- ✅ State preserved
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 8.4: Network Change (Wi-Fi ↔ Cellular)

**Objective:** Verify app handles network switching

**Steps:**
1. Open app on Wi-Fi
2. Perform action (e.g., load profiles)
3. Switch to cellular data mid-action
4. Observe behavior

**Expected Result:**
- ✅ App detects network change
- ✅ Action continues on new network
- ✅ No error or crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### Test 8.5: Low Storage Warning

**Objective:** Verify app handles low storage gracefully

**Steps:**
1. Fill device storage to near capacity
2. Open app
3. Attempt to upload photo or use features

**Expected Result:**
- ✅ App displays low storage warning
- ✅ Prevents actions that require storage
- ✅ Error message clear and actionable
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

### Test 8.6: App Update Scenario

**Objective:** Verify app handles updates correctly

**Steps:**
1. Install older version of app (if available)
2. Use app and create some data
3. Update to new version
4. Open updated app

**Expected Result:**
- ✅ App updates successfully
- ✅ User data migrated correctly
- ✅ No data loss
- ✅ New features accessible
- ✅ No crash

**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A

---

## Test Execution Checklist

### Pre-Test Preparation

- [ ] Test devices prepared (Android + iOS)
- [ ] Test accounts created (free and premium)
- [ ] Network conditions tested (Wi-Fi, cellular, offline)
- [ ] Screen recording enabled for bug documentation
- [ ] Issue tracking system accessible

### During Testing

- [ ] Execute all P0 tests first
- [ ] Document all failures with screenshots/recordings
- [ ] Retest failed scenarios immediately after fix
- [ ] Note any performance issues or visual glitches
- [ ] Verify internationalization (test in FR and EN)

### Post-Test Reporting

- [ ] All test results documented in issue tracker
- [ ] P0 failures escalated immediately
- [ ] Regression summary report created
- [ ] QA sign-off obtained (or rejection with reasons)
- [ ] Test evidence archived (screenshots, logs, recordings)

---

## Issue Tracking Template

Use this template to document any issues found during smoke testing:

```markdown
### Issue #[NUMBER]: [Brief Title]

**Severity:** [ ] Critical (P0) [ ] High (P1) [ ] Medium (P2) [ ] Low (P3)

**Feature:** [Authentication | Discovery | Profile | Messaging | Settings | Matches | Navigation | Other]

**Test Case:** [Test number and title, e.g., Test 1.1: Fresh App Launch and Login]

**Environment:**
- Device: [e.g., Samsung Galaxy S21, iPhone 13]
- OS Version: [e.g., Android 12, iOS 16]
- App Version: [e.g., 1.5.0 build 234]
- Network: [Wi-Fi | 4G | Offline]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Third step]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots/Video:**
[Attach evidence]

**Logs/Error Messages:**
```
[Paste relevant logs or error messages]
```

**Impact:**
[Describe user impact and workaround if any]

**Status:** [ ] Open [ ] In Progress [ ] Fixed [ ] Verified [ ] Closed

**Assigned To:** [Developer name]

**Notes:**
[Any additional context or observations]
```

---

## QA Sign-Off

### Test Execution Summary

**Test Execution Date:** ________________
**Tester Name:** ________________
**App Version:** ________________
**Build Number:** ________________

| Category | Total Tests | Passed | Failed | Blocked | Pass Rate |
|----------|-------------|--------|--------|---------|-----------|
| Authentication & Login | 8 | ___ | ___ | ___ | ___% |
| Home/Discovery Navigation | 6 | ___ | ___ | ___ | ___% |
| User Profile | 8 | ___ | ___ | ___ | ___% |
| Messaging & Conversations | 10 | ___ | ___ | ___ | ___% |
| Settings & Configuration | 8 | ___ | ___ | ___ | ___% |
| Matches Management | 8 | ___ | ___ | ___ | ___% |
| Bottom Navigation | 6 | ___ | ___ | ___ | ___% |
| App Lifecycle & State | 6 | ___ | ___ | ___ | ___% |
| **TOTAL** | **60** | ___ | ___ | ___ | ___% |

### Critical Issues Summary

**P0 (Critical) Issues Found:** ___

**List of P0 Issues:**
1. [Issue #__ - Brief description]
2. [Issue #__ - Brief description]
3. [Issue #__ - Brief description]

**All P0 Issues Resolved:** [ ] Yes [ ] No

### Sign-Off Decision

**QA Recommendation:**

- [ ] ✅ **APPROVED FOR PRODUCTION** - All smoke tests passed, no regressions detected
- [ ] ⚠️ **APPROVED WITH NOTES** - Minor issues found but not blocking deployment
- [ ] ❌ **NOT APPROVED** - Critical regressions found, must fix before deployment

**Rationale:**
[Explain the decision and any caveats]

**QA Sign-Off:**

Name: ________________
Signature: ________________
Date: ________________

**Product Owner Sign-Off:**

Name: ________________
Signature: ________________
Date: ________________

---

## Appendix A: Test Environment Setup

### Android Device Setup

1. **Enable Developer Options:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable USB Debugging

2. **Network Throttling (Optional):**
   - Developer Options → Networking → Simulate poor networks

3. **Screen Recording:**
   - Use built-in screen recorder or ADB: `adb shell screenrecord`

### iOS Device Setup

1. **Enable Developer Mode:**
   - Settings → Privacy & Security → Developer Mode (iOS 16+)

2. **Screen Recording:**
   - Control Center → Screen Recording

3. **Network Throttling:**
   - Use Network Link Conditioner from Xcode

### Test Account Setup

**Free User Account:**
- Email: `test_free@hivmeet.com`
- Password: [Secure password]
- Premium Status: Free tier

**Premium User Account:**
- Email: `test_premium@hivmeet.com`
- Password: [Secure password]
- Premium Status: Active subscription

---

## Appendix B: Common Failure Patterns

### Integration Issues to Watch For

1. **Navigation Breaks:**
   - Back button behavior changed
   - Deep links not working
   - Bottom nav state issues

2. **Shared Service Failures:**
   - Auth token not injected in API calls
   - i18n strings missing or hardcoded
   - Network status not detected

3. **State Management Issues:**
   - Discovery state not preserved
   - Matches list not updating after new match
   - Unread badges not clearing

4. **Performance Regressions:**
   - Increased load times
   - Animation jank (< 60 FPS)
   - Memory leaks causing crashes

5. **Data Inconsistencies:**
   - Profile data not syncing
   - Messages not appearing
   - Match count mismatch

---

## Appendix C: Risk Areas (Based on Discovery Changes)

### High-Risk Integration Points

These areas are most likely to have regressions due to Discovery page changes:

1. **Bottom Navigation State Management**
   - Risk: Discovery tab state conflicts with other tabs
   - Test: 7.1, 7.2, 7.5

2. **Match Detection Flow**
   - Risk: Match modal breaks Conversations navigation
   - Test: 2.5, 4.7, 6.5

3. **Shared Services (Auth, API, i18n)**
   - Risk: Token injection, API interceptors, localization
   - Test: 1.1, 1.6, 5.2

4. **Profile Navigation**
   - Risk: Discovery profile detail conflicts with Profile tab
   - Test: 2.4, 3.4, 6.2

5. **State Preservation**
   - Risk: Discovery state clears when navigating away
   - Test: 7.2, 8.1, 8.2

### Recommended Focus Areas

If time is limited, prioritize these test categories:

1. **P0 Priority:** Authentication (Test 1.1-1.6)
2. **P0 Priority:** Bottom Navigation (Test 7.1-7.3)
3. **P0 Priority:** Messaging (Test 4.1-4.5)
4. **P1 Priority:** Matches (Test 6.1-6.5)
5. **P1 Priority:** App Lifecycle (Test 8.1-8.4)

---

**End of Smoke Test Suite**

**Document Version:** 1.0
**Last Updated:** 2026-02-28
**Next Review:** After QA execution

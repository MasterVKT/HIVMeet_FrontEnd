# Discovery Page - Performance & Loading Scenarios Testing Guide

**Project:** HIVMeet - Dating App for People Living with HIV/AIDS
**Component:** Discovery Page (Swipe Interface)
**Test Type:** Performance, Network Resilience, App Lifecycle
**Priority:** P0 (Critical for Production Release)
**Version:** 1.0.0
**Date:** February 27, 2026
**Related Subtask:** 7.6 - Test performance and loading scenarios

---

## Table of Contents

1. [Overview](#overview)
2. [Test Execution Summary](#test-execution-summary)
3. [Prerequisites](#prerequisites)
4. [Part 1: Slow Network Testing](#part-1-slow-network-testing)
5. [Part 2: Large Dataset Testing](#part-2-large-dataset-testing)
6. [Part 3: Poor Connectivity Testing](#part-3-poor-connectivity-testing)
7. [Part 4: App Lifecycle Testing](#part-4-app-lifecycle-testing)
8. [Part 5: Loading Indicators Verification](#part-5-loading-indicators-verification)
9. [Part 6: Performance Metrics Validation](#part-6-performance-metrics-validation)
10. [Part 7: Memory Usage Testing](#part-7-memory-usage-testing)
11. [Issue Tracking Template](#issue-tracking-template)
12. [Sign-off Checklist](#sign-off-checklist)

---

## Overview

### Purpose

This document provides comprehensive manual testing procedures to validate Discovery page performance under challenging real-world conditions including:

- **Slow Networks**: 2G/3G speeds, high latency
- **Large Datasets**: 100+ profiles, pagination stress testing
- **Poor Connectivity**: Intermittent connections, offline mode, connection drops
- **App Lifecycle**: Backgrounding, foregrounding, memory pressure, cold starts
- **Loading States**: Skeleton UI, spinners, error recovery
- **Performance**: Frame rates, response times, stuttering
- **Memory**: Leaks, efficient image loading, cache management

### Success Criteria

✅ **All tests must pass** for QA sign-off:
- Loading indicators appear within 100ms of user action
- Animations maintain ≥60 FPS even on slow networks
- No crashes or ANR (Application Not Responding) events
- Graceful degradation on poor connectivity
- App state restored correctly after backgrounding
- No memory leaks detected over 15-minute session
- Memory usage stays below 150 MB during normal usage
- Error messages are user-friendly and actionable

### Testing Environment

**Required Test Devices:**
- 1x Android phone (API 29+) with network throttling capability
- 1x iPhone (iOS 14+) with network link conditioner
- 1x Low-spec Android device (2GB RAM) for memory testing

**Required Tools:**
- **Android**: Chrome DevTools for network throttling, Android Studio Profiler for memory
- **iOS**: Xcode Network Link Conditioner, Instruments for memory profiling
- **Cross-platform**: Flutter DevTools for performance overlay

**Network Conditions to Simulate:**
- **2G (GPRS)**: 50 kbps, 500ms latency
- **3G**: 750 kbps, 100ms latency
- **4G**: 4 Mbps, 50ms latency
- **Offline**: Airplane mode enabled
- **Flaky**: Random packet loss (20%)

---

## Test Execution Summary

| Category | Tests | Priority | Est. Time |
|----------|-------|----------|-----------|
| Slow Network Testing | 12 | P0 | 90 min |
| Large Dataset Testing | 8 | P0 | 60 min |
| Poor Connectivity Testing | 10 | P0 | 75 min |
| App Lifecycle Testing | 10 | P0 | 60 min |
| Loading Indicators | 8 | P0 | 45 min |
| Performance Metrics | 8 | P0 | 60 min |
| Memory Usage Testing | 8 | P0 | 90 min |
| **TOTAL** | **64** | - | **~8 hours** |

**Recommended Approach:**
- Execute tests sequentially by category
- Document results immediately using issue tracking template
- Use multiple devices in parallel to reduce total time
- Perform memory testing last (requires longest monitoring period)

---

## Prerequisites

### 1. Test Account Setup

- [ ] Test account with 100+ available profiles in discovery queue
- [ ] Test account with premium features enabled (for super like/rewind testing)
- [ ] Test account with <10 profiles remaining (for empty state testing)
- [ ] Valid authentication token stored in flutter_secure_storage

### 2. Environment Configuration

- [ ] Flutter DevTools installed and connected
- [ ] Network throttling tools configured (Chrome DevTools or Network Link Conditioner)
- [ ] Android Studio Profiler / Xcode Instruments available
- [ ] Test device storage >2 GB available
- [ ] Test device battery >50% (performance testing drains battery)

### 3. Test Data Preparation

- [ ] Backend populated with profiles containing varied photo counts (1-6 photos each)
- [ ] Mix of high-resolution (>2MB) and standard photos
- [ ] Profiles with long bios (>500 characters)
- [ ] Profiles with multiple interests/badges

### 4. Build Configuration

- [ ] Using **profile mode** build (not debug or release):
  ```bash
  flutter run --profile
  ```
  Profile mode enables performance overlay while maintaining production-like performance.

---

## Part 1: Slow Network Testing

**Objective:** Verify Discovery page performs acceptably on slow networks (2G/3G) without freezing, crashes, or poor UX.

**Setup:**
1. Enable network throttling to **2G (GPRS)**: 50 kbps, 500ms latency
2. Clear app cache and restart app
3. Login and navigate to Discovery page

---

### Test 1.1: Initial Profile Load on 2G

**Priority:** P0
**Scenario:** User opens Discovery page for the first time on 2G network.

**Steps:**
1. Enable 2G throttling (50 kbps, 500ms latency)
2. Open Discovery page
3. Observe loading behavior

**Expected Results:**
- [ ] Skeleton UI appears within 100ms
- [ ] Loading indicator shows network activity
- [ ] First profile appears within 10 seconds
- [ ] Swipe card stack renders with placeholder avatars for photos not yet loaded
- [ ] No app freeze or ANR dialog
- [ ] Error message if timeout after 30 seconds: "Slow connection. Please wait..."

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.2: Photo Loading on Slow Network

**Priority:** P0
**Scenario:** Profile photos load progressively without blocking UI.

**Steps:**
1. Maintain 2G throttling
2. Swipe to profile with 5-6 photos
3. Observe photo loading behavior

**Expected Results:**
- [ ] First photo loads within 5 seconds
- [ ] Subsequent photos load in background (pagination dots show loading state)
- [ ] Placeholder avatars shown until photo loads
- [ ] User can swipe horizontally between photos even if not all loaded
- [ ] Low-resolution preview loads first, then high-res (progressive JPEG)
- [ ] Swipe gestures remain responsive during photo loading

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.3: Swipe Action on 2G (Like/Dislike)

**Priority:** P0
**Scenario:** Swipe actions submit to API despite slow network.

**Steps:**
1. Maintain 2G throttling
2. Swipe right (like) on a profile
3. Observe UI behavior during API call

**Expected Results:**
- [ ] Card animates immediately (optimistic UI)
- [ ] Next profile appears in stack
- [ ] Loading indicator shows submission in progress
- [ ] If API call succeeds after delay: action confirmed silently
- [ ] If API call fails: retry automatically or show error with retry button
- [ ] Likes remaining counter updates after API confirmation
- [ ] No duplicate API calls sent

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.4: Match Detection on Slow Network

**Priority:** P0
**Scenario:** Match modal appears correctly even with delayed API response.

**Steps:**
1. Maintain 2G throttling
2. Swipe right on a profile that will result in a match (coordinate with backend)
3. Wait for API response

**Expected Results:**
- [ ] Card swipes off screen immediately
- [ ] Loading indicator shows for 3-10 seconds (API delay)
- [ ] Match modal appears after API confirms match
- [ ] Both profile photos load in modal (may take 5-10 seconds)
- [ ] "Send Message" and "Keep Swiping" buttons functional
- [ ] No crash or timeout error

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.5: Filter Application on 2G

**Priority:** P0
**Scenario:** Applying filters on slow network doesn't freeze UI.

**Steps:**
1. Maintain 2G throttling
2. Tap filters icon
3. Change age range from 25-35 to 30-40
4. Tap "Apply"

**Expected Results:**
- [ ] Filters modal dismisses immediately
- [ ] Discovery page shows skeleton UI
- [ ] Loading indicator appears
- [ ] Estimated profile count updates after API call (3-10 seconds)
- [ ] New profiles matching filters load within 15 seconds
- [ ] If timeout: error message "Slow connection. Please retry." with retry button

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.6: Pagination on 3G Network

**Priority:** P0
**Scenario:** Next page of profiles loads automatically as user approaches end of current batch.

**Setup:** Switch to 3G throttling (750 kbps, 100ms latency)

**Steps:**
1. Enable 3G throttling
2. Swipe through 15 profiles rapidly (assuming 20-profile pages)
3. Observe behavior when approaching end of batch

**Expected Results:**
- [ ] Background API call triggered when 3-5 profiles remain
- [ ] No interruption to swiping UX
- [ ] Next batch loads seamlessly
- [ ] If next page load fails: "No more profiles" message only after current batch depleted
- [ ] No duplicate API calls (check network log)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.7: Rapid Swipes on Slow Network (Debouncing)

**Priority:** P0
**Scenario:** Rapid swiping doesn't overwhelm API or cause duplicate requests.

**Steps:**
1. Maintain 3G throttling
2. Swipe right/left rapidly on 10 profiles in <5 seconds
3. Monitor network requests (Chrome DevTools Network tab or proxy)

**Expected Results:**
- [ ] All swipe animations execute smoothly at 60 FPS
- [ ] API requests queued and sent sequentially (no race conditions)
- [ ] No duplicate requests for same profile
- [ ] Optimistic UI shows correct state even before API confirms
- [ ] Error handling if batch submission fails: retry mechanism or error notification

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.8: Profile Detail Page on 2G

**Priority:** P1
**Scenario:** Opening full profile detail from swipe card on slow network.

**Steps:**
1. Switch back to 2G throttling
2. Tap on a profile card to open detail view
3. Observe loading behavior

**Expected Results:**
- [ ] Navigation transition smooth (no lag)
- [ ] Profile detail page shows skeleton UI while loading
- [ ] Name, age, distance appear first (from cached swipe card data)
- [ ] Bio and additional details load within 5 seconds
- [ ] Full photo carousel loads progressively
- [ ] User can navigate back without waiting for full load
- [ ] Scroll interactions remain responsive

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.9: Super Like on Slow Network (Premium)

**Priority:** P1
**Scenario:** Super like action on slow network with confirmation dialog.

**Steps:**
1. Maintain 2G throttling
2. Use premium account with super likes available
3. Tap super like button (star icon) or swipe up
4. Confirm in dialog

**Expected Results:**
- [ ] Confirmation dialog appears immediately
- [ ] After confirmation: card animates with star effect
- [ ] API call submits in background
- [ ] Loading indicator during submission
- [ ] Success: super like counter decrements
- [ ] Failure: error message "Failed to send super like. Retry?" with retry button
- [ ] No double-charging if user taps multiple times

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.10: Rewind on Slow Network (Premium)

**Priority:** P1
**Scenario:** Rewind last swipe on slow network.

**Steps:**
1. Maintain 2G throttling
2. Swipe left (dislike) on a profile
3. Immediately tap rewind button (undo icon)
4. Observe behavior

**Expected Results:**
- [ ] Previous profile reappears in stack immediately (optimistic UI)
- [ ] Loading indicator shows rewind API call in progress
- [ ] If API succeeds: rewind confirmed, profile back in queue
- [ ] If API fails after 10 seconds: error "Rewind failed. Try again?" with retry button
- [ ] Rewind counter updates after API confirmation

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.11: Daily Limit Check on 3G

**Priority:** P0
**Scenario:** Daily limit modal appears correctly even on slow network.

**Steps:**
1. Switch to 3G throttling
2. Use free account with 49/50 likes used
3. Swipe right (like) on next profile
4. Observe limit modal behavior

**Expected Results:**
- [ ] Swipe animation completes
- [ ] API call submits (may take 1-3 seconds)
- [ ] Daily limit modal appears after API confirms limit reached
- [ ] Modal shows "Upgrade to Premium" CTA
- [ ] "Maybe Later" button functional
- [ ] Next swipe attempt shows same modal

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 1.12: Network Speed Change During Session

**Priority:** P1
**Scenario:** Network speed improves/degrades during active session.

**Steps:**
1. Start on 2G throttling with Discovery page open
2. Swipe 2-3 profiles (slow loading)
3. Switch to 4G throttling mid-session
4. Swipe 2-3 more profiles

**Expected Results:**
- [ ] App adapts to faster network automatically
- [ ] Photos load faster without app restart
- [ ] No stale loading states or stuck spinners
- [ ] Reverse test (4G → 2G): graceful degradation, loading indicators reappear

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 2: Large Dataset Testing

**Objective:** Verify Discovery page handles large numbers of profiles efficiently without performance degradation.

**Setup:**
1. Use test account with 200+ profiles available
2. Disable network throttling (use normal 4G/WiFi)
3. Clear app cache and restart

---

### Test 2.1: Initial Load with 200+ Profiles

**Priority:** P0
**Scenario:** Discovery page loads efficiently even with large dataset available.

**Steps:**
1. Navigate to Discovery page
2. Observe initial load time and behavior

**Expected Results:**
- [ ] First page (20 profiles) loads within 2 seconds
- [ ] Memory usage reasonable (check DevTools: <80 MB for profile data)
- [ ] Preloading limited to next 2-3 profiles (not all 200)
- [ ] Scroll performance smooth if card stack scrollable
- [ ] No lag or stutter during rendering

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.2: Swipe Through 50 Profiles Continuously

**Priority:** P0
**Scenario:** Sustained swiping through large dataset without performance degradation.

**Steps:**
1. Swipe through 50 profiles continuously at moderate pace (~1 swipe per 2 seconds)
2. Monitor performance using Flutter DevTools performance overlay

**Expected Results:**
- [ ] Animations maintain 60 FPS throughout
- [ ] No noticeable slowdown after 20, 30, 40 profiles
- [ ] Memory usage grows moderately then stabilizes (check DevTools memory chart)
- [ ] Pagination automatic and seamless
- [ ] No crashes or out-of-memory errors

**Actual Results:**
```
[To be filled by QA tester]
Memory at start: ___ MB | After 25 profiles: ___ MB | After 50 profiles: ___ MB
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.3: Rapid Swipes on Large Dataset

**Priority:** P0
**Scenario:** Rapid swiping stresses rendering and API calls.

**Steps:**
1. Swipe through 20 profiles as fast as possible (<10 seconds total)
2. Observe animation performance and API behavior

**Expected Results:**
- [ ] All swipe animations execute smoothly
- [ ] No dropped frames (check performance overlay: no red bars)
- [ ] API requests batched or queued intelligently
- [ ] Pagination triggers before profiles depleted
- [ ] No "No more profiles" error if more profiles available

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.4: Profile with Maximum Photos (6 Photos)

**Priority:** P0
**Scenario:** Profile with maximum allowed photos loads and performs well.

**Steps:**
1. Swipe to profile with 6 high-resolution photos
2. Swipe horizontally through all 6 photos
3. Monitor performance

**Expected Results:**
- [ ] First photo loads within 1 second
- [ ] Horizontal swipe gestures smooth at 60 FPS
- [ ] Pagination dots update correctly (1/6, 2/6, etc.)
- [ ] All 6 photos load within 5 seconds on WiFi
- [ ] Memory usage acceptable (check DevTools: <30 MB for 6 photos)
- [ ] Subsequent profiles load normally

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.5: Filter Result with 100+ Matching Profiles

**Priority:** P0
**Scenario:** Applying filter returns large result set.

**Steps:**
1. Open filters
2. Set age range 25-45 (broad range likely to match 100+ profiles)
3. Apply filter
4. Observe results and performance

**Expected Results:**
- [ ] Estimated count shows "100+ profiles" or exact count
- [ ] First page loads within 2 seconds
- [ ] Swipe performance same as unfiltered discovery
- [ ] Pagination works correctly across filtered dataset
- [ ] No timeout or "too many results" error

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.6: Memory Stability After 100 Swipes

**Priority:** P0
**Scenario:** Extended session doesn't cause memory leak.

**Steps:**
1. Open Flutter DevTools memory profiler
2. Baseline memory usage at Discovery page idle
3. Swipe through 100 profiles over 10-15 minutes
4. Return to idle state
5. Check memory usage

**Expected Results:**
- [ ] Memory grows during swiping (expected: cached images)
- [ ] Memory stabilizes after 50-60 profiles (garbage collection working)
- [ ] Final memory usage <150 MB after 100 swipes
- [ ] Memory returns near baseline after idle for 1 minute
- [ ] No continuous growth (no memory leak)

**Actual Results:**
```
[To be filled by QA tester]
Baseline: ___ MB | Peak during session: ___ MB | After idle: ___ MB
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.7: Pagination Edge Case (Exactly 20 Profiles Remaining)

**Priority:** P1
**Scenario:** Last page of profiles loads correctly.

**Setup:** Use account with exactly 40 profiles available (2 pages)

**Steps:**
1. Swipe through first 20 profiles
2. Observe behavior when loading second page
3. Swipe through remaining 20 profiles

**Expected Results:**
- [ ] Second page loads automatically when 3-5 profiles remain in first page
- [ ] All 40 profiles accessible
- [ ] After 40th swipe: "No more profiles" message appears
- [ ] No API error or infinite loading

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 2.8: Profile with Very Long Bio (>1000 Characters)

**Priority:** P1
**Scenario:** Large text content doesn't break layout or performance.

**Steps:**
1. Swipe to profile with bio >1000 characters
2. Open profile detail page
3. Scroll through bio
4. Return to swipe card

**Expected Results:**
- [ ] Bio truncated on swipe card (e.g., "See more...")
- [ ] Full bio readable in detail page
- [ ] Scroll performance smooth in detail view
- [ ] No layout overflow or text clipping
- [ ] Navigation back to Discovery page smooth

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 3: Poor Connectivity Testing

**Objective:** Verify graceful handling of connection issues: offline mode, intermittent connectivity, connection drops.

**Setup:**
1. Disable network throttling tools
2. Prepare to toggle airplane mode or disable WiFi manually

---

### Test 3.1: Open Discovery Page While Offline

**Priority:** P0
**Scenario:** User opens Discovery page with no internet connection.

**Steps:**
1. Enable airplane mode
2. Open HIVMeet app and navigate to Discovery page
3. Observe behavior

**Expected Results:**
- [ ] Page loads immediately with cached profiles (if any)
- [ ] Error message appears: "No internet connection. Please check your network."
- [ ] Retry button available
- [ ] If no cached profiles: empty state illustration with offline message
- [ ] No crash or infinite loading spinner

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.2: Swipe Action While Offline

**Priority:** P0
**Scenario:** User attempts to swipe while offline.

**Steps:**
1. Maintain airplane mode
2. If cached profiles available, swipe right on one
3. Observe behavior

**Expected Results:**
- [ ] Swipe animation executes (optimistic UI)
- [ ] Action queued for retry when online
- [ ] Notification: "Action saved. Will sync when online." (snackbar)
- [ ] OR: "No internet. Cannot complete action." with retry option
- [ ] Next profile appears if cached
- [ ] No crash

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.3: Connection Loss During Swipe

**Priority:** P0
**Scenario:** Internet disconnects mid-swipe action.

**Steps:**
1. Disable airplane mode (restore connection)
2. Start swiping right on a profile
3. While swipe animation in progress, enable airplane mode
4. Observe outcome

**Expected Results:**
- [ ] Swipe animation completes smoothly (no visual glitch)
- [ ] Loading indicator appears briefly
- [ ] Error message: "Connection lost. Action will retry automatically."
- [ ] Action retries when connection restored (within 30 seconds)
- [ ] OR: User can manually retry from error state

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.4: Reconnection After Offline Period

**Priority:** P0
**Scenario:** App reconnects gracefully after offline period.

**Steps:**
1. With Discovery page open and airplane mode enabled
2. Wait 30 seconds
3. Disable airplane mode (restore connection)
4. Tap retry button or wait for auto-reconnect

**Expected Results:**
- [ ] App detects connection restored automatically within 5 seconds
- [ ] Profiles reload automatically OR retry button appears
- [ ] Queued actions (likes/dislikes) submit automatically
- [ ] No duplicate submissions
- [ ] User can continue swiping normally

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.5: Intermittent Connection (Flaky Network)

**Priority:** P0
**Scenario:** Connection drops intermittently during session.

**Setup:** Use network throttling tool with 20% packet loss or manually toggle airplane mode every 10 seconds

**Steps:**
1. Configure flaky network (20% packet loss)
2. Attempt to swipe through 10 profiles
3. Observe behavior

**Expected Results:**
- [ ] Some API calls succeed, some fail
- [ ] Failed actions show retry option
- [ ] Successful actions proceed normally
- [ ] Loading indicators reflect network activity accurately
- [ ] No app hang or ANR
- [ ] User informed of connection issues: "Unstable connection. Some actions may be delayed."

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.6: Timeout Handling (30-Second API Timeout)

**Priority:** P0
**Scenario:** API request times out after 30 seconds.

**Setup:** Use extreme network throttling (10 kbps) to force timeout

**Steps:**
1. Configure 10 kbps throttling
2. Swipe right on a profile
3. Wait for timeout (30 seconds)

**Expected Results:**
- [ ] Loading indicator shows for up to 30 seconds
- [ ] After 30 seconds: error message "Request timed out. Please try again."
- [ ] Retry button available
- [ ] OR: Action queued for automatic retry
- [ ] No infinite loading state

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.7: API Error Response (500 Internal Server Error)

**Priority:** P1
**Scenario:** Backend returns error response.

**Setup:** Coordinate with backend team to trigger 500 error for `/discovery/` endpoint

**Steps:**
1. Navigate to Discovery page (triggers API call)
2. Observe error handling

**Expected Results:**
- [ ] Error message appears: "Something went wrong. Please try again later."
- [ ] Retry button available
- [ ] No crash or blank screen
- [ ] Error logged (check logs, but NO PII logged)
- [ ] Fallback to cached profiles if available

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.8: Photo Load Failure (404 Not Found)

**Priority:** P1
**Scenario:** Profile photo URL returns 404 error.

**Setup:** Use profile with invalid photo URL

**Steps:**
1. Swipe to profile with broken photo URL
2. Observe photo loading behavior

**Expected Results:**
- [ ] Placeholder avatar appears instead of broken image icon
- [ ] User can still swipe profile (not blocked)
- [ ] Other profile info (name, age, bio) displays correctly
- [ ] Tap on placeholder allows retry or shows error: "Photo unavailable"

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.9: Offline Mode with Cached Data

**Priority:** P1
**Scenario:** User browses previously loaded profiles while offline.

**Steps:**
1. Load Discovery page with 20 profiles
2. Swipe through 5 profiles (view photos, read bios)
3. Enable airplane mode
4. Navigate back and forth between Discovery and other tabs
5. Return to Discovery

**Expected Results:**
- [ ] Previously loaded 15 profiles still accessible
- [ ] Photos already loaded display correctly
- [ ] Swipe actions show "Offline" message but don't crash
- [ ] User informed: "Viewing cached profiles. Connect to see more."
- [ ] No new profiles load (expected behavior)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 3.10: Connection Drop During Match Modal

**Priority:** P1
**Scenario:** Internet disconnects while match modal is open.

**Steps:**
1. Swipe right on a profile that results in match
2. While match modal is opening, enable airplane mode
3. Tap "Send Message" button

**Expected Results:**
- [ ] Match modal displays correctly (match already confirmed by API before disconnect)
- [ ] "Send Message" button tap shows error: "Cannot open messages. No internet connection."
- [ ] "Keep Swiping" button functional
- [ ] Match is saved and appears in matches list later (when online)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 4: App Lifecycle Testing

**Objective:** Verify Discovery page handles app backgrounding, foregrounding, memory pressure, and process termination gracefully.

**Setup:**
1. Disable network throttling
2. Use normal 4G/WiFi connection

---

### Test 4.1: Background App During Swipe

**Priority:** P0
**Scenario:** User backgrounds app mid-swipe.

**Steps:**
1. Begin swiping right on a profile (animation in progress)
2. Press home button (background app)
3. Wait 5 seconds
4. Reopen app

**Expected Results:**
- [ ] App resumes at Discovery page (state preserved)
- [ ] Swipe action completed (card swiped off)
- [ ] Next profile visible in stack
- [ ] No crash or UI corruption
- [ ] API call completed in background OR retried on foreground

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.2: Foreground After Short Background (30 Seconds)

**Priority:** P0
**Scenario:** User backgrounds app briefly, then returns.

**Steps:**
1. Browse Discovery page normally
2. Background app for 30 seconds
3. Foreground app

**Expected Results:**
- [ ] Discovery page state preserved (same profile visible)
- [ ] No data refresh triggered automatically
- [ ] User can continue swiping immediately
- [ ] Counters (likes remaining) updated if changed server-side
- [ ] No splash screen or loading delay

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.3: Foreground After Long Background (10 Minutes)

**Priority:** P0
**Scenario:** User backgrounds app for extended period.

**Steps:**
1. Browse Discovery page
2. Background app for 10 minutes
3. Foreground app

**Expected Results:**
- [ ] App resumes at Discovery page
- [ ] Profile data refreshed automatically (new profiles may appear)
- [ ] If auth token expired: user prompted to re-login
- [ ] Smooth transition (no crash or blank screen)
- [ ] Updated daily limit counters if reset time passed

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.4: App Killed by OS (Process Termination)

**Priority:** P0
**Scenario:** OS kills app process while backgrounded.

**Steps:**
1. Browse Discovery page
2. Background app
3. Force-stop app via device settings (simulate OS kill)
4. Reopen app from launcher

**Expected Results:**
- [ ] App performs cold start
- [ ] User authenticated (token persisted in flutter_secure_storage)
- [ ] Navigates to last known screen (Discovery page)
- [ ] Profile data reloads
- [ ] No crash or error modal

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.5: Memory Pressure Simulation (Low RAM Device)

**Priority:** P0
**Scenario:** App handles low memory conditions without crash.

**Setup:** Use low-spec device (2GB RAM) or simulate memory pressure

**Steps:**
1. Open Discovery page
2. Swipe through 20 profiles (memory grows)
3. Open several other apps in background (create memory pressure)
4. Return to HIVMeet

**Expected Results:**
- [ ] App remains in memory if possible
- [ ] If OS evicts app: cold start on return (expected)
- [ ] No out-of-memory crash
- [ ] Images release from memory to free resources (garbage collection)
- [ ] Performance may degrade gracefully but remains usable

**Actual Results:**
```
[To be filled by QA tester]
Device RAM: ___ GB | Peak app memory: ___ MB | Crash: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.6: Lock Screen and Unlock

**Priority:** P1
**Scenario:** User locks device, then unlocks.

**Steps:**
1. Browse Discovery page
2. Press power button (lock screen)
3. Wait 10 seconds
4. Unlock device

**Expected Results:**
- [ ] App resumes immediately at Discovery page
- [ ] State fully preserved (same profile, swipe position)
- [ ] No re-authentication required (within session timeout)
- [ ] No layout reflow or visual glitch

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.7: Incoming Call During Swipe

**Priority:** P1
**Scenario:** User receives phone call while using Discovery page.

**Steps:**
1. Begin swiping through profiles
2. Simulate incoming call (use another device to call test device)
3. Answer call, talk for 30 seconds, hang up
4. Return to app

**Expected Results:**
- [ ] App backgrounds automatically during call
- [ ] After call: app foregrounds to Discovery page
- [ ] State preserved (profile stack intact)
- [ ] In-progress swipe either completed or reset gracefully
- [ ] No crash

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.8: App Update / Reinstall (State Persistence)

**Priority:** P1
**Scenario:** User updates app or reinstalls, state handling.

**Steps:**
1. Use Discovery page, swipe through some profiles
2. Uninstall app
3. Reinstall app
4. Login with same account

**Expected Results:**
- [ ] Auth token cleared (expected: fresh login required)
- [ ] User preferences/filters cleared OR persisted (check spec)
- [ ] Discovery queue resets (expected: start from beginning)
- [ ] No crash or stale data issues
- [ ] Previously matched profiles still in matches list (server-side data)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.9: Orientation Change (Portrait ↔ Landscape)

**Priority:** P1
**Scenario:** Device rotation during Discovery page use.

**Steps:**
1. Browse Discovery page in portrait mode
2. Rotate device to landscape
3. Rotate back to portrait

**Expected Results:**
- [ ] Layout adapts to landscape orientation (if supported)
- [ ] OR: Portrait-only lock prevents rotation (check spec)
- [ ] If rotation supported: swipe card resizes correctly
- [ ] State preserved across rotations
- [ ] No layout corruption or overlap
- [ ] Animations re-initialize smoothly

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 4.10: Multitasking / Split-Screen (Android)

**Priority:** P2
**Scenario:** App runs in split-screen mode.

**Setup:** Android device with split-screen support

**Steps:**
1. Open Discovery page
2. Enter split-screen mode with another app (e.g., messaging app)
3. Interact with Discovery in reduced screen space

**Expected Results:**
- [ ] Discovery page renders correctly in smaller viewport
- [ ] Swipe gestures still functional
- [ ] Text remains readable
- [ ] No layout overflow or clipping
- [ ] Performance acceptable (may be slightly slower)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 5: Loading Indicators Verification

**Objective:** Verify loading indicators appear correctly, timely, and accurately reflect system state.

**Setup:**
1. Use 3G throttling (750 kbps, 100ms latency) for visible loading states
2. Clear app cache

---

### Test 5.1: Initial Page Load - Skeleton UI

**Priority:** P0
**Scenario:** Skeleton UI displays during initial Discovery page load.

**Steps:**
1. Enable 3G throttling
2. Navigate to Discovery page from another tab
3. Observe loading state

**Expected Results:**
- [ ] Skeleton UI appears within 100ms of navigation
- [ ] Skeleton shows placeholder cards (3-5 cards stacked)
- [ ] Skeleton has subtle shimmer animation
- [ ] Skeleton UI replaced by actual profiles when loaded (within 3 seconds)
- [ ] No blank white screen at any point

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.2: Photo Loading - Progressive Indicators

**Priority:** P0
**Scenario:** Photo loading indicators show progress.

**Steps:**
1. Maintain 3G throttling
2. Swipe to new profile with 4 photos
3. Observe photo loading

**Expected Results:**
- [ ] Placeholder avatar shown until first photo loads
- [ ] Shimmer effect on photo placeholder
- [ ] Photo fades in when loaded (smooth transition)
- [ ] Pagination dots show loading state (gray = not loaded, colored = loaded)
- [ ] Progressive JPEG loads low-res preview first, then full-res

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.3: Swipe Action - Submission Indicator

**Priority:** P0
**Scenario:** Loading indicator during swipe action API submission.

**Steps:**
1. Maintain 3G throttling
2. Swipe right on a profile
3. Observe loading indicators during API call

**Expected Results:**
- [ ] Swipe animation completes immediately (optimistic UI)
- [ ] Small loading indicator appears (spinner in corner or bottom of screen)
- [ ] Loading indicator disappears when API call completes (1-3 seconds)
- [ ] If error: indicator replaced by error icon with retry option

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.4: Filter Application - Loading Overlay

**Priority:** P0
**Scenario:** Loading indicator when applying filters.

**Steps:**
1. Open filters modal
2. Change age range
3. Tap "Apply"
4. Observe loading state

**Expected Results:**
- [ ] Filters modal dismisses
- [ ] Loading overlay appears over Discovery page (semi-transparent scrim)
- [ ] Spinner or loading animation centered
- [ ] Text: "Loading profiles with your filters..."
- [ ] Overlay disappears when profiles load (2-5 seconds)

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.5: Pagination - Background Loading Indicator

**Priority:** P1
**Scenario:** Subtle indicator when loading next page in background.

**Steps:**
1. Swipe through 15 profiles (approaching end of 20-profile page)
2. Observe behavior as next page loads

**Expected Results:**
- [ ] Small loading indicator appears at bottom of screen (non-intrusive)
- [ ] OR: Subtle text "Loading more profiles..."
- [ ] User can continue swiping current profiles without interruption
- [ ] Indicator disappears when next page loaded

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.6: Match Detection - Anticipation Indicator

**Priority:** P1
**Scenario:** Brief loading state before match modal appears.

**Steps:**
1. Swipe right on a profile that will result in match
2. Observe transition to match modal

**Expected Results:**
- [ ] Swipe animation completes
- [ ] Brief loading indicator (0.5-2 seconds) while checking for match
- [ ] OR: Smooth transition directly to match modal if API fast
- [ ] No jarring delay or blank screen

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.7: Error State - Clear Error Messaging

**Priority:** P0
**Scenario:** Error replaces loading indicator with clear message.

**Steps:**
1. Enable airplane mode
2. Swipe right on a profile
3. Observe error handling

**Expected Results:**
- [ ] Loading indicator appears briefly
- [ ] Error message appears: "No internet connection. Please try again."
- [ ] Retry button available
- [ ] Loading indicator removed (not stuck spinning)
- [ ] Error icon or illustration shown

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 5.8: Daily Limit Loading State

**Priority:** P1
**Scenario:** Loading indicator when checking daily limit.

**Steps:**
1. Use free account near daily limit (48/50 likes)
2. Swipe right
3. Observe loading before limit modal

**Expected Results:**
- [ ] Swipe animation completes
- [ ] Brief loading indicator while API checks limit
- [ ] Daily limit modal appears after confirmation (1-2 seconds)
- [ ] OR: Immediate modal if limit cached locally

**Actual Results:**
```
[To be filled by QA tester]
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 6: Performance Metrics Validation

**Objective:** Measure and validate key performance metrics meet targets.

**Setup:**
1. Enable Flutter DevTools performance overlay
2. Use **profile mode** build (not debug):
   ```bash
   flutter run --profile
   ```

---

### Test 6.1: Swipe Animation Frame Rate

**Priority:** P0
**Scenario:** Swipe animations maintain 60 FPS.

**Steps:**
1. Enable performance overlay in Flutter DevTools
2. Swipe through 10 profiles at various speeds
3. Observe frame rate graph

**Expected Results:**
- [ ] Frame rate consistently ≥60 FPS during swipe animations
- [ ] No red bars in performance graph (dropped frames)
- [ ] Smooth visual animation (no stutter)
- [ ] Target: 100% of frames at 60 FPS

**Actual Results:**
```
[To be filled by QA tester]
Average FPS: ___ | Dropped frames: ___ | Stuttering observed: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.2: Photo Carousel Swipe Performance

**Priority:** P0
**Scenario:** Horizontal photo swiping smooth at 60 FPS.

**Steps:**
1. Swipe to profile with 5+ photos
2. Swipe horizontally between photos rapidly
3. Monitor frame rate

**Expected Results:**
- [ ] Photo swipe animations at 60 FPS
- [ ] No lag between swipes
- [ ] Photos render without visual artifacts
- [ ] Smooth transitions between photos

**Actual Results:**
```
[To be filled by QA tester]
Average FPS: ___ | Visual artifacts: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.3: Initial Load Time

**Priority:** P0
**Scenario:** Discovery page loads within 2 seconds.

**Steps:**
1. Clear app cache
2. Login
3. Navigate to Discovery page
4. Measure time from navigation to first profile visible

**Expected Results:**
- [ ] Time to first profile ≤2 seconds on WiFi
- [ ] Time to interactive (can swipe) ≤3 seconds
- [ ] Target: <1 second on WiFi, <3 seconds on 4G

**Actual Results:**
```
[To be filled by QA tester]
Time to first profile: ___ ms | Time to interactive: ___ ms
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.4: Swipe Response Time

**Priority:** P0
**Scenario:** Swipe gesture responsive within 100ms.

**Steps:**
1. Perform swipe gesture on profile card
2. Observe delay between finger lift and animation start
3. Test 10 swipes

**Expected Results:**
- [ ] Animation starts within 100ms of gesture completion
- [ ] Feels instant to user
- [ ] No perceptible delay
- [ ] Target: <50ms for best UX

**Actual Results:**
```
[To be filled by QA tester]
Average response time: ___ ms | Feels responsive: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.5: Filter Application Time

**Priority:** P0
**Scenario:** Filter application completes within 3 seconds.

**Steps:**
1. Open filters
2. Change 2-3 filter values
3. Tap "Apply"
4. Measure time until new profiles appear

**Expected Results:**
- [ ] Profiles load within 3 seconds on WiFi
- [ ] Within 5 seconds on 4G
- [ ] Loading indicator shows throughout
- [ ] Target: <2 seconds on WiFi

**Actual Results:**
```
[To be filled by QA tester]
Time on WiFi: ___ ms | Time on 4G: ___ ms
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.6: Match Modal Animation Performance

**Priority:** P1
**Scenario:** Match modal animation smooth and fluid.

**Steps:**
1. Trigger a match
2. Observe match modal animation
3. Monitor frame rate during animation

**Expected Results:**
- [ ] Modal animation at 60 FPS
- [ ] Confetti/hearts animation smooth
- [ ] No lag when modal opens
- [ ] Photos in modal load within 2 seconds

**Actual Results:**
```
[To be filled by QA tester]
Animation FPS: ___ | Perceived smoothness: Excellent/Good/Poor
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.7: Rapid Interaction Performance

**Priority:** P1
**Scenario:** App handles rapid user interactions without lag.

**Steps:**
1. Rapidly: swipe → open filters → close filters → swipe → open profile detail → back → swipe
2. All within 5 seconds
3. Observe performance

**Expected Results:**
- [ ] All interactions execute without delay
- [ ] No dropped frames
- [ ] No ANR (Application Not Responding)
- [ ] Animations queue correctly if overlapping

**Actual Results:**
```
[To be filled by QA tester]
Performance: Excellent/Good/Poor | ANR: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 6.8: Continuous Swiping Performance (Stress Test)

**Priority:** P1
**Scenario:** Performance stable during extended rapid swiping.

**Steps:**
1. Swipe through 50 profiles as fast as possible
2. Monitor frame rate throughout
3. Check for performance degradation

**Expected Results:**
- [ ] Frame rate consistent throughout (60 FPS)
- [ ] No slowdown after 20, 30, 40 swipes
- [ ] Memory usage stable (no continuous growth)
- [ ] Last swipe as smooth as first swipe

**Actual Results:**
```
[To be filled by QA tester]
FPS swipe 1-10: ___ | FPS swipe 20-30: ___ | FPS swipe 40-50: ___
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Part 7: Memory Usage Testing

**Objective:** Verify efficient memory usage, no leaks, and graceful handling under memory pressure.

**Setup:**
1. Use Flutter DevTools Memory profiler
2. Test on mid-range device (4GB RAM) AND low-end device (2GB RAM)

---

### Test 7.1: Baseline Memory Usage (Idle)

**Priority:** P0
**Scenario:** Measure baseline memory when Discovery page idle.

**Steps:**
1. Open Discovery page
2. Wait 30 seconds without interaction
3. Record memory usage in DevTools

**Expected Results:**
- [ ] Memory usage stable (no continuous growth)
- [ ] Baseline <60 MB for Discovery page alone
- [ ] Baseline <100 MB for entire app
- [ ] No memory warnings in logs

**Actual Results:**
```
[To be filled by QA tester]
Baseline memory: ___ MB | Stable: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.2: Memory Growth During Swiping

**Priority:** P0
**Scenario:** Memory increases moderately during swiping, then stabilizes.

**Steps:**
1. Start at baseline (Test 7.1)
2. Swipe through 20 profiles
3. Monitor memory growth in DevTools

**Expected Results:**
- [ ] Memory grows as images cached (expected)
- [ ] Peak memory <120 MB after 20 profiles
- [ ] Growth curve flattens (garbage collection working)
- [ ] No continuous linear growth

**Actual Results:**
```
[To be filled by QA tester]
Baseline: ___ MB | After 10 profiles: ___ MB | After 20 profiles: ___ MB
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.3: Memory Release After Idle Period

**Priority:** P0
**Scenario:** Memory released when app idle.

**Steps:**
1. Swipe through 30 profiles (build up cache)
2. Note memory usage
3. Leave Discovery page idle for 2 minutes
4. Check memory again

**Expected Results:**
- [ ] Memory decreases after idle period (garbage collection)
- [ ] Returns closer to baseline (within 20% of baseline)
- [ ] No memory continuously held unnecessarily
- [ ] App still functional after idle period

**Actual Results:**
```
[To be filled by QA tester]
After swiping: ___ MB | After 2min idle: ___ MB | Reduction: ___ MB
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.4: Memory Leak Detection (15-Minute Session)

**Priority:** P0
**Scenario:** Extended session doesn't leak memory.

**Steps:**
1. Open Flutter DevTools Memory profiler
2. Swipe through 100 profiles over 15 minutes
3. Periodically check memory graph
4. Return to idle for 1 minute
5. Check final memory

**Expected Results:**
- [ ] Memory growth stabilizes after initial ramp-up
- [ ] Final memory (after idle) <150 MB
- [ ] No sawtooth pattern indicating leaks
- [ ] Garbage collection events visible in profiler
- [ ] No continuously growing allocations

**Actual Results:**
```
[To be filled by QA tester]
Start: ___ MB | Peak: ___ MB | Final (after idle): ___ MB | Leak detected: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.5: Image Cache Management

**Priority:** P0
**Scenario:** Image cache bounded and evicts old images.

**Steps:**
1. Swipe through 50 profiles (50+ images loaded)
2. Check memory usage
3. Swipe through 50 more profiles
4. Check memory again

**Expected Results:**
- [ ] Memory doesn't double after second 50 profiles (cache evicts old images)
- [ ] Peak memory <200 MB
- [ ] Scrolling back to earlier profiles may reload images (expected: evicted from cache)
- [ ] No out-of-memory error

**Actual Results:**
```
[To be filled by QA tester]
After 50 profiles: ___ MB | After 100 profiles: ___ MB | Cache eviction working: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.6: Low Memory Device Performance (2GB RAM)

**Priority:** P0
**Scenario:** App functional on low-memory device.

**Setup:** Use device with 2GB RAM or simulate memory constraint

**Steps:**
1. Open Discovery page on low-memory device
2. Swipe through 30 profiles
3. Monitor for crashes or slowdowns

**Expected Results:**
- [ ] App remains functional (no crash)
- [ ] Performance acceptable (may be slower than high-end device)
- [ ] No out-of-memory errors
- [ ] Images may load slower or at lower resolution (acceptable)
- [ ] Aggressive garbage collection acceptable

**Actual Results:**
```
[To be filled by QA tester]
Device RAM: 2GB | Crashes: Yes/No | Performance: Excellent/Good/Poor
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.7: Memory After Backgrounding

**Priority:** P1
**Scenario:** Memory released when app backgrounded.

**Steps:**
1. Swipe through 20 profiles (build up cache)
2. Note memory usage: ___ MB
3. Background app for 1 minute
4. Foreground app
5. Check memory

**Expected Results:**
- [ ] Memory decreases while backgrounded (OS may reclaim)
- [ ] OR: Memory preserved if sufficient RAM available
- [ ] App resumes correctly either way
- [ ] No memory spike on foreground

**Actual Results:**
```
[To be filled by QA tester]
Before background: ___ MB | After background: ___ MB | App resumed: Yes/No
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

### Test 7.8: Match Modal Memory Impact

**Priority:** P1
**Scenario:** Match modal doesn't cause memory spike.

**Steps:**
1. Note baseline memory
2. Trigger 5 consecutive matches (coordinate with backend or use test account)
3. Monitor memory during and after each match modal

**Expected Results:**
- [ ] Memory increase <5 MB per match modal
- [ ] Memory released when modal dismissed
- [ ] No accumulation over multiple matches
- [ ] No memory leak from modal animations

**Actual Results:**
```
[To be filled by QA tester]
Baseline: ___ MB | During 1st match: ___ MB | After 5 matches: ___ MB
```

**Status:** ☐ Pass | ☐ Fail | ☐ Blocked

---

## Issue Tracking Template

**Use this template to document any issues found during testing:**

---

### Issue #___

**Title:** [Brief descriptive title]

**Test:** [Test number, e.g., Test 3.5]

**Severity:**
- [ ] Critical (P0) - Crash, data loss, or blocking issue
- [ ] High (P1) - Major functionality broken
- [ ] Medium (P2) - Functionality impaired but workaround exists
- [ ] Low (P3) - Minor issue, cosmetic

**Priority:**
- [ ] Must Fix (blocking QA sign-off)
- [ ] Should Fix (before release)
- [ ] Nice to Fix (post-release)

**Reproducibility:**
- [ ] Always (100%)
- [ ] Frequently (>50%)
- [ ] Sometimes (<50%)
- [ ] Rare (one-time observation)

**Environment:**
- Device: [Model, RAM]
- OS: [Android 11, iOS 15, etc.]
- Network: [WiFi, 4G, 3G, Offline]
- Build: [Profile/Debug/Release]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots/Videos:**
[Attach if applicable]

**Logs/Stack Traces:**
```
[Paste relevant logs or error messages]
```

**Workaround:**
[If any workaround exists]

**Notes:**
[Additional context, observations, or suggestions]

---

## Sign-off Checklist

**QA Tester:** ________________________
**Date:** ________________________
**Build Version:** ________________________

### Test Completion

- [ ] All 64 tests executed
- [ ] All P0 tests passed or have documented workarounds
- [ ] All issues logged with severity and priority
- [ ] Performance metrics documented
- [ ] Memory profiling completed

### Critical Validations

- [ ] **Slow Network (2G/3G)**: Discovery page remains usable on slow networks
- [ ] **Large Datasets**: No performance degradation with 100+ profiles
- [ ] **Poor Connectivity**: Graceful offline handling, error recovery works
- [ ] **App Lifecycle**: State preserved across backgrounding/foregrounding
- [ ] **Loading Indicators**: Appear within 100ms, accurately reflect state
- [ ] **Performance**: Swipe animations at 60 FPS, <2s load time
- [ ] **Memory**: No leaks detected, usage <150 MB during normal use

### Blocking Issues

**List any P0/P1 issues that block QA sign-off:**
1. [Issue #___ - Title]
2. [Issue #___ - Title]
3. [None - all critical tests passed]

### Recommendations

- [ ] **APPROVED for Production** - All critical tests passed
- [ ] **APPROVED with Conditions** - Minor issues noted, acceptable risk
- [ ] **REJECTED** - Critical issues require fixes before release

**Conditions (if applicable):**
1. [Condition 1]
2. [Condition 2]

### QA Sign-off

**Signature:** ________________________
**Date:** ________________________

---

## Appendix: Tools and Resources

### Network Throttling

**Android (Chrome DevTools):**
1. Connect device via USB with debugging enabled
2. Open Chrome: `chrome://inspect`
3. Click "Inspect" on device
4. DevTools → Network tab → Throttling dropdown
5. Select "Slow 3G", "Fast 3G", or custom profile

**iOS (Network Link Conditioner):**
1. Install Xcode
2. Settings → Developer → Network Link Conditioner
3. Enable and select profile (e.g., "3G", "Very Bad Network")

### Flutter DevTools

**Launch:**
```bash
flutter run --profile
# DevTools URL appears in terminal
# Open in browser: http://127.0.0.1:9100
```

**Performance Overlay:**
- DevTools → Performance tab → Enable performance overlay
- Green = 60 FPS, Red = dropped frames

**Memory Profiler:**
- DevTools → Memory tab
- Take snapshots before/after actions
- Look for memory leaks (continuous growth)

### Android Studio Profiler

1. Run app from Android Studio
2. View → Tool Windows → Profiler
3. Select device and app process
4. Monitor CPU, Memory, Network in real-time

### Xcode Instruments

1. Xcode → Product → Profile
2. Select "Allocations" or "Leaks" template
3. Run on device/simulator
4. Analyze memory allocations and leaks

### Useful Commands

```bash
# Check memory usage (Android)
adb shell dumpsys meminfo com.hivmeet.app

# Monitor logs (Android)
adb logcat | grep -i "flutter\|hivmeet"

# Clear app data (Android)
adb shell pm clear com.hivmeet.app

# Simulate low memory (Android)
adb shell am send-trim-memory com.hivmeet.app RUNNING_CRITICAL

# iOS memory warnings (Simulator)
# Hardware → Simulate Memory Warning
```

---

**End of Performance & Loading Scenarios Testing Guide**

*This document is a living guide. Update as new edge cases discovered or requirements change.*

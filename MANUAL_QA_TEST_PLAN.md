# Manual QA Test Plan - Discovery Page
## HIVMeet - Task 7.1: Execute Core User Flow Scenarios

**Version:** 1.0
**Date:** 2026-02-26
**Tester:** [To be filled]
**Device:** [To be filled]
**OS Version:** [To be filled]
**App Version:** [To be filled]
**Test Environment:** [Debug/Profile/Release]

---

## Overview

This manual QA test plan covers all critical user journeys on the Discovery page. Each test case includes:
- **Test ID**: Unique identifier
- **Priority**: P0 (Critical), P1 (High), P2 (Medium), P3 (Low)
- **Preconditions**: What must be true before the test
- **Steps**: Detailed steps to execute
- **Expected Result**: What should happen
- **Actual Result**: What actually happened (to be filled during testing)
- **Status**: Pass/Fail/Blocked/Skip
- **Notes**: Any observations, issues, or edge cases discovered

---

## Test Execution Summary

| Category | Total Tests | Passed | Failed | Blocked | Skipped |
|----------|-------------|--------|--------|---------|---------|
| Navigation | 4 | - | - | - | - |
| Content Display | 8 | - | - | - | - |
| Swipe Interactions | 10 | - | - | - | - |
| Action Buttons | 8 | - | - | - | - |
| Filters | 9 | - | - | - | - |
| Match Detection | 6 | - | - | - | - |
| Daily Limits | 5 | - | - | - | - |
| Premium Features | 6 | - | - | - | - |
| Error Handling | 6 | - | - | - | - |
| Navigation Away | 4 | - | - | - | - |
| **TOTAL** | **66** | **-** | **-** | **-** | **-** |

---

## Category 1: Navigation to Discovery Page

### TEST-NAV-001: Navigate to Discovery from Login
**Priority:** P0
**Preconditions:** User is logged in successfully
**Steps:**
1. Complete login flow
2. Observe default screen after login

**Expected Result:**
- Discovery page loads automatically as the home screen
- Bottom navigation bar shows Discovery tab as selected (highlighted)
- "HIVMeet" logo appears in app bar with purple Pacifico font

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-002: Navigate to Discovery from Bottom Navigation
**Priority:** P0
**Preconditions:** User is on any other tab (Matches, Messages, Profile)
**Steps:**
1. From another tab, tap the Discovery icon in bottom navigation
2. Observe the transition

**Expected Result:**
- Discovery page loads smoothly
- Previous page dismisses
- Discovery tab becomes highlighted in bottom navigation
- Page state is preserved if previously visited

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-003: Deep Link to Discovery Page
**Priority:** P2
**Preconditions:** App supports deep linking
**Steps:**
1. Open deep link to Discovery page (e.g., hivmeet://discovery)
2. Observe behavior

**Expected Result:**
- App opens and navigates directly to Discovery page
- User authentication is checked
- If not authenticated, redirects to login first

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-004: Return to Discovery After Match Modal
**Priority:** P1
**Preconditions:** User has just matched with someone
**Steps:**
1. Create a match by liking a profile that already liked you
2. Observe match modal appears
3. Tap "Keep Swiping" button
4. Observe transition back to Discovery

**Expected Result:**
- Match modal dismisses smoothly
- Discovery page resumes with next profile
- Swipe counter updates correctly
- No duplicate profiles shown

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 2: Content Display

### TEST-DISP-001: Initial Profile Load
**Priority:** P0
**Preconditions:** First time opening Discovery page
**Steps:**
1. Navigate to Discovery page for the first time
2. Observe loading behavior
3. Wait for profiles to load

**Expected Result:**
- Loading indicator appears (skeleton UI or spinner)
- Loading state lasts < 2 seconds with good network
- First profile card appears with all information
- Next 2-3 profiles preload in background (scaled/faded)
- No blank screens or loading indefinitely

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-002: Profile Card Information Display
**Priority:** P0
**Preconditions:** At least one profile is loaded
**Steps:**
1. Observe the top profile card
2. Check all displayed information

**Expected Result:**
- Profile photo is visible and properly sized
- Name is displayed
- Age is displayed
- Distance in km is displayed (e.g., "5 km")
- Compatibility score is shown as percentage (e.g., "87%")
- "Verified" badge appears if profile is verified
- "Premium" badge appears if user has premium
- "Online Now" indicator shows if user is online
- Last active timestamp shows if user is offline (e.g., "Active 2h ago")
- Mutual interests appear as chips/tags

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-003: Photo Carousel Navigation
**Priority:** P0
**Preconditions:** Profile has multiple photos (2+)
**Steps:**
1. Observe profile card with multiple photos
2. Tap left side of card to go to previous photo
3. Tap right side of card to go to next photo
4. Observe pagination indicators (dots)

**Expected Result:**
- Pagination dots appear at top of card showing total photos
- Current photo indicator is highlighted
- Tapping right advances to next photo smoothly
- Tapping left goes to previous photo
- First photo: left tap does nothing
- Last photo: right tap does nothing
- Transition is smooth animation (not instant jump)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-004: Profile Stack Preview
**Priority:** P1
**Preconditions:** At least 3 profiles loaded
**Steps:**
1. Observe Discovery page with loaded profiles
2. Look behind the top card

**Expected Result:**
- 2nd profile card visible behind top card, scaled down
- 3rd profile card visible behind 2nd card, scaled down more
- Cards are slightly faded/dimmed
- Cards are offset vertically for depth effect
- Stack looks like a deck of cards

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-005: Daily Likes Counter (Free User)
**Priority:** P0
**Preconditions:** User is a free (non-premium) user
**Steps:**
1. Observe the Discovery page
2. Look for likes remaining counter

**Expected Result:**
- Counter displays "X likes remaining" (e.g., "48 likes remaining")
- Text is clear and visible
- Counter updates in real-time after each like
- Text is internationalized (French: "X j'aime restants", English: "X likes remaining")

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-006: Daily Likes Counter (Premium User)
**Priority:** P1
**Preconditions:** User has premium subscription
**Steps:**
1. Login as premium user
2. Navigate to Discovery page
3. Observe likes counter

**Expected Result:**
- Counter shows "Unlimited likes" or no counter at all
- No numeric limit displayed
- Premium badge visible somewhere on UI

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-007: Super Likes Counter
**Priority:** P1
**Preconditions:** User has at least 1 super like remaining
**Steps:**
1. Observe Discovery page
2. Look for super likes counter

**Expected Result:**
- Super like counter visible (e.g., "1 super like remaining")
- Counter is near super like button (star icon)
- Free users: 1 per day
- Premium users: 5 per day or unlimited
- Counter updates after using super like

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-DISP-008: Empty State Display
**Priority:** P0
**Preconditions:** No profiles available (all swiped, or filters too restrictive)
**Steps:**
1. Swipe through all available profiles OR
2. Set very restrictive filters (e.g., age 18-19, distance 1km)
3. Observe the empty state

**Expected Result:**
- Empty state illustration appears
- Message: "No more profiles" or "Adjust your filters"
- Suggestions: "Check back later" or "Broaden your search"
- Button to adjust filters
- No loading spinner
- Text is internationalized

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 3: Swipe Interactions

### TEST-SWIPE-001: Swipe Right (Like)
**Priority:** P0
**Preconditions:** At least one profile loaded
**Steps:**
1. Swipe right on the top profile card (drag from center to right)
2. Observe animation and transition

**Expected Result:**
- Card follows finger during drag
- Card rotates slightly during drag
- Green "LIKE" overlay appears on card
- Card animates off screen to the right when released
- Next profile appears smoothly
- Likes counter decrements (free users)
- Haptic feedback on swipe completion

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-002: Swipe Left (Dislike)
**Priority:** P0
**Preconditions:** At least one profile loaded
**Steps:**
1. Swipe left on the top profile card (drag from center to left)
2. Observe animation and transition

**Expected Result:**
- Card follows finger during drag
- Card rotates slightly during drag
- Red "NOPE" overlay appears on card
- Card animates off screen to the left when released
- Next profile appears smoothly
- No counter changes (dislikes are unlimited)
- Haptic feedback on swipe completion

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-003: Swipe Up (Super Like)
**Priority:** P1
**Preconditions:** User has super likes remaining (premium or 1/day for free)
**Steps:**
1. Swipe up on the top profile card (drag from center upward)
2. Observe animation and transition

**Expected Result:**
- Card follows finger during drag upward
- Blue "SUPER LIKE" overlay with star icon appears
- Special star animation/particles on card
- Card animates off screen upward when released
- Super like counter decrements
- Haptic feedback (stronger than regular like)
- Next profile appears

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-004: Partial Swipe (Cancel)
**Priority:** P1
**Preconditions:** At least one profile loaded
**Steps:**
1. Start swiping right (drag card partially to the right)
2. Release before reaching the threshold
3. Observe card behavior

**Expected Result:**
- Card animates back to center position
- Card returns to original rotation
- Overlay fades out
- No action is registered (no like/dislike)
- Counters do not change

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-005: Rapid Consecutive Swipes
**Priority:** P1
**Preconditions:** At least 5 profiles loaded
**Steps:**
1. Swipe right quickly on 5 profiles in succession
2. Observe behavior and performance

**Expected Result:**
- All swipes register correctly
- Animations remain smooth (60fps)
- No duplicate API calls
- Counters update correctly for each swipe
- No UI freezing or lag
- Profile stack updates smoothly
- API calls are debounced/queued appropriately

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-006: Swipe with Poor Network
**Priority:** P1
**Preconditions:** Simulate poor network (slow 3G or enable network throttling)
**Steps:**
1. Enable network throttling (slow connection)
2. Swipe through profiles
3. Observe behavior

**Expected Result:**
- Swipe actions are queued and sent when connection improves
- Optimistic UI: card disappears immediately
- Loading indicator shows for next profile fetch
- User can continue swiping on preloaded profiles
- No crashes or errors
- Error message if network completely fails

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-007: Swipe Animation at 60fps
**Priority:** P1
**Preconditions:** Device with performance monitoring enabled
**Steps:**
1. Enable Flutter performance overlay (fps counter)
2. Perform swipe gestures
3. Observe fps metrics

**Expected Result:**
- Swipe animation runs at 60fps consistently
- No frame drops during swipe
- Smooth rotation and translation
- Overlay appears/fades smoothly

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-008: Tap to View Full Profile
**Priority:** P0
**Preconditions:** At least one profile loaded
**Steps:**
1. Tap on the center of the profile card (not left/right for photos)
2. Observe navigation

**Expected Result:**
- Navigation to Profile Detail page
- Profile Detail shows full information (bio, photos, interests, etc.)
- Back button returns to Discovery page
- Card position is preserved

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-009: Swipe During Photo Carousel
**Priority:** P2
**Preconditions:** Profile with multiple photos loaded
**Steps:**
1. Navigate through photos (tap left/right)
2. While on photo 2 or 3, swipe right to like
3. Observe behavior

**Expected Result:**
- Swipe gesture takes precedence over photo tap
- Profile is liked/disliked correctly
- Photo carousel state is not confused with swipe

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-SWIPE-010: Swipe Gesture Accessibility Alternative
**Priority:** P0 (Accessibility Critical)
**Preconditions:** Screen reader enabled OR user who cannot swipe
**Steps:**
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate to Discovery page
3. Use action buttons instead of swipe gestures

**Expected Result:**
- Screen reader announces profile information
- Action buttons are focusable and labeled
- Buttons work as alternative to swipe gestures
- All functionality accessible without swiping

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 4: Action Buttons

### TEST-BTN-001: Like Button (Heart Icon)
**Priority:** P0
**Preconditions:** At least one profile loaded, likes remaining
**Steps:**
1. Tap the heart icon button (green, bottom center-right)
2. Observe behavior

**Expected Result:**
- Profile card animates to the right (same as swipe right)
- Button provides visual feedback (press animation)
- Likes counter decrements
- Next profile appears
- Haptic feedback
- Same behavior as swipe right gesture

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-002: Dislike Button (X Icon)
**Priority:** P0
**Preconditions:** At least one profile loaded
**Steps:**
1. Tap the X icon button (red, bottom center-left)
2. Observe behavior

**Expected Result:**
- Profile card animates to the left (same as swipe left)
- Button provides visual feedback (press animation)
- Next profile appears
- Haptic feedback
- Same behavior as swipe left gesture

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-003: Super Like Button (Star Icon)
**Priority:** P1
**Preconditions:** At least one super like remaining
**Steps:**
1. Tap the star icon button (blue, bottom center)
2. Observe behavior

**Expected Result:**
- Profile card animates upward (same as swipe up)
- Special star animation appears
- Button provides visual feedback
- Super like counter decrements
- Next profile appears
- Haptic feedback (stronger)
- Same behavior as swipe up gesture

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-004: Rewind Button (Undo Icon) - Premium
**Priority:** P1
**Preconditions:** Premium user, just swiped on a profile
**Steps:**
1. Swipe right/left on a profile
2. Immediately tap the rewind button
3. Observe behavior

**Expected Result:**
- Previous profile reappears
- Profile card animates back into view from the side
- Action is undone (like/dislike is reverted)
- Counters revert to previous values
- Button is only enabled after a swipe
- Button shows premium badge/indicator

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-005: Rewind Button - Free User (Locked)
**Priority:** P1
**Preconditions:** Free user, just swiped on a profile
**Steps:**
1. Swipe right/left on a profile
2. Tap the rewind button
3. Observe behavior

**Expected Result:**
- Button shows locked state (lock icon or disabled appearance)
- Tapping shows upgrade CTA modal
- Modal explains rewind is a premium feature
- Modal has "Upgrade" and "Cancel" buttons
- No rewind action occurs

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-006: Filters Button
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Tap the filters button (funnel icon, top-right of app bar)
2. Observe filters modal appearance

**Expected Result:**
- Filters modal/bottom sheet appears
- Modal shows all filter options (age, distance, etc.)
- Current filter values are pre-selected
- Modal has "Apply" and "Clear Filters" buttons
- Animation is smooth

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-007: Action Button Disabled State (No Likes)
**Priority:** P0
**Preconditions:** Free user with 0 likes remaining
**Steps:**
1. Use all daily likes (50 for free users)
2. Observe like and super like buttons
3. Try to tap them

**Expected Result:**
- Like button appears disabled (grayed out)
- Super like button appears disabled
- Tapping shows "Daily limit reached" message
- Upgrade CTA appears
- Dislike button still works (unlimited)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-BTN-008: Action Button Sizes (Accessibility)
**Priority:** P0 (Accessibility Critical)
**Preconditions:** Discovery page loaded
**Steps:**
1. Observe all action buttons
2. Measure touch target sizes (use developer tools if available)

**Expected Result:**
- All buttons have touch targets ≥ 44x44 dp
- Buttons are easily tappable
- Adequate spacing between buttons (no accidental taps)
- Buttons work with large text accessibility setting

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 5: Filters

### TEST-FILT-001: Open Filters Modal
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Tap filters button (funnel icon)
2. Observe modal appearance

**Expected Result:**
- Filters modal/bottom sheet slides up from bottom
- Modal shows all filter options
- Current filter values are displayed
- Modal has proper header and close button
- Background is dimmed

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-002: Age Range Slider
**Priority:** P0
**Preconditions:** Filters modal is open
**Steps:**
1. Observe age range double slider
2. Drag minimum age handle to 25
3. Drag maximum age handle to 35
4. Observe real-time updates

**Expected Result:**
- Double slider with two handles (min/max)
- Current values display above slider (e.g., "25 - 35")
- Range: 18 to 100 years
- Minimum cannot be greater than maximum
- Handles are draggable and responsive
- Estimated profile count updates in real-time

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-003: Distance Slider
**Priority:** P0
**Preconditions:** Filters modal is open
**Steps:**
1. Observe distance slider
2. Drag slider to various positions (e.g., 10 km, 50 km, 100 km)
3. Observe value display

**Expected Result:**
- Single slider with one handle
- Current value displays above slider (e.g., "50 km")
- Range: 1 to 100 km
- Slider is smooth and responsive
- Estimated profile count updates in real-time

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-004: Relationship Type Multi-Select
**Priority:** P1
**Preconditions:** Filters modal is open
**Steps:**
1. Observe relationship type options
2. Tap multiple relationship types (e.g., "Friendship", "Serious Relationship")
3. Observe selection state

**Expected Result:**
- Multiple options can be selected simultaneously
- Selected options are visually highlighted
- Icons for each relationship type
- Estimated profile count updates with each selection
- At least one must be selected (cannot deselect all)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-005: Interests Multi-Select
**Priority:** P1
**Preconditions:** Filters modal is open
**Steps:**
1. Observe interests section
2. Select up to 5 interests
3. Try to select a 6th interest

**Expected Result:**
- All available interests displayed as chips/tags
- Up to 5 interests can be selected
- Selected interests are highlighted
- Attempting to select 6th shows message: "Maximum 5 interests"
- Estimated profile count updates with selections

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-006: Verified Profiles Only Toggle (Premium)
**Priority:** P1
**Preconditions:** Premium user, filters modal is open
**Steps:**
1. Locate "Verified profiles only" toggle
2. Toggle it ON
3. Observe behavior

**Expected Result:**
- Toggle switches to ON state
- Estimated profile count updates (likely decreases)
- No premium lock indicator for premium users
- Apply filters to see only verified profiles

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-007: Verified Profiles Toggle - Free User (Locked)
**Priority:** P1
**Preconditions:** Free user, filters modal is open
**Steps:**
1. Locate "Verified profiles only" toggle
2. Observe lock indicator
3. Try to toggle it ON

**Expected Result:**
- Toggle shows lock icon or premium badge
- Toggle is disabled or shows upgrade CTA when tapped
- Tooltip: "Premium feature"
- Upgrade modal appears if tapped

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-008: Apply Filters
**Priority:** P0
**Preconditions:** Filters modal is open, filters have been modified
**Steps:**
1. Change filters (age, distance, etc.)
2. Tap "Apply" button
3. Observe behavior

**Expected Result:**
- Filters modal closes
- Loading indicator appears briefly
- Discovery page refreshes with new profiles matching filters
- Profile stack is cleared and rebuilt
- Applied filters are saved to local storage
- Next time filters are opened, same values are shown

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-FILT-009: Clear Filters
**Priority:** P1
**Preconditions:** Filters modal is open, filters have been applied
**Steps:**
1. Have some filters applied (age 25-35, distance 20km, etc.)
2. Tap "Clear Filters" button
3. Observe behavior

**Expected Result:**
- All filters reset to default values
  - Age: 18-100
  - Distance: 100 km
  - Relationship types: All selected
  - Interests: None selected
  - Toggles: All OFF
- Estimated profile count updates to show maximum profiles
- Can apply cleared filters to reset discovery

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 6: Match Detection

### TEST-MATCH-001: Match Detected on Like
**Priority:** P0
**Preconditions:** Profile to like has already liked the current user
**Steps:**
1. Swipe right (or tap like button) on a profile that has already liked you
2. Observe match detection

**Expected Result:**
- Match modal appears immediately with animation
- Celebratory animation plays (hearts, confetti)
- Modal shows both profile photos side-by-side
- Message: "It's a Match!" (internationalized)
- Two buttons: "Send Message" and "Keep Swiping"
- Optional: Celebratory sound effect

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-MATCH-002: Match Modal - Send Message
**Priority:** P0
**Preconditions:** Match modal is displayed
**Steps:**
1. Trigger a match (TEST-MATCH-001)
2. Tap "Send Message" button
3. Observe navigation

**Expected Result:**
- Modal closes
- Navigation to Chat/Messages screen
- Conversation with matched user opens
- Text input is focused (keyboard appears)
- Can send first message immediately

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-MATCH-003: Match Modal - Keep Swiping
**Priority:** P0
**Preconditions:** Match modal is displayed
**Steps:**
1. Trigger a match (TEST-MATCH-001)
2. Tap "Keep Swiping" button
3. Observe behavior

**Expected Result:**
- Modal closes smoothly
- Returns to Discovery page
- Next profile appears
- Can continue swiping immediately
- Match is saved (visible in Matches tab)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-MATCH-004: Match Modal - Dismiss by Back Button
**Priority:** P1
**Preconditions:** Match modal is displayed
**Steps:**
1. Trigger a match (TEST-MATCH-001)
2. Press device back button (Android) or swipe down (iOS)
3. Observe behavior

**Expected Result:**
- Modal closes (same as "Keep Swiping")
- Returns to Discovery page
- Next profile appears
- Match is still saved

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-MATCH-005: Match Modal Animation
**Priority:** P2
**Preconditions:** Match modal is displayed
**Steps:**
1. Trigger a match (TEST-MATCH-001)
2. Observe the animation closely

**Expected Result:**
- Animation is smooth and celebratory
- Hearts, confetti, or similar celebratory graphics
- Animation runs at 60fps
- Not too long (< 3 seconds)
- Respectful and tasteful (appropriate for HIV+ dating app)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-MATCH-006: Multiple Consecutive Matches
**Priority:** P2
**Preconditions:** Multiple profiles have already liked the current user
**Steps:**
1. Like profile 1 → Match
2. Dismiss match modal → "Keep Swiping"
3. Like profile 2 → Match
4. Observe behavior

**Expected Result:**
- Each match shows its own modal sequentially
- No overlapping modals
- Modals are queued if necessary
- All matches are saved correctly
- No duplicate match notifications

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 7: Daily Limits

### TEST-LIMIT-001: Daily Like Limit Counter (Free User)
**Priority:** P0
**Preconditions:** Free user with likes remaining
**Steps:**
1. Observe likes remaining counter
2. Like several profiles
3. Observe counter updates

**Expected Result:**
- Counter starts at 50 (daily limit for free users)
- Decrements by 1 for each like
- Updates in real-time
- Displays accurate count at all times

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-LIMIT-002: Daily Limit Reached (Free User)
**Priority:** P0
**Preconditions:** Free user, 0 likes remaining
**Steps:**
1. Use all 50 daily likes
2. Observe UI changes
3. Try to like another profile

**Expected Result:**
- Counter shows "0 likes remaining"
- Like button becomes disabled (grayed out)
- Super like button also disabled
- Tapping like button shows "Daily limit reached" modal
- Modal explains limit and shows upgrade CTA
- Modal has "Upgrade to Premium" and "Close" buttons
- Dislike button still works

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-LIMIT-003: Upgrade CTA from Daily Limit Modal
**Priority:** P1
**Preconditions:** Daily limit reached, upgrade modal displayed
**Steps:**
1. Reach daily limit (TEST-LIMIT-002)
2. Tap "Upgrade to Premium" button in modal
3. Observe navigation

**Expected Result:**
- Modal closes
- Navigation to Premium/Subscription page
- Subscription options displayed
- Can purchase premium subscription
- "Cancel" button returns to Discovery

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-LIMIT-004: Super Like Daily Limit (Free User)
**Priority:** P1
**Preconditions:** Free user, 0 super likes remaining (1/day for free)
**Steps:**
1. Use the daily super like
2. Try to super like another profile

**Expected Result:**
- Super like counter shows "0 super likes remaining"
- Super like button becomes disabled
- Tapping shows "Daily limit reached" message
- Upgrade CTA appears
- Regular likes still work (if not at limit)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-LIMIT-005: Daily Limit Reset (Midnight)
**Priority:** P2
**Preconditions:** Daily limit reached, wait until midnight server time
**Steps:**
1. Reach daily limit in the evening
2. Wait until midnight (server time, check API timezone)
3. Refresh Discovery page or wait for auto-refresh
4. Observe counters

**Expected Result:**
- Counters reset to full at midnight
- Free user: 50 likes, 1 super like
- Like buttons become enabled again
- No manual action required (automatic reset)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:** [May require coordination with QA team to test across midnight]

---

## Category 8: Premium Features

### TEST-PREM-001: Rewind Feature (Premium User)
**Priority:** P1
**Preconditions:** Premium user, just swiped on a profile
**Steps:**
1. Swipe right or left on a profile
2. Tap the rewind button immediately
3. Observe behavior

**Expected Result:**
- Previous profile reappears
- Swipe action is undone (API call to rewind endpoint)
- Counters revert (if like was undone, counter increments)
- Can rewind multiple times
- Smooth animation bringing card back

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PREM-002: Rewind Unavailable After Multiple Swipes
**Priority:** P2
**Preconditions:** Premium user, swiped on multiple profiles
**Steps:**
1. Swipe on profile A
2. Swipe on profile B
3. Try to rewind to profile A (not just B)

**Expected Result:**
- Rewind only works for the most recent swipe
- Cannot rewind multiple steps back
- Rewind button disabled if no recent swipe
- Only one level of undo supported

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PREM-003: Super Like Premium Allowance
**Priority:** P1
**Preconditions:** Premium user
**Steps:**
1. Observe super like counter
2. Use super likes
3. Check daily allowance

**Expected Result:**
- Premium users get 5 super likes per day (or unlimited)
- Counter shows correct allowance
- Counter updates with each use
- Resets at midnight

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PREM-004: Verified Profiles Only Filter (Premium)
**Priority:** P1
**Preconditions:** Premium user
**Steps:**
1. Open filters modal
2. Enable "Verified profiles only" toggle
3. Apply filters
4. Observe profiles

**Expected Result:**
- Toggle is enabled (no lock icon)
- After applying, only verified profiles appear
- All profiles show verified badge
- No unverified profiles in stack

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PREM-005: Online Only Filter (Premium)
**Priority:** P1
**Preconditions:** Premium user
**Steps:**
1. Open filters modal
2. Enable "Online only" toggle
3. Apply filters
4. Observe profiles

**Expected Result:**
- Toggle is enabled (no lock icon)
- After applying, only online users appear
- All profiles show "Online Now" indicator
- No offline users in stack

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PREM-006: Unlimited Likes (Premium)
**Priority:** P1
**Preconditions:** Premium user
**Steps:**
1. Observe likes counter
2. Like more than 50 profiles
3. Observe counter behavior

**Expected Result:**
- Counter shows "Unlimited likes" or no counter
- No daily limit enforced
- Like button never becomes disabled
- Can like infinite profiles per day

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 9: Error Handling

### TEST-ERR-001: Network Connection Lost During Load
**Priority:** P0
**Preconditions:** Discovery page, profiles loading
**Steps:**
1. Navigate to Discovery page
2. Immediately disable network (airplane mode)
3. Observe behavior

**Expected Result:**
- Loading stops
- Error message appears: "Connection error" (internationalized)
- Retry button is displayed
- No crash or infinite loading
- Tapping retry attempts to reload profiles

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-ERR-002: API Error (500 Internal Server Error)
**Priority:** P1
**Preconditions:** Backend returns 500 error (may need mock/test environment)
**Steps:**
1. Navigate to Discovery page
2. Backend returns 500 error
3. Observe error handling

**Expected Result:**
- Error message: "Something went wrong" (internationalized)
- Retry button available
- User-friendly message (no technical jargon)
- No crash
- Error logged for debugging (not visible to user)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-ERR-003: API Error (401 Unauthorized)
**Priority:** P0
**Preconditions:** Auth token is invalid or expired
**Steps:**
1. Invalidate auth token (logout from another device, or wait for expiration)
2. Navigate to Discovery page
3. Observe behavior

**Expected Result:**
- Error is detected
- User is logged out automatically
- Redirected to login page
- Message: "Session expired, please log in again"
- No data loss (can log back in)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-ERR-004: Photo Load Failure
**Priority:** P1
**Preconditions:** Profile has photo URL that returns 404 or fails to load
**Steps:**
1. Load a profile with broken photo URL
2. Observe photo display

**Expected Result:**
- Placeholder avatar appears instead of broken image
- No blank space or error icon
- Profile is still usable
- Tapping placeholder shows error or retry option
- Other profile information displays correctly

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-ERR-005: No Profiles Available (Filters Too Restrictive)
**Priority:** P1
**Preconditions:** Apply very restrictive filters
**Steps:**
1. Open filters
2. Set age to 18-19, distance to 1 km, verified only
3. Apply filters
4. Observe result

**Expected Result:**
- Empty state appears
- Message: "No profiles found. Try adjusting your filters."
- Button: "Adjust Filters"
- Tapping button reopens filters modal
- Helpful illustration or icon

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-ERR-006: Geolocation Permission Denied
**Priority:** P1
**Preconditions:** First app launch, geolocation permission not granted
**Steps:**
1. Install app fresh
2. During onboarding, deny geolocation permission
3. Navigate to Discovery page
4. Observe behavior

**Expected Result:**
- App explains importance of location for Discovery
- Fallback to city-based discovery (if possible)
- OR: Prompt to grant location permission again
- Discovery still works (may show profiles from broader area)
- No crash

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 10: Navigation Away from Discovery

### TEST-NAV-OUT-001: Navigate to Matches Tab
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Tap "Matches" icon in bottom navigation
2. Observe transition
3. Return to Discovery tab
4. Observe state preservation

**Expected Result:**
- Smooth transition to Matches page
- Returning to Discovery preserves state
- Current profile stack is preserved
- No profiles reload unnecessarily
- Counters remain accurate

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-OUT-002: Navigate to Messages Tab
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Tap "Messages" icon in bottom navigation
2. Observe transition
3. Return to Discovery tab
4. Observe state preservation

**Expected Result:**
- Smooth transition to Messages page
- Returning to Discovery preserves state
- Current profile stack is preserved
- No profiles reload unnecessarily
- Counters remain accurate

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-OUT-003: Navigate to Profile Tab
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Tap "Profile" icon in bottom navigation
2. Observe transition
3. Return to Discovery tab
4. Observe state preservation

**Expected Result:**
- Smooth transition to Profile page
- Returning to Discovery preserves state
- Current profile stack is preserved
- No profiles reload unnecessarily
- Counters remain accurate

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-NAV-OUT-004: App Backgrounded and Restored
**Priority:** P1
**Preconditions:** Discovery page loaded with profiles
**Steps:**
1. Navigate to Discovery page
2. Press home button (background the app)
3. Wait 30 seconds
4. Restore the app
5. Observe behavior

**Expected Result:**
- Discovery page is still visible
- Profile stack is preserved
- No unnecessary reload
- State is maintained
- If backgrounded for long time (e.g., hours), may refresh profiles

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 11: Internationalization (i18n)

### TEST-I18N-001: French Locale (FR)
**Priority:** P0
**Preconditions:** Device language set to French
**Steps:**
1. Change device language to French (Français)
2. Restart app or refresh Discovery page
3. Observe all text on Discovery page

**Expected Result:**
- All UI text is in French:
  - "Découverte" (Discovery)
  - "J'aime" (Like)
  - "Passer" (Dislike)
  - "Super Like" (Super Like)
  - "X j'aime restants" (X likes remaining)
  - "Filtres" (Filters)
  - "C'est un match!" (It's a Match!)
  - "Envoyer un message" (Send Message)
  - "Continuer" (Keep Swiping)
  - Error messages in French
  - Empty states in French
- No English text visible
- No hardcoded strings

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-I18N-002: English Locale (EN)
**Priority:** P0
**Preconditions:** Device language set to English
**Steps:**
1. Change device language to English
2. Restart app or refresh Discovery page
3. Observe all text on Discovery page

**Expected Result:**
- All UI text is in English:
  - "Discovery"
  - "Like"
  - "Pass"
  - "Super Like"
  - "X likes remaining"
  - "Filters"
  - "It's a Match!"
  - "Send Message"
  - "Keep Swiping"
  - Error messages in English
  - Empty states in English
- No French text visible
- No hardcoded strings

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-I18N-003: Dynamic Content with Placeholders
**Priority:** P1
**Preconditions:** Discovery page loaded
**Steps:**
1. Observe dynamic text with numbers/variables
2. Check likes counter, age, distance, etc.
3. Switch language and observe

**Expected Result:**
- Placeholders work correctly: "{count} likes remaining" → "48 likes remaining"
- French: "{count} j'aime restants" → "48 j'aime restants"
- Numbers are locale-aware (if applicable)
- Distance units are correct (km for both FR/EN)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 12: Accessibility (a11y)

### TEST-A11Y-001: Screen Reader Support (TalkBack/VoiceOver)
**Priority:** P0
**Preconditions:** Enable TalkBack (Android) or VoiceOver (iOS)
**Steps:**
1. Enable screen reader
2. Navigate to Discovery page
3. Use screen reader to navigate

**Expected Result:**
- All elements are announced with semantic labels:
  - Profile name, age, distance announced
  - "Like button", "Dislike button", "Super Like button" announced
  - "Filters button" announced
  - Card swipe alternatives available (buttons)
- Logical navigation order
- No unlabeled interactive elements
- Can perform all actions using screen reader

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-A11Y-002: Color Contrast Ratio (WCAG 2.1 AA)
**Priority:** P0
**Preconditions:** Use color contrast analyzer tool
**Steps:**
1. Observe all text on Discovery page
2. Measure contrast ratios using tool

**Expected Result:**
- All text meets WCAG 2.1 AA standard (4.5:1 minimum)
- Like button (green): adequate contrast
- Dislike button (red): adequate contrast
- Super like button (blue): adequate contrast
- All labels and counters: adequate contrast
- No text is too light or washed out

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-A11Y-003: Touch Target Sizes
**Priority:** P0
**Preconditions:** Discovery page loaded
**Steps:**
1. Observe all interactive elements
2. Measure touch target sizes (developer tools or manual)

**Expected Result:**
- All buttons ≥ 44x44 dp
- Like, dislike, super like buttons: adequate size
- Filters button: adequate size
- Profile card tap area: adequate size
- Photo carousel tap areas: adequate size
- No tiny tap targets

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-A11Y-004: Reduced Motion Support
**Priority:** P1
**Preconditions:** Enable "Reduce Motion" in device accessibility settings
**Steps:**
1. Enable Reduce Motion
2. Navigate to Discovery page
3. Swipe on profiles
4. Trigger match modal

**Expected Result:**
- Complex animations are simplified or disabled
- Swipe still works but animation is reduced
- Match modal appears with minimal animation
- Functionality is preserved
- No jarring instant transitions (crossfade instead)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-A11Y-005: Large Text Support
**Priority:** P1
**Preconditions:** Enable large text in device accessibility settings
**Steps:**
1. Enable large text (200% or maximum size)
2. Navigate to Discovery page
3. Observe all text and layouts

**Expected Result:**
- All text scales appropriately
- No text is cut off or truncated
- Layouts adapt to larger text
- Buttons remain usable
- No overlapping text
- All information remains readable

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-A11Y-006: Dark Mode Support
**Priority:** P1
**Preconditions:** Enable dark mode in device settings
**Steps:**
1. Enable dark mode
2. Navigate to Discovery page
3. Observe colors and contrast

**Expected Result:**
- App respects system dark mode setting
- Discovery page uses dark theme colors
- All text is readable on dark background
- Contrast ratios still meet WCAG standards
- Colors are inverted/adjusted appropriately
- No white flashes or light backgrounds

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Category 13: Performance

### TEST-PERF-001: Profile Load Time
**Priority:** P1
**Preconditions:** Good network connection
**Steps:**
1. Navigate to Discovery page (cold start)
2. Measure time from page load to first profile visible

**Expected Result:**
- First profile appears in < 2 seconds
- Loading indicator appears immediately
- Skeleton UI provides visual feedback
- Preloading works (next 2-3 profiles ready)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PERF-002: Swipe Animation Smoothness
**Priority:** P1
**Preconditions:** Discovery page loaded, Flutter DevTools available
**Steps:**
1. Enable performance overlay (fps counter)
2. Perform multiple swipe gestures
3. Observe fps metrics

**Expected Result:**
- Swipe animations run at 60fps consistently
- No frame drops during swipe
- Smooth rotation and translation
- Overlay appears/fades smoothly

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

### TEST-PERF-003: Memory Usage
**Priority:** P2
**Preconditions:** Discovery page loaded, DevTools memory profiler available
**Steps:**
1. Open memory profiler
2. Navigate to Discovery page
3. Swipe through 50 profiles
4. Observe memory usage

**Expected Result:**
- Memory usage stays below 100 MB
- No memory leaks (memory returns to baseline)
- Old profiles are properly disposed
- Images are cached efficiently

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] Skip
**Notes:**

---

## Test Execution Sign-off

**Tester Name:** ______________________
**Date Completed:** ______________________
**Device(s) Used:** ______________________
**OS Version(s):** ______________________
**App Version:** ______________________

**Overall Test Results:**
- Total Tests Executed: _____
- Tests Passed: _____
- Tests Failed: _____
- Tests Blocked: _____
- Tests Skipped: _____

**Critical Issues Found:**
1. _______________________________________
2. _______________________________________
3. _______________________________________

**Recommendations:**
- [ ] Release approved - all critical tests passed
- [ ] Minor issues found - fix before release
- [ ] Major issues found - do not release, requires fixes
- [ ] Blocked - cannot complete testing due to: ______________

**QA Sign-off:** ______________________ **Date:** __________

---

## Notes for Tester

### Test Environment Setup
1. Ensure device has network connectivity
2. Have both free and premium user accounts ready
3. Clear app data before testing if needed
4. Enable Flutter performance overlay for performance tests
5. Have accessibility settings accessible for a11y tests
6. Can switch device language for i18n tests

### Test Execution Tips
- Mark actual results immediately after each test
- Take screenshots of failures
- Note any unexpected behavior even if test passes
- Test on multiple devices if possible (iOS + Android)
- Verify both portrait and landscape modes
- Test with both Wi-Fi and cellular data

### Priority Guide
- **P0 (Critical)**: Must pass before release - core functionality
- **P1 (High)**: Should pass - important features
- **P2 (Medium)**: Nice to have - enhancements
- **P3 (Low)**: Optional - future improvements

### Issue Reporting
For each failed test, document:
1. Test ID
2. Steps to reproduce
3. Expected vs actual result
4. Screenshots/screen recording
5. Device and OS version
6. Frequency (always/sometimes/rarely)
7. Severity (critical/major/minor)
8. Workaround (if any)

---

**End of Manual QA Test Plan**

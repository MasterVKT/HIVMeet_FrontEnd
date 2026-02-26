# Device and Responsive Design Testing Guide - Discovery Page
## HIVMeet - Task 7.5: Test on Multiple Devices and Screen Sizes

**Version:** 1.0
**Date:** 2026-02-27
**Tester:** [To be filled]
**Test Environment:** [Debug/Profile/Release]

---

## Overview

This comprehensive device testing guide covers testing the Discovery page across various devices, screen sizes, and OS versions to ensure optimal user experience on all supported platforms. The guide validates responsive layouts, touch target adequacy, and device-specific behaviors.

**Why Device Testing is Critical:**
- Users access HIVMeet on diverse devices (phones, tablets, foldables)
- Screen sizes range from small phones (320dp width) to large tablets (900dp+ width)
- Different OS versions have varying behaviors and capabilities
- Touch targets must meet accessibility standards (44x44 dp minimum)
- Performance characteristics vary significantly by device

**Testing Scope:**
1. Phone testing (small, medium, large screen sizes)
2. Tablet testing (7", 10", 12" tablets)
3. OS version compatibility (Android 8.0+, iOS 13+)
4. Responsive layout verification
5. Touch target size validation
6. Device-specific behaviors (notch, foldables, split-screen)
7. Orientation testing (portrait, landscape)
8. Performance on low-end and high-end devices

---

## Test Execution Summary

| Category | Total Tests | Passed | Failed | Blocked | Notes |
|----------|-------------|--------|--------|---------|-------|
| Small Phone (< 360dp) | 12 | - | - | - | - |
| Medium Phone (360-410dp) | 12 | - | - | - | - |
| Large Phone (> 410dp) | 12 | - | - | - | - |
| Tablet (600-900dp) | 10 | - | - | - | - |
| Android OS Versions | 6 | - | - | - | - |
| iOS OS Versions | 6 | - | - | - | - |
| Touch Target Validation | 8 | - | - | - | - |
| Device-Specific Features | 8 | - | - | - | - |
| Orientation Testing | 6 | - | - | - | - |
| Performance Testing | 8 | - | - | - | - |
| **TOTAL** | **88** | **-** | **-** | **-** | **-** |

---

## Test Device Matrix

### Recommended Test Devices

#### Android Devices
| Category | Device Examples | Screen Size | Resolution | OS Version |
|----------|----------------|-------------|------------|------------|
| Small Phone | Samsung Galaxy A10, Pixel 3a | 5.5" - 5.8" | 720x1480 | Android 9-14 |
| Medium Phone | Samsung Galaxy S21, Pixel 6 | 6.0" - 6.2" | 1080x2400 | Android 11-14 |
| Large Phone | Samsung Galaxy S23 Ultra, Pixel 7 Pro | 6.5" - 6.8" | 1440x3088 | Android 12-14 |
| Tablet | Samsung Galaxy Tab A7, Tab S8 | 10.1" - 11.0" | 1920x1200 | Android 11-14 |
| Foldable | Samsung Galaxy Z Fold 4 | 7.6" unfolded | 1812x2176 | Android 12-14 |

#### iOS Devices
| Category | Device Examples | Screen Size | Resolution | OS Version |
|----------|----------------|-------------|------------|------------|
| Small Phone | iPhone SE (2020/2022) | 4.7" | 750x1334 | iOS 13-17 |
| Medium Phone | iPhone 13, iPhone 14 | 6.1" | 1170x2532 | iOS 15-17 |
| Large Phone | iPhone 14 Pro Max, iPhone 15 Pro Max | 6.7" | 1290x2796 | iOS 16-17 |
| Tablet | iPad (9th/10th gen), iPad Air | 10.2" - 10.9" | 2160x1620 | iPadOS 15-17 |

### Minimum Test Coverage
**Required for QA Sign-Off:**
- [ ] At least 1 small Android phone (< 360dp width)
- [ ] At least 1 medium Android phone (360-410dp width)
- [ ] At least 1 large Android phone (> 410dp width)
- [ ] At least 1 Android tablet
- [ ] At least 1 small iOS phone (iPhone SE)
- [ ] At least 1 medium iOS phone (iPhone 13/14)
- [ ] At least 1 large iOS phone (iPhone Pro Max)
- [ ] At least 1 iPad
- [ ] At least 1 device with Android 9 (oldest supported)
- [ ] At least 1 device with iOS 13 (oldest supported)

---

## Prerequisites

### Test Environment Setup
- [ ] Install latest app version on all test devices
- [ ] Enable developer options on Android devices
- [ ] Enable pointer/touch location for touch target validation
- [ ] Prepare test accounts (free and premium)
- [ ] Ensure devices have >50% battery
- [ ] Test in good Wi-Fi environment initially
- [ ] Prepare screenshot/recording tools

### Tools Required
- **Android**: Developer Options → Pointer Location
- **iOS**: Settings → Accessibility → Touch → Touch Accommodations (optional)
- **Screen Ruler Tool**: Physical ruler or on-screen measurement app
- **Performance Monitor**: Flutter DevTools, Android Profiler, Xcode Instruments
- **Issue Tracking**: Screenshots, device info, reproduction steps

---

## Part 1: Small Phone Testing (< 360dp width)

**Target Devices:** iPhone SE, Samsung Galaxy A10, Pixel 3a, budget Android phones

**Screen Width Range:** 320dp - 359dp
**Common Resolutions:** 640x960, 720x1280, 750x1334

### TEST-SP-001: Discovery Page Layout Rendering
**Priority:** P0
**Device:** [Device name]
**OS:** [OS version]
**Resolution:** [Actual resolution]

**Test Steps:**
1. Launch HIVMeet app and log in
2. Navigate to Discovery page
3. Observe initial page layout

**Expected Results:**
- [ ] Swipe card displays without horizontal scroll
- [ ] Profile photo fills card width without cropping critical content
- [ ] Profile name, age, distance text is fully visible
- [ ] All action buttons (X, heart, star) are visible
- [ ] No UI elements overlap or clip
- [ ] Bottom navigation bar fully visible
- [ ] Top app bar (if present) fully visible
- [ ] Daily limit counter visible and readable

**Issue Found:** [ ] Yes [ ] No
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low
**Screenshot:** [Attach]
**Notes:**
```
[Describe any layout issues, clipping, or overlap problems]
```

---

### TEST-SP-002: Swipe Card Content Readability
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. On Discovery page, view the top profile card
2. Read all text content on the card
3. Swipe horizontally to view all photos
4. Tap to view profile details

**Expected Results:**
- [ ] Profile name readable without truncation (or elegant ellipsis if >20 chars)
- [ ] Age and distance clearly visible
- [ ] Compatibility score percentage legible
- [ ] Badge icons (verified, premium) visible and not overlapping text
- [ ] Bio preview (if shown) readable
- [ ] Photo pagination dots visible and distinguishable
- [ ] All photos load at appropriate resolution (not pixelated)
- [ ] Profile detail page displays all sections correctly

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any readability issues, font sizes, truncation problems]
```

---

### TEST-SP-003: Action Buttons Touch Targets
**Priority:** P0 (Accessibility Critical)
**Device:** [Device name]

**Test Steps:**
1. Enable Android pointer location (Settings → Developer Options → Pointer Location)
2. On Discovery page, tap each action button precisely
3. Measure touch target size visually or with ruler app

**Expected Results:**
- [ ] Like button (heart): Touch target ≥ 44x44 dp
- [ ] Dislike button (X): Touch target ≥ 44x44 dp
- [ ] Super Like button (star): Touch target ≥ 44x44 dp
- [ ] Rewind button (if visible): Touch target ≥ 44x44 dp
- [ ] All buttons respond to tap without requiring precise aim
- [ ] Button spacing prevents accidental adjacent button taps
- [ ] Visual button size appears appropriate for screen

**Touch Target Measurements:**
- Like button: [____] x [____] dp
- Dislike button: [____] x [____] dp
- Super Like button: [____] x [____] dp
- Rewind button: [____] x [____] dp

**Issue Found:** [ ] Yes [ ] No
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low
**Screenshot:** [Attach with pointer location enabled]
**Notes:**
```
[Document any buttons below 44x44 dp - CRITICAL ACCESSIBILITY ISSUE]
```

---

### TEST-SP-004: Filters Page Usability
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. From Discovery page, tap filters icon/button
2. Observe filters page layout on small screen
3. Interact with all filter controls
4. Apply filters and return to Discovery

**Expected Results:**
- [ ] Filters page content fits within screen without horizontal scroll
- [ ] Age range slider handles are tappable (≥44x44 dp)
- [ ] Distance slider handle is tappable (≥44x44 dp)
- [ ] Current filter values are readable
- [ ] Toggle switches are tappable and clearly show on/off state
- [ ] Relationship type chips are readable and tappable
- [ ] Interest tags are readable and tappable
- [ ] "Apply Filters" button is fully visible and tappable
- [ ] Estimated profile count is visible
- [ ] Page scrolls smoothly if content exceeds screen height

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any cramped layouts, difficult-to-tap controls, or readability issues]
```

---

### TEST-SP-005: Match Found Modal Display
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Swipe right on a test profile that will match
2. Observe match found modal animation
3. Verify modal layout and content
4. Tap modal action buttons

**Expected Results:**
- [ ] Modal covers screen appropriately (not too large/small)
- [ ] "It's a Match!" text is visible and readable
- [ ] Both profile photos display clearly
- [ ] Profile names visible under photos
- [ ] "Send Message" button is fully visible and tappable (≥44x44 dp)
- [ ] "Keep Swiping" button is fully visible and tappable (≥44x44 dp)
- [ ] Buttons don't overlap
- [ ] Modal can be dismissed (back button or outside tap)
- [ ] Animation plays smoothly without lag

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document any layout issues with modal on small screen]
```

---

### TEST-SP-006: Daily Limit Reached Modal
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Use test account near/at daily limit
2. Trigger daily limit reached modal
3. Verify modal layout and CTA

**Expected Results:**
- [ ] Modal displays without clipping content
- [ ] Title text readable ("Daily Limit Reached" or equivalent)
- [ ] Explanation text readable and not cut off
- [ ] Upgrade CTA button fully visible and tappable
- [ ] Dismiss button or X icon tappable
- [ ] Counter reset time visible (if shown)
- [ ] No layout overflow or scroll issues

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any issues with modal content fitting on small screen]
```

---

### TEST-SP-007: Swipe Gesture Recognition
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. On Discovery page, perform swipe gestures on profile card
2. Test swipe right (like), swipe left (dislike), swipe up (super like)
3. Test various swipe speeds (slow, medium, fast)

**Expected Results:**
- [ ] Swipe right triggers like action reliably
- [ ] Swipe left triggers dislike action reliably
- [ ] Swipe up triggers super like (or upgrade prompt if free user)
- [ ] Swipe threshold appropriate (not too sensitive/insensitive)
- [ ] Card animation smooth during swipe
- [ ] Haptic feedback occurs on action completion
- [ ] Gesture recognition works in all screen areas
- [ ] No accidental swipes when scrolling photos

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any gesture recognition issues, especially if swipes not detected]
```

---

### TEST-SP-008: Profile Photo Carousel
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View profile card with multiple photos
2. Swipe horizontally on card to navigate photos
3. Tap left/right edges to advance photos (if supported)
4. Observe pagination indicators

**Expected Results:**
- [ ] Horizontal swipe advances to next photo
- [ ] Swipe gesture smooth and responsive
- [ ] Pagination dots update correctly
- [ ] Current photo indicator clearly visible
- [ ] Photos load at appropriate resolution (not blurry)
- [ ] Edge tap zones work (if implemented)
- [ ] No conflict between photo swipe and card swipe gestures
- [ ] All photos accessible (no missing photos)

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any issues with photo navigation or visual quality]
```

---

### TEST-SP-009: Bottom Navigation Bar
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. On Discovery page, observe bottom navigation bar
2. Tap each navigation item
3. Return to Discovery from other tabs

**Expected Results:**
- [ ] All navigation items visible (Discovery, Matches, Messages, Profile)
- [ ] Icons clearly visible and distinguishable
- [ ] Labels visible (or tooltips on long-press if icons-only)
- [ ] Active tab clearly indicated
- [ ] Each tab button tappable (≥44x44 dp touch target)
- [ ] Navigation smooth without lag
- [ ] Discovery tab returns to top when tapped while already on Discovery

**Touch Target Measurements:**
- Nav item 1: [____] x [____] dp
- Nav item 2: [____] x [____] dp
- Nav item 3: [____] x [____] dp
- Nav item 4: [____] x [____] dp

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document any navigation issues or touch target problems]
```

---

### TEST-SP-010: Error States on Small Screen
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Trigger network error (enable airplane mode, then try to load profiles)
2. Trigger "No More Profiles" state
3. Trigger "Adjust Filters" state
4. Observe error message layout

**Expected Results:**
- [ ] Error icon/illustration displays without clipping
- [ ] Error message text fully visible and readable
- [ ] Action button (Retry, Adjust Filters) fully visible and tappable
- [ ] Layout doesn't overflow screen
- [ ] Text doesn't overlap images
- [ ] Sufficient padding around content
- [ ] Error state dismissible or actionable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach for each error state]
**Notes:**
```
[Document any layout issues with error states on small screen]
```

---

### TEST-SP-011: Text Scaling (Large Fonts)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Set device font size to largest setting
   - Android: Settings → Display → Font Size → Largest
   - iOS: Settings → Display & Brightness → Text Size → Largest
2. Navigate to Discovery page
3. Observe all text elements

**Expected Results:**
- [ ] Profile name visible (may wrap to 2 lines if very long)
- [ ] Age and distance readable
- [ ] Action button labels visible (if text-based)
- [ ] Compatibility score visible
- [ ] Daily limit counter readable
- [ ] No text clipping or severe overlap
- [ ] Overall layout remains usable
- [ ] Filter labels readable
- [ ] Modal text readable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach before/after font scaling]
**Notes:**
```
[Document any text overflow, clipping, or layout breaking at large font sizes]
```

---

### TEST-SP-012: Performance on Small Phone
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Launch Discovery page (cold start)
2. Swipe through 10 profiles rapidly
3. Apply filters and reload profiles
4. Open profile details
5. Trigger match modal

**Expected Results:**
- [ ] Initial page load < 3 seconds
- [ ] Swipe animations smooth (≥30fps, target 60fps)
- [ ] No visible frame drops during animations
- [ ] Profile photos load progressively (placeholder → full image)
- [ ] No app freezing or ANR (Application Not Responding)
- [ ] Memory usage stable (monitor with DevTools if possible)
- [ ] Battery drain acceptable for typical 10-minute session

**Performance Notes:**
- Initial load time: [____] seconds
- Swipe animation quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
- Frame drops observed: [ ] None [ ] Occasional [ ] Frequent
- Overall performance: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any performance issues, lag, or stuttering on small phone]
```

---

## Part 2: Medium Phone Testing (360-410dp width)

**Target Devices:** Samsung Galaxy S21, Google Pixel 6, iPhone 13/14

**Screen Width Range:** 360dp - 410dp
**Common Resolutions:** 1080x2340, 1080x2400, 1170x2532

### TEST-MP-001: Discovery Page Layout Optimization
**Priority:** P0
**Device:** [Device name]
**OS:** [OS version]
**Resolution:** [Actual resolution]

**Test Steps:**
1. Launch HIVMeet app and navigate to Discovery page
2. Observe layout utilization of screen space
3. Compare with small phone layout (if tested)

**Expected Results:**
- [ ] Swipe card takes advantage of additional screen width
- [ ] Profile content well-proportioned
- [ ] Action buttons appropriately sized (not too small/large)
- [ ] Adequate white space around elements
- [ ] Layout feels balanced and not cramped
- [ ] No excessive empty space
- [ ] All elements visible without scroll

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any layout optimization issues or poor use of available space]
```

---

### TEST-MP-002: Swipe Card Content Display
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. View profile cards on Discovery page
2. Examine all profile information elements
3. Swipe through photos
4. View profile details

**Expected Results:**
- [ ] Profile photos display at high quality
- [ ] Name, age, distance clearly readable
- [ ] Compatibility score prominent
- [ ] Badges (verified, premium, online) clearly visible
- [ ] Bio preview (if shown) readable without truncation
- [ ] Interest tags visible and readable
- [ ] Photo pagination smooth
- [ ] All content well-proportioned for screen size

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document any content display issues]
```

---

### TEST-MP-003: Action Buttons Layout and Touch
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Examine action button layout at bottom of card
2. Tap each button to verify touch response
3. Measure touch targets (enable pointer location)

**Expected Results:**
- [ ] Like button: Touch target ≥ 56x56 dp (preferred on medium phones)
- [ ] Dislike button: Touch target ≥ 56x56 dp
- [ ] Super Like button: Touch target ≥ 56x56 dp
- [ ] Rewind button: Touch target ≥ 56x56 dp
- [ ] Buttons spaced appropriately (8-16dp gap minimum)
- [ ] Button visual size matches touch target
- [ ] All buttons respond immediately to tap
- [ ] No accidental adjacent button activations

**Touch Target Measurements:**
- Like button: [____] x [____] dp
- Dislike button: [____] x [____] dp
- Super Like button: [____] x [____] dp
- Rewind button: [____] x [____] dp

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach with pointer location]
**Notes:**
```
[Document touch target sizes and any tap accuracy issues]
```

---

### TEST-MP-004: Filters Page Layout
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Open filters page from Discovery
2. Interact with all filter controls
3. Observe layout and spacing
4. Apply filters

**Expected Results:**
- [ ] All filter sections visible without excessive scrolling
- [ ] Slider controls easy to manipulate
- [ ] Age range slider handles ≥44x44 dp
- [ ] Distance slider handle ≥44x44 dp
- [ ] Toggle switches clear on/off state
- [ ] Relationship type and interest chips readable and tappable
- [ ] Current filter values clearly displayed
- [ ] Estimated profile count visible
- [ ] "Apply Filters" and "Clear Filters" buttons clearly visible

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note any usability issues with filters on medium phone]
```

---

### TEST-MP-005: Match Found Modal
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Trigger match found modal
2. Verify modal layout and content
3. Test action buttons

**Expected Results:**
- [ ] Modal well-proportioned for screen
- [ ] "It's a Match!" text prominent
- [ ] Both profile photos clearly visible
- [ ] Profile names readable
- [ ] "Send Message" button tappable (≥56x56 dp preferred)
- [ ] "Keep Swiping" button tappable (≥56x56 dp preferred)
- [ ] Animation smooth and not laggy
- [ ] Modal dismissible

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document modal layout and interaction issues]
```

---

### TEST-MP-006: Swipe Gestures and Animations
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Perform swipe right, left, and up gestures
2. Test various swipe speeds and distances
3. Observe animation smoothness

**Expected Results:**
- [ ] All swipe directions recognized accurately
- [ ] Swipe threshold feels natural
- [ ] Card animation smooth at 60fps
- [ ] Overlay colors clear (green=like, red=dislike, blue=super like)
- [ ] Haptic feedback on completion
- [ ] Next card appears smoothly
- [ ] No animation stuttering or lag
- [ ] Gesture recognition consistent across screen area

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any gesture or animation issues]
```

---

### TEST-MP-007: Profile Photo Carousel Navigation
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View profile with multiple photos
2. Navigate through photos via swipe
3. Test tap zones for photo navigation
4. Observe pagination indicators

**Expected Results:**
- [ ] Horizontal swipe between photos smooth
- [ ] Left/right tap zones work (if implemented)
- [ ] Pagination dots update correctly
- [ ] Current photo indicator clear
- [ ] Photos load quickly and at high quality
- [ ] No gesture conflicts between photo and card swipes
- [ ] All photos accessible

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note photo navigation issues or quality problems]
```

---

### TEST-MP-008: Daily Limit UI
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Log in with free account
2. Observe daily limit counter
3. Trigger daily limit reached state (if possible)
4. Verify upgrade prompt

**Expected Results:**
- [ ] "X likes remaining" counter visible and clear
- [ ] Counter updates after each like
- [ ] Daily limit modal displays properly
- [ ] Upgrade CTA clear and tappable
- [ ] Explanation text readable
- [ ] Dismiss option available

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document daily limit UI issues]
```

---

### TEST-MP-009: Error States
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Trigger network error
2. Trigger "No More Profiles" state
3. Trigger "Adjust Filters" state
4. Test retry/action buttons

**Expected Results:**
- [ ] Error illustrations/icons display well
- [ ] Error messages clear and readable
- [ ] Action buttons prominent and tappable
- [ ] Layout clean without overflow
- [ ] Error states dismissible/actionable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach for each error]
**Notes:**
```
[Document error state layout issues]
```

---

### TEST-MP-010: Text Scaling
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Set device to largest font size
2. Navigate through Discovery page
3. Open filters, modals, profile details

**Expected Results:**
- [ ] All text remains readable
- [ ] Layouts adapt to larger text
- [ ] Minimal text clipping
- [ ] Interactive elements remain tappable
- [ ] Overall layout remains usable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document text scaling issues]
```

---

### TEST-MP-011: Bottom Navigation
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Test all bottom navigation tabs
2. Verify active/inactive states
3. Test navigation flow

**Expected Results:**
- [ ] All tabs visible and clearly labeled
- [ ] Icons distinguishable
- [ ] Active tab clearly indicated
- [ ] Each tab tappable (≥44x44 dp minimum, 56x56 dp preferred)
- [ ] Navigation smooth
- [ ] State preserved when switching tabs

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document navigation issues]
```

---

### TEST-MP-012: Performance
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Launch Discovery page
2. Swipe through 20 profiles rapidly
3. Apply filters multiple times
4. Open profile details
5. Trigger match modal

**Expected Results:**
- [ ] Initial load < 2 seconds
- [ ] Swipe animations 60fps consistently
- [ ] No frame drops
- [ ] Photo loading smooth with placeholders
- [ ] No freezing or lag
- [ ] Memory usage stable

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
- Overall performance: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document performance issues]
```

---

## Part 3: Large Phone Testing (> 410dp width)

**Target Devices:** Samsung Galaxy S23 Ultra, Google Pixel 7 Pro, iPhone 14/15 Pro Max

**Screen Width Range:** 410dp - 480dp
**Common Resolutions:** 1440x3088, 1290x2796

### TEST-LP-001: Discovery Page Layout (Large Screen)
**Priority:** P0
**Device:** [Device name]
**OS:** [OS version]
**Resolution:** [Actual resolution]

**Test Steps:**
1. Launch Discovery page on large phone
2. Observe card sizing and layout
3. Compare with medium phone layout

**Expected Results:**
- [ ] Swipe card appropriately sized (not excessively large)
- [ ] Card maintains good proportions (not stretched)
- [ ] Content well-balanced with white space
- [ ] Action buttons appropriately sized
- [ ] Layout takes advantage of screen real estate
- [ ] No awkward spacing or excessive padding
- [ ] Visual hierarchy clear

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note layout optimization for large screens]
```

---

### TEST-LP-002: High-Resolution Photo Display
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View profile cards with photos
2. Examine photo quality and sharpness
3. Navigate through photo carousel
4. View full profile with all photos

**Expected Results:**
- [ ] Photos display at high resolution
- [ ] No pixelation or blurriness
- [ ] Photos load progressively (low-res → high-res)
- [ ] Aspect ratios preserved
- [ ] Photos fill card appropriately
- [ ] No excessive compression artifacts
- [ ] Carousel navigation smooth

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document photo quality issues on high-res display]
```

---

### TEST-LP-003: Action Buttons Touch Targets (Large Phone)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Measure action button touch targets
2. Test button tap responsiveness
3. Verify visual size matches touch target

**Expected Results:**
- [ ] Like button: Touch target 56x56 dp or larger
- [ ] Dislike button: Touch target 56x56 dp or larger
- [ ] Super Like button: Touch target 56x56 dp or larger
- [ ] Rewind button: Touch target 56x56 dp or larger
- [ ] Buttons easy to tap accurately
- [ ] Sufficient spacing between buttons
- [ ] Button size appropriate for large screen (not tiny)

**Touch Target Measurements:**
- Like button: [____] x [____] dp
- Dislike button: [____] x [____] dp
- Super Like button: [____] x [____] dp
- Rewind button: [____] x [____] dp

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document touch target measurements and usability]
```

---

### TEST-LP-004: Filters Page (Large Screen)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Open filters page
2. Interact with all controls
3. Observe layout and spacing

**Expected Results:**
- [ ] Filter controls well-spaced
- [ ] Sliders easy to manipulate
- [ ] All text readable
- [ ] Toggle switches clear
- [ ] Multi-select chips readable
- [ ] Estimated count prominent
- [ ] Apply/Clear buttons visible
- [ ] Layout feels spacious, not cramped

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note filters layout on large screen]
```

---

### TEST-LP-005: Match Found Modal (Large Screen)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Trigger match found modal
2. Verify modal sizing and layout
3. Test action buttons

**Expected Results:**
- [ ] Modal appropriately sized for large screen
- [ ] Profile photos large and clear
- [ ] "It's a Match!" text prominent
- [ ] Profile names readable
- [ ] Action buttons appropriately sized
- [ ] Animation smooth and impressive
- [ ] Modal not awkwardly small or overly large

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document modal appearance on large screen]
```

---

### TEST-LP-006: Swipe Gestures (Large Screen)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Perform swipes across different screen areas
2. Test short, medium, and long swipe distances
3. Test various swipe speeds

**Expected Results:**
- [ ] Swipe gestures recognized across entire card
- [ ] Swipe threshold appropriate for large screen
- [ ] Card animation smooth
- [ ] Overlay colors clear
- [ ] Haptic feedback consistent
- [ ] Gesture recognition reliable
- [ ] No gesture detection issues due to large screen

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document gesture recognition on large screen]
```

---

### TEST-LP-007: Profile Detail Page (Large Screen)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Tap profile card to open details
2. Scroll through full profile
3. View all profile sections

**Expected Results:**
- [ ] Profile detail page well-laid out
- [ ] Photos display at high quality
- [ ] Bio text readable with appropriate line length
- [ ] Interest tags clear and readable
- [ ] Compatibility score visible
- [ ] Scrolling smooth
- [ ] Action buttons at bottom accessible
- [ ] Layout optimized for large screen

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note profile detail layout on large screen]
```

---

### TEST-LP-008: Text Readability
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View all text elements on Discovery page
2. Test with default and large font sizes

**Expected Results:**
- [ ] Text appropriately sized for large screen
- [ ] Line lengths reasonable (not excessively wide)
- [ ] Font scaling works correctly
- [ ] Text remains readable at all sizes
- [ ] No layout breaking at large fonts

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document text readability issues]
```

---

### TEST-LP-009: Error States (Large Screen)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Trigger various error states
2. Verify error layout on large screen

**Expected Results:**
- [ ] Error illustrations appropriately sized
- [ ] Error messages readable
- [ ] Action buttons prominent
- [ ] Layout balanced with white space
- [ ] No awkward spacing

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document error state layout on large screen]
```

---

### TEST-LP-010: Bottom Navigation (Large Screen)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Test bottom navigation on large phone
2. Verify tab switching

**Expected Results:**
- [ ] Navigation items appropriately sized
- [ ] Icons and labels clear
- [ ] Active state clear
- [ ] Tappable areas generous
- [ ] Navigation smooth

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document navigation on large screen]
```

---

### TEST-LP-011: Daily Limit UI (Large Screen)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View daily limit counter
2. Trigger limit reached modal

**Expected Results:**
- [ ] Counter clearly visible
- [ ] Modal well-proportioned
- [ ] Upgrade CTA prominent
- [ ] Text readable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document daily limit UI on large screen]
```

---

### TEST-LP-012: Performance (Large Screen)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Test Discovery page performance
2. Rapid swipes, filters, navigation

**Expected Results:**
- [ ] Initial load < 2 seconds
- [ ] 60fps animations consistently
- [ ] High-res photo loading smooth
- [ ] No lag or stuttering
- [ ] Memory usage acceptable

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
- Overall: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document performance on large phone]
```

---

## Part 4: Tablet Testing (600-900dp width)

**Target Devices:** iPad (9th/10th gen), iPad Air, Samsung Galaxy Tab S8, Tab A7

**Screen Width Range:** 600dp - 900dp
**Common Resolutions:** 1200x1920, 1620x2160

### TEST-TAB-001: Discovery Page Layout (Tablet)
**Priority:** P1
**Device:** [Device name]
**OS:** [OS version]
**Screen Size:** [inches]

**Test Steps:**
1. Launch Discovery page on tablet
2. Observe layout adaptation for large screen
3. Test in both portrait and landscape

**Expected Results:**
- [ ] Layout adapts intelligently to tablet screen
- [ ] Swipe card not excessively large (max width constraint?)
- [ ] Content centered or well-positioned
- [ ] Action buttons appropriately positioned
- [ ] White space used effectively
- [ ] Layout doesn't feel stretched or awkward
- [ ] May show additional UI elements (e.g., sidebar, two-pane)
- [ ] Portrait and landscape both usable

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach portrait and landscape]
**Notes:**
```
[Document tablet layout adaptation - this is critical for user experience]
```

---

### TEST-TAB-002: Swipe Card Content (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. View profile cards on tablet
2. Examine photo quality and layout
3. Review all profile information

**Expected Results:**
- [ ] Profile photos high resolution
- [ ] Card size appropriate (not tiny, not huge)
- [ ] Text readable and well-proportioned
- [ ] Badges and icons clear
- [ ] Bio preview readable
- [ ] Interest tags visible
- [ ] Photo carousel smooth

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note content display on tablet]
```

---

### TEST-TAB-003: Action Buttons (Tablet)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Measure and test action buttons
2. Verify touch targets
3. Test tap accuracy

**Expected Results:**
- [ ] All buttons ≥ 56x56 dp touch target
- [ ] Buttons positioned for easy thumb reach
- [ ] Sufficient spacing between buttons
- [ ] Visual size matches touch target
- [ ] All buttons responsive
- [ ] No accidental taps

**Touch Target Measurements:**
- Like: [____] x [____] dp
- Dislike: [____] x [____] dp
- Super Like: [____] x [____] dp
- Rewind: [____] x [____] dp

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document button usability on tablet]
```

---

### TEST-TAB-004: Filters Page (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Open filters on tablet
2. Test all filter controls
3. Observe layout

**Expected Results:**
- [ ] Filters layout optimized for tablet
- [ ] Controls well-spaced and easy to use
- [ ] Sliders easy to manipulate
- [ ] All text readable
- [ ] Multi-select chips clear
- [ ] Apply/Clear buttons accessible

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note filters experience on tablet]
```

---

### TEST-TAB-005: Match Modal (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Trigger match found modal on tablet
2. Verify modal layout

**Expected Results:**
- [ ] Modal appropriately sized for tablet
- [ ] Content not too small
- [ ] Profile photos large and clear
- [ ] Action buttons accessible
- [ ] Animation smooth

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document modal on tablet]
```

---

### TEST-TAB-006: Swipe Gestures (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Test swipe gestures on tablet
2. Try different grip positions

**Expected Results:**
- [ ] Swipes recognized reliably
- [ ] Gesture threshold appropriate for tablet
- [ ] Animation smooth
- [ ] Haptic feedback (if available)
- [ ] Gesture works across card area

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document gesture recognition on tablet]
```

---

### TEST-TAB-007: Profile Detail (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Open profile details on tablet
2. View all profile content

**Expected Results:**
- [ ] Profile detail optimized for tablet
- [ ] Photos display beautifully
- [ ] Bio readable with good line length
- [ ] Layout uses screen space effectively
- [ ] May show two-pane layout (profile + actions)

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Note profile detail layout on tablet]
```

---

### TEST-TAB-008: Orientation Change
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Test Discovery in portrait
2. Rotate to landscape
3. Rotate back to portrait

**Expected Results:**
- [ ] Layout adapts smoothly to orientation change
- [ ] Content repositions correctly
- [ ] No data loss
- [ ] State preserved
- [ ] Both orientations usable
- [ ] Landscape layout optimized (may differ from portrait)

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach both orientations]
**Notes:**
```
[Document orientation handling on tablet]
```

---

### TEST-TAB-009: Text Scaling (Tablet)
**Priority:** P1
**Device:** [Device name]

**Test Steps:**
1. Set tablet to largest font size
2. Test Discovery page

**Expected Results:**
- [ ] All text readable
- [ ] Layout adapts to larger text
- [ ] Minimal clipping
- [ ] Interactive elements remain accessible

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document text scaling on tablet]
```

---

### TEST-TAB-010: Performance (Tablet)
**Priority:** P0
**Device:** [Device name]

**Test Steps:**
1. Test Discovery page performance on tablet
2. Rapid interactions

**Expected Results:**
- [ ] Load time < 2 seconds
- [ ] 60fps animations
- [ ] High-res photos load smoothly
- [ ] No lag
- [ ] Memory usage acceptable

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
- Overall: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document tablet performance]
```

---

## Part 5: Android OS Version Testing

**Test on minimum supported version (Android 8.0 Oreo) and latest (Android 14)**

### TEST-AOS-001: Discovery on Android 8.0 (API 26)
**Priority:** P0 (Minimum Supported Version)
**Device:** [Device name]
**OS:** Android 8.0 (API 26)

**Test Steps:**
1. Install app on Android 8.0 device
2. Navigate to Discovery page
3. Test all core functionality

**Expected Results:**
- [ ] App launches successfully
- [ ] Discovery page loads without crash
- [ ] Swipe gestures work
- [ ] Action buttons functional
- [ ] Filters work
- [ ] Match modal displays
- [ ] No API compatibility issues
- [ ] Performance acceptable for older OS

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any Android 8.0 specific issues - CRITICAL if app doesn't work]
```

---

### TEST-AOS-002: Discovery on Android 9 (API 28)
**Priority:** P1
**Device:** [Device name]
**OS:** Android 9.0 (API 28)

**Test Steps:**
1. Test Discovery page on Android 9
2. Verify all features

**Expected Results:**
- [ ] All features working
- [ ] No OS-specific issues
- [ ] Performance good

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document Android 9 issues]
```

---

### TEST-AOS-003: Discovery on Android 10 (API 29)
**Priority:** P1
**Device:** [Device name]
**OS:** Android 10 (API 29)

**Test Steps:**
1. Test Discovery on Android 10
2. Test dark mode (introduced in Android 10)
3. Verify gestures with gesture navigation

**Expected Results:**
- [ ] All features working
- [ ] Dark mode applies correctly
- [ ] Gesture navigation compatible
- [ ] No status bar overlap issues

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document Android 10 specific issues]
```

---

### TEST-AOS-004: Discovery on Android 11 (API 30)
**Priority:** P1
**Device:** [Device name]
**OS:** Android 11 (API 30)

**Test Steps:**
1. Test Discovery on Android 11
2. Verify all features

**Expected Results:**
- [ ] All features working
- [ ] No OS-specific issues
- [ ] Conversations notifications work (if applicable)

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document Android 11 issues]
```

---

### TEST-AOS-005: Discovery on Android 12+ (API 31+)
**Priority:** P1
**Device:** [Device name]
**OS:** Android 12/13/14

**Test Steps:**
1. Test Discovery on Android 12+
2. Verify Material You theming (if implemented)
3. Test with dynamic colors

**Expected Results:**
- [ ] All features working
- [ ] Material You colors apply (if supported)
- [ ] Splash screen API compatible
- [ ] No OS-specific crashes

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document Android 12+ issues]
```

---

### TEST-AOS-006: OS Upgrade Scenario
**Priority:** P2
**Device:** [Device name]

**Test Steps:**
1. Install app on device with older OS
2. Use Discovery page
3. Upgrade OS (if possible in test environment)
4. Retest Discovery page

**Expected Results:**
- [ ] App continues working after OS upgrade
- [ ] Data/state preserved
- [ ] No crashes post-upgrade

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document OS upgrade compatibility]
```

---

## Part 6: iOS Version Testing

**Test on minimum supported version (iOS 13) and latest (iOS 17)**

### TEST-IOS-001: Discovery on iOS 13
**Priority:** P0 (Minimum Supported Version)
**Device:** [Device name]
**OS:** iOS 13.x

**Test Steps:**
1. Install app on iOS 13 device
2. Navigate to Discovery page
3. Test all core functionality

**Expected Results:**
- [ ] App launches successfully
- [ ] Discovery page loads
- [ ] Swipe gestures work
- [ ] Action buttons functional
- [ ] Filters work
- [ ] Match modal displays
- [ ] Dark mode works (iOS 13 introduced system dark mode)
- [ ] No compatibility crashes

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS 13 specific issues - CRITICAL if app doesn't work]
```

---

### TEST-IOS-002: Discovery on iOS 14
**Priority:** P1
**Device:** [Device name]
**OS:** iOS 14.x

**Test Steps:**
1. Test Discovery on iOS 14
2. Test all features

**Expected Results:**
- [ ] All features working
- [ ] App Clips compatible (if applicable)
- [ ] No OS-specific issues

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS 14 issues]
```

---

### TEST-IOS-003: Discovery on iOS 15
**Priority:** P1
**Device:** [Device name]
**OS:** iOS 15.x

**Test Steps:**
1. Test Discovery on iOS 15
2. Verify all features

**Expected Results:**
- [ ] All features working
- [ ] Focus mode compatible
- [ ] No crashes or issues

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS 15 issues]
```

---

### TEST-IOS-004: Discovery on iOS 16
**Priority:** P1
**Device:** [Device name]
**OS:** iOS 16.x

**Test Steps:**
1. Test Discovery on iOS 16
2. Test with lock screen widgets (if implemented)

**Expected Results:**
- [ ] All features working
- [ ] No OS-specific crashes
- [ ] Live Activities compatible (if used)

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS 16 issues]
```

---

### TEST-IOS-005: Discovery on iOS 17
**Priority:** P1
**Device:** [Device name]
**OS:** iOS 17.x (latest)

**Test Steps:**
1. Test Discovery on iOS 17
2. Verify all features

**Expected Results:**
- [ ] All features working
- [ ] Latest iOS features compatible
- [ ] No deprecation warnings

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS 17 issues]
```

---

### TEST-IOS-006: iOS Upgrade Scenario
**Priority:** P2
**Device:** [Device name]

**Test Steps:**
1. Install app on device with older iOS
2. Use Discovery page
3. Upgrade iOS (if possible)
4. Retest Discovery

**Expected Results:**
- [ ] App continues working after iOS upgrade
- [ ] Data preserved
- [ ] No crashes

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document iOS upgrade compatibility]
```

---

## Part 7: Touch Target Validation

**WCAG 2.1 AA Requirement: Minimum 44x44 dp touch targets**
**HIVMeet Preferred Standard: 56x56 dp on medium+ screens**

### TEST-TT-001: Discovery Action Buttons
**Priority:** P0 (Accessibility Critical)
**Device:** [All devices tested]

**Test Procedure:**
1. Enable pointer location (Android: Developer Options → Pointer Location)
2. Measure each action button touch target
3. Document measurements

**Measurements Table:**
| Device | Like Button | Dislike Button | Super Like | Rewind | Pass/Fail |
|--------|-------------|----------------|------------|--------|-----------|
| [Small Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Medium Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Large Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Tablet] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |

**Acceptance Criteria:**
- [ ] All buttons on all devices ≥ 44x44 dp (MINIMUM)
- [ ] All buttons on medium+ phones ideally ≥ 56x56 dp (PREFERRED)

**Critical Issues Found:** [ ] Yes [ ] No

**Notes:**
```
[Any button < 44x44 dp is a CRITICAL ACCESSIBILITY FAILURE that MUST be fixed]
```

---

### TEST-TT-002: Filters Page Controls
**Priority:** P0
**Device:** [All devices tested]

**Test Procedure:**
1. Measure touch targets for filter controls
2. Test slider handles, toggles, chips

**Measurements:**
- Age slider handles: [____] x [____] dp
- Distance slider handle: [____] x [____] dp
- Toggle switches: [____] x [____] dp
- Relationship chips: [____] x [____] dp
- Interest tags: [____] x [____] dp

**Acceptance:**
- [ ] All interactive elements ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any controls < 44x44 dp]
```

---

### TEST-TT-003: Bottom Navigation Tabs
**Priority:** P0
**Device:** [All devices tested]

**Test Procedure:**
1. Measure each bottom navigation tab touch target

**Measurements Table:**
| Device | Tab 1 | Tab 2 | Tab 3 | Tab 4 | Pass/Fail |
|--------|-------|-------|-------|-------|-----------|
| [Small Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Medium Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Large Phone] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |
| [Tablet] | __ x __ dp | __ x __ dp | __ x __ dp | __ x __ dp | [ ] Pass [ ] Fail |

**Acceptance:**
- [ ] All tabs ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document navigation touch target issues]
```

---

### TEST-TT-004: Match Modal Buttons
**Priority:** P0
**Device:** [All devices tested]

**Test Procedure:**
1. Trigger match modal
2. Measure "Send Message" and "Keep Swiping" buttons

**Measurements:**
- "Send Message" button: [____] x [____] dp
- "Keep Swiping" button: [____] x [____] dp
- Close/Dismiss button: [____] x [____] dp

**Acceptance:**
- [ ] All buttons ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document modal button touch target issues]
```

---

### TEST-TT-005: Profile Card Interactive Elements
**Priority:** P1
**Device:** [All devices tested]

**Test Procedure:**
1. Identify all tappable areas on profile card
2. Measure touch targets

**Measurements:**
- Photo tap (to open details): [Full card or specific area?]
- Photo carousel left/right zones: [____] x [____] dp (if implemented)
- Info icon (if present): [____] x [____] dp

**Acceptance:**
- [ ] All tappable elements ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document card interactive element touch targets]
```

---

### TEST-TT-006: Filter Apply/Clear Buttons
**Priority:** P1
**Device:** [All devices tested]

**Test Procedure:**
1. Measure "Apply Filters" and "Clear Filters" buttons

**Measurements:**
- "Apply Filters" button: [____] x [____] dp
- "Clear Filters" button: [____] x [____] dp

**Acceptance:**
- [ ] Both buttons ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document filter button touch targets]
```

---

### TEST-TT-007: Daily Limit Modal Buttons
**Priority:** P1
**Device:** [All devices tested]

**Test Procedure:**
1. Trigger daily limit modal
2. Measure upgrade CTA and dismiss buttons

**Measurements:**
- Upgrade button: [____] x [____] dp
- Dismiss button: [____] x [____] dp

**Acceptance:**
- [ ] All buttons ≥ 44x44 dp

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document daily limit modal button touch targets]
```

---

### TEST-TT-008: Touch Target Usability Test
**Priority:** P0
**Device:** [Representative device from each category]

**Test Procedure:**
1. Ask 3-5 test users to use Discovery page
2. Observe any difficulty tapping buttons
3. Note any accidental adjacent button taps
4. Collect subjective feedback

**Observations:**
- [ ] All buttons easy to tap
- [ ] No accidental adjacent taps reported
- [ ] Users comfortable with button sizes
- [ ] No user complaints about "hard to tap" elements

**User Feedback:**
```
[Collect qualitative feedback on button sizes and tap accuracy]
```

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document any usability issues with touch targets]
```

---

## Part 8: Device-Specific Features Testing

### TEST-DSF-001: Notch/Dynamic Island Compatibility (iOS)
**Priority:** P1
**Device:** iPhone 14 Pro/15 Pro (with Dynamic Island)
**OS:** iOS 16+

**Test Steps:**
1. Launch Discovery page on device with notch/Dynamic Island
2. Observe content positioning
3. Test with active Live Activities (if applicable)

**Expected Results:**
- [ ] Content not obscured by notch/Dynamic Island
- [ ] Top app bar (if present) adapts to safe area
- [ ] Status bar info visible
- [ ] No layout clipping at top of screen

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document notch/Dynamic Island layout issues]
```

---

### TEST-DSF-002: Punch-Hole Camera Compatibility (Android)
**Priority:** P1
**Device:** Samsung Galaxy S21+, Pixel 6+ (with punch-hole)
**OS:** Android 10+

**Test Steps:**
1. Launch Discovery page on device with punch-hole camera
2. Observe content positioning

**Expected Results:**
- [ ] Content not obscured by punch-hole
- [ ] Status bar icons position around punch-hole
- [ ] No layout clipping

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document punch-hole compatibility issues]
```

---

### TEST-DSF-003: Foldable Device Support (Fold/Unfold)
**Priority:** P2
**Device:** Samsung Galaxy Z Fold 4/5 or similar
**OS:** Android 12+

**Test Steps:**
1. Open Discovery page in folded state
2. Unfold device while on Discovery page
3. Fold device again

**Expected Results:**
- [ ] Layout adapts smoothly when unfolding (small → tablet layout)
- [ ] Content/state preserved across fold/unfold
- [ ] No crashes during fold/unfold
- [ ] Both layouts (folded/unfolded) usable
- [ ] App continuity maintained

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach both states]
**Notes:**
```
[Document foldable device behavior - this is important for premium devices]
```

---

### TEST-DSF-004: Split-Screen Mode (Multi-Window)
**Priority:** P2
**Device:** [Tablet or large phone with split-screen support]
**OS:** Android 7+ or iPadOS 13+

**Test Steps:**
1. Open HIVMeet Discovery page
2. Enter split-screen mode with another app
3. Resize split-screen divider
4. Test Discovery functionality in split-screen

**Expected Results:**
- [ ] Discovery page adapts to reduced screen space
- [ ] Layout remains usable in split-screen
- [ ] Swipe gestures still work
- [ ] Action buttons accessible
- [ ] No crashes in split-screen mode
- [ ] Layout adjusts when resizing split

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document split-screen behavior]
```

---

### TEST-DSF-005: Picture-in-Picture (PiP) Interaction
**Priority:** P3
**Device:** [Any device with PiP support]

**Test Steps:**
1. If app has video/call features, trigger PiP
2. Navigate to Discovery while PiP active
3. Interact with Discovery

**Expected Results:**
- [ ] PiP doesn't obscure critical Discovery UI
- [ ] Discovery functional with PiP overlay
- [ ] No conflicts between PiP and Discovery interactions

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document PiP interaction if applicable]
```

---

### TEST-DSF-006: Home Indicator Compatibility (iOS)
**Priority:** P1
**Device:** iPhone X or later (no home button)
**OS:** iOS 11+

**Test Steps:**
1. Launch Discovery page
2. Observe bottom UI and home indicator
3. Test swipe-up gesture for home

**Expected Results:**
- [ ] Bottom action buttons not obscured by home indicator
- [ ] Safe area insets respected
- [ ] Swipe-up home gesture doesn't conflict with app gestures
- [ ] Bottom navigation visible above home indicator

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach]
**Notes:**
```
[Document home indicator layout issues]
```

---

### TEST-DSF-007: Haptic Feedback
**Priority:** P2
**Device:** [Devices with haptic engine: iPhone 8+, Android with vibrator]

**Test Steps:**
1. Enable haptics in device settings
2. Perform swipe actions on Discovery page
3. Tap action buttons

**Expected Results:**
- [ ] Haptic feedback occurs on swipe completion (like/dislike/super like)
- [ ] Haptic feedback appropriate intensity (not too strong/weak)
- [ ] Haptic on button taps (optional but nice)
- [ ] Haptic on match found (optional celebratory)
- [ ] User can disable haptics in app settings (if implemented)

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document haptic feedback implementation and quality]
```

---

### TEST-DSF-008: Edge Gesture Compatibility
**Priority:** P1
**Device:** [Android 10+ with gesture navigation, iOS with edge swipes]

**Test Steps:**
1. Enable gesture navigation (Android) or test iOS edge swipes
2. On Discovery page, swipe from left edge (back gesture)
3. Swipe from right edge (if applicable)
4. Test swipe card gestures

**Expected Results:**
- [ ] Edge back gesture works correctly
- [ ] No conflict between edge gestures and card swipes
- [ ] User can distinguish between back swipe and card swipe
- [ ] Card swipes still work reliably with gesture nav enabled

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document gesture navigation compatibility]
```

---

## Part 9: Orientation Testing

### TEST-ORI-001: Portrait Mode (Primary Orientation)
**Priority:** P0
**Device:** [All device categories]

**Test Steps:**
1. Launch Discovery page in portrait mode
2. Test all functionality

**Expected Results:**
- [ ] Discovery page fully functional in portrait
- [ ] Layout optimized for portrait
- [ ] All interactions work correctly

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Portrait is primary orientation - must work flawlessly]
```

---

### TEST-ORI-002: Landscape Mode Support
**Priority:** P1
**Device:** [All device categories, especially tablets]

**Test Steps:**
1. Rotate device to landscape
2. Observe Discovery page layout
3. Test all functionality

**Expected Results:**
- [ ] Discovery page adapts to landscape (may be phone-specific)
- [ ] Layout usable in landscape
- [ ] Swipe card not awkwardly proportioned
- [ ] Action buttons accessible
- [ ] Tablets: landscape layout optimized
- [ ] Phones: landscape acceptable or gracefully handled

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach landscape layout]
**Notes:**
```
[Document landscape support - especially important for tablets]
```

---

### TEST-ORI-003: Rotation Animation
**Priority:** P2
**Device:** [Representative device]

**Test Steps:**
1. Slowly rotate device from portrait to landscape and back
2. Observe layout transition

**Expected Results:**
- [ ] Rotation animation smooth
- [ ] Content repositions correctly
- [ ] No layout glitches during rotation
- [ ] State preserved during rotation

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document rotation transition quality]
```

---

### TEST-ORI-004: Orientation Lock Respect
**Priority:** P2
**Device:** [Any device]

**Test Steps:**
1. Enable orientation lock in device settings
2. Try to rotate device
3. Verify app respects lock

**Expected Results:**
- [ ] App respects device orientation lock
- [ ] Discovery page doesn't force rotation
- [ ] User control over orientation

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document orientation lock behavior]
```

---

### TEST-ORI-005: State Preservation Across Rotation
**Priority:** P1
**Device:** [Any device]

**Test Steps:**
1. On Discovery page, partially swipe a card (don't complete)
2. Rotate device
3. Open filters, rotate device
4. Trigger match modal, rotate device

**Expected Results:**
- [ ] Current profile preserved across rotation
- [ ] Swipe progress reset (acceptable) or preserved
- [ ] Filter selections preserved
- [ ] Modal state preserved

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document state preservation across orientation changes]
```

---

### TEST-ORI-006: Tablet Landscape Optimization
**Priority:** P1
**Device:** [iPad or Android tablet]

**Test Steps:**
1. Use Discovery page on tablet in landscape
2. Compare with portrait layout

**Expected Results:**
- [ ] Landscape layout optimized for wide screen
- [ ] May show two-pane layout (card + details, or card + filters)
- [ ] Uses screen real estate effectively
- [ ] Not just stretched portrait layout

**Issue Found:** [ ] Yes [ ] No
**Screenshot:** [Attach tablet landscape]
**Notes:**
```
[Tablet landscape optimization is important for premium UX]
```

---

## Part 10: Performance Testing Across Devices

### TEST-PERF-001: Low-End Phone Performance
**Priority:** P0
**Device:** [Budget Android phone with 2GB RAM, older processor]
**Example:** Samsung Galaxy A10, Moto G Play

**Test Steps:**
1. Clear app cache and restart app
2. Navigate to Discovery page (cold start)
3. Swipe through 20 profiles rapidly
4. Apply filters multiple times
5. Trigger match modal
6. Background app and return

**Expected Results:**
- [ ] Initial load time < 5 seconds (acceptable for low-end)
- [ ] Swipe animations ≥ 30fps (minimum acceptable)
- [ ] No app crashes or ANR
- [ ] Profile photos load progressively
- [ ] App responsive (not frozen)
- [ ] Memory usage < 150MB
- [ ] Battery drain reasonable

**Performance Metrics:**
- Cold start to Discovery page: [____] seconds
- Animation frame rate: [____] fps (estimate or measure)
- Memory usage (peak): [____] MB
- Crashes/ANR: [ ] Yes [ ] No
- Overall experience: [ ] Good [ ] Acceptable [ ] Poor [ ] Unacceptable

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document performance issues on low-end device - critical for accessibility]
```

---

### TEST-PERF-002: Mid-Range Phone Performance
**Priority:** P0
**Device:** [Mid-range Android or older iPhone]
**Example:** Samsung Galaxy A52, iPhone 11, Pixel 5a

**Test Steps:**
1. Test Discovery page performance
2. Rapid swipes, filters, navigation

**Expected Results:**
- [ ] Initial load < 3 seconds
- [ ] Swipe animations 60fps consistently
- [ ] No frame drops
- [ ] Smooth photo loading
- [ ] Responsive interactions
- [ ] Memory usage < 100MB

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] 60fps [ ] 45-60fps [ ] 30-45fps [ ] <30fps
- Overall: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document mid-range performance]
```

---

### TEST-PERF-003: High-End Phone Performance
**Priority:** P1
**Device:** [Flagship Android or latest iPhone]
**Example:** Samsung Galaxy S23, iPhone 15 Pro, Pixel 8 Pro

**Test Steps:**
1. Test Discovery page performance
2. Verify optimal experience

**Expected Results:**
- [ ] Initial load < 2 seconds
- [ ] 60fps animations consistently
- [ ] Instant photo loading
- [ ] Buttery smooth interactions
- [ ] Memory usage < 80MB

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] Flawless 60fps [ ] Occasional drops [ ] Inconsistent
- Overall: [ ] Excellent [ ] Good

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document flagship performance - should be excellent]
```

---

### TEST-PERF-004: Tablet Performance
**Priority:** P1
**Device:** [iPad or Android tablet]

**Test Steps:**
1. Test Discovery page performance on tablet

**Expected Results:**
- [ ] Load time < 3 seconds
- [ ] 60fps animations
- [ ] High-res photos load smoothly
- [ ] Responsive
- [ ] Memory usage < 120MB

**Performance Metrics:**
- Load time: [____] seconds
- Animation quality: [ ] Excellent [ ] Good [ ] Acceptable
- Overall: [ ] Excellent [ ] Good [ ] Acceptable

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document tablet performance]
```

---

### TEST-PERF-005: Memory Leak Test
**Priority:** P1
**Device:** [Any device with profiling tools]

**Test Steps:**
1. Connect device to Flutter DevTools or Xcode Instruments
2. Launch Discovery page
3. Swipe through 100 profiles
4. Navigate away and back to Discovery multiple times
5. Monitor memory usage

**Expected Results:**
- [ ] Memory usage increases initially then stabilizes
- [ ] No continuous memory growth (leak indicator)
- [ ] Memory released when leaving Discovery page
- [ ] No OutOfMemory crashes

**Memory Profile:**
- Initial memory: [____] MB
- After 100 swipes: [____] MB
- After 10 navigate-aways: [____] MB
- Memory leak detected: [ ] Yes [ ] No

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document memory usage patterns and potential leaks]
```

---

### TEST-PERF-006: Photo Loading Performance
**Priority:** P1
**Device:** [Representative device]

**Test Steps:**
1. Observe profile photo loading behavior
2. Test on slow network (throttle to 3G)
3. Test on fast network (Wi-Fi)

**Expected Results:**
- [ ] Placeholder images shown immediately
- [ ] Progressive loading (low-res → high-res)
- [ ] Photos cached locally after first load
- [ ] No blocking of UI while photos load
- [ ] Graceful handling of failed photo loads

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document photo loading strategy and performance]
```

---

### TEST-PERF-007: Rapid Interaction Stress Test
**Priority:** P1
**Device:** [Any device]

**Test Steps:**
1. On Discovery page, swipe profiles as fast as possible for 30 seconds
2. Rapidly tap action buttons
3. Quickly open/close filters multiple times
4. Observe app behavior

**Expected Results:**
- [ ] App remains responsive
- [ ] No crashes or freezes
- [ ] Animations may degrade gracefully under stress
- [ ] No duplicate API calls (proper debouncing)
- [ ] No ANR or "app not responding" dialog

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document behavior under rapid interaction stress]
```

---

### TEST-PERF-008: Battery Impact Test
**Priority:** P2
**Device:** [Physical device]

**Test Steps:**
1. Fully charge device
2. Use Discovery page for 15 minutes continuously
3. Note battery percentage before/after

**Expected Results:**
- [ ] Battery drain ≤ 5% for 15 minutes of use (acceptable)
- [ ] Device doesn't get excessively hot
- [ ] Battery usage reasonable compared to other apps

**Battery Metrics:**
- Battery before: [____]%
- Battery after 15 min: [____]%
- Battery drain: [____]%
- Device temperature: [ ] Normal [ ] Warm [ ] Hot

**Issue Found:** [ ] Yes [ ] No
**Notes:**
```
[Document battery impact - important for user satisfaction]
```

---

## Test Completion Checklist

### Device Coverage Sign-Off
- [ ] At least 3 different phone screen sizes tested (small, medium, large)
- [ ] At least 1 tablet tested
- [ ] Android 8.0 (minimum version) tested
- [ ] iOS 13 (minimum version) tested
- [ ] Latest Android version tested
- [ ] Latest iOS version tested
- [ ] Both portrait and landscape orientations tested
- [ ] At least 1 low-end device tested for performance

### Touch Target Compliance
- [ ] All action buttons ≥ 44x44 dp on all devices (MANDATORY)
- [ ] Filter controls ≥ 44x44 dp
- [ ] Navigation tabs ≥ 44x44 dp
- [ ] Modal buttons ≥ 44x44 dp
- [ ] No critical accessibility violations found

### Layout and Responsiveness
- [ ] Small phones: Layout functional, no clipping
- [ ] Medium phones: Layout optimized
- [ ] Large phones: Layout takes advantage of screen size
- [ ] Tablets: Layout adapted for large screen
- [ ] All orientations: Layout adapts correctly

### Device-Specific Features
- [ ] Notch/punch-hole compatibility verified
- [ ] Foldable device support tested (if available)
- [ ] Split-screen mode works
- [ ] Haptic feedback working
- [ ] Gesture navigation compatible

### Performance
- [ ] Low-end device performance acceptable
- [ ] Mid-range device performance good
- [ ] High-end device performance excellent
- [ ] No memory leaks detected
- [ ] Battery impact reasonable

### Critical Issues
- [ ] No critical issues blocking release
- [ ] All P0 issues resolved or documented with workaround
- [ ] P1 issues documented for post-release fix

---

## Issue Tracking Template

**Issue ID:** [DRT-###]
**Test Case:** [TEST-XX-###]
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low
**Device:** [Device name, OS version]
**Screen Size:** [e.g., Small Phone, Tablet]

**Description:**
```
[Clear description of the issue]
```

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
```
[What should happen]
```

**Actual Result:**
```
[What actually happens]
```

**Screenshot/Video:**
[Attach evidence]

**Frequency:**
[ ] Always [ ] Sometimes [ ] Rarely

**Workaround:**
```
[If any workaround exists]
```

**Recommended Fix:**
```
[If applicable]
```

---

## QA Sign-Off

**QA Tester:** [Name]
**Date:** [Date]
**Total Tests Executed:** [____] / 88
**Tests Passed:** [____]
**Tests Failed:** [____]
**Critical Issues:** [____]
**High Issues:** [____]
**Medium Issues:** [____]
**Low Issues:** [____]

**Device Testing Status:**
- [ ] Small phone testing complete
- [ ] Medium phone testing complete
- [ ] Large phone testing complete
- [ ] Tablet testing complete
- [ ] Android OS version testing complete
- [ ] iOS version testing complete
- [ ] Touch target validation complete (all devices ≥ 44x44 dp)
- [ ] Device-specific features tested
- [ ] Orientation testing complete
- [ ] Performance testing complete

**Overall Assessment:**
[ ] Ready for production release
[ ] Ready with minor issues documented
[ ] Requires fixes before release
[ ] Significant issues - major revision needed

**Recommendation:**
```
[QA recommendation for release readiness]
```

**Sign-Off:** ___________________ **Date:** ___________

---

## Appendix A: Device Specification Reference

### How to Determine Device Screen Size Category

**Small Phone:** Width < 360dp
- Typically 4.7"-5.5" diagonal
- Resolutions: 640x960, 720x1280, 750x1334
- Examples: iPhone SE, budget Android phones

**Medium Phone:** Width 360-410dp
- Typically 5.5"-6.2" diagonal
- Resolutions: 1080x2340, 1080x2400, 1170x2532
- Examples: Most modern mid-range phones

**Large Phone:** Width > 410dp
- Typically 6.5"-6.8" diagonal
- Resolutions: 1440x3088, 1290x2796
- Examples: Pro Max iPhones, Ultra Androids

**Tablet:** Width > 600dp
- Typically 7"-13" diagonal
- Resolutions: 1200x1920, 1620x2160, 2048x2732
- Examples: iPads, Galaxy Tabs

### How to Check Screen Dimensions

**Android:**
1. Go to Settings → About Phone → Software Information
2. Or use command: `adb shell wm size` (shows pixels)
3. Convert pixels to dp: `dp = pixels / (dpi / 160)`
4. Or use Android Studio Device Manager for specs

**iOS:**
1. Check device model and look up specs online
2. iOS doesn't expose dp directly, use point measurements
3. Refer to Apple's Human Interface Guidelines for device dimensions

---

## Appendix B: Touch Target Measurement Tools

### Android - Pointer Location
1. Settings → About Phone → Tap "Build Number" 7 times (enable Developer Options)
2. Settings → Developer Options → Pointer Location (toggle ON)
3. Touch targets shown as crosshairs when tapping

### Android - Layout Inspector (Android Studio)
1. Connect device via USB
2. Android Studio → Tools → Layout Inspector
3. Select running HIVMeet app
4. Click elements to see dimensions in dp

### iOS - Accessibility Inspector (Xcode)
1. Xcode → Open Developer Tool → Accessibility Inspector
2. Select device/simulator
3. Use inspection mode to measure elements

### Physical Ruler Method
1. Measure button size in mm on screen
2. Convert to dp using device pixel density
3. Formula: `dp = mm * (dpi / 160) / 25.4`

---

## Appendix C: Performance Measurement Tools

### Flutter DevTools
- Run `flutter run --release`
- Open DevTools in browser
- Monitor: Memory, Performance (FPS), Network

### Android Profiler (Android Studio)
- Tools → Android Profiler
- Monitor: CPU, Memory, Network, Battery

### Xcode Instruments (iOS)
- Xcode → Open Developer Tool → Instruments
- Select: Time Profiler, Allocations, Core Animation

---

## Appendix D: Recommended Test Devices (Budget-Friendly Options)

If full device coverage is cost-prohibitive, prioritize:

**Minimum Test Set (5 devices):**
1. **Small Phone:** iPhone SE (2020/2022) - iOS minimum, small screen
2. **Medium Android:** Samsung Galaxy A52/A53 - Popular mid-range
3. **Large Android:** OnePlus Nord or Pixel 6a - Large screen, good specs
4. **Tablet:** iPad (9th gen) or Samsung Tab A7 - Tablet validation
5. **Low-End:** Budget Android (Moto G Play, Galaxy A12) - Performance floor

**Ideal Test Set (8 devices):**
- Add: iPhone 14 (medium iOS), Samsung S21 (flagship Android), iPad Pro (large tablet)

---

**END OF DEVICE AND RESPONSIVE DESIGN TESTING GUIDE**

---

**Document Version:** 1.0
**Last Updated:** 2026-02-27
**Total Test Cases:** 88
**Estimated Testing Time:** 12-16 hours (full execution)
**Priority:** P0 (Critical for QA sign-off)

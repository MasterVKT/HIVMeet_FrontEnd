# Manual Accessibility Testing Guide - Discovery Page
## HIVMeet - Task 7.3: Test Accessibility with Assistive Technologies

**Version:** 1.0
**Date:** 2026-02-27
**Tester:** [To be filled]
**Device:** [To be filled]
**OS Version:** [To be filled]
**App Version:** [To be filled]
**Test Environment:** [Debug/Profile/Release]

---

## Overview

This manual accessibility testing guide covers comprehensive testing of the Discovery page with assistive technologies and accessibility features following **WCAG 2.1 Level AA** guidelines. This testing complements the automated accessibility tests in `test/accessibility/`.

**Why Manual Testing is Essential:**
- Automated tests verify technical implementation (contrast ratios, touch targets, semantic labels)
- Manual testing validates real-world user experience with assistive technologies
- Screen readers require human verification of announcement quality and navigation flow
- Gesture and interaction patterns need subjective assessment

**Testing Scope:**
1. Screen reader testing (TalkBack on Android, VoiceOver on iOS)
2. Keyboard navigation (desktop/web if applicable, limited on mobile)
3. High contrast mode
4. Large fonts and text scaling
5. Reduced motion
6. Color blindness simulation
7. Touch target adequacy

---

## Test Execution Summary

| Category | Total Tests | Passed | Failed | Blocked | Notes |
|----------|-------------|--------|--------|---------|-------|
| Screen Reader (TalkBack) | 15 | - | - | - | - |
| Screen Reader (VoiceOver) | 15 | - | - | - | - |
| Keyboard Navigation | 5 | - | - | - | - |
| High Contrast Mode | 6 | - | - | - | - |
| Large Fonts/Text Scaling | 8 | - | - | - | - |
| Reduced Motion | 5 | - | - | - | - |
| Color Blindness | 4 | - | - | - | - |
| Touch Targets | 6 | - | - | - | - |
| **TOTAL** | **64** | **-** | **-** | **-** | **-** |

---

## Prerequisites

### Test Devices Required
- **Android Device** (API 30+) with TalkBack enabled
- **iOS Device** (iOS 13+) with VoiceOver enabled
- **Variety of screen sizes**: Small phone, large phone, tablet (if supported)

### Test Accounts
- **Free user account**: To test daily limit accessibility
- **Premium user account**: To test premium feature announcements

### Preparation Checklist
- [ ] Install latest app version on test devices
- [ ] Familiarize yourself with TalkBack/VoiceOver basic gestures
- [ ] Ensure device battery is charged (screen readers drain faster)
- [ ] Test in quiet environment (for audio feedback verification)
- [ ] Have contrast analyzer tool ready (optional but recommended)
- [ ] Prepare issue tracking system (screenshots, recordings)

---

## Part 1: Screen Reader Testing - TalkBack (Android)

### Enabling TalkBack

**Steps:**
1. Go to **Settings → Accessibility → TalkBack**
2. Toggle **Use TalkBack** to ON
3. Complete the tutorial if first time using
4. Adjust TalkBack settings:
   - **Speech rate**: Medium (adjust if needed)
   - **Verbosity**: Default
   - **Audio ducking**: ON (reduces media volume during announcements)

**TalkBack Basic Gestures:**
- **Swipe right**: Navigate to next element
- **Swipe left**: Navigate to previous element
- **Double-tap**: Activate selected element
- **Swipe down then right**: Navigate to next reading control (headings, links, etc.)
- **Two-finger swipe down**: Read from top
- **Two-finger swipe up**: Read from current position
- **Three-finger swipe left/right**: Navigate between pages

---

### TEST-SR-TB-001: Discovery Page Initial Load Announcement
**Priority:** P0
**WCAG:** 1.3.1 Info and Relationships, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- User logged in
- Navigate to Discovery page for first time

**Steps:**
1. With TalkBack enabled, navigate to Discovery page from another tab
2. Listen to the initial announcement
3. Swipe right to hear all elements announced in order

**Expected Result:**
- TalkBack announces: "Discovery page" or "HIVMeet Discovery"
- First element announced is the app bar with "HIVMeet" logo
- Filters button in app bar is announced with label: "Ouvrir les filtres de recherche, Button"
- Profile card is announced next with comprehensive description
- All navigation elements (bottom nav) are announced with correct labels
- Announcement order is logical (top to bottom, left to right)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-002: Profile Card Comprehensive Description
**Priority:** P0
**WCAG:** 1.1.1 Non-text Content, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- At least one profile loaded on Discovery page

**Steps:**
1. Focus on the profile card (should auto-focus or swipe to it)
2. Listen to the complete announcement
3. Verify all profile information is announced

**Expected Result:**
TalkBack announces (in order):
1. Profile name: "Alice"
2. Age: "28 ans"
3. Distance: "à 3 kilomètres"
4. Online status (if applicable): "En ligne maintenant" OR "Active il y a X heures"
5. Verification badge (if verified): "Profil vérifié"
6. Premium badge (if premium): "Membre premium"
7. Compatibility score: "85% de compatibilité"
8. Bio excerpt (truncated to ~100 characters): "Passionnée de randonnée..."
9. Interaction hint: "Balayez à gauche pour passer, à droite pour aimer"

**Quality Checks:**
- Announcement is clear and not cluttered
- Information is in a logical, understandable order
- No redundant or confusing information
- Essential details are not omitted
- Announcement completes in reasonable time (<10 seconds)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-003: Photo Carousel Navigation
**Priority:** P1
**WCAG:** 2.4.6 Headings and Labels, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- Profile with multiple photos loaded (3+ photos)

**Steps:**
1. Focus on profile card
2. Swipe right to navigate to photo indicators/carousel controls
3. Listen for photo navigation announcements
4. Attempt to navigate between photos using TalkBack gestures

**Expected Result:**
- Photo pagination indicators are announced: "Photo 1 sur 4"
- Swipe gestures on photo area announce: "Balayez horizontalement pour voir plus de photos"
- Each photo transition is announced: "Photo 2 sur 4", "Photo 3 sur 4"
- Photo navigation is intuitive and doesn't interfere with profile card swiping

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-004: Action Buttons Announcement
**Priority:** P0
**WCAG:** 1.1.1 Non-text Content, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- Discovery page with profile loaded

**Steps:**
1. Swipe right from profile card to navigate to action buttons
2. Focus on each button (dislike, like, super like, rewind)
3. Listen to announcements for each button
4. Verify premium status is announced for restricted features

**Expected Result:**
Each button announces clearly:
- **Dislike button**: "Passer ce profil, Button" (with red X icon description)
- **Like button**: "Aimer ce profil, Button" (with green heart icon description)
- **Super Like button**: "Super like ce profil, fonctionnalité premium, Button" (with star icon)
- **Rewind button** (if premium): "Annuler la dernière action, Button" OR (if free user): "Annuler la dernière action, fonctionnalité premium verrouillée, Button"

**Quality Checks:**
- Button purpose is clear from announcement alone
- Premium status is explicitly announced
- Icons are described or implied in announcement
- Disabled state is announced if applicable

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-005: Swipe Gesture Execution with TalkBack
**Priority:** P0
**WCAG:** 2.1.1 Keyboard Accessible (gesture alternatives)

**Preconditions:**
- TalkBack enabled
- Profile loaded on Discovery page

**Steps:**
1. Focus on action buttons (not profile card directly, as direct swipe won't work with TalkBack)
2. Double-tap on "Like" button
3. Observe and listen to announcement
4. Repeat with "Dislike" button on next profile

**Expected Result:**
- Double-tapping action buttons successfully triggers like/dislike action
- TalkBack announces action result: "Profil aimé" or "Profil passé"
- Next profile loads smoothly
- Screen reader announces new profile automatically
- No confusion or conflicting gestures

**Note:** Direct swipe gestures on profile card are not accessible with TalkBack enabled. Action buttons provide the alternative as required by WCAG.

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-006: Match Found Modal Announcement
**Priority:** P0
**WCAG:** 4.1.3 Status Messages, 1.3.1 Info and Relationships

**Preconditions:**
- TalkBack enabled
- Like a profile that already liked you (to trigger match)

**Steps:**
1. Trigger a match by liking a mutual profile
2. Listen for match modal announcement
3. Navigate through modal elements with TalkBack
4. Verify action buttons are announced

**Expected Result:**
- **Immediate announcement**: "C'est un match ! Vous vous êtes mutuellement aimés" (announced automatically as a live region)
- Modal is focused automatically (not stuck on previous screen)
- Both profile photos are announced: "Votre photo" and "[Match name]'s photo"
- **Send Message button**: "Envoyer un message, Button"
- **Keep Swiping button**: "Continuer à découvrir, Button"
- Close/dismiss option is announced: "Fermer, Button" or "Double-tap to dismiss"

**Quality Checks:**
- Match announcement is celebratory but not overwhelming
- User understands what happened without visual context
- Navigation through modal is logical
- Dismissing modal is clear and accessible

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-007: Filters Page Navigation
**Priority:** P1
**WCAG:** 2.4.6 Headings and Labels, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- On Discovery page

**Steps:**
1. Navigate to filters button in app bar
2. Double-tap to open filters page
3. Swipe through all filter controls
4. Listen to each element's announcement

**Expected Result:**
- **Page title**: "Filtres de recherche" announced
- **Age range slider**: "Tranche d'âge, de 25 à 35 ans, Slider" (announces current values)
  - Adjusting slider announces new values dynamically
- **Distance slider**: "Distance maximale, 50 kilomètres, Slider"
  - Adjusting announces: "60 kilomètres", "70 kilomètres", etc.
- **Verified profiles toggle**: "Profils vérifiés uniquement, désactivé, Switch" or "activé"
  - State (on/off) is clearly announced
- **Online profiles toggle**: "Uniquement les personnes en ligne, désactivé, Switch" (with premium indicator if locked)
- **Apply button**: "Appliquer les filtres, Button"
- **Clear filters button**: "Réinitialiser les filtres, Button"

**Quality Checks:**
- All controls are focusable and operable
- Current values are announced before interaction
- Changes are announced in real-time
- Premium restrictions are announced
- Estimated profile count (if present) is announced

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-008: Daily Limit Reached Announcement
**Priority:** P1
**WCAG:** 4.1.3 Status Messages, 3.3.1 Error Identification

**Preconditions:**
- TalkBack enabled
- Free user account at or near daily like limit (50 likes)

**Steps:**
1. Swipe profiles until daily limit is reached
2. Attempt to like the 51st profile
3. Listen for limit announcement
4. Navigate through upgrade modal

**Expected Result:**
- **Before limit**: Counter announcement when focused: "8 likes restants aujourd'hui"
- **At limit**: Immediate announcement: "Limite quotidienne atteinte. Passez à Premium pour des likes illimités"
- Like button announces disabled state: "Aimer ce profil, désactivé, Button"
- Upgrade modal is announced: "Passez à Premium"
- Modal action buttons are accessible and clear

**Quality Checks:**
- User understands why action is blocked
- Limit context is explained (daily, resets at midnight)
- Upgrade path is clear but not pushy
- User can dismiss modal and continue with dislike action

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-009: Error States Announcement
**Priority:** P1
**WCAG:** 3.3.1 Error Identification, 4.1.3 Status Messages

**Preconditions:**
- TalkBack enabled
- Simulate error conditions (network off, API error)

**Steps:**
1. Turn off device network connectivity
2. Navigate to Discovery page or attempt to swipe
3. Listen for error announcement
4. Verify retry option is accessible

**Expected Result:**
- **Network error**: "Erreur de connexion. Vérifiez votre connexion Internet, Retry button available"
- **No profiles error**: "Aucun profil disponible. Ajustez vos filtres pour voir plus de personnes"
- **API error**: "Une erreur est survenue. Veuillez réessayer"
- **Retry button**: "Réessayer, Button" is announced and accessible
- Error announcement is not aggressive but clear

**Quality Checks:**
- Error is announced automatically (live region)
- User understands what went wrong
- Recovery action is clear
- Announcement doesn't loop or repeat excessively

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-010: Empty State Announcement
**Priority:** P2
**WCAG:** 1.3.1 Info and Relationships, 4.1.3 Status Messages

**Preconditions:**
- TalkBack enabled
- User has swiped through all available profiles (or has very restrictive filters)

**Steps:**
1. Swipe until no more profiles available
2. Listen for empty state announcement
3. Verify suggestions/actions are accessible

**Expected Result:**
- Announcement: "Plus de profils disponibles. Revenez plus tard ou ajustez vos filtres"
- Illustration (if present) has alt text: "No profiles illustration"
- **Adjust Filters button**: "Modifier les filtres, Button"
- **Expand Search button** (if applicable): "Élargir la zone de recherche, Button"

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-011: Bottom Navigation Announcement
**Priority:** P0
**WCAG:** 2.4.1 Bypass Blocks, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- On Discovery page

**Steps:**
1. Swipe through elements until reaching bottom navigation
2. Listen to each navigation item announcement
3. Verify selected state is announced

**Expected Result:**
Each bottom nav item announces:
- **Discovery**: "Découverte, sélectionné, onglet 1 sur 4" (when on Discovery page)
- **Matches**: "Matchs, onglet 2 sur 4"
- **Messages**: "Messages, onglet 3 sur 4" (with badge count if applicable: "3 nouveaux messages")
- **Profile**: "Profil, onglet 4 sur 4"

**Quality Checks:**
- Selected state is clearly announced
- Icon labels are descriptive
- Badge counts are announced (for Messages/Matches)
- Navigation is logical and predictable

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-012: Rewind Action Announcement
**Priority:** P1
**WCAG:** 4.1.2 Name, Role, Value, 4.1.3 Status Messages

**Preconditions:**
- TalkBack enabled
- Premium user account OR free user (to test locked state)

**Steps:**
1. Swipe a profile (like or dislike)
2. Focus on Rewind button
3. Double-tap to execute rewind
4. Listen to announcement

**Expected Result:**
- **Premium user**:
  - Button: "Annuler la dernière action, Button"
  - After activation: "Action annulée. Profil précédent restauré"
  - Previous profile reappears
- **Free user**:
  - Button: "Annuler la dernière action, fonctionnalité premium verrouillée, Button"
  - After tap: "Cette fonctionnalité est réservée aux membres Premium. Passez à Premium pour l'utiliser"

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-013: Super Like Confirmation Dialog
**Priority:** P1
**WCAG:** 3.3.4 Error Prevention, 4.1.2 Name, Role, Value

**Preconditions:**
- TalkBack enabled
- Premium user with super likes remaining

**Steps:**
1. Focus on Super Like button (star)
2. Double-tap to activate
3. Listen for confirmation dialog announcement
4. Navigate through dialog options

**Expected Result:**
- **Confirmation dialog**: "Utiliser un Super Like ? Il vous reste 3 Super Likes aujourd'hui"
- **Confirm button**: "Confirmer, Button"
- **Cancel button**: "Annuler, Button"
- After confirmation: "Super Like envoyé à [Name]"
- Counter updates: "2 Super Likes restants"

**Quality Checks:**
- Confirmation prevents accidental activation
- Remaining count is announced
- Both options (confirm/cancel) are clearly announced
- Dialog can be dismissed easily

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-014: Haptic Feedback (Non-Audio Verification)
**Priority:** P2
**WCAG:** 1.3.3 Sensory Characteristics

**Preconditions:**
- TalkBack enabled
- Device haptic feedback enabled in settings

**Steps:**
1. Swipe a profile using action buttons
2. Feel for haptic feedback on interaction
3. Verify announcements accompany haptic feedback

**Expected Result:**
- Haptic feedback occurs on swipe action (light vibration)
- TalkBack announcement confirms action: "Profil aimé" or "Profil passé"
- Haptic feedback enhances experience but is not sole indicator of action
- Action is still understandable without haptic feedback

**Note:** WCAG requires that information conveyed through sensory characteristics (sound, haptic, color) is also available through other means (announcements, labels).

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-SR-TB-015: Overall Navigation Flow Quality
**Priority:** P0
**WCAG:** 2.4.3 Focus Order, 2.4.7 Focus Visible

**Preconditions:**
- TalkBack enabled
- Complete user journey on Discovery page

**Steps:**
1. Navigate entire Discovery page from top to bottom using TalkBack
2. Verify logical reading order
3. Test tab navigation if keyboard connected
4. Verify focus doesn't get trapped

**Expected Result:**
- **Reading order**: App bar → Profile card → Action buttons → Limit counter (if visible) → Bottom navigation
- Focus moves logically (top to bottom, left to right)
- No elements are skipped or unreachable
- No focus traps (can always navigate away)
- Modals/dialogs trap focus appropriately but can be dismissed
- Focus returns to logical element after modal dismissal

**Quality Checks:**
- Navigation feels natural and predictable
- User can explore entire page without confusion
- All interactive elements are reachable
- No dead ends or circular navigation issues

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## Part 2: Screen Reader Testing - VoiceOver (iOS)

### Enabling VoiceOver

**Steps:**
1. Go to **Settings → Accessibility → VoiceOver**
2. Toggle **VoiceOver** to ON
3. Complete tutorial if first time using
4. Adjust settings:
   - **Speaking Rate**: 50% (adjust to preference)
   - **Verbosity**: Medium
   - **Speech**: Adjust pitch/volume if needed

**VoiceOver Basic Gestures:**
- **Swipe right**: Navigate to next element
- **Swipe left**: Navigate to previous element
- **Double-tap**: Activate selected element
- **Two-finger tap**: Pause/resume speaking
- **Three-finger swipe up/down**: Scroll
- **Rotor** (two-finger rotate): Change navigation mode (headings, links, form controls)

---

### TEST-SR-VO-001 to TEST-SR-VO-015

**Instructions:** Repeat all 15 tests from TalkBack section (TEST-SR-TB-001 to TEST-SR-TB-015) using VoiceOver on iOS device.

**Key Differences to Note:**
- VoiceOver gestures differ slightly from TalkBack
- Announcement phrasing may vary (e.g., "Button" vs "button")
- Rotor functionality for navigation modes
- VoiceOver typically announces punctuation differently
- iOS-specific UI elements (e.g., navigation bars) may have different announcement patterns

**Comparison Matrix:**

| Test Case | TalkBack (Android) | VoiceOver (iOS) | Differences Noted |
|-----------|-------------------|-----------------|-------------------|
| TEST-SR-VO-001 | [Status] | [Status] | [Notes] |
| TEST-SR-VO-002 | [Status] | [Status] | [Notes] |
| ... | ... | ... | ... |
| TEST-SR-VO-015 | [Status] | [Status] | [Notes] |

**Expected Cross-Platform Consistency:**
- Semantic labels should be identical or functionally equivalent
- All interactive elements accessible on both platforms
- Information conveyed should be the same
- Minor differences in announcement phrasing are acceptable if meaning is preserved

**Actual Results:** [To be filled for each test]

---

## Part 3: Keyboard Navigation Testing

### TEST-KB-001: Tab Navigation Through Interactive Elements
**Priority:** P2
**WCAG:** 2.1.1 Keyboard, 2.4.3 Focus Order

**Note:** Full keyboard navigation is primarily for web/desktop apps. On mobile, external keyboard support is limited but should be tested if available.

**Preconditions:**
- Physical or Bluetooth keyboard connected to device
- On Discovery page

**Steps:**
1. Connect keyboard to mobile device
2. Press Tab key repeatedly
3. Observe focus indicator movement
4. Verify all interactive elements are reachable

**Expected Result:**
- Tab key moves focus through interactive elements in logical order:
  1. Filters button (app bar)
  2. Profile card (if interactive/tappable for details)
  3. Dislike button
  4. Like button
  5. Super Like button
  6. Rewind button
  7. Bottom navigation items (Discovery, Matches, Messages, Profile)
- Focus indicator is clearly visible (outline, highlight, or system default)
- Shift+Tab navigates backward
- No keyboard traps

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A (mobile only)
**Issues Found:**

---

### TEST-KB-002: Enter/Space Key Activation
**Priority:** P2
**WCAG:** 2.1.1 Keyboard

**Preconditions:**
- Keyboard connected
- Focus on interactive element

**Steps:**
1. Tab to Like button
2. Press Enter or Space key
3. Verify action is triggered
4. Repeat for other buttons

**Expected Result:**
- Enter key activates focused button (same as tap)
- Space key also activates button (standard behavior)
- Action result is same as touch interaction
- Focus moves appropriately after activation

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A
**Issues Found:**

---

### TEST-KB-003: Escape Key to Dismiss Modals
**Priority:** P2
**WCAG:** 2.1.1 Keyboard

**Preconditions:**
- Keyboard connected
- Modal dialog open (match modal, upgrade modal, etc.)

**Steps:**
1. Open match found modal
2. Press Escape key
3. Verify modal dismisses
4. Repeat for other modals

**Expected Result:**
- Escape key dismisses modal
- Focus returns to element that triggered modal (or logical alternative)
- Page state is preserved correctly

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A
**Issues Found:**

---

### TEST-KB-004: Arrow Keys for Slider Adjustment
**Priority:** P3
**WCAG:** 2.1.1 Keyboard

**Preconditions:**
- Keyboard connected
- Filters page open

**Steps:**
1. Tab to age range slider
2. Press Left/Right arrow keys
3. Observe slider value changes

**Expected Result:**
- Left arrow decreases value
- Right arrow increases value
- Value changes are announced (if screen reader active)
- Slider can reach min and max values

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A
**Issues Found:**

---

### TEST-KB-005: No Keyboard Traps
**Priority:** P1
**WCAG:** 2.1.2 No Keyboard Trap

**Preconditions:**
- Keyboard connected
- Navigate through entire Discovery page

**Steps:**
1. Tab through all interactive elements on Discovery page
2. Open and dismiss modals using keyboard
3. Navigate to filters and back using keyboard
4. Verify you can always navigate away from any element

**Expected Result:**
- Focus never gets stuck on any element
- All modals can be dismissed with keyboard (Tab to close button, or Escape key)
- Can always reach browser/app controls or navigation
- Shift+Tab can reverse direction at any point

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked [ ] N/A
**Issues Found:**

---

## Part 4: High Contrast Mode Testing

### Enabling High Contrast Mode

**Android:**
1. Settings → Accessibility → Visibility enhancements → High contrast fonts
2. Settings → Developer options → Simulate color space → Monochromacy (for extreme test)

**iOS:**
1. Settings → Accessibility → Display & Text Size → Increase Contrast
2. Settings → Accessibility → Display & Text Size → Reduce Transparency

---

### TEST-HC-001: Text Contrast in High Contrast Mode
**Priority:** P1
**WCAG:** 1.4.3 Contrast (Minimum), 1.4.6 Contrast (Enhanced)

**Preconditions:**
- High contrast mode enabled
- On Discovery page

**Steps:**
1. Enable high contrast mode
2. Navigate to Discovery page
3. Inspect all text elements (profile name, age, distance, bio, labels)
4. Verify text is clearly visible

**Expected Result:**
- All text remains readable
- Contrast ratios remain above 4.5:1 minimum (7:1 for AAA)
- No text becomes invisible or extremely difficult to read
- Text doesn't blend with background
- Badge text (verified, premium, online) is visible

**Manual Contrast Check:**
- Use color picker to sample foreground and background colors
- Use contrast analyzer tool to verify ratio
- Document any elements that fail

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-HC-002: Button Visibility in High Contrast Mode
**Priority:** P1
**WCAG:** 1.4.11 Non-text Contrast

**Preconditions:**
- High contrast mode enabled

**Steps:**
1. Observe all action buttons (like, dislike, super like, rewind)
2. Verify button boundaries and icons are visible
3. Check disabled state visibility

**Expected Result:**
- Button outlines/borders are clearly visible (3:1 contrast minimum)
- Icon graphics remain distinguishable
- Button fill colors maintain sufficient contrast
- Disabled buttons are visually distinct from enabled
- Touch targets remain clear

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-HC-003: Badge and Indicator Visibility
**Priority:** P1
**WCAG:** 1.4.11 Non-text Contrast

**Preconditions:**
- High contrast mode enabled
- Profile with verified, premium, and online badges visible

**Steps:**
1. Observe verified badge (blue checkmark)
2. Observe premium badge (gold star)
3. Observe online indicator (green dot)
4. Verify all are distinguishable

**Expected Result:**
- Badge background colors maintain contrast with card background
- Badge icons remain visible (checkmark, star, dot)
- Badge borders (if any) are visible
- Badges don't disappear or become illegible

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-HC-004: Swipe Overlay Visibility
**Priority:** P2
**WCAG:** 1.4.3 Contrast (Minimum)

**Preconditions:**
- High contrast mode enabled

**Steps:**
1. Swipe a profile partially (don't complete)
2. Observe the overlay color (green for like, red for dislike, blue for super like)
3. Verify overlay text is visible ("LIKE", "NOPE", "SUPER LIKE")

**Expected Result:**
- Overlay color is visible over profile photo
- Text on overlay maintains minimum 4.5:1 contrast
- User can distinguish overlay meaning from color or text alone

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-HC-005: Compatibility Score Visibility
**Priority:** P2
**WCAG:** 1.4.3 Contrast (Minimum)

**Preconditions:**
- High contrast mode enabled
- Profile with compatibility score visible

**Steps:**
1. Observe compatibility score indicator (percentage with heart icon)
2. Verify text and icon are visible
3. Check if color-coding (if any) is supplemented by other cues

**Expected Result:**
- Percentage text is clearly readable
- Heart icon is visible
- If color indicates score level (high/medium/low), shape or label also indicates this
- Contrast ratio meets minimum 4.5:1

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-HC-006: Dark Mode + High Contrast Combination
**Priority:** P2
**WCAG:** 1.4.3 Contrast (Minimum)

**Preconditions:**
- Dark mode enabled (system-wide)
- High contrast mode enabled
- On Discovery page

**Steps:**
1. Enable both dark mode and high contrast
2. Navigate Discovery page
3. Verify all elements remain visible and readable

**Expected Result:**
- Text contrast remains above 4.5:1 on dark backgrounds
- UI elements don't disappear or become invisible
- High contrast adjustments apply correctly to dark theme
- No white text on white backgrounds or black on black

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## Part 5: Large Fonts and Text Scaling Testing

### Enabling Large Fonts

**Android:**
1. Settings → Display → Font size → Largest
2. Settings → Display → Display size → Largest

**iOS:**
1. Settings → Display & Text Size → Text Size → Drag slider to maximum
2. Settings → Display & Text Size → Larger Text → Enable + max slider
3. Settings → Accessibility → Display & Text Size → Larger Text → Enable (up to 310%)

---

### TEST-LF-001: Profile Card Layout at Maximum Text Size
**Priority:** P1
**WCAG:** 1.4.4 Resize Text, 1.4.10 Reflow

**Preconditions:**
- Text size set to maximum (200% or higher)
- On Discovery page with profile loaded

**Steps:**
1. Set device text size to maximum
2. Observe profile card layout
3. Verify all text is readable and layout is not broken

**Expected Result:**
- All text scales proportionally (name, age, distance, bio)
- No text is cut off or truncated inappropriately
- Layout adjusts gracefully (may stack vertically if needed)
- No overlapping text
- Scrolling is available if content exceeds card height
- Images/photos adjust size appropriately
- Minimum information remains visible (name, age, distance)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-002: Action Button Labels at Large Text Size
**Priority:** P1
**WCAG:** 1.4.4 Resize Text

**Preconditions:**
- Text size at maximum

**Steps:**
1. Observe action buttons area
2. Verify button labels (if any text) are readable
3. Verify buttons remain usable and don't overlap

**Expected Result:**
- Button icons scale appropriately or remain visible
- Any text labels scale up to 200%
- Buttons don't overlap each other
- Touch targets remain at least 44x44 dp (don't shrink)
- Button row may stack vertically or scroll horizontally if needed

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-003: Filters Page Sliders and Labels at Large Text
**Priority:** P1
**WCAG:** 1.4.4 Resize Text, 1.4.10 Reflow

**Preconditions:**
- Text size at maximum
- Filters page open

**Steps:**
1. Navigate to filters page
2. Observe all filter controls and labels
3. Verify usability at large text size

**Expected Result:**
- Filter labels scale up (e.g., "Tranche d'âge", "Distance maximale")
- Slider value labels remain visible and readable
- Toggle switch labels don't overflow
- Page content may scroll vertically if needed
- No critical controls are hidden or inaccessible
- Apply/Clear buttons remain visible and tappable

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-004: Match Found Modal at Large Text Size
**Priority:** P2
**WCAG:** 1.4.4 Resize Text, 1.4.10 Reflow

**Preconditions:**
- Text size at maximum
- Trigger a match to display modal

**Steps:**
1. Create a match
2. Observe match modal layout
3. Verify all text is readable and buttons are accessible

**Expected Result:**
- "It's a Match!" heading scales up and remains visible
- Profile photos may shrink slightly to accommodate text
- Button labels ("Send Message", "Keep Swiping") scale up
- Modal content may scroll if needed
- Modal remains centered and dismissible
- No text overflows modal boundaries

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-005: Daily Limit Counter at Large Text Size
**Priority:** P2
**WCAG:** 1.4.4 Resize Text

**Preconditions:**
- Text size at maximum
- Free user account with visible like counter

**Steps:**
1. Observe daily limit counter (e.g., "8 likes remaining")
2. Verify text is readable and doesn't overflow

**Expected Result:**
- Counter text scales up to 200%
- Text doesn't overflow or get cut off
- Counter remains visible on screen
- Updates are visible when counter changes

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-006: Error Messages at Large Text Size
**Priority:** P2
**WCAG:** 1.4.4 Resize Text

**Preconditions:**
- Text size at maximum
- Trigger error state (network off, no profiles, etc.)

**Steps:**
1. Trigger error state
2. Observe error message display
3. Verify message is fully readable

**Expected Result:**
- Error message text scales up
- Message doesn't overflow container
- Retry button (if any) remains visible and tappable
- Error icon (if any) scales or remains visible

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-007: Bottom Navigation Labels at Large Text Size
**Priority:** P1
**WCAG:** 1.4.4 Resize Text

**Preconditions:**
- Text size at maximum

**Steps:**
1. Observe bottom navigation bar
2. Verify all tab labels are readable

**Expected Result:**
- Navigation labels scale up
- Labels don't overlap with icons or each other
- If labels overflow, icons remain visible and tappable
- Selected state remains distinguishable

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-LF-008: Overall Usability at Large Text Size
**Priority:** P0
**WCAG:** 1.4.4 Resize Text, 1.4.10 Reflow

**Preconditions:**
- Text size at maximum (200-300%)
- Complete user journey on Discovery page

**Steps:**
1. Navigate through entire Discovery page
2. Perform core actions (view profile, swipe, open filters, dismiss modals)
3. Verify app remains fully functional

**Expected Result:**
- All text is readable without horizontal scrolling
- All interactive elements remain accessible
- No critical functionality is lost
- Layout may change (vertical stacking, scrolling) but is logical
- User can complete all primary tasks
- No frustration or usability barriers introduced

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## Part 6: Reduced Motion Testing

### Enabling Reduced Motion

**Android:**
1. Settings → Accessibility → Remove animations
2. Settings → Developer options → Animator duration scale → Off (or 0.5x)

**iOS:**
1. Settings → Accessibility → Motion → Reduce Motion → ON

---

### TEST-RM-001: Swipe Card Animation with Reduced Motion
**Priority:** P1
**WCAG:** 2.3.3 Animation from Interactions

**Preconditions:**
- Reduced motion enabled
- On Discovery page

**Steps:**
1. Enable reduced motion
2. Swipe a profile (using action buttons or gesture)
3. Observe animation behavior

**Expected Result:**
- Card swipe animation is simplified or instant (no complex rotation/scaling)
- Card transitions to next profile without elaborate animation
- Essential information is still conveyed (which profile was swiped, direction)
- No vestibular motion that could trigger discomfort
- Animation duration is significantly reduced (300ms → 100ms or instant)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-RM-002: Match Found Modal Animation with Reduced Motion
**Priority:** P1
**WCAG:** 2.3.3 Animation from Interactions

**Preconditions:**
- Reduced motion enabled
- Trigger a match

**Steps:**
1. Like a profile that likes you back
2. Observe match modal appearance
3. Verify animation is reduced

**Expected Result:**
- Modal appears with minimal or no animation (fade in vs. bounce/scale)
- Confetti/hearts animation is disabled or significantly simplified
- Profile photos don't have elaborate entrance animations
- Modal dismissal is also simplified
- Match is still clear and celebratory despite reduced motion

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-RM-003: Loading Indicators with Reduced Motion
**Priority:** P2
**WCAG:** 2.3.3 Animation from Interactions

**Preconditions:**
- Reduced motion enabled
- Trigger loading state (initial page load, refresh)

**Steps:**
1. Navigate to Discovery page with slow network
2. Observe loading indicator
3. Verify it respects reduced motion

**Expected Result:**
- Spinner/loading animation is simplified or static
- Skeleton UI (if used) may have reduced or no shimmer effect
- Loading state is still clear to user
- Progress is still indicated (even if static)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-RM-004: Overlay and Transition Animations
**Priority:** P2
**WCAG:** 2.3.3 Animation from Interactions

**Preconditions:**
- Reduced motion enabled

**Steps:**
1. Partially swipe a profile to show overlay (like/dislike)
2. Open filters page
3. Observe page transitions

**Expected Result:**
- Swipe overlay appears without bounce or pulse animation
- Page transitions are simplified (crossfade vs. slide)
- Modal overlays appear with minimal animation
- No parallax or complex motion effects

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-RM-005: Overall Experience with Reduced Motion
**Priority:** P1
**WCAG:** 2.2.2 Pause, Stop, Hide, 2.3.3 Animation from Interactions

**Preconditions:**
- Reduced motion enabled
- Complete user journey

**Steps:**
1. Navigate entire Discovery page with reduced motion on
2. Perform all core actions
3. Verify app remains pleasant and functional

**Expected Result:**
- App feels responsive despite reduced animations
- All functionality works identically
- No essential information is lost due to reduced motion
- User experience is smooth (not janky or broken)
- No auto-playing animations that can't be stopped
- Experience is comfortable for users with vestibular disorders

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## Part 7: Color Blindness Testing

### Simulating Color Blindness

**Tools:**
- **Android**: Accessibility → Color correction (Deuteranomaly, Protanomaly, Tritanomaly)
- **iOS**: Accessibility → Display & Text Size → Color Filters (various types)
- **External tools**: Color Oracle, Sim Daltonism (desktop tools for screenshots)

**Types to Test:**
1. **Deuteranopia** (green-blind, most common, ~5% of males)
2. **Protanopia** (red-blind)
3. **Tritanopia** (blue-blind, rare)
4. **Monochromacy** (complete color blindness, very rare)

---

### TEST-CB-001: Action Button Differentiation (Deuteranopia)
**Priority:** P1
**WCAG:** 1.4.1 Use of Color

**Preconditions:**
- Deuteranopia color filter enabled
- On Discovery page

**Steps:**
1. Enable deuteranopia (green-blind) filter
2. Observe action buttons (like/dislike/super like)
3. Verify buttons are distinguishable without relying on color alone

**Expected Result:**
- Like button (green heart) and dislike button (red X) are distinguishable by:
  - **Icon shape** (heart vs. X)
  - **Position** (consistent left-to-right order)
  - **Label** (if text is present or on long-press)
- Super like button (blue/amber star) is distinguishable by star shape
- Buttons don't become identical or confusing
- User can perform actions without color perception

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-CB-002: Swipe Overlay Differentiation
**Priority:** P1
**WCAG:** 1.4.1 Use of Color

**Preconditions:**
- Color blindness filter enabled (any type)

**Steps:**
1. Partially swipe left (dislike) to show red overlay
2. Partially swipe right (like) to show green overlay
3. Verify overlays are distinguishable without color

**Expected Result:**
- Overlays display text: "LIKE", "NOPE", "SUPER LIKE"
- Text provides meaning independent of color
- User can understand action even if colors are indistinguishable
- Overlay icons (if present) are different shapes

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-CB-003: Badge and Status Indicator Differentiation
**Priority:** P2
**WCAG:** 1.4.1 Use of Color

**Preconditions:**
- Color blindness filter enabled
- Profile with verified (blue), premium (gold), online (green) badges

**Steps:**
1. Observe all badges on profile card
2. Verify each badge is distinguishable by shape or icon, not just color

**Expected Result:**
- **Verified badge**: Blue checkmark → Checkmark icon is recognizable regardless of color
- **Premium badge**: Gold star → Star shape is distinctive
- **Online indicator**: Green dot → May be challenging, but "Online now" text supplements
- Each badge has unique icon or text label

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-CB-004: Compatibility Score and Other Color-Coded Elements
**Priority:** P2
**WCAG:** 1.4.1 Use of Color

**Preconditions:**
- Color blindness filter enabled

**Steps:**
1. Observe compatibility score (if color-coded)
2. Observe any other color-coded indicators
3. Verify information is conveyed without color alone

**Expected Result:**
- Compatibility percentage is shown as numeric text (e.g., "85%")
- If color indicates score level (high/medium/low), shape or label also indicates this
- No critical information is conveyed by color alone
- User with complete color blindness can understand all information

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## Part 8: Touch Target Adequacy Testing

### TEST-TT-001: Action Button Touch Targets
**Priority:** P0
**WCAG:** 2.5.5 Target Size (Level AAA, but recommended)

**Preconditions:**
- On Discovery page with action buttons visible

**Steps:**
1. Visually measure or estimate action button sizes
2. Tap each button with finger to test ease of activation
3. Try tapping near edges of buttons

**Expected Result:**
- All action buttons are at least 44x44 dp (iOS) or 48x48 dp (Material Design recommended)
- Automated tests verify ActionButton widget default size is 56x56 dp ✓
- Buttons are comfortably tappable without precision
- Adequate spacing between buttons (at least 8dp) to prevent mis-taps
- Buttons don't require precise aim

**Measurement Guide:**
- **56 dp ≈ 9-10mm** on typical phone screen (assuming ~160dpi)
- Use ruler on physical device or developer tools to measure

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-TT-002: Filters Page Controls Touch Targets
**Priority:** P1
**WCAG:** 2.5.5 Target Size

**Preconditions:**
- Filters page open

**Steps:**
1. Test tapping slider thumbs (age range, distance)
2. Test tapping toggle switches
3. Test tapping buttons (Apply, Clear)

**Expected Result:**
- Slider thumbs are at least 44x44 dp and easily draggable
- Toggle switches have tappable area of at least 44x44 dp (entire switch, not just thumb)
- Apply and Clear buttons meet 44x44 dp minimum
- No controls are too small to tap comfortably

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-TT-003: Small Text Links and Icons
**Priority:** P2
**WCAG:** 2.5.5 Target Size

**Preconditions:**
- On Discovery page or related screens

**Steps:**
1. Identify any small links or icons (e.g., info icons, close buttons)
2. Attempt to tap them precisely
3. Verify adequate touch area

**Expected Result:**
- Even small icons have minimum 44x44 dp touch area (padding extends touch zone)
- Close buttons (×) on modals are easily tappable
- Filter toggle icons (if any) are tappable
- No frustration from missed taps

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-TT-004: Bottom Navigation Touch Targets
**Priority:** P0
**WCAG:** 2.5.5 Target Size

**Preconditions:**
- On any screen with bottom navigation visible

**Steps:**
1. Tap each bottom navigation item
2. Verify easy activation
3. Test tapping near edges of navigation area

**Expected Result:**
- Each navigation item (Discovery, Matches, Messages, Profile) has adequate touch area
- Items are easily tappable even at screen edges
- Spacing prevents accidental activation of adjacent items

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-TT-005: Modal Close and Action Buttons
**Priority:** P1
**WCAG:** 2.5.5 Target Size

**Preconditions:**
- Various modals open (match modal, upgrade modal, etc.)

**Steps:**
1. Test close/dismiss buttons on modals
2. Test action buttons within modals
3. Verify all are easily tappable

**Expected Result:**
- Close buttons (×, back, dismiss) are at least 44x44 dp
- Modal action buttons (Send Message, Keep Swiping, Upgrade, etc.) meet minimum size
- Buttons are positioned for comfortable tapping (not too close to screen edge)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

### TEST-TT-006: Profile Card Interactive Elements
**Priority:** P2
**WCAG:** 2.5.5 Target Size

**Preconditions:**
- Profile card visible with multiple photos

**Steps:**
1. Tap on profile card to open detail view (if applicable)
2. Tap photo pagination indicators to change photos
3. Verify touch targets are adequate

**Expected Result:**
- Profile card tap area is large and forgiving
- Photo pagination dots (if tappable) have adequate touch area
- Swipe gestures have wide activation area (doesn't require precision)

**Actual Result:** [To be filled]
**Status:** [ ] Pass [ ] Fail [ ] Blocked
**Issues Found:**

---

## WCAG 2.1 Level AA Compliance Summary

| WCAG Criterion | Requirement | Status | Notes |
|----------------|-------------|--------|-------|
| **1.1.1 Non-text Content** | All images, icons have text alternatives | [ ] Pass [ ] Fail | Semantic labels for all interactive elements |
| **1.3.1 Info and Relationships** | Semantic structure for assistive tech | [ ] Pass [ ] Fail | Screen reader tests verify structure |
| **1.3.3 Sensory Characteristics** | Instructions don't rely solely on sensory characteristics | [ ] Pass [ ] Fail | Color, shape, sound not sole means of conveying info |
| **1.4.1 Use of Color** | Color is not the only visual means | [ ] Pass [ ] Fail | Action buttons have shapes/labels, not just color |
| **1.4.3 Contrast (Minimum)** | 4.5:1 for text, 3:1 for UI components | [ ] Pass [ ] Fail | Automated tests verify, manual check in high contrast mode |
| **1.4.4 Resize Text** | Text can be resized to 200% | [ ] Pass [ ] Fail | Large font tests verify no loss of content/functionality |
| **1.4.10 Reflow** | No 2D scrolling at 320px width / 200% zoom | [ ] Pass [ ] Fail | Layout adapts to large text without horizontal scroll |
| **1.4.11 Non-text Contrast** | 3:1 for UI components and graphics | [ ] Pass [ ] Fail | Buttons, badges, indicators meet contrast requirements |
| **1.4.12 Text Spacing** | Supports user text spacing adjustments | [ ] Pass [ ] Fail | Layout doesn't break with adjusted line height/spacing |
| **1.4.13 Content on Hover/Focus** | Hoverable, dismissible, persistent | [ ] Pass [ ] Fail | Tooltips/overlays (if any) meet requirements |
| **2.1.1 Keyboard** | All functionality via keyboard | [ ] Pass [ ] Fail | Action buttons alternative to swipe gestures |
| **2.1.2 No Keyboard Trap** | Focus can move away from any component | [ ] Pass [ ] Fail | Keyboard navigation tests verify no traps |
| **2.2.2 Pause, Stop, Hide** | Control for auto-updating content | [ ] Pass [ ] Fail | No auto-playing content that can't be paused |
| **2.3.3 Animation from Interactions** | Motion triggered by interaction can be disabled | [ ] Pass [ ] Fail | Reduced motion tests verify animations respect preference |
| **2.4.1 Bypass Blocks** | Mechanism to skip repeated content | [ ] Pass [ ] Fail | Bottom nav provides direct access to sections |
| **2.4.3 Focus Order** | Sequential navigation order is logical | [ ] Pass [ ] Fail | Screen reader navigation flow is logical |
| **2.4.6 Headings and Labels** | Descriptive headings and labels | [ ] Pass [ ] Fail | All labels are clear and descriptive |
| **2.4.7 Focus Visible** | Keyboard focus is visible | [ ] Pass [ ] Fail | Focus indicator visible in keyboard nav tests |
| **2.5.3 Label in Name** | Accessible name contains visible label | [ ] Pass [ ] Fail | Button labels match semantic labels |
| **2.5.5 Target Size** | Touch targets at least 44x44 pixels | [ ] Pass [ ] Fail | Touch target tests verify minimum sizes |
| **3.3.1 Error Identification** | Errors are identified and described | [ ] Pass [ ] Fail | Error messages clear and announced |
| **3.3.4 Error Prevention** | Confirmation for important actions | [ ] Pass [ ] Fail | Super Like confirmation dialog |
| **4.1.2 Name, Role, Value** | UI components have proper semantics | [ ] Pass [ ] Fail | Screen reader tests verify all interactive elements |
| **4.1.3 Status Messages** | Status messages announced to assistive tech | [ ] Pass [ ] Fail | Match, error, limit messages announced |

**Overall WCAG 2.1 AA Compliance:** [ ] Pass [ ] Fail [ ] Partial

---

## Issue Tracking Template

For each issue found during testing, document using this template:

### Issue #[NUMBER]: [Brief Title]

**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low
**WCAG Criterion:** [e.g., 1.4.3 Contrast (Minimum)]
**Test Case:** [e.g., TEST-SR-TB-002]
**Platform:** [ ] Android [ ] iOS [ ] Both

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen according to WCAG/spec]

**Actual Behavior:**
[What actually happens]

**Impact:**
[How does this affect users with disabilities?]

**Suggested Fix:**
[Recommended solution]

**Screenshots/Recordings:**
[Attach evidence]

**Assigned To:** [Developer name]
**Priority:** [ ] P0 [ ] P1 [ ] P2 [ ] P3
**Status:** [ ] Open [ ] In Progress [ ] Fixed [ ] Verified [ ] Closed

---

## Final Accessibility Sign-Off

### Test Completion Checklist

- [ ] All 64 test cases executed
- [ ] TalkBack testing complete on Android (15 tests)
- [ ] VoiceOver testing complete on iOS (15 tests)
- [ ] Keyboard navigation tested (5 tests)
- [ ] High contrast mode tested (6 tests)
- [ ] Large fonts tested (8 tests)
- [ ] Reduced motion tested (5 tests)
- [ ] Color blindness tested (4 tests)
- [ ] Touch targets verified (6 tests)
- [ ] All issues documented and tracked
- [ ] WCAG 2.1 AA compliance summary completed
- [ ] Critical and high severity issues resolved or documented
- [ ] Automated accessibility tests pass (reference: test/accessibility/)

### Tester Sign-Off

**Tester Name:** _______________________________
**Date:** _______________________________
**Signature:** _______________________________

**Recommendation:**
[ ] APPROVED - Discovery page meets WCAG 2.1 AA standards
[ ] APPROVED WITH EXCEPTIONS - Minor issues documented, can be addressed post-launch
[ ] REJECTED - Critical accessibility issues must be resolved before launch

**Comments:**
[Additional notes, observations, or recommendations]

---

## Appendix A: Assistive Technology Setup Guides

### TalkBack Detailed Setup (Android)

1. **Enable TalkBack:**
   - Settings → Accessibility → TalkBack → Toggle ON
   - Shortcut: Volume Up + Volume Down (on some devices)

2. **Configure TalkBack Settings:**
   - Speech rate: Adjust to preference (50-75% recommended for testing)
   - Verbosity: "Default" or "High" for thorough testing
   - Audio ducking: ON
   - Vibration feedback: ON
   - Sound feedback: ON

3. **Learn TalkBack Gestures:**
   - Complete the TalkBack tutorial (Settings → Accessibility → TalkBack → Settings → Tutorial)
   - Practice basic navigation before testing

4. **TalkBack Shortcuts:**
   - **Local context menu**: Swipe up then right
   - **Global context menu**: Swipe down then right
   - **Reading controls**: Swipe down then right repeatedly to cycle through granularity (default, characters, words, lines, paragraphs, headings)

### VoiceOver Detailed Setup (iOS)

1. **Enable VoiceOver:**
   - Settings → Accessibility → VoiceOver → Toggle ON
   - Shortcut: Triple-click side button (must enable in Settings → Accessibility → Accessibility Shortcut)

2. **Configure VoiceOver Settings:**
   - Speaking Rate: 50% (adjust to preference)
   - Verbosity: "High" for thorough testing
   - Pitch: Default
   - Braille: Not required for basic testing

3. **Learn VoiceOver Gestures:**
   - Complete the VoiceOver practice in Settings → Accessibility → VoiceOver → VoiceOver Practice

4. **VoiceOver Rotor:**
   - Two-finger rotate to access rotor
   - Rotor options: Headings, Links, Form Controls, Containers, etc.
   - Swipe up/down to navigate by rotor selection

### Keyboard Navigation Setup

**Android with Physical Keyboard:**
- Connect via Bluetooth or USB
- No additional setup required
- Tab/Shift+Tab should work automatically

**iOS with Physical Keyboard:**
- Connect via Bluetooth
- Full keyboard access: Settings → Accessibility → Keyboards → Full Keyboard Access → ON
- Tab/Shift+Tab, arrow keys should work

### High Contrast Mode Setup

**Android:**
- High contrast fonts: Settings → Accessibility → Visibility enhancements → High contrast fonts
- Color inversion: Settings → Accessibility → Visibility enhancements → Color inversion
- Contrast theme: Settings → Display → Dark theme (with high contrast fonts)

**iOS:**
- Increase Contrast: Settings → Accessibility → Display & Text Size → Increase Contrast → ON
- Reduce Transparency: Settings → Accessibility → Display & Text Size → Reduce Transparency → ON
- Dark Mode: Settings → Display & Brightness → Dark

### Text Scaling Setup

**Android:**
- Font size: Settings → Display → Font size → Largest
- Display size: Settings → Display → Display size → Largest

**iOS:**
- Text Size: Settings → Display & Text Size → Text Size → Drag to maximum
- Larger Text: Settings → Accessibility → Display & Text Size → Larger Text → ON, then drag to maximum (up to 310%)
- Bold Text: Settings → Display & Text Size → Bold Text → ON (optional)

### Reduced Motion Setup

**Android:**
- Remove animations: Settings → Accessibility → Remove animations → ON
- Reduce animations: Settings → Developer Options → Window animation scale / Transition animation scale → OFF or 0.5x

**iOS:**
- Reduce Motion: Settings → Accessibility → Motion → Reduce Motion → ON
- Auto-Play Video Previews: Settings → Accessibility → Motion → Auto-Play Video Previews → OFF

### Color Blindness Simulation

**Android:**
- Settings → Accessibility → Color correction
- Choose: Deuteranomaly (red-green), Protanomaly (red-green), Tritanomaly (blue-yellow)

**iOS:**
- Settings → Accessibility → Display & Text Size → Color Filters → ON
- Choose: Grayscale, Red/Green Filter (Protanopia), Green/Red Filter (Deuteranopia), Blue/Yellow Filter (Tritanopia)

---

## Appendix B: Accessibility Resources

### WCAG 2.1 Guidelines
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [WCAG 2.1 Understanding Docs](https://www.w3.org/WAI/WCAG21/Understanding/)
- [How to Meet WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)

### Mobile Accessibility Guidelines
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android Accessibility Guidelines](https://developer.android.com/guide/topics/ui/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)

### Testing Tools
- [Colour Contrast Analyser (CCA)](https://www.tpgi.com/color-contrast-checker/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Color Oracle](https://colororacle.org/) - Color blindness simulator
- [Android Accessibility Scanner](https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor)

### Flutter Accessibility Resources
- [Flutter Accessibility Docs](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Semantics Widget API](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter Accessibility Testing](https://docs.flutter.dev/testing/accessibility)

### Screen Reader User Guides
- [TalkBack User Guide](https://support.google.com/accessibility/android/answer/6283677)
- [VoiceOver User Guide](https://support.apple.com/guide/iphone/turn-on-and-practice-voiceover-iph3e2e415f/ios)

### Community Resources
- [WebAIM Articles](https://webaim.org/articles/)
- [A11y Project](https://www.a11yproject.com/)
- [Inclusive Design Principles](https://inclusivedesignprinciples.org/)

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-27 | auto-claude | Initial comprehensive manual accessibility testing guide |

---

**End of Manual Accessibility Testing Guide**

# Discovery Page - Comprehensive Requirements Matrix

**Task:** Subtask 1.4 - Consolidate requirements into structured matrix
**Date:** 2026-02-25
**Sources:**
- Task 1.1: discovery_page_rules_extraction.md
- Task 1.2: claude_md_discovery_requirements.md
- Task 1.3: discovery-documentation-audit.md
- Specification documents in docs/ directory

---

## Matrix Overview

This matrix consolidates **ALL** Discovery page requirements extracted from specifications, categorized for systematic implementation and verification.

**Categories:**
- **FUNC** - Functional Requirements
- **NFR** - Non-Functional Requirements (Performance, Reliability)
- **UI** - User Interface & Experience
- **DATA** - Data Models & Storage
- **API** - Backend Integration & API Contracts
- **SEC** - Security & Privacy
- **A11Y** - Accessibility
- **I18N** - Internationalization
- **TEST** - Testing Requirements
- **ARCH** - Architecture & Patterns

**Priorities:**
- **P0** - Critical (blocks core functionality)
- **P1** - High (major feature/UX impact)
- **P2** - Medium (important but not blocking)
- **P3** - Low (nice-to-have, polish)

---

## 1. FUNCTIONAL REQUIREMENTS (FUNC)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| FUNC-001 | Swipe Right (Like) | User can swipe profile card right or tap heart button to like | P0 | spec.md:271-279, DISCOVERY_PAGE_IMPLEMENTATION.md | - Swipe right gesture detected<br>- Like action sent to API<br>- Smooth animation at 60fps<br>- Haptic feedback on completion<br>- Daily limit enforced |
| FUNC-002 | Swipe Left (Dislike) | User can swipe profile card left or tap X button to dislike | P0 | spec.md:271-279, DISCOVERY_PAGE_IMPLEMENTATION.md | - Swipe left gesture detected<br>- Dislike action sent to API<br>- Smooth transition to next profile<br>- No visible feedback to other user |
| FUNC-003 | Swipe Up (Super Like) | Premium users can swipe up or tap star button for super like | P1 | rules:1.2, FRONTEND_MATCHING_API.md:234-323 | - Swipe up gesture detected (Premium only)<br>- Special star animation<br>- Super like notification sent<br>- Daily limit (5/day Premium) enforced<br>- Free users see upgrade CTA |
| FUNC-004 | View Profile Detail | Tap on profile card opens detailed profile view | P0 | spec.md:282-298, Description Détaillé:2.2.2 | - Tap gesture opens profile detail page<br>- Full photo gallery visible<br>- Complete bio displayed<br>- Verification badges shown<br>- Back navigation works |
| FUNC-005 | Profile Preloading | Load 2-3 next profiles in background for smooth UX | P1 | rules:7.1, DISCOVERY_PAGE_IMPLEMENTATION.md | - Next 2-3 profiles fetched ahead<br>- Images cached<br>- Smooth transitions<br>- No loading delays between swipes |
| FUNC-006 | Photo Carousel | Swipe horizontally between profile photos with pagination dots | P0 | spec.md:289-298, rules:5.1 | - Horizontal swipe between photos<br>- Pagination indicators (dots)<br>- Smooth transitions<br>- Auto-return to main photo on card change |
| FUNC-007 | Match Detection | Detect mutual likes and display match modal | P0 | spec.md:318-332, FRONTEND_MATCHING_API.md:120-157 | - API returns "match" status<br>- Full-screen match modal appears<br>- Animation (hearts/confetti)<br>- Both users' photos shown<br>- "Send Message" and "Keep Swiping" buttons |
| FUNC-008 | Match Modal Actions | Navigate to conversation or continue swiping after match | P0 | spec.md:327-332 | - "Send Message" opens conversation<br>- "Keep Swiping" dismisses modal, continues discovery<br>- Modal dismissible by tap outside or back button |
| FUNC-009 | Daily Like Limit (Free) | Enforce 50 likes/day limit for free users | P0 | rules:1.4, FRONTEND_MATCHING_API.md:379-399 | - Like counter decrements with each like<br>- Limit modal shown at 50 likes<br>- Like button disabled when limit reached<br>- Upgrade CTA displayed<br>- Auto-reset at midnight (server-side) |
| FUNC-010 | Super Like Limit | Enforce super like limits (1/day free, 5/day premium) | P1 | rules:1.4, spec.md:349-362 | - Counter shown for super likes remaining<br>- Disabled state when limit reached<br>- Premium users see higher limit<br>- Free users see upgrade CTA on tap |
| FUNC-011 | Rewind Last Swipe | Premium users can undo last swipe | P2 | rules:1.4, spec.md:356-362 | - Rewind button visible after swipe (Premium)<br>- Restores previous profile<br>- API call to /rewind endpoint<br>- Counter decrements (5/day limit)<br>- Free users see lock icon + upgrade CTA |
| FUNC-012 | Profile Boost | Premium users can boost profile visibility | P2 | rules:1.4, API spec:5.9 | - Boost activates for 30 minutes<br>- Increased visibility to other users<br>- Monthly limit enforced<br>- UI shows boost status |
| FUNC-013 | Age Range Filter | Double slider to set min/max age preference | P0 | spec.md:299-316, rules:1.5 | - Double slider functional<br>- Min >= 18, Max <= 100, Min < Max<br>- Real-time value display<br>- Auto-save to preferences<br>- Apply button triggers profile reload |
| FUNC-014 | Distance Filter | Single slider to set max distance (1-100 km) | P0 | spec.md:299-316, rules:1.5 | - Single slider functional<br>- Range 1-100 km<br>- Real-time value display<br>- Geolocation permission required<br>- Auto-save and apply |
| FUNC-015 | Relationship Type Filter | Multi-select for relationship preferences | P1 | spec.md:299-316, rules:1.5 | - Multiple options selectable<br>- Icon-based UI<br>- Selected state visible<br>- Auto-save and apply |
| FUNC-016 | Interests Filter | Multi-select interests (max 5) | P1 | spec.md:299-316, rules:1.5 | - Max 5 interests selectable<br>- Visual feedback when limit reached<br>- Auto-save and apply<br>- Tags displayed clearly |
| FUNC-017 | Verified Only Filter | Toggle to show only verified profiles (Premium) | P2 | spec.md:310-315, rules:1.5 | - Toggle functional<br>- Premium badge if locked (Free users)<br>- Filter applied immediately<br>- Profile count updates |
| FUNC-018 | Online Only Filter | Toggle to show only online users (Premium) | P2 | spec.md:310-315, rules:1.5 | - Toggle functional<br>- Premium badge if locked<br>- Shows "Online Now" indicator<br>- Profile count updates |
| FUNC-019 | Estimated Profile Count | Real-time profile count as filters change | P1 | spec.md:311-315 | - Count updates when filters change<br>- Displayed prominently<br>- Helps user adjust criteria<br>- API call to /filters endpoint |
| FUNC-020 | Clear Filters | Reset all filters to defaults | P1 | spec.md:315 | - Button to clear all filters<br>- Resets to default values<br>- Profile count updates<br>- Profiles reload |
| FUNC-021 | Filter Persistence | Save filter preferences locally | P1 | spec.md:313, rules:1.5 | - Filters auto-save on change<br>- Restored on app restart<br>- Sync with backend profile preferences |
| FUNC-022 | No More Profiles State | Handle empty profile queue gracefully | P0 | spec.md:369-376, rules:5.2 | - "No more profiles" illustration shown<br>- Message: adjust filters or check back later<br>- Button to modify filters<br>- Suggestions to widen criteria |
| FUNC-023 | Network Error Recovery | Gracefully handle network failures | P0 | spec.md:369-376, rules:2.3 | - "Connection error" message displayed<br>- Retry button functional<br>- Queue actions for retry on reconnect<br>- Show pending state |
| FUNC-024 | Rapid Swipe Handling | Prevent duplicate requests from rapid swipes | P1 | spec.md:421 | - Debounce API calls<br>- Prevent duplicate requests<br>- Show optimistic UI<br>- Handle errors gracefully |
| FUNC-025 | Auto-pagination | Fetch next page when 3 profiles remaining | P1 | rules:7.3, spec.md:422 | - Automatic prefetch when low on profiles<br>- Seamless UX (no loading pause)<br>- Cursor-based pagination<br>- Smart cache invalidation |

---

## 2. NON-FUNCTIONAL REQUIREMENTS (NFR)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| NFR-001 | Load Time | Initial profile load < 2 seconds | P1 | DISCOVERY_PAGE_IMPLEMENTATION.md, rules:7.2 | - Measured from event to DiscoveryLoaded state<br>- Average < 2s over 10 tests<br>- 95th percentile < 3s |
| NFR-002 | Animation Performance | Swipe animations at 60 FPS | P0 | spec.md:279, rules:7.2 | - Measured with Flutter DevTools<br>- Consistent 60 FPS during swipes<br>- No frame drops during transitions |
| NFR-003 | Memory Usage | Normal usage < 100 MB | P1 | rules:7.2, DISCOVERY_PAGE_IMPLEMENTATION.md | - Measured with Flutter DevTools profiler<br>- No memory leaks detected<br>- Stable memory usage over time |
| NFR-004 | Swipe Response Time | Gesture recognition < 100ms | P0 | spec.md:604 | - Instant visual feedback<br>- Measured manually<br>- Feels responsive to user |
| NFR-005 | Offline Capability | Queue actions when offline | P2 | rules:2.3 | - Actions queued locally<br>- Retry on reconnect<br>- User notified of offline state |
| NFR-006 | Stability | No crashes during normal usage | P0 | QA criteria | - Zero unhandled exceptions<br>- Error boundaries in place<br>- All edge cases handled |
| NFR-007 | Scalability | Handle large profile datasets | P1 | rules:7.3 | - Pagination working efficiently<br>- No performance degradation with 1000+ profiles<br>- Lazy loading images |

---

## 3. UI/UX REQUIREMENTS (UI)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| UI-001 | Profile Card Design | Card shows photo, name, age, distance, compatibility | P0 | spec.md:282-298, Charte Graphique | - Main photo displayed prominently<br>- Name and age visible<br>- Distance in km shown<br>- Compatibility score displayed<br>- Visual badges (verified, premium, online) |
| UI-002 | Verification Badge | Display "Verified" badge if is_verified: true | P1 | spec.md:292, rules:5.1 | - Badge visible on verified profiles<br>- Clear visual indicator<br>- Positioned consistently |
| UI-003 | Premium Badge | Display "Premium" badge for premium users | P2 | spec.md:293, rules:5.1 | - Badge visible on premium profiles<br>- Distinct from verified badge |
| UI-004 | Online Indicator | Show "Online Now" if is_online: true | P1 | spec.md:294, rules:5.1 | - Green dot or "Online Now" text<br>- Real-time status (or last active timestamp) |
| UI-005 | Compatibility Score | Display compatibility percentage with visual indicator | P1 | spec.md:291, FRONTEND_MATCHING_API.md | - Percentage shown (e.g., "85%")<br>- Visual indicator (color, icon, progress bar)<br>- Algorithm factors visible on tap |
| UI-006 | Mutual Interests | Display mutual interests as chips/tags | P1 | spec.md:296 | - Tags visible below bio<br>- Max 3-5 visible<br>- Tap to expand all |
| UI-007 | Swipe Overlays | Visual overlay during swipe (heart for like, X for dislike) | P0 | spec.md:275-278, rules:5.1 | - Green "LIKE" overlay on right swipe<br>- Red "NOPE" overlay on left swipe<br>- Star icon on up swipe<br>- Smooth fade in/out |
| UI-008 | Action Buttons | Like, Dislike, Super Like buttons below card | P0 | spec.md:276, rules:5.1 | - Heart (like), X (dislike), Star (super like)<br>- Disabled states when limits reached<br>- Smooth press animations |
| UI-009 | Skeleton Loading | Show skeleton UI during loading, not just spinner | P1 | spec.md:279, 374 | - Skeleton cards visible during load<br>- Shimmer animation<br>- Better UX than blank screen or spinner |
| UI-010 | Empty State Illustration | Custom illustration for "no profiles" state | P1 | spec.md:358-365, Description Détaillé | - Engaging illustration<br>- Supportive message<br>- Action button (adjust filters) |
| UI-011 | Match Animation | Celebratory animation on match | P0 | spec.md:326-331, rules:5.3 | - Full-screen modal<br>- Hearts/confetti animation<br>- Both users' photos shown<br>- Celebratory sound (optional, device settings) |
| UI-012 | Filter Modal Design | Intuitive filter interface | P0 | spec.md:299-316, Charte Graphique | - Sliders for age/distance<br>- Multi-select for types/interests<br>- Toggles for verified/online<br>- Profile count displayed<br>- Apply and Clear buttons |
| UI-013 | Responsive Layout | Adapt to screen sizes (phone, tablet, desktop) | P1 | rules:5.4, Description Détaillé | - Phone: full-screen cards<br>- Tablet: split view<br>- Desktop: larger cards with more info |
| UI-014 | Dark Mode | Support dark theme automatically | P1 | rules:10.2, spec.md:416 | - Follows system theme<br>- Colors adjusted for dark mode<br>- Contrast maintained |
| UI-015 | Haptic Feedback | Vibration on swipe completion | P1 | spec.md:277, rules:5.3 | - Subtle haptic on like/dislike<br>- Stronger haptic on super like<br>- Respects device settings |
| UI-016 | Limit Counter Display | Show remaining likes for free users | P0 | spec.md:340-346, rules:1.4 | - Counter visible (e.g., "8 likes remaining")<br>- Updates in real-time<br>- Premium users see "Unlimited" or no counter |
| UI-017 | Upgrade CTA Modal | Modal when daily limit reached | P1 | spec.md:343-345 | - Displayed on 50th like (Free)<br>- Clear benefits of Premium<br>- "Upgrade Now" button<br>- "Not Now" dismisses modal |
| UI-018 | Accessibility Touch Targets | All interactive elements >= 44x44dp | P0 | spec.md:411, rules:10.1 | - Buttons meet size requirement<br>- Adequate spacing between targets<br>- Easy to tap without mistakes |

---

## 4. DATA REQUIREMENTS (DATA)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| DATA-001 | Discovery Profile Entity | Pure business object with no framework dependencies | P0 | rules:3.3, Architecture doc | - Entity in lib/domain/entities/<br>- No JSON serialization<br>- Immutable properties<br>- All required fields: id, name, age, photos, bio, interests, compatibility, etc. |
| DATA-002 | Discovery Profile Model | DTO extending entity with JSON serialization | P0 | rules:3.4, spec.md:99-101 | - Model in lib/data/models/<br>- Extends DiscoveryProfile entity<br>- fromJson() and toJson() methods<br>- Matches API response structure exactly |
| DATA-003 | Match Response Model | Model for match API responses | P0 | rules:4.1, spec.md:196-206 | - result field: "match" or "like_sent"<br>- match_id if matched<br>- daily_likes_remaining<br>- super_likes_remaining |
| DATA-004 | Filters Model | Model for filter preferences | P1 | rules:1.5, spec.md:260-279 | - age_min, age_max, distance_max_km<br>- genders, relationship_types, interests arrays<br>- verified_only, online_only booleans<br>- Validation logic included |
| DATA-005 | Photo Model | Nested model for profile photos | P0 | rules:4.1, spec.md:170-176 | - photo_url, thumbnail_url, is_main<br>- Array of photos per profile<br>- Lazy loading support |
| DATA-006 | Filter Persistence | Save filters to local storage | P1 | spec.md:313, rules:1.5 | - Use SharedPreferences or Hive<br>- Restore on app restart<br>- Sync with backend |
| DATA-007 | Profile Cache | Cache profiles locally for offline access | P2 | rules:7.1, NFR-005 | - Cache recent profiles<br>- Expiry logic (24h)<br>- Invalidate on filter change |
| DATA-008 | Pagination State | Track pagination cursor/page number | P0 | rules:7.3, FRONTEND_MATCHING_API.md | - Cursor-based pagination<br>- has_next boolean<br>- Smart prefetching |

---

## 5. API REQUIREMENTS (API)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| API-001 | GET /api/v1/discovery/ | Fetch discovery profiles | P0 | API_DOCUMENTATION.md, CLAUDE.md:Rule#1 | - Endpoint verified in API_DOCUMENTATION.md<br>- Query params: page, page_size, latitude, longitude<br>- Returns profiles array + pagination<br>- Status 200 on success |
| API-002 | POST /api/v1/discovery/interactions/like | Send like action | P0 | API_DOCUMENTATION.md, spec.md:195-206 | - Request: { target_user_id }<br>- Response: { result, match_id?, daily_likes_remaining }<br>- Status 200 on success, 429 on limit |
| API-003 | POST /api/v1/discovery/interactions/dislike | Send dislike action | P0 | API_DOCUMENTATION.md, spec.md:207-215 | - Request: { target_user_id }<br>- Response: { result: "dislike_sent" }<br>- Status 200 on success |
| API-004 | POST /api/v1/discovery/interactions/superlike | Send super like (Premium) | P1 | API_DOCUMENTATION.md, spec.md:216-228 | - Request: { target_user_id }<br>- Response: { result, super_likes_remaining }<br>- Status 200 on success, 403 if not Premium |
| API-005 | POST /api/v1/discovery/interactions/rewind | Undo last swipe (Premium) | P2 | API_DOCUMENTATION.md, spec.md:229-242 | - Response: { result, rewinds_remaining, restored_profile }<br>- Status 200 on success, 403 if not Premium |
| API-006 | POST /api/v1/discovery/boost/activate | Activate profile boost (Premium) | P2 | API_DOCUMENTATION.md, spec.md:244-256 | - Response: { boost: {id, expires_at}, boosts_remaining }<br>- Status 200 on success, 403 if not Premium |
| API-007 | POST /api/v1/discovery/filters | Apply discovery filters | P0 | API_DOCUMENTATION.md, spec.md:258-279 | - Request: age_min/max, distance, types, interests, toggles<br>- Response: { message, estimated_profiles }<br>- Status 200 on success |
| API-008 | Centralized Base URL | Use Constants.baseApiUrl for ALL endpoints | P0 | CLAUDE.md:Rule#3, rules:4.2 | - All API calls use ${Constants.baseApiUrl}<br>- No hardcoded URLs<br>- Mode-based configuration (debug/release) |
| API-009 | Auth Token Injection | Auto-inject Bearer token via interceptor | P0 | CLAUDE.md:Rule#1, rules:4.2 | - AuthInterceptor configured<br>- Token from FlutterSecureStorage<br>- "Authorization: Bearer {token}" header added |
| API-010 | Error Handling | Centralized error interceptor | P0 | rules:4.2, spec.md:367-376 | - 401: Trigger logout/refresh<br>- 403: Check subscription<br>- Timeout: Throw NetworkException<br>- Connection: Throw NetworkException |
| API-011 | Request/Response Logging | Debug-only logging with PII sanitization | P1 | CLAUDE.md:Rule#5, rules:4.2 | - LoggingInterceptor active in debug mode only<br>- Sanitize password, token, email<br>- Never log PII |
| API-012 | Pagination Support | Cursor-based pagination for profiles | P0 | rules:7.3, FRONTEND_MATCHING_API.md | - page parameter in request<br>- has_next in response<br>- Prefetch next page automatically |
| API-013 | Error Response Format | Consistent error format from backend | P0 | CLAUDE.md:Rule#7, rules:4.3 | - { error: "code", message: "text", details?: {} }<br>- All endpoints follow same format<br>- User-friendly messages |

---

## 6. SECURITY & PRIVACY REQUIREMENTS (SEC)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| SEC-001 | Secure Token Storage | Use FlutterSecureStorage for auth tokens | P0 | CLAUDE.md:Rule#5, rules:8.1 | - Tokens stored in FlutterSecureStorage<br>- NEVER in SharedPreferences<br>- Encrypted at rest |
| SEC-002 | No PII Logging | Never log tokens, emails, user IDs, locations | P0 | CLAUDE.md:Rule#5, rules:8.2 | - Verified with code search (grep)<br>- No print() statements with PII<br>- Generic debug logs only |
| SEC-003 | Input Sanitization | Clean all user inputs before API calls | P1 | rules:8.1 | - Age/distance validated<br>- Filter inputs sanitized<br>- SQL injection prevention |
| SEC-004 | HTTPS Only | All API calls over HTTPS in production | P0 | rules:4.2 | - baseApiUrl uses https:// in release mode<br>- Certificate pinning (optional) |
| SEC-005 | Location Privacy | Don't log exact coordinates | P0 | CLAUDE.md:Rule#5, Task 1.2 | - Location sent to API but not logged<br>- Generic logs like "Loading nearby profiles"<br>- User controls location precision |
| SEC-006 | Photo EXIF Stripping | Remove location metadata from photos | P1 | Task 1.2:702-708 | - EXIF data stripped before upload<br>- Location data removed<br>- Privacy protected |
| SEC-007 | Report & Block | Easy access to report/block inappropriate profiles | P0 | Task 1.2:733-744, spec.md:413 | - Report button accessible<br>- Immediate block capability<br>- Clear report process |
| SEC-008 | Verification Documents | Auto-delete verification docs after processing | P0 | CLAUDE.md:Rule#8, rules:11.2 | - Documents deleted after verification<br>- Encrypted during review<br>- Never displayed in profile |

---

## 7. ACCESSIBILITY REQUIREMENTS (A11Y)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| A11Y-001 | WCAG 2.1 AA Compliance | Meet WCAG accessibility standards | P0 | spec.md:403-417, rules:10.1 | - Contrast ratio >= 4.5:1<br>- Touch targets >= 44x44dp<br>- Screen reader support<br>- Keyboard navigation |
| A11Y-002 | Screen Reader Labels | Semantic labels on all interactive elements | P0 | spec.md:412, rules:10.1 | - All buttons labeled<br>- Images have alt text<br>- Logical navigation order |
| A11Y-003 | High Contrast Support | Support high contrast mode | P1 | rules:10.2 | - Tested with system high contrast<br>- Colors adjusted automatically<br>- Text remains readable |
| A11Y-004 | Text Scaling | Support system text size preferences | P1 | rules:10.2 | - UI adapts to large text<br>- No text truncation<br>- Layout remains usable |
| A11Y-005 | Reduced Motion | Respect reduced motion preference | P1 | spec.md:416, rules:10.2 | - Disable complex animations if preferred<br>- Basic transitions remain<br>- Functionality not affected |
| A11Y-006 | Alternative to Swipe | Action buttons as alternative to gestures | P0 | spec.md:414, Task 1.2:728 | - Buttons provide same functionality as swipes<br>- Accessible to users who can't swipe<br>- Keyboard accessible |
| A11Y-007 | Focus Management | Proper focus order and indicators | P1 | rules:10.1 | - Logical tab order<br>- Visible focus indicators<br>- Focus trapped in modals |
| A11Y-008 | Color Independence | Don't rely solely on color for information | P1 | rules:10.1 | - Icons or text accompany color coding<br>- Like/dislike distinguishable without color<br>- Accessible to colorblind users |

---

## 8. INTERNATIONALIZATION REQUIREMENTS (I18N)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| I18N-001 | French Translation | Complete French (FR) translation | P0 | CLAUDE.md:Rule#2, rules:6 | - All text in intl_fr.arb<br>- Natural, contextual French<br>- Tested by native speaker |
| I18N-002 | English Translation | Complete English (EN) translation | P0 | CLAUDE.md:Rule#2, rules:6 | - All text in intl_en.arb<br>- Clear, professional English<br>- Tested by native speaker |
| I18N-003 | Zero Hardcoded Strings | No hardcoded user-facing text in code | P0 | CLAUDE.md:Rule#2, spec.md:389-402 | - Verified with grep search<br>- All text uses AppLocalizations<br>- No exceptions |
| I18N-004 | Dynamic Placeholders | Support for dynamic content (counts, names) | P0 | rules:6.2, Task 1.2:152-175 | - {count} in "X likes remaining"<br>- {distance} in "Y km away"<br>- {percent} in compatibility score |
| I18N-005 | Date/Number Formatting | Locale-aware formatting | P1 | spec.md:596 | - Dates formatted per locale<br>- Numbers (distance, age) per locale<br>- Currency if applicable |
| I18N-006 | RTL Language Support | Support right-to-left languages (future) | P3 | spec.md:596 | - Layout mirrors for RTL<br>- Text alignment correct<br>- Icons flipped appropriately |
| I18N-007 | Translation Keys Organization | Logical key structure | P1 | Task 1.2:129-201 | - Keys prefixed with "discovery_"<br>- Grouped logically<br>- Self-documenting names |
| I18N-008 | Translation Coverage Verification | Verify all screens translated | P0 | spec.md:591-597 | - Change device language to FR/EN<br>- All text displays correctly<br>- No missing translations |

---

## 9. TESTING REQUIREMENTS (TEST)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| TEST-001 | Unit Tests - BLoC Events | Test all DiscoveryBloc events | P0 | spec.md:533-542, rules:9.1 | - LoadDiscoveryProfiles tested<br>- SwipeProfile tested<br>- RewindLastSwipe tested<br>- UpdateFilters tested<br>- LoadDailyLimit tested |
| TEST-002 | Unit Tests - BLoC States | Test all DiscoveryBloc state transitions | P0 | spec.md:533-542, rules:9.1 | - All 8 states tested<br>- Transitions validated<br>- Error states covered |
| TEST-003 | Unit Tests - UseCases | Test all Discovery use cases | P0 | spec.md:539-541, rules:9.1 | - GetDiscoveryProfiles tested<br>- LikeProfile tested<br>- DislikeProfile tested<br>- SuperLikeProfile tested<br>- RewindLastSwipe tested |
| TEST-004 | Unit Tests - Models | Test model serialization | P0 | rules:9.1, spec.md:541 | - fromJson() tested<br>- toJson() tested<br>- Edge cases (null, missing fields) |
| TEST-005 | Widget Tests - DiscoveryPage | Test page rendering in all states | P0 | spec.md:543-551, rules:9.2 | - Loading state renders<br>- Loaded state renders<br>- Error state renders<br>- Empty state renders |
| TEST-006 | Widget Tests - SwipeCard | Test swipe gestures | P0 | spec.md:547-549 | - Left swipe triggers callback<br>- Right swipe triggers callback<br>- Up swipe triggers callback<br>- Tap triggers detail view |
| TEST-007 | Widget Tests - Photo Carousel | Test photo navigation | P1 | spec.md:548 | - Horizontal swipe changes photo<br>- Pagination dots update<br>- Boundary handling (first/last) |
| TEST-008 | Widget Tests - Action Buttons | Test button interactions | P1 | spec.md:549 | - Like button triggers like<br>- Dislike button triggers dislike<br>- Super like button triggers super like<br>- Disabled states correct |
| TEST-009 | Widget Tests - Match Modal | Test match modal display | P1 | spec.md:550 | - Modal renders on match<br>- Both profiles shown<br>- Action buttons functional<br>- Dismissal works |
| TEST-010 | Widget Tests - Filters Page | Test filter UI | P1 | spec.md:551 | - Sliders work<br>- Toggles work<br>- Apply button works<br>- Profile count updates |
| TEST-011 | Integration Tests - Discovery Flow | Test complete discovery flow | P0 | spec.md:553-559 | - Load profiles → Swipe → Match → Message<br>- Full stack integration<br>- API mocking for tests |
| TEST-012 | Integration Tests - Filter Application | Test filter flow | P1 | spec.md:557 | - Change filters → Apply → Profiles reload<br>- New profiles match criteria |
| TEST-013 | Integration Tests - Daily Limit | Test limit enforcement | P1 | spec.md:558 | - Reach 50 likes → Limit modal → Upgrade CTA |
| TEST-014 | E2E Tests - New User Discovery | Test first-time discovery | P1 | spec.md:561-567 | - Login → Navigate → Swipe 3 profiles<br>- All features work |
| TEST-015 | Coverage Target - Critical Code | 100% coverage for matching logic | P0 | rules:9.2 | - Matching algorithm: 100%<br>- Limit enforcement: 100%<br>- Error handling: 100% |
| TEST-016 | Coverage Target - Business Logic | >90% coverage for BLoCs/UseCases | P0 | rules:9.2 | - BLoCs: >90%<br>- UseCases: >90%<br>- Report generated |
| TEST-017 | Coverage Target - Data Layer | >80% coverage for services/repos | P1 | rules:9.2 | - Services: >80%<br>- Repositories: >80%<br>- Models: >80% |
| TEST-018 | Coverage Target - Overall | >80% overall test coverage | P1 | spec.md:513, rules:9.2 | - Total coverage >80%<br>- Coverage report attached to PR<br>- Critical gaps justified |
| TEST-019 | Accessibility Tests | Automated accessibility testing | P1 | spec.md:577-589 | - Screen reader navigation tested<br>- Contrast ratios verified<br>- Touch targets verified |

---

## 10. ARCHITECTURE REQUIREMENTS (ARCH)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| ARCH-001 | Clean Architecture | Follow 3-layer architecture | P0 | rules:3.1, CLAUDE.md, Architecture doc | - Presentation layer: UI only<br>- Domain layer: business logic<br>- Data layer: API/storage<br>- Dependencies point inward |
| ARCH-002 | BLoC Pattern | Use BLoC for state management | P0 | rules:3.1, spec.md:378-389 | - One BLoC per feature (DiscoveryBloc)<br>- Events trigger state changes<br>- Immutable state objects<br>- Reactive UI updates |
| ARCH-003 | Repository Pattern | Abstract data access via repositories | P0 | rules:3.1, 3.3 | - Repository interface in domain<br>- Implementation in data layer<br>- UseCase depends on interface |
| ARCH-004 | UseCase Pattern | Single-responsibility use cases | P0 | rules:3.1, spec.md:101-103 | - One use case per action<br>- Clear input/output<br>- Testable in isolation |
| ARCH-005 | Dependency Injection | Use get_it service locator | P0 | rules:3.4 | - All dependencies registered in injection_container.dart<br>- BLoCs as factories<br>- Repositories as lazy singletons |
| ARCH-006 | Error Handling with Either | Use dartz Either for operations | P0 | rules:4.3 | - Either<Failure, Success> return type<br>- Failure hierarchy defined<br>- Fold pattern for handling results |
| ARCH-007 | File Organization | One class per file, logical grouping | P1 | rules:3.2 | - Files under 300 lines<br>- Grouped imports (Dart → Flutter → External → Internal)<br>- Barrel files for public APIs |
| ARCH-008 | Naming Conventions | Follow Dart/Flutter conventions | P0 | rules:3.3, CLAUDE.md | - Files: snake_case<br>- Classes: PascalCase<br>- Variables/functions: camelCase<br>- Private: _camelCase |
| ARCH-009 | Entity vs Model Separation | Entities pure, Models with JSON | P0 | rules:3.3, 3.4 | - Entities in domain/ (no JSON)<br>- Models in data/ (extend entities)<br>- Clear separation of concerns |
| ARCH-010 | Presentation Logic Separation | No business logic in widgets | P0 | rules:3.1, spec.md:133-152 | - Widgets only render UI<br>- BLoC handles business logic<br>- Clean separation verified in code review |

---

## 11. DOMAIN-SPECIFIC REQUIREMENTS (DOMAIN)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| DOMAIN-001 | Respectful Language | Use non-stigmatizing HIV/AIDS terminology | P0 | CLAUDE.md:Rule#8, Task 1.2:665-687 | - "Living with HIV" (not "HIV-positive person")<br>- Scientific, empowering language<br>- Reviewed by community advocate |
| DOMAIN-002 | Privacy-Focused UI | Emphasize user privacy and safety | P0 | rules:11.2, Task 1.2:689-708 | - Clear privacy policy link<br>- Control over profile visibility<br>- Optional disclosure options<br>- Incognito mode (Premium) |
| DOMAIN-003 | Inclusive Design | Support diverse identities and relationships | P0 | Task 1.2:711-729 | - Non-binary gender options<br>- Diverse relationship types<br>- No hierarchy or judgment<br>- Respectful of all orientations |
| DOMAIN-004 | Safety Features | Prominent safety tools (report, block) | P0 | Task 1.2:731-757, spec.md:413 | - Easy report access<br>- Immediate block<br>- Safety tips for new users<br>- Community guidelines linked |
| DOMAIN-005 | Verification Privacy | Protect verification document privacy | P0 | CLAUDE.md:Rule#8, rules:11.2 | - Docs auto-deleted after processing<br>- Encrypted during review<br>- Never shown in profile<br>- Clear privacy explanation |
| DOMAIN-006 | Empty State Messaging | Supportive, non-judgmental empty states | P1 | Task 1.2:767-787 | - No blaming language<br>- Constructive suggestions<br>- Empowering tone<br>- Clear action steps |
| DOMAIN-007 | Anonymity Options | Support user anonymity preferences | P1 | Task 1.2:759-765 | - Hide from contacts<br>- Control distance precision<br>- Hide last active<br>- Incognito browsing |

---

## 12. COMPLIANCE & VALIDATION REQUIREMENTS (COMP)

| ID | Requirement | Description | Priority | Source | Acceptance Criteria |
|----|-------------|-------------|----------|--------|---------------------|
| COMP-001 | Specification Adherence | Implement ONLY features in specifications | P0 | CLAUDE.md:Rule#6, spec.md:5-38 | - All features mapped to spec source<br>- No invented features<br>- Spec traceability in PR |
| COMP-002 | API Contract Compliance | Match API_DOCUMENTATION.md exactly | P0 | CLAUDE.md:Rule#1, spec.md:82-125 | - All endpoints verified<br>- Request/response match docs<br>- No endpoint guessing |
| COMP-003 | Graphic Charter Compliance | Match Charte Graphique Detaille | P1 | spec.md:123-124 | - Colors match charter<br>- Typography follows specs<br>- Component designs accurate<br>- Spacing per specs |
| COMP-004 | Navigation Flow Compliance | Follow Description Détaillé des Écrans | P1 | spec.md:122 | - Navigation paths match<br>- State transitions correct<br>- Screen structure accurate |
| COMP-005 | Anti-Regression Protocol | Test all related features before completion | P0 | CLAUDE.md:Rule#4, rules:13 | - Discovery tested<br>- Profile, Matches, Messages tested<br>- No regressions found<br>- Evidence documented |
| COMP-006 | Code Quality Standards | Pass flutter analyze with zero errors | P0 | spec.md:515-516 | - `flutter analyze` clean<br>- No warnings on modified code<br>- Lint rules followed |
| COMP-007 | Build Verification | Code builds successfully | P0 | spec.md:515 | - `flutter build apk` succeeds<br>- No build errors<br>- Assets bundled correctly |
| COMP-008 | Documentation Updates | Update docs if API changes required | P1 | spec.md:616, CLAUDE.md:Rule#7 | - API changes documented<br>- README updated if needed<br>- Changelog updated |

---

## Requirements Summary

### By Category
| Category | Total | P0 | P1 | P2 | P3 |
|----------|-------|----|----|----|----|
| FUNC (Functional) | 25 | 17 | 7 | 1 | 0 |
| NFR (Non-Functional) | 7 | 2 | 3 | 2 | 0 |
| UI (User Interface) | 18 | 7 | 9 | 2 | 0 |
| DATA (Data Models) | 8 | 4 | 3 | 1 | 0 |
| API (Backend Integration) | 13 | 8 | 4 | 1 | 0 |
| SEC (Security & Privacy) | 8 | 6 | 2 | 0 | 0 |
| A11Y (Accessibility) | 8 | 4 | 4 | 0 | 0 |
| I18N (Internationalization) | 8 | 5 | 2 | 0 | 1 |
| TEST (Testing) | 19 | 8 | 11 | 0 | 0 |
| ARCH (Architecture) | 10 | 7 | 3 | 0 | 0 |
| DOMAIN (Domain-Specific) | 7 | 5 | 2 | 0 | 0 |
| COMP (Compliance) | 8 | 6 | 2 | 0 | 0 |
| **TOTAL** | **139** | **79** | **52** | **7** | **1** |

### By Priority
- **P0 (Critical):** 79 requirements (56.8%)
- **P1 (High):** 52 requirements (37.4%)
- **P2 (Medium):** 7 requirements (5.0%)
- **P3 (Low):** 1 requirement (0.7%)

---

## Requirements Traceability

### Primary Sources
1. **spec.md** - Main specification document (this task's spec)
2. **CLAUDE.md** - 8 critical rules for project compliance
3. **DISCOVERY_PAGE_IMPLEMENTATION.md** - Implementation guide
4. **FRONTEND_MATCHING_API.md** - API specification
5. **Document de Spécification Interface** - Complete API spec
6. **Spécifications Fonctionnelles Frontend** - Functional specs
7. **Description Détaillé des Écrans et Navigation** - Screen descriptions
8. **Architecture Technique Frontend** - Architecture patterns
9. **Charte Graphique Detaille** - UI design guidelines
10. **API_DOCUMENTATION.md** - Most recent API reference

### Extracted From
- Task 1.1: `discovery_page_rules_extraction.md`
- Task 1.2: `claude_md_discovery_requirements.md`
- Task 1.3: `discovery-documentation-audit.md`

---

## Usage Guide

### For Implementation (Phase 5)
1. **Start with P0 requirements** - Critical functionality first
2. **Group by category** - Implement related features together
3. **Verify against source** - Check spec.md and docs for details
4. **Test immediately** - Unit test as you implement

### For Gap Analysis (Phase 3)
1. **Map each requirement to implementation files**
2. **Check status:** Implemented / Partial / Missing / Incorrect
3. **Document evidence** for each status
4. **Prioritize gaps** by priority and dependencies

### For Testing (Phase 6)
1. **Use TEST-xxx requirements** as test case checklist
2. **Verify coverage targets** per TEST-015 through TEST-018
3. **Cross-reference** with other categories for integration tests

### For QA Sign-off (Phase 7)
1. **Verify all P0 requirements** implemented and working
2. **Check compliance requirements** (COMP-xxx)
3. **Validate accessibility** (A11Y-xxx)
4. **Confirm internationalization** (I18N-xxx)

---

## Next Steps

1. **Phase 2 (Implementation Inventory):** Map requirements to existing files
2. **Phase 3 (Gap Analysis):** Compare requirements against implementation
3. **Phase 4 (Backlog):** Prioritize missing/incorrect requirements
4. **Phase 5 (Implementation):** Execute according to priority
5. **Phase 6 (Testing):** Verify all TEST-xxx requirements
6. **Phase 7 (QA):** Complete QA acceptance based on this matrix

---

**Document Status:** ✅ Complete
**Total Requirements:** 139
**Last Updated:** 2026-02-25
**Task:** 1.4 Complete - Requirements Matrix Created

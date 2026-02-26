# Test Coverage Report - Discovery Page Compliance

**Generated**: 2026-02-26
**Task**: Subtask 6.8 - Coverage Analysis and Gap Identification
**Target**: Minimum 80% test coverage

---

## Executive Summary

This report analyzes test coverage for the HIVMeet Discovery page implementation and identifies critical code paths requiring test coverage to achieve the minimum 80% coverage threshold.

### Coverage Status Overview

| Layer | Files | Test Coverage | Status |
|-------|-------|---------------|--------|
| **Presentation (BLoC)** | 3 | ~75% | 🟡 Good |
| **Presentation (UI)** | 8 | ~15% | 🔴 Critical |
| **Domain (UseCases)** | 9 | ~22% | 🔴 Critical |
| **Domain (Entities)** | 2 | 0% | 🔴 Missing |
| **Data (Models)** | 2 | 0% | 🔴 Missing |
| **Data (Repositories)** | 2 | ~50% | 🟡 Partial |
| **Data (API)** | 1 | ~30% | 🔴 Low |
| **Integration** | N/A | 0% | 🔴 Missing |
| **OVERALL ESTIMATE** | **27** | **~28%** | 🔴 **BELOW TARGET** |

### Critical Findings

- ✅ **Discovery BLoC**: Well-tested (16 test scenarios)
- ✅ **Matches BLoC**: Well-tested (22+ test scenarios)
- ✅ **Accessibility Tests**: Comprehensive (completed in 6.7)
- 🔴 **52% coverage gap** to reach 80% minimum
- 🔴 **Widget/UI layer critically undertested** (~15%)
- 🔴 **No integration tests** for user flows
- 🔴 **Use cases partially tested** (only 2/9 have tests)
- 🔴 **Data layer undertested** (models, API calls)

---

## 1. Current Test Coverage Analysis

### 1.1 Presentation Layer - BLoCs (State Management)

#### ✅ WELL COVERED: DiscoveryBloc
**File**: `lib/presentation/blocs/discovery/discovery_bloc.dart`
**Test File**: `test/presentation/blocs/discovery/discovery_bloc_test.dart`
**Estimated Coverage**: ~75%

**Tested Scenarios** (16 tests):
1. ✅ Initial state verification
2. ✅ Load profiles success/failure
3. ✅ Empty profile handling
4. ✅ Daily limit loading
5. ✅ Like profile (swipe right)
6. ✅ Match detection
7. ✅ Daily limit reached
8. ✅ Dislike profile (swipe left)
9. ✅ Super like (swipe up)
10. ✅ Swipe error handling
11. ✅ Rewind last swipe
12. ✅ Rewind error handling
13. ✅ Cannot rewind at start
14. ✅ Update filters success
15. ✅ Update filters failure
16. ✅ No more profiles state

**Uncovered Code Paths**:
- ⚠️ Profile preloading logic
- ⚠️ Cache invalidation on filter change
- ⚠️ Multiple rapid swipes (race conditions)
- ⚠️ Network timeout handling
- ⚠️ Profile queue management edge cases

---

#### ✅ WELL COVERED: MatchesBloc
**File**: `lib/presentation/blocs/matches/matches_bloc.dart`
**Test File**: `test/presentation/blocs/matches/matches_bloc_test.dart`
**Estimated Coverage**: ~80%

**Status**: Comprehensive testing with 22+ scenarios including optimistic updates and rollback patterns.

---

### 1.2 Presentation Layer - UI Widgets

#### 🔴 CRITICALLY UNDERTESTED: Discovery Page
**File**: `lib/presentation/pages/discovery/discovery_page.dart`
**Test File**: `test/presentation/pages/discovery/discovery_page_test.dart`
**Estimated Coverage**: ~20%

**Current Tests** (5 scenarios):
1. ✅ Loading state renders
2. ✅ Error state renders
3. ✅ Empty state renders
4. ✅ Loaded state renders
5. ✅ Daily limit modal renders

**Uncovered Critical Paths**:
- 🔴 Action button interactions (like/dislike/super like)
- 🔴 Navigation to filters page
- 🔴 Navigation to profile detail
- 🔴 Match modal display and dismissal
- 🔴 Rewind button interaction
- 🔴 Daily limit counter display
- 🔴 Profile stack preloading
- 🔴 Error retry mechanism
- 🔴 Pull-to-refresh functionality
- 🔴 Accessibility announcements

**Priority**: **P0 - CRITICAL**

---

#### 🔴 NOT TESTED: SwipeCard Widget
**File**: `lib/presentation/widgets/cards/swipe_card.dart`
**Test File**: **MISSING**
**Estimated Coverage**: 0%

**Required Test Scenarios** (15 tests needed):
1. 🔴 Swipe left gesture triggers onSwipeLeft
2. 🔴 Swipe right gesture triggers onSwipeRight
3. 🔴 Swipe up gesture triggers onSuperLike
4. 🔴 Tap on card triggers onTap
5. 🔴 Swipe threshold detection
6. 🔴 Swipe direction accuracy
7. 🔴 Cancel swipe before threshold
8. 🔴 Haptic feedback on completion
9. 🔴 Swipe animation smoothness
10. 🔴 Disabled state prevents swipes
11. 🔴 Photo carousel integration
12. 🔴 Pagination dots display
13. 🔴 Badge overlay rendering
14. 🔴 Profile data display
15. 🔴 Card stack positioning

**Priority**: **P0 - CRITICAL** (core interaction)

---

#### 🔴 NOT TESTED: Action Buttons
**File**: `lib/presentation/widgets/buttons/action_button.dart`
**Test File**: `test/presentation/widgets/buttons/action_button_test.dart` (EXISTS but needs review)
**Estimated Coverage**: ~30%

**Required Test Scenarios**:
- 🔴 Like button triggers callback
- 🔴 Dislike button triggers callback
- 🔴 Super like button triggers callback
- 🔴 Rewind button (premium feature)
- 🔴 Disabled state rendering
- 🔴 Premium badge display
- 🔴 Button animations
- 🔴 Tooltip display on long press

**Priority**: **P0 - CRITICAL**

---

#### 🔴 NOT TESTED: Match Found Modal
**File**: `lib/presentation/widgets/modals/match_found_modal.dart`
**Test File**: **MISSING**
**Estimated Coverage**: 0%

**Required Test Scenarios** (10 tests needed):
1. 🔴 Modal displays with both profiles
2. 🔴 Match animation plays
3. 🔴 "Send Message" button navigation
4. 🔴 "Keep Swiping" button dismisses
5. 🔴 Back button dismisses
6. 🔴 Tap outside dismisses
7. 🔴 Accessibility announcements
8. 🔴 Confetti animation
9. 🔴 Profile photo loading
10. 🔴 Modal respects reduced motion

**Priority**: **P1 - HIGH** (key UX moment)

---

#### 🔴 NOT TESTED: Filters Page
**File**: `lib/presentation/pages/discovery/filters_page.dart`
**Test File**: **MISSING**
**Estimated Coverage**: 0%

**Required Test Scenarios** (12 tests needed):
1. 🔴 Age slider updates min/max values
2. 🔴 Distance slider updates value
3. 🔴 Relationship type multi-select
4. 🔴 Interests multi-select (max 5)
5. �4 "Verified only" toggle
6. 🔴 "Online only" toggle (premium)
7. 🔴 Profile count updates real-time
8. 🔴 Apply button triggers update
9. 🔴 Clear filters resets to defaults
10. 🔴 Filter persistence to storage
11. 🔴 Premium badge on locked filters
12. 🔴 Accessibility labels

**Priority**: **P1 - HIGH**

---

#### 🔴 NOT TESTED: Profile Detail Page
**File**: `lib/presentation/pages/discovery/profile_detail_page.dart`
**Test File**: **MISSING**
**Estimated Coverage**: 0%

**Required Test Scenarios** (8 tests needed):
1. 🔴 Profile data displays correctly
2. 🔴 Photo carousel navigation
3. 🔴 Bio section expansion
4. 🔴 Badges display (verified, premium)
5. 🔴 Interests section rendering
6. 🔴 Action buttons functional
7. 🔴 Back navigation
8. 🔴 Accessibility labels

**Priority**: **P2 - MEDIUM**

---

### 1.3 Domain Layer - Use Cases

#### 🔴 PARTIALLY TESTED: Discovery Use Cases
**Files**: `lib/domain/usecases/match/`
**Estimated Coverage**: ~22% (2/9 use cases tested)

**Tested Use Cases**:
1. ✅ DislikeProfile - `test/domain/usecases/match/dislike_profile_test.dart`
2. ✅ RewindSwipe - `test/domain/usecases/match/rewind_swipe_test.dart`

**Untested Use Cases** (7 tests needed):
1. 🔴 **GetDiscoveryProfiles** - Core profile loading logic
2. 🔴 **LikeProfile** - Match creation logic
3. 🔴 **SuperLikeProfile** - Premium feature logic
4. 🔴 **UpdateFilters** - Filter application logic
5. 🔴 **GetDailyLikeLimit** - Limit enforcement logic
6. 🔴 **GetLikesReceived** - Likes received logic
7. 🔴 **ActivateBoost** - Premium boost feature

**Priority**: **P0 - CRITICAL** (business logic validation)

**Required Test Scenarios Per Use Case** (each ~5 tests):
- Success path with valid input
- Repository failure handling
- Network failure handling
- Validation error handling
- Edge cases (boundaries, null values)

---

### 1.4 Domain Layer - Entities

#### 🔴 NOT TESTED: Discovery Entities
**Files**: `lib/domain/entities/`
**Estimated Coverage**: 0%

**Untested Entities** (2 test files needed):
1. 🔴 **Match Entity** - Equality, immutability, copyWith
2. 🔴 **DiscoveryProfile Entity** (if exists) - Same tests

**Priority**: **P2 - MEDIUM**

---

### 1.5 Data Layer - Models

#### 🔴 NOT TESTED: Data Models
**Files**: `lib/data/models/`
**Estimated Coverage**: 0%

**Untested Models** (2 test files needed):
1. 🔴 **DiscoveryProfileModel** - JSON serialization/deserialization
2. 🔴 **MatchModel** - JSON serialization (partial test exists, needs review)

**Required Test Scenarios Per Model** (each ~8 tests):
1. fromJson() with complete data
2. fromJson() with missing optional fields
3. fromJson() with null values
4. fromJson() with invalid data types
5. toJson() serialization
6. toEntity() conversion
7. Edge cases (empty strings, zero values)
8. Nested object handling

**Priority**: **P0 - CRITICAL** (data integrity)

---

### 1.6 Data Layer - Repositories

#### 🟡 PARTIALLY TESTED: Match Repository
**File**: `lib/data/repositories/match_repository_impl.dart`
**Test File**: `test/data/repositories/match_repository_impl_test.dart`
**Estimated Coverage**: ~50%

**Status**: Basic tests exist, needs coverage review

**Potential Uncovered Paths**:
- 🔴 Cache invalidation logic
- 🔴 Network error mapping
- 🔴 Concurrent request handling
- 🔴 Data source coordination

**Priority**: **P1 - HIGH**

---

### 1.7 Data Layer - API

#### 🟡 PARTIALLY TESTED: Matching API
**File**: `lib/data/datasources/remote/matching_api.dart`
**Test File**: `test/data/datasources/remote/matching_api_test.dart`
**Estimated Coverage**: ~30%

**Potential Uncovered Paths**:
- 🔴 All endpoint calls with real payloads
- 🔴 Auth token injection
- 🔴 Error response parsing
- 🔴 Pagination handling
- 🔴 Query parameter construction
- 🔴 Network timeout handling

**Priority**: **P1 - HIGH**

---

### 1.8 Integration Tests

#### 🔴 NOT IMPLEMENTED: User Flows
**Test Files**: **ALL MISSING**
**Estimated Coverage**: 0%

**Required Integration Tests** (4 test files needed):

1. 🔴 **Discovery Flow Test** (`test/integration/discovery_flow_test.dart`)
   - Load profiles → Swipe right → Match detected → Modal shown → Navigate to messages

2. 🔴 **Filter Application Test** (`test/integration/filter_application_test.dart`)
   - Change filters → Apply → Profiles reload with new criteria

3. 🔴 **Daily Limit Test** (`test/integration/daily_limit_test.dart`)
   - Reach 50 likes → Limit modal shown → Upgrade CTA displayed

4. 🔴 **Super Like Flow Test** (`test/integration/super_like_test.dart`)
   - Premium user → Tap super like → Confirmation → API call → Counter decrements

**Priority**: **P0 - CRITICAL** (end-to-end validation)

---

## 2. Critical Uncovered Code Paths

### High-Risk Uncovered Paths (P0)

1. **SwipeCard Gesture Recognition** (0% coverage)
   - Impact: Core user interaction could fail silently
   - Risk: User cannot swipe profiles
   - Files: `lib/presentation/widgets/cards/swipe_card.dart`

2. **Match Detection Logic** (BLoC tested, but use case untested)
   - Impact: Matches may not be detected
   - Risk: Users miss connections
   - Files: `lib/domain/usecases/match/like_profile.dart`

3. **Daily Limit Enforcement** (untested use case)
   - Impact: Free users could exceed limits or premium users blocked
   - Risk: Business logic failure, revenue impact
   - Files: `lib/domain/usecases/match/get_daily_like_limit.dart`

4. **Filter Application** (untested use case + UI)
   - Impact: Filters may not apply correctly
   - Risk: Wrong profiles shown, bad UX
   - Files: `lib/domain/usecases/match/update_filters.dart`, `lib/presentation/pages/discovery/filters_page.dart`

5. **Profile Data Serialization** (0% coverage)
   - Impact: Data parsing errors cause crashes
   - Risk: App crashes on bad API data
   - Files: `lib/data/models/discovery_profile_model.dart`

6. **API Integration** (partial coverage)
   - Impact: Network calls may fail silently
   - Risk: Data not synced, stale state
   - Files: `lib/data/datasources/remote/matching_api.dart`

---

### Medium-Risk Uncovered Paths (P1)

7. **Match Modal Display** (0% coverage)
   - Impact: Match celebration may not display
   - Risk: Reduced user engagement
   - Files: `lib/presentation/widgets/modals/match_found_modal.dart`

8. **Action Button Interactions** (partial coverage)
   - Impact: Buttons may not trigger actions
   - Risk: User confusion, failed actions
   - Files: `lib/presentation/widgets/buttons/action_button.dart`

9. **Profile Detail View** (0% coverage)
   - Impact: Detail view may render incorrectly
   - Risk: User cannot view full profiles
   - Files: `lib/presentation/pages/discovery/profile_detail_page.dart`

10. **Repository Error Mapping** (partial coverage)
    - Impact: Generic errors shown instead of specific
    - Risk: Poor error UX
    - Files: `lib/data/repositories/match_repository_impl.dart`

---

### Low-Risk Uncovered Paths (P2)

11. **Entity Equality** (0% coverage)
    - Impact: State comparison may fail
    - Risk: Unnecessary re-renders
    - Files: `lib/domain/entities/match.dart`

12. **Profile Preloading Logic** (untested)
    - Impact: Slow swipe transitions
    - Risk: Poor UX performance
    - Files: `lib/presentation/blocs/discovery/discovery_bloc.dart`

---

## 3. Test Requirements for 80% Coverage

To achieve 80% test coverage, the following tests must be implemented:

### 3.1 Required Test Files (Priority Order)

#### Phase 1: Critical Widget Tests (P0) - 5 files
1. ✅ `test/presentation/widgets/cards/swipe_card_test.dart` (15 tests)
2. ✅ `test/presentation/widgets/modals/match_found_modal_test.dart` (10 tests)
3. ✅ `test/presentation/pages/discovery/filters_page_test.dart` (12 tests)
4. ✅ Enhance `test/presentation/pages/discovery/discovery_page_test.dart` (+10 tests)
5. ✅ Enhance `test/presentation/widgets/buttons/action_button_test.dart` (+8 tests)

**Estimated Coverage Gain**: +15%

---

#### Phase 2: Use Case Tests (P0) - 7 files
6. ✅ `test/domain/usecases/match/get_discovery_profiles_test.dart` (5 tests)
7. ✅ `test/domain/usecases/match/like_profile_test.dart` (5 tests)
8. ✅ `test/domain/usecases/match/super_like_profile_test.dart` (5 tests)
9. ✅ `test/domain/usecases/match/update_filters_test.dart` (5 tests)
10. ✅ `test/domain/usecases/match/get_daily_like_limit_test.dart` (5 tests)
11. ✅ `test/domain/usecases/match/get_likes_received_test.dart` (5 tests)
12. ✅ `test/domain/usecases/match/activate_boost_test.dart` (5 tests)

**Estimated Coverage Gain**: +12%

---

#### Phase 3: Model Tests (P0) - 2 files
13. ✅ `test/data/models/discovery_profile_model_test.dart` (8 tests)
14. ✅ Enhance `test/data/models/match_model_test.dart` (+5 tests)

**Estimated Coverage Gain**: +8%

---

#### Phase 4: Integration Tests (P0) - 4 files
15. ✅ `test/integration/discovery_flow_test.dart` (3 scenarios)
16. ✅ `test/integration/filter_application_test.dart` (2 scenarios)
17. ✅ `test/integration/daily_limit_test.dart` (2 scenarios)
18. ✅ `test/integration/super_like_flow_test.dart` (2 scenarios)

**Estimated Coverage Gain**: +10%

---

#### Phase 5: API & Repository Tests (P1) - 2 files
19. ✅ Enhance `test/data/datasources/remote/matching_api_test.dart` (+10 tests)
20. ✅ Enhance `test/data/repositories/match_repository_impl_test.dart` (+8 tests)

**Estimated Coverage Gain**: +8%

---

#### Phase 6: Profile Detail & Accessibility (P1-P2) - 3 files
21. ✅ `test/presentation/pages/discovery/profile_detail_page_test.dart` (8 tests)
22. ✅ `test/domain/entities/match_test.dart` (5 tests)
23. ✅ Enhanced accessibility tests (completed in 6.7)

**Estimated Coverage Gain**: +7%

---

### 3.2 Coverage Projection

| Phase | Tests Added | Cumulative Coverage | Status |
|-------|-------------|---------------------|--------|
| **Current** | 0 | ~28% | 🔴 Below target |
| **Phase 1** | 55 tests | ~43% | 🔴 Below target |
| **Phase 2** | 35 tests | ~55% | 🔴 Below target |
| **Phase 3** | 13 tests | ~63% | 🔴 Below target |
| **Phase 4** | 9 tests | ~73% | 🟡 Approaching target |
| **Phase 5** | 18 tests | ~81% | ✅ **TARGET ACHIEVED** |
| **Phase 6** | 13 tests | ~88% | ✅ **EXCEEDS TARGET** |

**Total Tests Needed**: ~143 additional tests
**Estimated Implementation Time**: 24-30 hours

---

## 4. Recommended Action Plan

### Immediate Actions (Week 1)

1. **Implement Phase 1: Critical Widget Tests**
   - SwipeCard gesture tests (highest priority)
   - Match modal tests
   - Filters page tests
   - Enhanced discovery page tests
   - Enhanced action button tests

2. **Implement Phase 2: Use Case Tests**
   - All 7 missing use case test files
   - Focus on GetDiscoveryProfiles and LikeProfile first

3. **Implement Phase 3: Model Tests**
   - DiscoveryProfileModel serialization tests
   - Enhanced MatchModel tests

**Expected Coverage After Week 1**: ~63%

---

### Follow-up Actions (Week 2)

4. **Implement Phase 4: Integration Tests**
   - Complete discovery flow test
   - Filter application test
   - Daily limit test
   - Super like flow test

5. **Implement Phase 5: API & Repository Tests**
   - Enhanced matching API tests
   - Enhanced repository tests

**Expected Coverage After Week 2**: ~81% ✅ **TARGET ACHIEVED**

---

### Optional Enhancement (Week 3)

6. **Implement Phase 6: Additional Coverage**
   - Profile detail page tests
   - Entity tests
   - Additional accessibility tests

**Expected Coverage After Week 3**: ~88%

---

## 5. Coverage Monitoring Strategy

### Automated Coverage Reports

```bash
# Generate coverage report
flutter test --coverage

# Convert to HTML (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### Coverage Thresholds

Set minimum coverage thresholds in `analysis_options.yaml`:

```yaml
coverage:
  minimum_coverage: 80
  exclude:
    - '**/*.g.dart'  # Generated files
    - '**/*.freezed.dart'  # Generated files
    - '**/main.dart'  # App entry point
```

### CI/CD Integration

Add coverage check to CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Check coverage threshold
  run: |
    lcov --summary coverage/lcov.info | grep "lines......: 80"
```

---

## 6. Coverage Gaps Justification

### Excluded from Coverage

The following files/paths are intentionally excluded from coverage requirements:

1. **Generated Files** (`*.g.dart`, `*.freezed.dart`)
   - Reason: Auto-generated, tested through their usage

2. **Main Entry Point** (`main.dart`)
   - Reason: Difficult to test, minimal logic

3. **Theme Files** (`lib/core/theme/`)
   - Reason: Visual constants, not business logic

4. **Asset Constants** (`lib/core/utils/assets.dart`)
   - Reason: String constants, not logic

5. **Mock Implementations** (`*_mock.dart`)
   - Reason: Test doubles, not production code

---

## 7. Conclusion

### Summary

- **Current Coverage**: ~28%
- **Target Coverage**: 80%
- **Coverage Gap**: 52%
- **Tests Required**: ~143 additional tests across 23 files
- **Estimated Effort**: 24-30 hours

### Critical Next Steps

1. ✅ Implement Phase 1: Critical Widget Tests (5 files, ~55 tests)
2. ✅ Implement Phase 2: Use Case Tests (7 files, ~35 tests)
3. ✅ Implement Phase 3: Model Tests (2 files, ~13 tests)
4. ✅ Implement Phase 4: Integration Tests (4 files, ~9 tests)
5. ✅ Verify 80% coverage achieved
6. ✅ Enhance to 88% coverage (optional)

### Risk Assessment

**High Risk**: SwipeCard gestures, match detection, daily limits, filters, data serialization
**Medium Risk**: Match modal, action buttons, profile detail, error mapping
**Low Risk**: Entity equality, preloading optimization

### Success Criteria

- ✅ Minimum 80% test coverage achieved
- ✅ All critical code paths tested
- ✅ Integration tests covering main user flows
- ✅ No high-risk uncovered code paths remaining
- ✅ Coverage reports generated and documented
- ✅ CI/CD coverage checks in place

---

**Report Generated**: 2026-02-26
**Next Review**: After Phase 1 implementation
**Status**: 🔴 **ACTION REQUIRED** - 52% coverage gap must be closed

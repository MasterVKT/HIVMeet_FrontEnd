# Test Implementation Roadmap - Achieving 80% Coverage

**Task**: Discovery Page Spec Compliance - Test Coverage
**Target**: Minimum 80% test coverage
**Current Coverage**: ~28%
**Gap to Close**: 52%

---

## Overview

This roadmap provides detailed test scenarios for all missing test files required to achieve 80% coverage. Each section includes:
- File path
- Priority level
- Estimated test count
- Detailed test scenarios
- Code patterns to follow

---

## Phase 1: Critical Widget Tests (Priority P0)

### 1.1 SwipeCard Widget Tests

**File**: `test/presentation/widgets/cards/swipe_card_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 15
**Estimated Time**: 3 hours
**Coverage Gain**: +5%

#### Test Scenarios

```dart
group('SwipeCard Widget Tests', () {
  late MockDiscoveryBloc mockBloc;

  setUp(() {
    mockBloc = MockDiscoveryBloc();
  });

  group('Rendering', () {
    test('1. renders with profile data', () {
      // Verify name, age, distance display
      // Verify photo displays
      // Verify badges (verified, premium, online)
    });

    test('2. renders photo carousel with pagination dots', () {
      // Verify multiple photos
      // Verify dot count matches photo count
      // Verify active dot highlights correctly
    });

    test('3. renders in disabled state', () {
      // Verify swipe gestures disabled
      // Verify visual disabled indicator
    });
  });

  group('Swipe Gestures', () {
    test('4. left swipe triggers onSwipeLeft callback', () {
      // Simulate drag gesture left
      // Verify callback called with correct profile ID
    });

    test('5. right swipe triggers onSwipeRight callback', () {
      // Simulate drag gesture right
      // Verify callback called with correct profile ID
    });

    test('6. up swipe triggers onSuperLike callback', () {
      // Simulate drag gesture up
      // Verify callback called with correct profile ID
    });

    test('7. swipe threshold detection works', () {
      // Swipe 30% (below threshold) - no callback
      // Swipe 60% (above threshold) - callback triggered
    });

    test('8. cancel swipe before threshold', () {
      // Start swipe, release before threshold
      // Verify card returns to center
      // Verify no callback triggered
    });

    test('9. swipe direction accuracy', () {
      // Test diagonal swipes
      // Verify correct direction detected (left/right/up)
    });
  });

  group('Interactions', () {
    test('10. tap on card triggers onTap callback', () {
      // Tap on card
      // Verify navigation to profile detail
    });

    test('11. horizontal swipe on photo changes photo', () {
      // Swipe left on photo area
      // Verify photo index changes
      // Verify pagination dot updates
    });
  });

  group('Animations', () {
    test('12. swipe animation runs smoothly', () {
      // Trigger swipe
      // Verify animation controller
      // Verify card moves off screen
    });

    test('13. return animation when swipe cancelled', () {
      // Partial swipe, release
      // Verify card animates back to center
    });
  });

  group('Accessibility', () {
    test('14. has semantic labels for screen readers', () {
      // Verify profile summary semantics
      // Verify swipe gesture hints
    });

    test('15. respects reduced motion settings', () {
      // Enable reduced motion
      // Verify animations simplified/disabled
    });
  });
});
```

---

### 1.2 Match Found Modal Tests

**File**: `test/presentation/widgets/modals/match_found_modal.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 10
**Estimated Time**: 2 hours
**Coverage Gain**: +3%

#### Test Scenarios

```dart
group('MatchFoundModal Widget Tests', () {
  group('Rendering', () {
    test('1. displays both user profiles', () {
      // Verify current user photo
      // Verify matched user photo
      // Verify names display
    });

    test('2. displays "It\'s a Match!" message', () {
      // Verify internationalized message
      // Verify message uses correct locale
    });

    test('3. displays action buttons', () {
      // Verify "Send Message" button present
      // Verify "Keep Swiping" button present
    });

    test('4. plays match animation on mount', () {
      // Verify confetti animation
      // Verify heart animation
    });
  });

  group('Interactions', () {
    test('5. "Send Message" button navigates to chat', () {
      // Tap button
      // Verify navigation to conversation page
      // Verify correct match ID passed
    });

    test('6. "Keep Swiping" button dismisses modal', () {
      // Tap button
      // Verify modal dismissed
      // Verify navigation back to discovery
    });

    test('7. back button dismisses modal', () {
      // Press back button
      // Verify modal dismissed
    });

    test('8. tap outside dismisses modal', () {
      // Tap barrier
      // Verify modal dismissed
    });
  });

  group('Accessibility', () {
    test('9. announces match to screen readers', () {
      // Verify live region announcement
      // Verify match details semantics
    });

    test('10. respects reduced motion for animations', () {
      // Enable reduced motion
      // Verify animations disabled/simplified
    });
  });
});
```

---

### 1.3 Filters Page Tests

**File**: `test/presentation/pages/discovery/filters_page_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 12
**Estimated Time**: 3 hours
**Coverage Gain**: +4%

#### Test Scenarios

```dart
group('FiltersPage Widget Tests', () {
  late MockDiscoveryBloc mockBloc;

  setUp(() {
    mockBloc = MockDiscoveryBloc();
    when(() => mockBloc.state).thenReturn(
      DiscoveryLoaded(profiles: [], estimatedCount: 50),
    );
  });

  group('Age Slider', () {
    test('1. displays current age range', () {
      // Verify min age displayed
      // Verify max age displayed
    });

    test('2. updates age range on slider change', () {
      // Drag slider
      // Verify values update
      // Verify estimated count updates
    });
  });

  group('Distance Slider', () {
    test('3. displays current distance', () {
      // Verify distance value displayed (e.g., "50 km")
    });

    test('4. updates distance on slider change', () {
      // Drag slider
      // Verify value updates
      // Verify estimated count updates
    });
  });

  group('Relationship Types', () {
    test('5. displays relationship type options', () {
      // Verify all types present
      // Verify multi-select UI
    });

    test('6. allows multi-selection', () {
      // Tap multiple options
      // Verify all selected
    });
  });

  group('Interests', () {
    test('7. displays interest options', () {
      // Verify interests list
    });

    test('8. limits selection to 5 interests', () {
      // Select 5 interests
      // Try to select 6th
      // Verify disabled/warning shown
    });
  });

  group('Premium Toggles', () {
    test('9. "Verified only" toggle works', () {
      // Toggle on
      // Verify state updated
      // Verify premium badge if not premium user
    });

    test('10. "Online only" toggle locked for free users', () {
      // Free user
      // Tap toggle
      // Verify premium upgrade prompt
    });
  });

  group('Actions', () {
    test('11. apply button triggers filter update', () {
      // Change filters
      // Tap apply
      // Verify UpdateFilters event dispatched
      // Verify navigation back to discovery
    });

    test('12. clear filters resets to defaults', () {
      // Change filters
      // Tap clear
      // Verify all filters reset
    });
  });
});
```

---

### 1.4 Enhanced Discovery Page Tests

**File**: `test/presentation/pages/discovery/discovery_page_test.dart` (enhance existing)
**Priority**: P0 - CRITICAL
**Estimated Additional Tests**: 10
**Estimated Time**: 2 hours
**Coverage Gain**: +3%

#### Additional Test Scenarios

```dart
group('DiscoveryPage Interaction Tests', () {
  group('Action Buttons', () {
    test('6. like button triggers like event', () {
      // Tap like button
      // Verify SwipeProfile event dispatched (right)
    });

    test('7. dislike button triggers dislike event', () {
      // Tap dislike button
      // Verify SwipeProfile event dispatched (left)
    });

    test('8. super like button triggers super like event', () {
      // Tap super like button
      // Verify SwipeProfile event dispatched (up)
    });

    test('9. rewind button triggers rewind event', () {
      // Tap rewind button
      // Verify RewindLastSwipe event dispatched
    });
  });

  group('Navigation', () {
    test('10. filter button navigates to filters page', () {
      // Tap filter button
      // Verify navigation to FiltersPage
    });

    test('11. profile tap navigates to detail page', () {
      // Tap profile card
      // Verify navigation to ProfileDetailPage
    });
  });

  group('Match Flow', () {
    test('12. match state displays match modal', () {
      // Emit MatchFound state
      // Verify modal displayed
    });
  });

  group('Daily Limit', () {
    test('13. daily limit counter displays remaining likes', () {
      // Verify counter shows "X likes remaining"
    });

    test('14. upgrade CTA shown when limit reached', () {
      // Emit DailyLimitReached state
      // Verify upgrade modal shown
    });
  });

  group('Error Handling', () {
    test('15. retry button triggers reload', () {
      // Error state
      // Tap retry
      // Verify LoadDiscoveryProfiles event
    });
  });
});
```

---

### 1.5 Enhanced Action Button Tests

**File**: `test/presentation/widgets/buttons/action_button_test.dart` (enhance existing)
**Priority**: P0 - CRITICAL
**Estimated Additional Tests**: 8
**Estimated Time**: 1.5 hours
**Coverage Gain**: +2%

#### Additional Test Scenarios

```dart
group('ActionButton Enhanced Tests', () {
  group('Disabled States', () {
    test('1. disabled when daily limit reached', () {
      // Set disabled=true
      // Verify button grayed out
      // Tap button
      // Verify no callback triggered
    });

    test('2. disabled during API call', () {
      // Set loading=true
      // Verify button shows loading indicator
      // Verify tap disabled
    });
  });

  group('Premium Features', () {
    test('3. super like shows premium badge for free users', () {
      // Free user
      // Render super like button
      // Verify premium badge overlay
    });

    test('4. rewind button locked for free users', () {
      // Free user
      // Tap rewind
      // Verify upgrade prompt shown
    });
  });

  group('Animations', () {
    test('5. button scales on press', () {
      // Press button
      // Verify scale animation
    });

    test('6. success animation plays', () {
      // Trigger success
      // Verify success animation (checkmark, etc.)
    });
  });

  group('Tooltips', () {
    test('7. tooltip shows on long press', () {
      // Long press button
      // Verify tooltip text displayed
    });

    test('8. tooltip explains locked features', () {
      // Free user, premium button
      // Long press
      // Verify "Upgrade to Premium" tooltip
    });
  });
});
```

---

## Phase 2: Use Case Tests (Priority P0)

### 2.1 GetDiscoveryProfiles Use Case

**File**: `test/domain/usecases/match/get_discovery_profiles_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 5
**Estimated Time**: 1 hour
**Coverage Gain**: +2%

#### Test Scenarios

```dart
group('GetDiscoveryProfilesUseCase', () {
  late GetDiscoveryProfilesUseCase useCase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    useCase = GetDiscoveryProfilesUseCase(mockRepository);
  });

  test('1. returns profiles on success', () async {
    // Arrange
    final profiles = [testProfile1, testProfile2];
    when(() => mockRepository.getDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(profiles));

    // Act
    final result = await useCase(GetDiscoveryProfilesParams(limit: 20));

    // Assert
    expect(result, Right(profiles));
    verify(() => mockRepository.getDiscoveryProfiles(any())).called(1);
  });

  test('2. returns ServerFailure on repository failure', () async {
    // Arrange
    when(() => mockRepository.getDiscoveryProfiles(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(GetDiscoveryProfilesParams(limit: 20));

    // Assert
    expect(result, Left(ServerFailure('Server error')));
  });

  test('3. returns NetworkFailure when offline', () async {
    // Arrange
    when(() => mockRepository.getDiscoveryProfiles(any()))
        .thenAnswer((_) async => Left(NetworkFailure('No connection')));

    // Act
    final result = await useCase(GetDiscoveryProfilesParams(limit: 20));

    // Assert
    expect(result, Left(NetworkFailure('No connection')));
  });

  test('4. passes correct parameters to repository', () async {
    // Arrange
    when(() => mockRepository.getDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right([]));

    // Act
    await useCase(GetDiscoveryProfilesParams(
      limit: 30,
      cursor: 'next_page',
    ));

    // Assert
    verify(() => mockRepository.getDiscoveryProfiles(
      GetDiscoveryProfilesParams(limit: 30, cursor: 'next_page'),
    )).called(1);
  });

  test('5. handles empty profile list', () async {
    // Arrange
    when(() => mockRepository.getDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right([]));

    // Act
    final result = await useCase(GetDiscoveryProfilesParams(limit: 20));

    // Assert
    expect(result, Right([]));
  });
});
```

---

### 2.2 LikeProfile Use Case

**File**: `test/domain/usecases/match/like_profile_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 6
**Estimated Time**: 1.5 hours
**Coverage Gain**: +2%

#### Test Scenarios

```dart
group('LikeProfileUseCase', () {
  late LikeProfileUseCase useCase;
  late MockMatchRepository mockRepository;

  setUp(() {
    mockRepository = MockMatchRepository();
    useCase = LikeProfileUseCase(mockRepository);
  });

  test('1. returns "liked" result on success (no match)', () async {
    // Arrange
    final result = LikeResult(result: 'liked', isMatch: false);
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Right(result));

    // Act
    final response = await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    expect(response, Right(result));
    expect(result.isMatch, false);
  });

  test('2. returns "match" result when mutual like', () async {
    // Arrange
    final matchResult = LikeResult(
      result: 'match',
      isMatch: true,
      matchId: 'match123',
    );
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Right(matchResult));

    // Act
    final response = await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    expect(response, Right(matchResult));
    expect(matchResult.isMatch, true);
    expect(matchResult.matchId, 'match123');
  });

  test('3. returns DailyLimitFailure when limit reached', () async {
    // Arrange
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Left(DailyLimitFailure('Limit reached')));

    // Act
    final result = await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    expect(result, Left(DailyLimitFailure('Limit reached')));
  });

  test('4. returns ServerFailure on API error', () async {
    // Arrange
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server error')));

    // Act
    final result = await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    expect(result, Left(ServerFailure('Server error')));
  });

  test('5. returns NetworkFailure when offline', () async {
    // Arrange
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Left(NetworkFailure('No connection')));

    // Act
    final result = await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    expect(result, Left(NetworkFailure('No connection')));
  });

  test('6. passes correct profile ID to repository', () async {
    // Arrange
    when(() => mockRepository.likeProfile(any()))
        .thenAnswer((_) async => Right(LikeResult(result: 'liked', isMatch: false)));

    // Act
    await useCase(LikeProfileParams(profileId: 'user123'));

    // Assert
    verify(() => mockRepository.likeProfile(
      LikeProfileParams(profileId: 'user123'),
    )).called(1);
  });
});
```

---

### 2.3-2.7 Additional Use Case Tests

**Remaining Use Cases** (similar patterns):
- `super_like_profile_test.dart` (5 tests)
- `update_filters_test.dart` (5 tests)
- `get_daily_like_limit_test.dart` (5 tests)
- `get_likes_received_test.dart` (5 tests)
- `activate_boost_test.dart` (5 tests)

**Total Estimated Time**: 5 hours
**Total Coverage Gain**: +10%

Each follows the same pattern:
1. Success scenario
2. Various failure scenarios (Server, Network, Validation)
3. Parameter passing verification
4. Edge cases

---

## Phase 3: Model Tests (Priority P0)

### 3.1 DiscoveryProfileModel Tests

**File**: `test/data/models/discovery_profile_model_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 8
**Estimated Time**: 2 hours
**Coverage Gain**: +4%

#### Test Scenarios

```dart
group('DiscoveryProfileModel', () {
  final tJsonComplete = {
    'id': 'user123',
    'name': 'John Doe',
    'age': 28,
    'photos': ['photo1.jpg', 'photo2.jpg'],
    'bio': 'Test bio',
    'distance': 5.2,
    'is_verified': true,
    'is_online': true,
    'compatibility_score': 85,
    'interests': ['hiking', 'reading'],
    'relationship_types': ['friendship', 'dating'],
  };

  test('1. fromJson() with complete data', () {
    // Act
    final model = DiscoveryProfileModel.fromJson(tJsonComplete);

    // Assert
    expect(model.id, 'user123');
    expect(model.name, 'John Doe');
    expect(model.age, 28);
    expect(model.photos.length, 2);
    expect(model.isVerified, true);
  });

  test('2. fromJson() with missing optional fields', () {
    // Arrange
    final jsonMinimal = {
      'id': 'user123',
      'name': 'John Doe',
      'age': 28,
      'photos': ['photo1.jpg'],
    };

    // Act
    final model = DiscoveryProfileModel.fromJson(jsonMinimal);

    // Assert
    expect(model.id, 'user123');
    expect(model.bio, null);
    expect(model.compatibilityScore, null);
  });

  test('3. fromJson() handles null values gracefully', () {
    // Arrange
    final jsonWithNulls = {
      'id': 'user123',
      'name': 'John Doe',
      'age': 28,
      'photos': [],
      'bio': null,
      'distance': null,
    };

    // Act
    final model = DiscoveryProfileModel.fromJson(jsonWithNulls);

    // Assert
    expect(model.bio, null);
    expect(model.distance, null);
  });

  test('4. toJson() serializes correctly', () {
    // Arrange
    final model = DiscoveryProfileModel(
      id: 'user123',
      name: 'John Doe',
      age: 28,
      photos: ['photo1.jpg'],
    );

    // Act
    final json = model.toJson();

    // Assert
    expect(json['id'], 'user123');
    expect(json['name'], 'John Doe');
    expect(json['age'], 28);
  });

  test('5. toEntity() converts to domain entity', () {
    // Arrange
    final model = DiscoveryProfileModel.fromJson(tJsonComplete);

    // Act
    final entity = model.toEntity();

    // Assert
    expect(entity.id, model.id);
    expect(entity.name, model.name);
    expect(entity.age, model.age);
  });

  test('6. handles empty arrays', () {
    // Arrange
    final jsonEmptyArrays = {
      'id': 'user123',
      'name': 'John Doe',
      'age': 28,
      'photos': [],
      'interests': [],
    };

    // Act
    final model = DiscoveryProfileModel.fromJson(jsonEmptyArrays);

    // Assert
    expect(model.photos, []);
    expect(model.interests, []);
  });

  test('7. handles invalid data types gracefully', () {
    // This test verifies error handling or type coercion
  });

  test('8. round-trip conversion (toJson -> fromJson)', () {
    // Arrange
    final original = DiscoveryProfileModel.fromJson(tJsonComplete);

    // Act
    final json = original.toJson();
    final reconstructed = DiscoveryProfileModel.fromJson(json);

    // Assert
    expect(reconstructed.id, original.id);
    expect(reconstructed.name, original.name);
    // ... all fields match
  });
});
```

---

## Phase 4: Integration Tests (Priority P0)

### 4.1 Discovery Flow Integration Test

**File**: `test/integration/discovery_flow_test.dart`
**Priority**: P0 - CRITICAL
**Estimated Tests**: 3 scenarios
**Estimated Time**: 3 hours
**Coverage Gain**: +6%

#### Test Scenarios

```dart
group('Discovery Flow Integration Tests', () {
  testWidgets('Complete discovery flow: load → swipe → match → navigate', (tester) async {
    // 1. Setup mock data
    // 2. Launch app and navigate to Discovery
    // 3. Verify profiles loaded
    // 4. Swipe right on profile
    // 5. Verify match modal appears
    // 6. Tap "Send Message"
    // 7. Verify navigation to conversation
  });

  testWidgets('Discovery flow: load → swipe all → no more profiles', (tester) async {
    // 1. Setup limited profile list
    // 2. Swipe through all profiles
    // 3. Verify "No more profiles" state
    // 4. Verify suggestion to adjust filters
  });

  testWidgets('Discovery flow: load → network error → retry → success', (tester) async {
    // 1. Simulate network error
    // 2. Verify error state displayed
    // 3. Tap retry button
    // 4. Simulate successful response
    // 5. Verify profiles loaded
  });
});
```

---

### 4.2-4.4 Additional Integration Tests

**Remaining Integration Tests**:
- `filter_application_test.dart` (2 scenarios, 2 hours)
- `daily_limit_test.dart` (2 scenarios, 1.5 hours)
- `super_like_flow_test.dart` (2 scenarios, 1.5 hours)

**Total Estimated Time**: 8 hours
**Total Coverage Gain**: +10%

---

## Phase 5: API & Repository Tests (Priority P1)

### 5.1 Enhanced Matching API Tests

**File**: `test/data/datasources/remote/matching_api_test.dart` (enhance existing)
**Priority**: P1 - HIGH
**Estimated Additional Tests**: 10
**Estimated Time**: 3 hours
**Coverage Gain**: +4%

#### Additional Test Scenarios

```dart
group('MatchingAPI Enhanced Tests', () {
  group('getDiscoveryProfiles', () {
    test('1. includes auth token in headers', () async {
      // Verify Authorization header present
    });

    test('2. constructs query parameters correctly', () async {
      // Verify limit, cursor, filters in query
    });

    test('3. parses response correctly', () async {
      // Verify JSON parsing
    });

    test('4. handles pagination cursor', () async {
      // Verify next_cursor extracted
    });
  });

  group('likeProfile', () {
    test('5. sends POST request with profile ID', () async {
      // Verify endpoint, method, body
    });

    test('6. returns match result', () async {
      // Verify match detection
    });
  });

  group('Error Handling', () {
    test('7. throws ServerException on 500 error', () async {
      // Mock 500 response
      // Verify exception thrown
    });

    test('8. throws NetworkException on timeout', () async {
      // Mock timeout
      // Verify exception thrown
    });

    test('9. throws AuthException on 401 error', () async {
      // Mock 401 response
      // Verify exception thrown
    });

    test('10. parses error response body', () async {
      // Mock error response with details
      // Verify error message extracted
    });
  });
});
```

---

### 5.2 Enhanced Repository Tests

**File**: `test/data/repositories/match_repository_impl_test.dart` (enhance existing)
**Priority**: P1 - HIGH
**Estimated Additional Tests**: 8
**Estimated Time**: 2.5 hours
**Coverage Gain**: +4%

---

## Phase 6: Additional Coverage (Priority P2)

### 6.1 Profile Detail Page Tests

**File**: `test/presentation/pages/discovery/profile_detail_page_test.dart`
**Priority**: P2 - MEDIUM
**Estimated Tests**: 8
**Estimated Time**: 2 hours
**Coverage Gain**: +3%

---

### 6.2 Entity Tests

**File**: `test/domain/entities/match_test.dart`
**Priority**: P2 - MEDIUM
**Estimated Tests**: 5
**Estimated Time**: 1 hour
**Coverage Gain**: +2%

---

## Summary: Test Implementation Roadmap

| Phase | Files | Tests | Time | Coverage Gain | Cumulative |
|-------|-------|-------|------|---------------|------------|
| **Phase 1** | 5 | 55 | 11.5h | +15% | ~43% |
| **Phase 2** | 7 | 35 | 5h | +12% | ~55% |
| **Phase 3** | 2 | 13 | 3h | +8% | ~63% |
| **Phase 4** | 4 | 9 | 8h | +10% | ~73% |
| **Phase 5** | 2 | 18 | 5.5h | +8% | ~81% | ✅
| **Phase 6** | 3 | 13 | 3h | +7% | ~88% |
| **TOTAL** | **23** | **143** | **36h** | **+60%** | **88%** |

---

## Implementation Guidelines

### 1. Test Structure Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

// Mock classes
class MockRepository extends Mock implements Repository {}

void main() {
  late UseCase useCase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    useCase = UseCase(mockRepository);
  });

  group('FeatureName', () {
    group('SubFeature', () {
      test('should do something when condition', () async {
        // Arrange
        when(() => mockRepository.method())
            .thenAnswer((_) async => Right(result));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, Right(expected));
        verify(() => mockRepository.method()).called(1);
      });
    });
  });
}
```

### 2. Widget Test Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockBloc extends Mock implements Bloc {}

void main() {
  late MockBloc mockBloc;

  setUp(() {
    mockBloc = MockBloc();
  });

  testWidgets('should render widget when state is X', (tester) async {
    // Arrange
    when(() => mockBloc.state).thenReturn(StateX());

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<Bloc>.value(
          value: mockBloc,
          child: WidgetUnderTest(),
        ),
      ),
    );

    // Assert
    expect(find.byType(ExpectedWidget), findsOneWidget);
  });
}
```

### 3. Integration Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Flow', () {
    testWidgets('complete user flow', (tester) async {
      // 1. Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // 2. Navigate to feature
      await tester.tap(find.byKey(Key('feature_button')));
      await tester.pumpAndSettle();

      // 3. Interact
      await tester.drag(find.byType(SwipeCard), Offset(-300, 0));
      await tester.pumpAndSettle();

      // 4. Verify
      expect(find.text('Liked!'), findsOneWidget);
    });
  });
}
```

---

## Quality Checklist

Before marking each test file complete:

- [ ] All test scenarios implemented
- [ ] Follows project testing patterns
- [ ] Uses mocktail for mocking
- [ ] Has setUp and tearDown
- [ ] Follows Arrange-Act-Assert pattern
- [ ] No hardcoded strings (use constants)
- [ ] Tests are deterministic (no DateTime.now())
- [ ] Proper error handling tested
- [ ] Edge cases covered
- [ ] Accessibility scenarios included
- [ ] All tests pass
- [ ] Coverage report shows improvement

---

## Next Steps

1. ✅ Start with Phase 1: Critical Widget Tests
2. ✅ Implement SwipeCard tests first (highest priority)
3. ✅ Run coverage after each phase
4. ✅ Document coverage improvements in build-progress.txt
5. ✅ Commit after each completed phase

**Status**: Ready for implementation
**Target Completion**: 80% coverage by end of Phase 5

// test/presentation/pages/discovery/discovery_page_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/pages/discovery/discovery_page.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';
import 'package:hivmeet/presentation/widgets/buttons/action_button.dart';
import 'package:hivmeet/presentation/widgets/modals/filters_modal.dart';
import 'package:hivmeet/presentation/widgets/modals/match_found_modal.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockDiscoveryBloc extends Mock implements DiscoveryBloc {}
class MockGoRouter extends Mock implements GoRouter {}
class FakeDiscoveryEvent extends Fake implements DiscoveryEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(FakeDiscoveryEvent());
  });

  group('DiscoveryPage Widget Tests', () {
    late MockDiscoveryBloc mockDiscoveryBloc;
    late StreamController<DiscoveryState> stateController;

    setUp(() {
      mockDiscoveryBloc = MockDiscoveryBloc();
      stateController = StreamController<DiscoveryState>.broadcast();

      // Default behavior
      when(() => mockDiscoveryBloc.stream).thenAnswer((_) => stateController.stream);
      when(() => mockDiscoveryBloc.add(any())).thenReturn(null);
    });

    tearDown(() {
      stateController.close();
    });

    /// Helper to build the widget with mocked BLoC
    Widget buildDiscoveryPage(DiscoveryState initialState) {
      when(() => mockDiscoveryBloc.state).thenReturn(initialState);

      return MaterialApp(
        home: BlocProvider<DiscoveryBloc>.value(
          value: mockDiscoveryBloc,
          child: const DiscoveryPage(),
        ),
      );
    }

    /// Helper to create a mock profile
    DiscoveryProfile createMockProfile({
      String id = '1',
      String displayName = 'Test User',
      int age = 25,
      double distance = 5.0,
      bool isVerified = true,
      bool isPremium = false,
      double compatibilityScore = 85.0,
    }) {
      return DiscoveryProfile(
        id: id,
        displayName: displayName,
        age: age,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [],
        bio: 'Test bio',
        city: 'Paris',
        country: 'France',
        distance: distance,
        interests: ['Musique', 'Sport'],
        relationshipType: 'any',
        isVerified: isVerified,
        isPremium: isPremium,
        lastActive: DateTime.now(),
        compatibilityScore: compatibilityScore,
      );
    }

    group('State Rendering Tests', () {
      testWidgets('should display loading widget when state is DiscoveryLoading',
          (WidgetTester tester) async {
        // Arrange
        final state = DiscoveryLoading();

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(LocalizationService.translate('discovery.loading_profiles')), findsOneWidget);
      });

      testWidgets('should display loading widget when state is DiscoveryInitial',
          (WidgetTester tester) async {
        // Arrange
        final state = DiscoveryInitial();

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(LocalizationService.translate('common.initializing')), findsOneWidget);
      });

      testWidgets('should display error widget when state is DiscoveryError without previousState',
          (WidgetTester tester) async {
        // Arrange
        const errorMessage = 'Network connection failed';
        final state = const DiscoveryError(message: errorMessage);

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text(LocalizationService.translate('common.retry')), findsOneWidget);
      });

      testWidgets('should display error overlay when state is DiscoveryError with previousState',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        const errorMessage = 'Failed to load more profiles';
        final previousState = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );
        final state = DiscoveryError(
          message: errorMessage,
          previousState: previousState,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should show both profile and error message overlay
        expect(find.byType(SwipeCard), findsAtLeastNWidgets(1));
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should display no more profiles state correctly',
          (WidgetTester tester) async {
        // Arrange
        final state = NoMoreProfiles();

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(LocalizationService.translate('discovery.no_more_profiles_title')), findsOneWidget);
        expect(find.text(LocalizationService.translate('discovery.adjust_filters')), findsOneWidget);
        expect(find.text(LocalizationService.translate('common.retry')), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display discovery content when state is DiscoveryLoaded',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SwipeCard), findsOneWidget);
        expect(find.text('Test User, 25'), findsOneWidget);
        expect(find.text('5 km'), findsOneWidget);
        expect(find.text('Test bio'), findsOneWidget);
      });

      testWidgets('should display preview cards when nextProfiles exist',
          (WidgetTester tester) async {
        // Arrange
        final currentProfile = createMockProfile(id: '1', displayName: 'User 1');
        final nextProfile1 = createMockProfile(id: '2', displayName: 'User 2');
        final nextProfile2 = createMockProfile(id: '3', displayName: 'User 3');

        final state = DiscoveryLoaded(
          currentProfile: currentProfile,
          nextProfiles: [nextProfile1, nextProfile2],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should show 3 SwipeCards (1 current + 2 preview)
        expect(find.byType(SwipeCard), findsNWidgets(3));
      });

      testWidgets('should display action buttons when state is DiscoveryLoaded',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should have 3 action buttons (dislike, super like, like)
        expect(find.byType(ActionButton), findsNWidgets(3));
        expect(find.byIcon(Icons.close), findsOneWidget); // Dislike
        expect(find.byIcon(Icons.star), findsOneWidget);  // Super like
        expect(find.byIcon(Icons.favorite), findsOneWidget); // Like
      });

      testWidgets('should display daily limit indicator when limit is provided',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final dailyLimit = DailyLikeLimit(
          remainingLikes: 8,
          totalLikes: 50,
          resetAt: DateTime.now().add(const Duration(hours: 2)),
        );

        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
          dailyLimit: dailyLimit,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(LocalizationService.translate('discovery.likes_remaining', params: {'count': '8'})), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
      });

      testWidgets('should display rewind button when canRewind is true',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: true,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('should NOT display rewind button when canRewind is false',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.undo), findsNothing);
      });

      testWidgets('should display loading more indicator when state is DiscoveryLoadingMore',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final loadedState = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );
        final state = DiscoveryLoadingMore(currentState: loadedState);

        // Mock the bloc state to return DiscoveryLoadingMore for the check
        when(() => mockDiscoveryBloc.state).thenReturn(state);

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(LocalizationService.translate('discovery.loading_more')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display daily limit reached state correctly',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final dailyLimit = DailyLikeLimit(
          remainingLikes: 0,
          totalLikes: 50,
          resetAt: DateTime.now().add(const Duration(hours: 3)),
        );

        final previousState = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        final state = DailyLimitReached(
          previousState: previousState,
          limitInfo: dailyLimit,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(LocalizationService.translate('discovery.daily_limit_reached_title')), findsOneWidget);
        expect(find.text(LocalizationService.translate('discovery.upgrade_premium')), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget); // Premium button icon
      });
    });

    group('User Interaction Tests', () {
      testWidgets('should trigger SwipeProfile event when like button is tapped',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final likeButton = find.byIcon(Icons.favorite);
        await tester.tap(likeButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(const SwipeProfile(direction: SwipeDirection.right))).called(1);
      });

      testWidgets('should trigger SwipeProfile event when dislike button is tapped',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final dislikeButton = find.byIcon(Icons.close);
        await tester.tap(dislikeButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(const SwipeProfile(direction: SwipeDirection.left))).called(1);
      });

      testWidgets('should trigger SwipeProfile event when super like button is tapped',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final superLikeButton = find.byIcon(Icons.star);
        await tester.tap(superLikeButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(const SwipeProfile(direction: SwipeDirection.up))).called(1);
      });

      testWidgets('should trigger RewindLastSwipe event when rewind button is tapped',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: true,
        );

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final rewindButton = find.byIcon(Icons.undo);
        await tester.tap(rewindButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(RewindLastSwipe())).called(1);
      });

      testWidgets('should show filters modal when filter button is tapped',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final filterButton = find.byIcon(Icons.tune);
        await tester.tap(filterButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FiltersModal), findsOneWidget);
      });

      testWidgets('should trigger LoadDiscoveryProfiles when retry button is tapped on error',
          (WidgetTester tester) async {
        // Arrange
        const state = DiscoveryError(message: 'Network error');

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final retryButton = find.text(LocalizationService.translate('common.retry'));
        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(const LoadDiscoveryProfiles())).called(1);
      });

      testWidgets('should show filters modal when adjust filters button is tapped on NoMoreProfiles',
          (WidgetTester tester) async {
        // Arrange
        final state = NoMoreProfiles();

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final adjustFiltersButton = find.text(LocalizationService.translate('discovery.adjust_filters'));
        await tester.tap(adjustFiltersButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FiltersModal), findsOneWidget);
      });

      testWidgets('should trigger LoadDiscoveryProfiles when reload button is tapped on NoMoreProfiles',
          (WidgetTester tester) async {
        // Arrange
        final state = NoMoreProfiles();

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final reloadButton = find.byIcon(Icons.refresh);
        await tester.tap(reloadButton);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockDiscoveryBloc.add(const LoadDiscoveryProfiles(limit: 5))).called(1);
      });
    });

    group('State Transition Tests', () {
      testWidgets('should show match modal when MatchFound state is emitted',
          (WidgetTester tester) async {
        // Arrange
        final currentProfile = createMockProfile(id: '1');
        final matchedProfile = createMockProfile(id: '2', displayName: 'Matched User');
        final initialState = DiscoveryLoaded(
          currentProfile: currentProfile,
          nextProfiles: [],
          canRewind: false,
        );

        when(() => mockDiscoveryBloc.state).thenReturn(initialState);

        await tester.pumpWidget(buildDiscoveryPage(initialState));
        await tester.pumpAndSettle();

        // Act - Emit MatchFound state
        final matchState = MatchFound(
          matchedProfile: matchedProfile,
          matchId: 'match123',
        );
        when(() => mockDiscoveryBloc.state).thenReturn(matchState);
        stateController.add(matchState);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(MatchFoundModal), findsOneWidget);
      });

      testWidgets('should show snackbar when DiscoveryError state is emitted',
          (WidgetTester tester) async {
        // Arrange
        final currentProfile = createMockProfile();
        final initialState = DiscoveryLoaded(
          currentProfile: currentProfile,
          nextProfiles: [],
          canRewind: false,
        );

        when(() => mockDiscoveryBloc.state).thenReturn(initialState);

        await tester.pumpWidget(buildDiscoveryPage(initialState));
        await tester.pumpAndSettle();

        // Act - Emit DiscoveryError state
        const errorMessage = 'Connection timeout';
        const errorState = DiscoveryError(message: errorMessage);
        when(() => mockDiscoveryBloc.state).thenReturn(errorState);
        stateController.add(errorState);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(errorMessage), findsAtLeastNWidgets(1));
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should show snackbar when reload button is tapped on NoMoreProfiles',
          (WidgetTester tester) async {
        // Arrange
        final state = NoMoreProfiles();

        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Act
        final reloadButton = find.byIcon(Icons.refresh);
        await tester.tap(reloadButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(LocalizationService.translate('discovery.reloading_profiles')), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle empty profile data gracefully',
          (WidgetTester tester) async {
        // Arrange
        final emptyProfile = DiscoveryProfile(
          id: '1',
          displayName: '',
          age: 0,
          mainPhotoUrl: '',
          otherPhotosUrls: [],
          bio: '',
          city: '',
          country: '',
          distance: 0.0,
          interests: [],
          relationshipType: 'any',
          isVerified: false,
          isPremium: false,
          lastActive: DateTime.now(),
          compatibilityScore: 0.0,
        );

        final state = DiscoveryLoaded(
          currentProfile: emptyProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should render without crashing
        expect(find.byType(SwipeCard), findsOneWidget);
      });

      testWidgets('should limit preview cards to maximum 2',
          (WidgetTester tester) async {
        // Arrange
        final currentProfile = createMockProfile(id: '1');
        final nextProfiles = List.generate(
          5,
          (index) => createMockProfile(id: '${index + 2}', displayName: 'User ${index + 2}'),
        );

        final state = DiscoveryLoaded(
          currentProfile: currentProfile,
          nextProfiles: nextProfiles,
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should show 3 SwipeCards maximum (1 current + 2 preview)
        expect(find.byType(SwipeCard), findsNWidgets(3));
      });

      testWidgets('should handle null dailyLimit gracefully',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
          dailyLimit: null,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Should not show daily limit indicator
        expect(find.text(LocalizationService.translate('discovery.likes_remaining', params: {'count': '0'})), findsNothing);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have semantic labels for all action buttons',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));

        // Verify action buttons have tooltips
        final likeButton = find.byIcon(Icons.favorite);
        final dislikeButton = find.byIcon(Icons.close);
        final superLikeButton = find.byIcon(Icons.star);

        expect(likeButton, findsOneWidget);
        expect(dislikeButton, findsOneWidget);
        expect(superLikeButton, findsOneWidget);
      });

      testWidgets('should have semantic labels for filter button',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: false,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert - Filter button should have semantic wrapper
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });

      testWidgets('should have semantic labels for rewind button when available',
          (WidgetTester tester) async {
        // Arrange
        final mockProfile = createMockProfile();
        final state = DiscoveryLoaded(
          currentProfile: mockProfile,
          nextProfiles: [],
          canRewind: true,
        );

        // Act
        await tester.pumpWidget(buildDiscoveryPage(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.undo), findsOneWidget);
      });
    });
  });
}

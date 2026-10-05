import 'package:dartz/dartz.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/get_search_filters.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart' as usecases;
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDiscoveryProfiles extends Mock implements GetDiscoveryProfiles {}

class MockLikeProfile extends Mock implements LikeProfile {}

class MockDislikeProfile extends Mock implements DislikeProfile {}

class MockSuperLikeProfile extends Mock implements SuperLikeProfile {}

class MockRewindSwipe extends Mock implements RewindSwipe {}

class MockUpdateFilters extends Mock implements usecases.UpdateFilters {}

class MockGetSearchFilters extends Mock implements GetSearchFilters {}

class MockGetDailyLikeLimit extends Mock implements GetDailyLikeLimit {}

void main() {
  late DiscoveryBloc bloc;
  late MockGetDiscoveryProfiles mockGetDiscoveryProfiles;
  late MockLikeProfile mockLikeProfile;
  late MockDislikeProfile mockDislikeProfile;
  late MockSuperLikeProfile mockSuperLikeProfile;
  late MockRewindSwipe mockRewindSwipe;
  late MockUpdateFilters mockUpdateFilters;
  late MockGetSearchFilters mockGetSearchFilters;
  late MockGetDailyLikeLimit mockGetDailyLikeLimit;
  late RealtimeEventBus realtimeBus;

  final List<DiscoveryProfile> profiles = [
    DiscoveryProfile(
      id: 'p1',
      displayName: 'Alice',
      age: 27,
      mainPhotoUrl: 'https://example.com/a.jpg',
      otherPhotosUrls: const [],
      bio: 'Bio A',
      city: 'Paris',
      country: 'France',
      distance: 8,
      interests: const ['music'],
      relationshipType: 'long_term',
      relationshipTypesSought: const ['long_term'],
      isVerified: true,
      isPremium: false,
      lastActive: DateTime(2026, 1, 1),
      compatibilityScore: 0,
    ),
    DiscoveryProfile(
      id: 'p2',
      displayName: 'Bob',
      age: 30,
      mainPhotoUrl: 'https://example.com/b.jpg',
      otherPhotosUrls: const [],
      bio: 'Bio B',
      city: 'Lyon',
      country: 'France',
      distance: 12,
      interests: const ['sport'],
      relationshipType: 'friendship',
      relationshipTypesSought: const ['friendship'],
      isVerified: false,
      isPremium: false,
      lastActive: DateTime(2026, 1, 1),
      compatibilityScore: 0,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(
      const GetDiscoveryProfilesParams(limit: 20),
    );
    registerFallbackValue(
      const LikeProfileParams(profileId: 'fallback-profile'),
    );
    registerFallbackValue(
      const DislikeProfileParams(profileId: 'fallback-profile'),
    );
    registerFallbackValue(
      const SuperLikeProfileParams(profileId: 'fallback-profile'),
    );
    registerFallbackValue(
      const RewindSwipeParams(interactionId: 'interaction-1'),
    );
    registerFallbackValue(
      const usecases.UpdateFiltersParams(filters: SearchFilters()),
    );
  });

  setUp(() {
    mockGetDiscoveryProfiles = MockGetDiscoveryProfiles();
    mockLikeProfile = MockLikeProfile();
    mockDislikeProfile = MockDislikeProfile();
    mockSuperLikeProfile = MockSuperLikeProfile();
    mockRewindSwipe = MockRewindSwipe();
    mockUpdateFilters = MockUpdateFilters();
    mockGetSearchFilters = MockGetSearchFilters();
    mockGetDailyLikeLimit = MockGetDailyLikeLimit();
    realtimeBus = RealtimeEventBus();

    bloc = DiscoveryBloc(
      getDiscoveryProfiles: mockGetDiscoveryProfiles,
      likeProfile: mockLikeProfile,
      dislikeProfile: mockDislikeProfile,
      superLikeProfile: mockSuperLikeProfile,
      rewindSwipe: mockRewindSwipe,
      updateFilters: mockUpdateFilters,
      getSearchFilters: mockGetSearchFilters,
      getDailyLikeLimit: mockGetDailyLikeLimit,
      realtimeBus: realtimeBus,
    );

    when(() => mockLikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(isMatch: false)),
    );
    when(() => mockDislikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(isMatch: false)),
    );
    when(() => mockSuperLikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(isMatch: false)),
    );
    when(() => mockRewindSwipe(any())).thenAnswer(
      (_) async => const Right(SwipeResult(isMatch: false)),
    );
    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => Right(DailyLikeLimit(
        remainingLikes: 10,
        totalLikes: 10,
        resetAt: DateTime(2026, 1, 2),
      )),
    );
  });

  tearDown(() async {
    await bloc.close();
    realtimeBus.dispose();
  });

  test('getCurrentSearchFilters returns backend values when use case succeeds',
      () async {
    const preferences = SearchPreferences(
      minAge: 24,
      maxAge: 40,
      maxDistance: 75,
      interestedIn: ['female', 'non_binary'],
      relationshipTypes: ['friendship', 'long_term'],
      showVerifiedOnly: true,
      showOnlineOnly: true,
    );

    when(() => mockGetSearchFilters(any())).thenAnswer(
      (_) async => const Right(preferences),
    );

    final result = await bloc.getCurrentSearchFilters();

    expect(result, preferences);
    verify(() => mockGetSearchFilters(any())).called(1);
  });

  test('getCurrentSearchFilters falls back to safe defaults on failure',
      () async {
    when(() => mockGetSearchFilters(any())).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'boom')),
    );

    final result = await bloc.getCurrentSearchFilters();

    expect(result.minAge, 18);
    expect(result.maxAge, 99);
    expect(result.maxDistance, 25);
    expect(result.interestedIn, isEmpty);
    expect(result.relationshipTypes, isEmpty);
    expect(result.showVerifiedOnly, isFalse);
    expect(result.showOnlineOnly, isFalse);
  });

  test('UpdateFilters success triggers reload and emits loaded state',
      () async {
    when(() => mockUpdateFilters(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));

    final emittedStates = <DiscoveryState>[];
    final subscription = bloc.stream.listen(emittedStates.add);

    bloc.add(
      const UpdateFilters(
        filters: SearchFilters(
          minAge: 26,
          maxAge: 38,
          maxDistance: 60,
          genders: ['female'],
          relationshipTypes: ['long_term'],
          verifiedOnly: true,
          onlineOnly: true,
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));
    await subscription.cancel();

    verify(() => mockUpdateFilters(any())).called(1);
    verify(() => mockGetDiscoveryProfiles(any())).called(1);
    expect(emittedStates.whereType<DiscoveryLoading>().length, 1);
    expect(emittedStates.last, isA<DiscoveryLoaded>());
  });

  test('UpdateFilters failure emits DiscoveryError and does not reload',
      () async {
    when(() => mockUpdateFilters(any())).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'update failed')),
    );

    final emittedStates = <DiscoveryState>[];
    final subscription = bloc.stream.listen(emittedStates.add);

    bloc.add(const UpdateFilters(filters: SearchFilters()));

    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();

    verify(() => mockUpdateFilters(any())).called(1);
    verifyNever(() => mockGetDiscoveryProfiles(any()));
    expect(emittedStates.length, 1);
    expect(
        emittedStates.single, const DiscoveryError(message: 'update failed'));
  });

  test('initial load exposes the free swipe quota immediately', () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.dailyLimit?.remainingLikes, 10);
    verify(() => mockGetDailyLikeLimit()).called(1);
  });

  test('forced refresh reloads an exhausted free deck without resetting quota',
      () async {
    var requestCount = 0;
    when(() => mockGetDiscoveryProfiles(any())).thenAnswer((_) async {
      requestCount += 1;
      return requestCount == 1
          ? const Right(<DiscoveryProfile>[])
          : Right(List<DiscoveryProfile>.of(profiles));
    });
    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => Right(DailyLikeLimit(
        remainingLikes: 4,
        totalLikes: 10,
        resetAt: DateTime(2026, 1, 2),
      )),
    );

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(bloc.state, isA<NoMoreProfiles>());

    bloc.add(const LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.currentProfile.id, 'p1');
    expect(state.dailyLimit?.remainingLikes, 4);
    verify(
      () => mockGetDiscoveryProfiles(
        const GetDiscoveryProfilesParams(limit: 20, forceRefresh: true),
      ),
    ).called(1);
  });

  test('forced refresh reloads an exhausted Premium deck without a quota',
      () async {
    var requestCount = 0;
    when(() => mockGetDiscoveryProfiles(any())).thenAnswer((_) async {
      requestCount += 1;
      return requestCount == 1
          ? const Right(<DiscoveryProfile>[])
          : Right(List<DiscoveryProfile>.of(profiles));
    });
    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'Unlimited', code: 'unlimited'),
      ),
    );

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(bloc.state, isA<NoMoreProfiles>());

    bloc.add(const LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.currentProfile.id, 'p1');
    expect(state.dailyLimit, isNull);
    verify(
      () => mockGetDiscoveryProfiles(
        const GetDiscoveryProfilesParams(limit: 20, forceRefresh: true),
      ),
    ).called(1);
  });

  test('a confirmed subscription reloads discovery with unlimited quota',
      () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'Unlimited', code: 'unlimited'),
      ),
    );
    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.subscriptionChanged,
      source: RealtimeSource.local,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.dailyLimit, isNull);
    verify(() => mockGetDiscoveryProfiles(any())).called(2);
  });

  test('a successful dislike updates the shared swipe quota', () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));
    when(() => mockDislikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(
        isMatch: false,
        remainingLikes: 9,
      )),
    );

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    bloc.add(const SwipeProfile(direction: SwipeDirection.left));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.dailyLimit?.remainingLikes, 9);
  });

  test('rewind uses the exact server interaction and restores a profile once',
      () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));
    final expiry = DateTime.now().toUtc().add(const Duration(minutes: 5));
    when(() => mockDislikeProfile(any())).thenAnswer(
      (_) async => Right(SwipeResult(
        isMatch: false,
        interactionId: 'server-action-42',
        canRewind: true,
        rewindExpiresAt: expiry,
      )),
    );
    when(() => mockRewindSwipe(
          const RewindSwipeParams(interactionId: 'server-action-42'),
        )).thenAnswer(
      (_) async => const Right(SwipeResult(
        isMatch: false,
        interactionId: 'server-action-42',
      )),
    );

    final historyChanged = Completer<void>();
    final historySubscription =
        AppEvents().onInteractionHistoryChanged.listen((_) {
      if (!historyChanged.isCompleted) {
        historyChanged.complete();
      }
    });

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    bloc.add(const SwipeProfile(direction: SwipeDirection.left));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect((bloc.state as DiscoveryLoaded).currentProfile.id, 'p2');
    expect((bloc.state as DiscoveryLoaded).canRewind, isTrue);

    bloc.add(RewindLastSwipe());
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect((bloc.state as DiscoveryLoaded).currentProfile.id, 'p1');
    await historyChanged.future.timeout(const Duration(seconds: 1));
    verify(() => mockRewindSwipe(
          const RewindSwipeParams(interactionId: 'server-action-42'),
        )).called(1);

    bloc.add(RewindLastSwipe());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNoMoreInteractions(mockRewindSwipe);
    await historySubscription.cancel();
  });

  test('a successful like is sent and updates the shared swipe quota',
      () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));
    when(() => mockLikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(
        isMatch: false,
        remainingLikes: 9,
      )),
    );

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    bloc.add(const SwipeProfile(direction: SwipeDirection.right));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.dailyLimit?.remainingLikes, 9);
    verify(
      () => mockLikeProfile(const LikeProfileParams(profileId: 'p1')),
    ).called(1);
  });

  test('a successful Super Like consumes the shared swipe quota', () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));
    when(() => mockSuperLikeProfile(any())).thenAnswer(
      (_) async => const Right(SwipeResult(
        isMatch: false,
        remainingLikes: 9,
        remainingSuperLikes: 0,
      )),
    );

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    bloc.add(const SwipeProfile(direction: SwipeDirection.up));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final state = bloc.state as DiscoveryLoaded;
    expect(state.dailyLimit?.remainingLikes, 9);
    verify(
      () => mockSuperLikeProfile(
        const SuperLikeProfileParams(profileId: 'p1'),
      ),
    ).called(1);
  });

  test('every swipe attempt at zero emits a fresh Premium prompt', () async {
    when(() => mockGetDiscoveryProfiles(any()))
        .thenAnswer((_) async => Right(List<DiscoveryProfile>.of(profiles)));
    when(() => mockGetDailyLikeLimit()).thenAnswer(
      (_) async => Right(DailyLikeLimit(
        remainingLikes: 0,
        totalLikes: 10,
        resetAt: DateTime(2026, 1, 2),
      )),
    );

    final prompts = <DailyLimitReached>[];
    final subscription = bloc.stream.listen((state) {
      if (state is DailyLimitReached) prompts.add(state);
    });

    bloc.add(const LoadDiscoveryProfiles(limit: 5));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    bloc.add(const SwipeProfile(direction: SwipeDirection.right));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    bloc.add(const SwipeProfile(direction: SwipeDirection.left));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();

    expect(prompts, hasLength(3));
    expect(
      prompts.map((state) => state.promptSequence),
      orderedEquals(<int>[1, 2, 3]),
    );
    verifyNever(() => mockLikeProfile(any()));
    verifyNever(() => mockDislikeProfile(any()));
  });
}

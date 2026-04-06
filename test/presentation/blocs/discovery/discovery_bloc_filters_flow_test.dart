import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
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

    bloc = DiscoveryBloc(
      getDiscoveryProfiles: mockGetDiscoveryProfiles,
      likeProfile: mockLikeProfile,
      dislikeProfile: mockDislikeProfile,
      superLikeProfile: mockSuperLikeProfile,
      rewindSwipe: mockRewindSwipe,
      updateFilters: mockUpdateFilters,
      getSearchFilters: mockGetSearchFilters,
      getDailyLikeLimit: mockGetDailyLikeLimit,
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
  });

  tearDown(() async {
    await bloc.close();
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
        .thenAnswer((_) async => Right(profiles));

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
}

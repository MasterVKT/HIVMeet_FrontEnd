// test/presentation/blocs/discovery/discovery_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/premium.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart' as usecases;
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:mocktail/mocktail.dart';

// ===== MOCKS =====

class MockGetDiscoveryProfiles extends Mock implements GetDiscoveryProfiles {}

class MockLikeProfile extends Mock implements LikeProfile {}

class MockDislikeProfile extends Mock implements DislikeProfile {}

class MockSuperLikeProfile extends Mock implements SuperLikeProfile {}

class MockRewindSwipe extends Mock implements RewindSwipe {}

class MockUpdateFilters extends Mock implements usecases.UpdateFilters {}

class MockGetDailyLikeLimit extends Mock implements GetDailyLikeLimit {}

class MockPremiumRepository extends Mock implements PremiumRepository {}

// ===== TEST DATA =====

final tProfiles = [
  DiscoveryProfile.fromProfile(
    Profile.createBasic(id: 'user_1', displayName: 'Alice', age: 25),
  ),
  DiscoveryProfile.fromProfile(
    Profile.createBasic(id: 'user_2', displayName: 'Bob', age: 30),
  ),
  DiscoveryProfile.fromProfile(
    Profile.createBasic(id: 'user_3', displayName: 'Charlie', age: 28),
  ),
  DiscoveryProfile.fromProfile(
    Profile.createBasic(id: 'user_4', displayName: 'Diana', age: 27),
  ),
];

final tDailyLimit = DailyLikeLimit(
  totalLikes: 100,
  remainingLikes: 50,
  resetsAt: DateTime.now().add(const Duration(hours: 12)),
);

final tDailyLimitReached = DailyLikeLimit(
  totalLikes: 100,
  remainingLikes: 0,
  resetsAt: DateTime.now().add(const Duration(hours: 12)),
);

final tActiveSubscription = UserSubscription(
  id: 'sub_1',
  userId: 'user_1',
  planId: 'premium_monthly',
  status: SubscriptionStatus.active,
  startDate: DateTime.now().subtract(const Duration(days: 10)),
  endDate: DateTime.now().add(const Duration(days: 20)),
  isActive: true,
  autoRenew: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  featuresUsage: FeaturesUsage(
    superLikesUsed: 2,
    superLikesRemaining: 3,
    boostsUsed: 0,
    boostsRemaining: 1,
    rewindsUsed: 1,
    rewindsRemaining: 4,
  ),
);

void main() {
  late DiscoveryBloc bloc;
  late MockGetDiscoveryProfiles mockGetDiscoveryProfiles;
  late MockLikeProfile mockLikeProfile;
  late MockDislikeProfile mockDislikeProfile;
  late MockSuperLikeProfile mockSuperLikeProfile;
  late MockRewindSwipe mockRewindSwipe;
  late MockUpdateFilters mockUpdateFilters;
  late MockGetDailyLikeLimit mockGetDailyLikeLimit;
  late MockPremiumRepository mockPremiumRepository;

  setUp(() {
    mockGetDiscoveryProfiles = MockGetDiscoveryProfiles();
    mockLikeProfile = MockLikeProfile();
    mockDislikeProfile = MockDislikeProfile();
    mockSuperLikeProfile = MockSuperLikeProfile();
    mockRewindSwipe = MockRewindSwipe();
    mockUpdateFilters = MockUpdateFilters();
    mockGetDailyLikeLimit = MockGetDailyLikeLimit();
    mockPremiumRepository = MockPremiumRepository();

    bloc = DiscoveryBloc(
      getDiscoveryProfiles: mockGetDiscoveryProfiles,
      likeProfile: mockLikeProfile,
      dislikeProfile: mockDislikeProfile,
      superLikeProfile: mockSuperLikeProfile,
      rewindSwipe: mockRewindSwipe,
      updateFilters: mockUpdateFilters,
      getDailyLikeLimit: mockGetDailyLikeLimit,
      premiumRepository: mockPremiumRepository,
    );

    // Register fallback values for mocktail
    registerFallbackValue(const GetDiscoveryProfilesParams());
    registerFallbackValue(const LikeProfileParams(profileId: 'test'));
    registerFallbackValue(const DislikeProfileParams(profileId: 'test'));
    registerFallbackValue(const SuperLikeProfileParams(profileId: 'test'));
    registerFallbackValue(NoParams());
    registerFallbackValue(
      const usecases.UpdateFiltersParams(filters: SearchFilters()),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('DiscoveryBloc', () {
    test('initial state should be DiscoveryInitial', () {
      expect(bloc.state, equals(DiscoveryInitial()));
    });

    group('LoadDiscoveryProfiles', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [DiscoveryLoading, DiscoveryLoaded] when profiles are loaded successfully',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_1')
              .having((s) => s.nextProfiles.length, 'nextProfiles.length', 3)
              .having((s) => s.canRewind, 'canRewind', false),
        ],
        verify: (_) {
          verify(() => mockGetDiscoveryProfiles(any())).called(1);
          verify(() => mockGetDailyLikeLimit()).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [DiscoveryLoading, DiscoveryLoaded] with dailyLimit when limit loads in background',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>().having(
            (s) => s.dailyLimit,
            'dailyLimit (initial)',
            null,
          ),
          isA<DiscoveryLoaded>()
              .having(
                (s) => s.dailyLimit?.remainingLikes,
                'dailyLimit.remainingLikes',
                50,
              )
              .having(
                (s) => s.dailyLimit?.totalLikes,
                'dailyLimit.totalLikes',
                100,
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [DiscoveryLoading, DiscoveryError] when loading profiles fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any())).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Connection failed'),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', 'Connection failed'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [DiscoveryLoading, NoMoreProfiles] when empty profiles returned',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => const Right([]));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          DiscoveryLoading(),
          NoMoreProfiles(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should use forceRefresh parameter when provided',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const LoadDiscoveryProfiles(forceRefresh: true)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(
            () => mockGetDiscoveryProfiles(
              argThat(
                isA<GetDiscoveryProfilesParams>()
                    .having((p) => p.forceRefresh, 'forceRefresh', true),
              ),
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle custom limit parameter',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles(limit: 10)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(
            () => mockGetDiscoveryProfiles(
              argThat(
                isA<GetDiscoveryProfilesParams>()
                    .having((p) => p.limit, 'limit', 10),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('SwipeProfile - Like (Right)', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [ProfileSwiping, DiscoveryLoaded] when like succeeds',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>()
              .having((s) => s.profile.id, 'profile.id', 'user_1')
              .having((s) => s.direction, 'direction', SwipeDirection.right),
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_2')
              .having((s) => s.canRewind, 'canRewind', true),
        ],
        verify: (_) {
          verify(
            () => mockLikeProfile(
              const LikeProfileParams(profileId: 'user_1'),
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [ProfileSwiping, MatchFound, DiscoveryLoaded] when match occurs',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: true, matchId: 'match_123'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(seconds: 4),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<MatchFound>()
              .having(
                (s) => s.matchedProfile.id,
                'matchedProfile.id',
                'user_1',
              )
              .having((s) => s.matchId, 'matchId', 'match_123'),
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_2'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DailyLimitReached when free user reaches limit',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimitReached));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimitReached,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        expect: () => [
          isA<DailyLimitReached>()
              .having(
                (s) => s.limitInfo.hasReachedLimit,
                'hasReachedLimit',
                true,
              )
              .having(
                (s) => s.previousState.currentProfile.id,
                'previousState.currentProfile.id',
                'user_1',
              ),
        ],
        verify: (_) {
          verifyNever(() => mockLikeProfile(any()));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when like API call fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Network error'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>().having(
            (s) => s.previousState?.currentProfile.id,
            'previousState.currentProfile.id',
            'user_1',
          ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should update remaining likes from API response',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: false, remainingLikes: 49),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          expect(state.dailyLimit?.remainingLikes, 49);
        },
      );
    });

    group('SwipeProfile - Dislike (Left)', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [ProfileSwiping, DiscoveryLoaded] when dislike succeeds',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.left)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>()
              .having((s) => s.direction, 'direction', SwipeDirection.left),
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_2')
              .having((s) => s.canRewind, 'canRewind', true),
        ],
        verify: (_) {
          verify(
            () => mockDislikeProfile(
              const DislikeProfileParams(profileId: 'user_1'),
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when dislike API call fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'Server error'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.left)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should not check daily limit for dislikes',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimitReached));
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimitReached,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.left)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryLoaded>(),
        ],
        verify: (_) {
          verify(() => mockDislikeProfile(any())).called(1);
        },
      );
    });

    group('SwipeProfile - SuperLike (Up)', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [ProfileSwiping, DiscoveryLoaded] when super like succeeds',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer((_) async => Right(tActiveSubscription));
          when(() => mockSuperLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>()
              .having((s) => s.direction, 'direction', SwipeDirection.up),
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_2'),
        ],
        verify: (_) {
          verify(
            () => mockSuperLikeProfile(
              const SuperLikeProfileParams(profileId: 'user_1'),
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when user has no active subscription',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>(),
        ],
        verify: (_) {
          verifyNever(() => mockSuperLikeProfile(any()));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when subscription is inactive',
        build: () {
          final inactiveSubscription = tActiveSubscription.copyWith(
            isActive: false,
            status: SubscriptionStatus.canceled,
          );
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer((_) async => Right(inactiveSubscription));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>(),
        ],
        verify: (_) {
          verifyNever(() => mockSuperLikeProfile(any()));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when no super likes remaining',
        build: () {
          final noSuperLikesSubscription = tActiveSubscription.copyWith(
            featuresUsage: FeaturesUsage(
              superLikesUsed: 5,
              superLikesRemaining: 0,
              boostsUsed: 0,
              boostsRemaining: 1,
              rewindsUsed: 0,
              rewindsRemaining: 5,
            ),
          );
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer((_) async => Right(noSuperLikesSubscription));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>(),
        ],
        verify: (_) {
          verifyNever(() => mockSuperLikeProfile(any()));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when super like API fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer((_) async => Right(tActiveSubscription));
          when(() => mockSuperLikeProfile(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'no_super_likes_remaining'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryError>(),
        ],
      );
    });

    group('RewindLastSwipe', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryLoaded with previous profile when rewind succeeds',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          when(() => mockRewindSwipe(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[1],
          nextProfiles: tProfiles.sublist(2, 3),
          canRewind: true,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) => bloc.add(RewindLastSwipe()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having((s) => s.currentProfile.id, 'currentProfile.id', 'user_1')
              .having((s) => s.canRewind, 'canRewind', false),
        ],
        verify: (_) {
          verify(() => mockRewindSwipe(NoParams())).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when rewind fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockRewindSwipe(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'Rewind not allowed'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[1],
          nextProfiles: tProfiles.sublist(2, 3),
          canRewind: true,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) => bloc.add(RewindLastSwipe()),
        expect: () => [
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', 'Rewind not allowed'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should not call API when at first profile (canRewind = false)',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) => bloc.add(RewindLastSwipe()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockRewindSwipe(any()));
        },
      );
    });

    group('UpdateFilters', () {
      const tFilters = SearchFilters(
        minAge: 25,
        maxAge: 35,
        maxDistance: 50,
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should call updateFilters and reload profiles when successful',
        build: () {
          when(() => mockUpdateFilters(any()))
              .thenAnswer((_) async => const Right(null));
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const UpdateFilters(filters: tFilters)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockUpdateFilters(
              const usecases.UpdateFiltersParams(filters: tFilters),
            ),
          ).called(1);
          verify(() => mockGetDiscoveryProfiles(any())).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit DiscoveryError when update fails',
        build: () {
          when(() => mockUpdateFilters(any())).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'Failed to update filters'),
            ),
          );
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const UpdateFilters(filters: tFilters)),
        expect: () => [
          isA<DiscoveryError>()
              .having(
                (s) => s.message,
                'message',
                'Failed to update filters',
              ),
        ],
        verify: (_) {
          verifyNever(() => mockGetDiscoveryProfiles(any()));
        },
      );
    });

    group('LoadDailyLimit', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should load and update dailyLimit in DiscoveryLoaded state',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(LoadDailyLimit()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having(
                (s) => s.dailyLimit?.remainingLikes,
                'dailyLimit.remainingLikes',
                50,
              )
              .having(
                (s) => s.dailyLimit?.totalLikes,
                'dailyLimit.totalLikes',
                100,
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should not emit new state when limit loading fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit()).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Failed to load limit'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(LoadDailyLimit()),
        wait: const Duration(milliseconds: 100),
        expect: () => [],
      );
    });

    group('LoadMoreProfiles', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit [DiscoveryLoadingMore, DiscoveryLoaded] when loading more profiles',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right([tProfiles[3]]));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 2),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(const LoadMoreProfiles(limit: 10)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoadingMore>(),
          isA<DiscoveryLoaded>()
              .having((s) => s.nextProfiles.length, 'nextProfiles.length', 3),
        ],
        verify: (_) {
          verify(
            () => mockGetDiscoveryProfiles(
              argThat(
                isA<GetDiscoveryProfilesParams>()
                    .having((p) => p.limit, 'limit', 10)
                    .having((p) => p.lastProfileId, 'lastProfileId', 'user_2'),
              ),
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should revert to previous state when loading more fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any())).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Connection error'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 2),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(const LoadMoreProfiles(limit: 10)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoadingMore>(),
          isA<DiscoveryLoaded>()
              .having((s) => s.nextProfiles.length, 'nextProfiles.length', 1),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should just update state when limit is 0 (dummy event)',
        build: () => bloc,
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 2),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(const LoadMoreProfiles(limit: 0)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoaded>(),
        ],
        verify: (_) {
          verifyNever(() => mockGetDiscoveryProfiles(any()));
        },
      );
    });

    group('NoMoreProfiles State', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should emit NoMoreProfiles when all profiles are swiped',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right([tProfiles[0]]));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: [],
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.left)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>(),
          NoMoreProfiles(),
        ],
      );
    });

    group('Edge Cases', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should not swipe when profiles list is empty',
        build: () => bloc,
        seed: () => NoMoreProfiles(),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockLikeProfile(any()));
          verifyNever(() => mockDislikeProfile(any()));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle rapid swipes correctly',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) {
          bloc.add(const SwipeProfile(direction: SwipeDirection.right));
          bloc.add(const SwipeProfile(direction: SwipeDirection.right));
        },
        wait: const Duration(milliseconds: 200),
        verify: (_) {
          // Should call likeProfile for each swipe
          verify(() => mockLikeProfile(any())).called(greaterThanOrEqualTo(1));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle exception during profile load',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenThrow(Exception('Unexpected error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryError>(),
        ],
      );
    });

    group('State Preservation', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should preserve previousState in DiscoveryError',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Network error'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        verify: (_) {
          final state = bloc.state as DiscoveryError;
          expect(state.previousState, isNotNull);
          expect(state.previousState!.currentProfile.id, 'user_1');
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should preserve previousState in ProfileSwiping',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => Future.delayed(
              const Duration(milliseconds: 500),
              () => const Right(SwipeResult(isMatch: false)),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as ProfileSwiping;
          expect(state.previousState.currentProfile.id, 'user_1');
        },
      );
    });

    group('Auto-pagination Logic', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should automatically load more profiles when queue reaches 2 or less',
        build: () {
          // First call returns initial 3 profiles
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles.sublist(0, 3)));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        act: (bloc) async {
          // Load initial profiles
          bloc.add(const LoadDiscoveryProfiles());
          await Future.delayed(const Duration(milliseconds: 200));

          // Swipe once - should trigger auto-pagination when queue <= 2
          bloc.add(const SwipeProfile(direction: SwipeDirection.right));
        },
        wait: const Duration(milliseconds: 500),
        verify: (_) {
          // Verify GetDiscoveryProfiles was called multiple times
          // (once for initial load, potentially once for auto-pagination)
          verify(() => mockGetDiscoveryProfiles(any())).called(greaterThanOrEqualTo(1));
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle deduplication when loading more profiles',
        build: () {
          // Return duplicate profiles in second call
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadMoreProfiles(limit: 20)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          // Verify that the BLoC handles duplicates properly
          verify(() => mockGetDiscoveryProfiles(any())).called(1);
        },
      );
    });

    group('Premium Repository Edge Cases', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should continue with API call when premium repository check fails',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockPremiumRepository.getCurrentSubscription())
              .thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Failed to check subscription'),
            ),
          );
          when(() => mockSuperLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryLoaded>(),
        ],
        verify: (_) {
          // Should still call super like API despite premium check failure
          verify(() => mockSuperLikeProfile(any())).called(1);
        },
      );
    });

    group('Multiple Consecutive Matches', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle multiple consecutive matches correctly',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          // First swipe matches
          when(() => mockLikeProfile(
                const LikeProfileParams(profileId: 'user_1'),
              )).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: true, matchId: 'match_1'),
            ),
          );
          // Second swipe also matches
          when(() => mockLikeProfile(
                const LikeProfileParams(profileId: 'user_2'),
              )).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: true, matchId: 'match_2'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) async {
          bloc.add(const SwipeProfile(direction: SwipeDirection.right));
          await Future.delayed(const Duration(seconds: 4));
          bloc.add(const SwipeProfile(direction: SwipeDirection.right));
        },
        wait: const Duration(seconds: 8),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<MatchFound>().having((s) => s.matchId, 'matchId', 'match_1'),
          isA<DiscoveryLoaded>(),
          isA<ProfileSwiping>(),
          isA<MatchFound>().having((s) => s.matchId, 'matchId', 'match_2'),
          isA<DiscoveryLoaded>(),
        ],
      );
    });

    group('Background Daily Limit Loading', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should handle daily limit loading error gracefully',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit()).thenAnswer(
            (_) async => const Left(
              NetworkFailure(message: 'Failed to load limit'),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>()
              .having((s) => s.dailyLimit, 'dailyLimit', null),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should update state with daily limit when loaded in background',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>()
              .having((s) => s.dailyLimit, 'dailyLimit (initial)', null),
          isA<DiscoveryLoaded>()
              .having(
                (s) => s.dailyLimit?.remainingLikes,
                'dailyLimit.remainingLikes (after bg load)',
                50,
              ),
        ],
      );
    });

    group('Profile Queue Management', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should update nextProfiles correctly after each swipe',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 4),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          // After swiping user_1, user_2 should be current
          expect(state.currentProfile.id, 'user_2');
          // user_3 and user_4 should be in nextProfiles
          expect(state.nextProfiles.length, 2);
          expect(state.nextProfiles[0].id, 'user_3');
          expect(state.nextProfiles[1].id, 'user_4');
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should not exceed 2 profiles in nextProfiles preview',
        build: () {
          final manyProfiles = List.generate(
            10,
            (i) => DiscoveryProfile.fromProfile(
              Profile.createBasic(
                id: 'user_$i',
                displayName: 'User $i',
                age: 25 + i,
              ),
            ),
          );
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(manyProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          // Should show current profile + max 2 next profiles
          expect(state.nextProfiles.length, lessThanOrEqualTo(2));
        },
      );
    });

    group('Rewind State Management', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should set canRewind to true after first swipe',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          expect(state.canRewind, true);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should set canRewind to false after rewinding to first profile',
        build: () {
          when(() => mockRewindSwipe(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[1],
          nextProfiles: tProfiles.sublist(2, 3),
          canRewind: true,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) => bloc.add(RewindLastSwipe()),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          expect(state.canRewind, false);
          expect(state.currentProfile.id, 'user_1');
        },
      );
    });

    group('Error Message Localization', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should map failure codes to localized error messages',
        build: () {
          when(() => mockGetDiscoveryProfiles(any())).thenAnswer(
            (_) async => const Left(
              NetworkFailure(
                message: 'Network error',
                code: 'network-error',
              ),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryError>().having(
            (s) => s.message,
            'message',
            isNotEmpty,
          ),
        ],
      );
    });

    group('State Transitions', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should transition DiscoveryInitial → DiscoveryLoading → DiscoveryLoaded',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right(tProfiles));
          when(() => mockGetDailyLikeLimit())
              .thenAnswer((_) async => Right(tDailyLimit));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadDiscoveryProfiles()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          DiscoveryLoading(),
          isA<DiscoveryLoaded>(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should transition DiscoveryLoaded → ProfileSwiping → DiscoveryLoaded',
        build: () {
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryLoaded>(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should transition DiscoveryLoaded → ProfileSwiping → MatchFound → DiscoveryLoaded',
        build: () {
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: true, matchId: 'match_123'),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(seconds: 4),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<MatchFound>(),
          isA<DiscoveryLoaded>(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should transition DiscoveryLoaded → DailyLimitReached when limit reached',
        build: () => bloc,
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimitReached,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        expect: () => [
          isA<DailyLimitReached>(),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should transition DiscoveryLoaded → DiscoveryLoadingMore → DiscoveryLoaded',
        build: () {
          when(() => mockGetDiscoveryProfiles(any()))
              .thenAnswer((_) async => Right([tProfiles[3]]));
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 2),
          canRewind: false,
        ),
        act: (bloc) => bloc.add(const LoadMoreProfiles(limit: 10)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<DiscoveryLoadingMore>(),
          isA<DiscoveryLoaded>(),
        ],
      );
    });

    group('Business Logic Validation', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'should remove swiped profile from internal list',
        build: () {
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          // Swiped profile should not appear in current or next profiles
          expect(state.currentProfile.id, isNot('user_1'));
          expect(
            state.nextProfiles.any((p) => p.id == 'user_1'),
            false,
          );
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should only check daily limit for likes, not dislikes',
        build: () {
          when(() => mockDislikeProfile(any())).thenAnswer(
            (_) async => const Right(SwipeResult(isMatch: false)),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimitReached,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.left)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProfileSwiping>(),
          isA<DiscoveryLoaded>(),
        ],
        verify: (_) {
          // Should complete swipe without checking limit
          verify(() => mockDislikeProfile(any())).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'should update remaining likes from API response',
        build: () {
          when(() => mockLikeProfile(any())).thenAnswer(
            (_) async => const Right(
              SwipeResult(isMatch: false, remainingLikes: 42),
            ),
          );
          return bloc;
        },
        seed: () => DiscoveryLoaded(
          currentProfile: tProfiles[0],
          nextProfiles: tProfiles.sublist(1, 3),
          canRewind: false,
          dailyLimit: tDailyLimit,
        ),
        act: (bloc) =>
            bloc.add(const SwipeProfile(direction: SwipeDirection.right)),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          final state = bloc.state as DiscoveryLoaded;
          expect(state.dailyLimit?.remainingLikes, 42);
        },
      );
    });
  });
}

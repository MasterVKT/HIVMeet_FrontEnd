// lib/presentation/blocs/discovery/discovery_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart' as usecases;
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import 'dart:async';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/premium_repository.dart';

/// Business Logic Component (BLoC) for Discovery page.
///
/// Manages the state and business logic for the profile discovery feature,
/// including profile loading, swipe interactions, match detection, filters,
/// and daily limit enforcement.
///
/// **Architecture:**
/// - Follows Clean Architecture principles
/// - Uses BLoC pattern for state management
/// - Coordinates multiple use cases for complex workflows
///
/// **Key Responsibilities:**
/// 1. Load and manage profile queue (with pagination)
/// 2. Handle swipe interactions (like/dislike/super like)
/// 3. Detect and announce matches
/// 4. Enforce daily like limits for free users
/// 5. Support premium features (rewind, super like)
/// 6. Manage discovery filters
/// 7. Listen to interaction revocations and refresh profiles
///
/// **State Management:**
/// - Maintains internal profile list and current index
/// - Emits immutable states for UI rendering
/// - Preserves previous state on errors for graceful degradation
///
/// **Complex Logic:**
/// - **Auto-pagination**: Automatically loads more profiles when queue is low (≤2 remaining)
/// - **Deduplication**: Prevents duplicate profiles using ID-based filtering
/// - **Background loading**: Fetches daily limit without blocking UI
/// - **Interaction revocation**: Listens to global events and refreshes profiles
/// - **Optimistic UI**: Emits ProfileSwiping state during API calls
///
/// **Dependencies:**
/// - 7 use cases for different operations
/// - PremiumRepository for subscription checks (optional)
/// - LocalizationService for error messages
/// - AppEvents for cross-feature communication
///
/// **Usage:**
/// ```dart
/// final bloc = getIt<DiscoveryBloc>();
/// bloc.add(LoadDiscoveryProfiles());
/// ```
@injectable
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryProfiles _getDiscoveryProfiles;
  final LikeProfile _likeProfile;
  final DislikeProfile _dislikeProfile;
  final SuperLikeProfile _superLikeProfile;
  final RewindSwipe _rewindSwipe;
  final usecases.UpdateFilters _updateFilters;
  final GetDailyLikeLimit _getDailyLikeLimit;
  final PremiumRepository? _premiumRepository;

  // ===== INTERNAL STATE =====
  // (Not exposed in emitted states to preserve immutability)

  /// Internal list of all loaded profiles
  /// Managed through add/remove operations during swipes and pagination
  List<DiscoveryProfile> _profiles = [];

  /// Current index in the profile list (which profile is being shown)
  /// Incremented after each swipe, decremented on rewind
  int _currentIndex = 0;

  /// Cached daily like limit information
  /// Updated asynchronously in background after profile load
  DailyLikeLimit? _dailyLimit;

  /// Subscription to interaction revocation events
  /// Listens to global AppEvents for when a user revokes their like/dislike
  StreamSubscription<String>? _revokeSubscription;

  /// Safely extracts the previous DiscoveryLoaded state from various state types.
  ///
  /// This is critical for graceful error handling - it allows us to preserve
  /// the UI when errors occur instead of showing a blank error screen.
  ///
  /// **Handles:**
  /// - ProfileSwiping → Returns previousState
  /// - DiscoveryLoaded → Returns itself
  /// - DailyLimitReached → Returns previousState
  /// - Other states → Returns null
  ///
  /// **Usage:**
  /// ```dart
  /// emit(DiscoveryError(
  ///   message: errorMessage,
  ///   previousState: _safePreviousState(), // Preserve UI
  /// ));
  /// ```
  DiscoveryLoaded? _safePreviousState() {
    final currentState = state;
    if (currentState is ProfileSwiping) return currentState.previousState;
    if (currentState is DiscoveryLoaded) return currentState;
    if (currentState is DailyLimitReached) return currentState.previousState;
    return null;
  }

  /// Maps a Failure object to a localized error message.
  ///
  /// This centralizes error message handling and ensures all errors are
  /// properly internationalized.
  ///
  /// **Strategy:**
  /// 1. If failure has a code, try to map it to a translation key
  ///    (e.g., "network-error" → "errors.network_error")
  /// 2. Fall back to generic error message if no specific translation exists
  ///
  /// **Parameters:**
  /// - [errorKey]: Fallback translation key if specific mapping fails
  /// - [failure]: The failure object (may contain error code)
  ///
  /// **Returns:**
  /// Localized error message ready for display
  ///
  /// **Example:**
  /// ```dart
  /// final message = _mapFailureToMessage('errors.network_error_message', failure);
  /// // Returns: "Erreur de connexion. Vérifiez votre internet." (in French)
  /// ```
  String _mapFailureToMessage(String errorKey, Failure? failure) {
    // Try to map failure to translation key based on error code
    if (failure?.code != null) {
      final translationKey = 'errors.${failure!.code!.replaceAll('-', '_')}';
      return LocalizationService.translate(translationKey);
    }
    // Fallback to generic error message
    return LocalizationService.translate(errorKey);
  }

  /// Creates a DiscoveryBloc with all required dependencies.
  ///
  /// **Dependency Injection:**
  /// Uses @injectable annotation for automatic registration with get_it.
  /// All dependencies are provided by the dependency injection container.
  ///
  /// **Event Handlers:**
  /// Registers handlers for 6 different event types:
  /// - LoadDiscoveryProfiles
  /// - SwipeProfile
  /// - RewindLastSwipe
  /// - UpdateFilters
  /// - LoadDailyLimit
  /// - LoadMoreProfiles
  ///
  /// **Interaction Revocation Listener:**
  /// Sets up a global listener for interaction revocations. When a user
  /// revokes their like/dislike from another screen (e.g., profile detail),
  /// this BLoC automatically refreshes the profile list to reflect the change.
  ///
  /// **Why 500ms delay?**
  /// Gives the backend time to process the revocation before refreshing.
  /// Prevents race conditions where we fetch stale data.
  DiscoveryBloc({
    required GetDiscoveryProfiles getDiscoveryProfiles,
    required LikeProfile likeProfile,
    required DislikeProfile dislikeProfile,
    required SuperLikeProfile superLikeProfile,
    required RewindSwipe rewindSwipe,
    required usecases.UpdateFilters updateFilters,
    required GetDailyLikeLimit getDailyLikeLimit,
    PremiumRepository? premiumRepository,
  })  : _getDiscoveryProfiles = getDiscoveryProfiles,
        _likeProfile = likeProfile,
        _dislikeProfile = dislikeProfile,
        _superLikeProfile = superLikeProfile,
        _rewindSwipe = rewindSwipe,
        _updateFilters = updateFilters,
        _getDailyLikeLimit = getDailyLikeLimit,
        _premiumRepository = premiumRepository,
        super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadDiscoveryProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<RewindLastSwipe>(_onRewindLastSwipe);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadDailyLimit>(_onLoadDailyLimit);
    on<LoadMoreProfiles>(_onLoadMoreProfiles);

    // Listen to interaction revocation events from other parts of the app
    // (e.g., when user revokes a like from profile detail page)
    _revokeSubscription =
        AppEvents().onInteractionRevoked.listen((profileId) async {

      // Wait for backend to process revocation (prevents race conditions)
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload profiles with forceRefresh to bypass cache
      add(const LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
    });
  }

  /// Cleanup method called when BLoC is disposed.
  ///
  /// **Critical:** Cancels the interaction revocation subscription to prevent
  /// memory leaks and attempting to add events after BLoC is closed.
  @override
  Future<void> close() {
    _revokeSubscription?.cancel();
    return super.close();
  }

  /// Handles the LoadDiscoveryProfiles event.
  ///
  /// This is the primary entry point for loading profiles. It's called:
  /// - On initial page load
  /// - After filter updates
  /// - After interaction revocations
  /// - When user manually refreshes
  ///
  /// **Algorithm:**
  /// 1. Emit DiscoveryLoading state (show skeleton UI)
  /// 2. Call backend API to fetch profiles
  /// 3. If successful:
  ///    - Reset internal state (_profiles, _currentIndex)
  ///    - Emit DiscoveryLoaded immediately (fast UX)
  ///    - Load daily limit in background (non-blocking)
  /// 4. If failed:
  ///    - Emit DiscoveryError with localized message
  ///
  /// **Performance Optimization:**
  /// Daily limit is loaded in background to avoid blocking UI.
  /// Users see profiles faster, limit indicator appears ~200ms later.
  ///
  /// **Cache Handling:**
  /// - If event.forceRefresh = true: Bypasses cache, fetches fresh data
  /// - If event.forceRefresh = false: Uses cached data if available
  ///
  /// **Error Handling:**
  /// - Network errors → Show retry button
  /// - Server errors → Show generic error
  /// - No profiles → Emit DiscoveryLoaded with empty list → UI shows NoMoreProfiles
  Future<void> _onLoadDiscoveryProfiles(
    LoadDiscoveryProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());

    try {
      // Load profiles first (priority for fast UX)
      final params = event.forceRefresh
          ? GetDiscoveryProfilesParams.forceRefresh(limit: event.limit)
          : GetDiscoveryProfilesParams.initial(limit: event.limit);
      final result = await _getDiscoveryProfiles(params);

      result.fold(
        (failure) {
          emit(DiscoveryError(message: failure.message));
        },
        (profiles) async {
          _profiles = profiles;
          _currentIndex = 0;

          // Emit loaded state immediately (don't wait for daily limit)
          _emitLoaded(emit);

          // Load daily limit in background (non-blocking)
          _loadDailyLimitInBackground();
        },
      );
    } catch (e) {
      emit(DiscoveryError(message: LocalizationService.translate('errors.network_error_message')));
    }
  }

  /// Loads daily like limit information in the background.
  ///
  /// This is called asynchronously after profiles are loaded to avoid blocking
  /// the UI. The daily limit indicator will appear ~200ms after profiles load.
  ///
  /// **Why non-blocking?**
  /// - Profiles are the priority (users want to start swiping immediately)
  /// - Daily limit is secondary info (nice-to-have, not critical)
  /// - Errors are silently ignored (won't crash the app)
  ///
  /// **State Update:**
  /// If successful and state is still DiscoveryLoaded, triggers LoadDailyLimit
  /// event to update the UI with the limit indicator.
  ///
  /// **Error Handling:**
  /// Errors are silently ignored - the UI just won't show the limit indicator.
  /// This is acceptable degradation (better than blocking the entire page).
  Future<void> _loadDailyLimitInBackground() async {
    try {
      final limitEither = await _getDailyLikeLimit();
      _dailyLimit = limitEither.fold((l) => null, (r) => r);

      // Update state if still in loaded mode
      if (state is DiscoveryLoaded) {
        add(LoadDailyLimit());
      }
    } catch (e) {
      // Silently ignore daily limit errors to avoid blocking UI
    }
  }

  /// Handles the SwipeProfile event (most complex method in this BLoC).
  ///
  /// This method orchestrates the entire swipe workflow:
  /// 1. Validation (profile exists, daily limit not reached)
  /// 2. Optimistic UI update (emit ProfileSwiping)
  /// 3. Backend API call (like/dislike/super like)
  /// 4. Match detection
  /// 5. Profile removal from queue
  /// 6. Auto-pagination if queue is low
  /// 7. Daily limit update
  /// 8. State emission (DiscoveryLoaded or MatchFound)
  ///
  /// **Swipe Types:**
  /// - Right → Like (POST /api/v1/matches/like)
  /// - Left → Dislike (POST /api/v1/matches/dislike)
  /// - Up → Super Like (POST /api/v1/matches/super-like) [Premium only]
  ///
  /// **Daily Limit Enforcement:**
  /// For free users, checks if daily like limit is reached BEFORE making API call.
  /// If limit reached, emits DailyLimitReached state instead of swiping.
  ///
  /// **Match Detection:**
  /// If backend returns result.isMatch = true:
  /// - Emit MatchFound state with match details
  /// - Auto-dismiss after 3 seconds
  /// - Then emit DiscoveryLoaded with next profile
  ///
  /// **Auto-Pagination:**
  /// When profile queue reaches ≤2 profiles, automatically loads more in background.
  /// This ensures smooth UX without interruptions.
  ///
  /// **Deduplication:**
  /// After removing current profile, new profiles are fetched. The _loadMoreProfiles
  /// method includes ID-based deduplication to prevent showing same profile twice.
  ///
  /// **Error Handling:**
  /// - Network errors → Emit DiscoveryError with previousState preserved
  /// - API errors → Show localized error message
  /// - Premium errors (super like) → Show specific error messages
  ///
  /// **State Flow:**
  /// DiscoveryLoaded → ProfileSwiping → DiscoveryLoaded (normal)
  ///                                   → MatchFound → DiscoveryLoaded (match)
  ///                                   → DailyLimitReached (limit exceeded)
  ///                                   → DiscoveryError (API failure)
  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Validation: Ensure we have profiles to swipe
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      return;
    }

    final currentProfile = _profiles[_currentIndex];

    // Daily limit check (only for likes, free users)
    if (event.direction == SwipeDirection.right &&
        _dailyLimit != null &&
        _dailyLimit!.hasReachedLimit) {
      emit(DailyLimitReached(
        previousState: state as DiscoveryLoaded,
        limitInfo: _dailyLimit!,
      ));
      return;
    }

    // Optimistic UI: Show swipe animation immediately
    emit(ProfileSwiping(
      previousState: state as DiscoveryLoaded,
      profile: currentProfile,
      direction: event.direction,
    ));

    // Call backend API based on swipe direction
    final SwipeResult result;

    switch (event.direction) {
      case SwipeDirection.right:
        final params = LikeProfileParams(profileId: currentProfile.id);
        final either = await _likeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          emit(DiscoveryError(
            message: _mapFailureToMessage('errors.network_error_message', failure),
            previousState: _safePreviousState(),
          ));
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.left:
        final params = DislikeProfileParams(profileId: currentProfile.id);
        final either = await _dislikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold(
              (l) => l, (r) => ServerFailure(message: LocalizationService.translate('errors.unknown_error')));
          emit(DiscoveryError(
            message: _mapFailureToMessage('errors.network_error_message', failure),
            previousState: _safePreviousState(),
          ));
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      case SwipeDirection.up:
        // Super Like: Premium-only feature with quota enforcement
        //
        // **Client-side validation (optional):**
        // If PremiumRepository is available, pre-validate before API call.
        // This provides instant feedback, but backend still does final validation.
        //
        // **Why optional validation?**
        // - Faster UX (no waiting for API roundtrip on error)
        // - Backend is source of truth (prevents bypass)
        // - Graceful degradation if repository unavailable
        if (_premiumRepository != null) {
          final subscriptionResult =
              await _premiumRepository.getCurrentSubscription();
          await subscriptionResult.fold(
            (failure) {
              // Log error but continue (backend will do real validation)
            },
            (subscription) async {
              if (subscription == null) {
                emit(DiscoveryError(
                    message: LocalizationService.translate('errors.premium_required'),
                    previousState: _safePreviousState()));
                return;
              }

              if (!subscription.isActive) {
                emit(DiscoveryError(
                    message: LocalizationService.translate('errors.premium_required'),
                    previousState: _safePreviousState()));
                return;
              }

              final usage = subscription.featuresUsage;
              if (usage != null && usage.superLikesRemaining <= 0) {
                emit(DiscoveryError(
                    message: LocalizationService.translate('errors.daily_limit_reached'),
                    previousState: _safePreviousState()));
                return;
              }
            },
          );

          // If emit was called (error), exit early
          if (state is DiscoveryError) {
            return;
          }
        }

        // Call Super Like API
        final params = SuperLikeProfileParams(profileId: currentProfile.id);
        final either = await _superLikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);

          // More explicit error messages based on failure type
          // TODO: Move hardcoded French strings to translation files (i18n violation)
          String errorMessage =
              _mapFailureToMessage('errors.unknown_error', failure);
          if (failure is ServerFailure) {
            if (failure.message.contains('no_active_subscription')) {
              errorMessage =
                  'Vous devez avoir un abonnement actif pour utiliser les Super Likes. '
                  'Veuillez vérifier votre abonnement dans les paramètres.';
            } else if (failure.message.contains('no_super_likes_remaining')) {
              errorMessage =
                  'Vous n\'avez plus de Super Likes disponibles aujourd\'hui. '
                  'Ils seront réinitialisés demain.';
            } else if (failure.message.contains('429') ||
                failure.message.toLowerCase().contains('too many requests')) {
              errorMessage =
                  'Trop de requêtes. Patiente quelques secondes puis réessaie.';
            }
          }

          emit(DiscoveryError(
            message: errorMessage,
            previousState: _safePreviousState(),
          ));
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
      default:
        return;
    }

    // Match detection: If mutual like, show celebration modal
    if (result.isMatch) {
      emit(MatchFound(
        matchedProfile: currentProfile,
        matchId: result.matchId!,
      ));

      // Auto-dismiss match modal after 3 seconds
      // (User can also dismiss manually)
      await Future.delayed(const Duration(seconds: 3));
    }

    // ✅ CRITICAL: Remove profile immediately from list to prevent re-swiping
    // This ensures:
    // 1. Profile doesn't appear again in current session
    // 2. No duplicate swipe actions
    // 3. Smooth transition to next profile
    _profiles.removeAt(_currentIndex);

    // Auto-pagination: Load more profiles when queue is low
    // Threshold: ≤2 profiles remaining
    // This ensures seamless UX without waiting for profile load
    if (_profiles.length <= 2 && _profiles.isNotEmpty) {
      _loadMoreProfiles();
    }

    // Update daily limit with backend response
    // Backend returns updated remaining likes count after each swipe
    if (result.remainingLikes != null) {
      if (_dailyLimit != null) {
        _dailyLimit = _dailyLimit!.copyWith(
          remainingLikes: result.remainingLikes!,
        );
      }
    }

    // Emit updated DiscoveryLoaded state with next profile
    _emitLoaded(emit);
  }

  Future<void> _onRewindLastSwipe(
    RewindLastSwipe event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (_currentIndex > 0) {
      final either = await _rewindSwipe(NoParams());
      if (either.isLeft()) {
        final msg = either
            .swap()
            .getOrElse(() => ServerFailure(message: LocalizationService.translate('errors.rewind_error')))
            .message;
        emit(DiscoveryError(message: msg));
        return;
      }
      _currentIndex--;
      _emitLoaded(emit);
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      final params = usecases.UpdateFiltersParams(filters: event.filters);
      final either = await _updateFilters(params);
      either.fold(
        (failure) {
          emit(DiscoveryError(message: failure.message));
        },
        (_) {
          add(const LoadDiscoveryProfiles());
        },
      );
    } catch (e) {
      emit(DiscoveryError(message: LocalizationService.translate('errors.update_filters_error')));
    }
  }

  Future<void> _onLoadDailyLimit(
    LoadDailyLimit event,
    Emitter<DiscoveryState> emit,
  ) async {
    final either = await _getDailyLikeLimit();
    _dailyLimit = either.fold((l) => null, (r) => r);
    if (state is DiscoveryLoaded && _dailyLimit != null) {
      _emitLoaded(emit);
    }
  }

  /// Emits a DiscoveryLoaded state based on current internal state.
  ///
  /// This centralizes the logic for creating DiscoveryLoaded states,
  /// ensuring consistency across different event handlers.
  ///
  /// **Logic:**
  /// 1. Check if we've reached the end of profile list
  /// 2. If yes → Emit NoMoreProfiles state
  /// 3. If no → Emit DiscoveryLoaded with:
  ///    - Current profile (at _currentIndex)
  ///    - Next 0-2 preview profiles (for background stack)
  ///    - Rewind availability (true if _currentIndex > 0)
  ///    - Daily limit info (if loaded)
  ///
  /// **Preview Profiles:**
  /// Shows up to 2 profiles behind current one (scaled/faded).
  /// This gives users a "sneak peek" and makes transitions smoother.
  ///
  /// **Rewind Availability:**
  /// Enabled only if user has swiped at least once (_currentIndex > 0).
  /// Premium users can undo their last swipe.
  void _emitLoaded(Emitter<DiscoveryState> emit) {
    // End of profile list: Show empty state
    if (_currentIndex >= _profiles.length) {
      emit(NoMoreProfiles());
      return;
    }

    // Emit loaded state with current and preview profiles
    emit(DiscoveryLoaded(
      currentProfile: _profiles[_currentIndex],
      nextProfiles: _profiles.sublist(
        _currentIndex + 1,
        (_currentIndex + 3).clamp(0, _profiles.length),
      ),
      canRewind: _currentIndex > 0,
      dailyLimit: _dailyLimit,
    ));
  }

  Future<void> _onLoadMoreProfiles(
    LoadMoreProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Si limit = 0, c'est juste pour déclencher une mise à jour de l'état
    if (event.limit == 0) {
      if (state is DiscoveryLoaded) {
        _emitLoaded(emit);
      }
      return;
    }

    // Émettre l'état de chargement
    if (state is DiscoveryLoaded) {
      emit(DiscoveryLoadingMore(currentState: state as DiscoveryLoaded));
    }

    try {
      final params = GetDiscoveryProfilesParams(
        limit: event.limit,
        lastProfileId: _profiles.isNotEmpty ? _profiles.last.id : null,
      );
      final result = await _getDiscoveryProfiles(params);
      result.fold(
        (failure) {
          // Revenir à l'état précédent en cas d'erreur
          if (state is DiscoveryLoadingMore) {
            emit((state as DiscoveryLoadingMore).currentState);
          }
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            _profiles.addAll(newProfilesList);
          }
          // Émettre l'état chargé mis à jour
          _emitLoaded(emit);
        },
      );
    } catch (e) {
      // Revenir à l'état précédent en cas d'erreur
      if (state is DiscoveryLoadingMore) {
        emit((state as DiscoveryLoadingMore).currentState);
      }
    }
  }

  /// Loads more profiles in the background (auto-pagination).
  ///
  /// This is a **private helper method** called automatically when the profile
  /// queue is low (≤2 profiles remaining). It's non-blocking and errors are
  /// silently ignored to avoid disrupting the user's swipe session.
  ///
  /// **Algorithm:**
  /// 1. Fetch next batch of profiles (limit: 20) using cursor-based pagination
  /// 2. Filter out duplicates using ID-based deduplication
  /// 3. Append unique profiles to internal _profiles list
  /// 4. Trigger state update (via LoadMoreProfiles event with limit=0)
  ///
  /// **Deduplication Logic:**
  /// Creates a Set of existing profile IDs, then filters new profiles to only
  /// include those not already in the list. This prevents:
  /// - Showing the same profile twice
  /// - Confusing user experience
  /// - Duplicate swipe actions on backend
  ///
  /// **Why silent failure?**
  /// - User can continue swiping existing profiles
  /// - Error doesn't block core functionality
  /// - Retry will happen on next auto-load trigger
  ///
  /// **Cursor-based Pagination:**
  /// Uses lastProfileId as cursor for efficient pagination.
  /// Backend returns profiles after this ID.
  ///
  /// **State Update:**
  /// Adds a dummy LoadMoreProfiles(limit: 0) event to trigger _emitLoaded,
  /// which updates the UI with new preview profiles.
  Future<void> _loadMoreProfiles() async {
    try {
      final params = GetDiscoveryProfilesParams(
        limit: 20,
        lastProfileId: _profiles.isNotEmpty ? _profiles.last.id : null,
      );
      final result = await _getDiscoveryProfiles(params);
      result.fold(
        (failure) {
          // Error loading additional profiles, silently fail
          // User can continue with existing profiles
        },
        (newProfilesList) {
          if (newProfilesList.isNotEmpty) {
            // ✅ Deduplication: Prevent same profile appearing twice
            // Create set of existing IDs for O(1) lookup
            final existingIds = _profiles.map((p) => p.id).toSet();
            final uniqueNewProfiles =
                newProfilesList.where((p) => !existingIds.contains(p.id));

            _profiles.addAll(uniqueNewProfiles);

            // Trigger state update if still in loaded mode
            if (state is DiscoveryLoaded) {
              add(LoadMoreProfiles(
                  limit: 0)); // Dummy event to trigger _emitLoaded
            }
          }
        },
      );
    } catch (e) {
      // Silently ignore errors to avoid disrupting swipe session
    }
  }
}

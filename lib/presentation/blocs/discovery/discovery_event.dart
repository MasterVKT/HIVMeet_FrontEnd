// lib/presentation/blocs/discovery/discovery_event.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';

/// Base class for all Discovery page events.
///
/// All events extend [Equatable] to enable value-based equality comparisons
/// which are essential for BLoC pattern and preventing duplicate event processing.
abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load discovery profiles from the backend.
///
/// This event triggers fetching a batch of profiles based on the matching algorithm.
/// Supports pagination through [lastProfileId] and cache invalidation through [forceRefresh].
///
/// **Parameters:**
/// - [limit]: Number of profiles to fetch (default: 20)
/// - [forceRefresh]: If true, bypasses cache and fetches fresh data from backend
///
/// **Usage:**
/// ```dart
/// // Initial load
/// bloc.add(LoadDiscoveryProfiles(limit: 20));
///
/// // Force refresh after interaction revocation
/// bloc.add(LoadDiscoveryProfiles(limit: 20, forceRefresh: true));
/// ```
///
/// **State Transitions:**
/// - DiscoveryInitial → DiscoveryLoading → DiscoveryLoaded (success)
/// - DiscoveryInitial → DiscoveryLoading → DiscoveryError (failure)
/// - DiscoveryLoaded → DiscoveryLoading → DiscoveryLoaded (refresh)
class LoadDiscoveryProfiles extends DiscoveryEvent {
  /// Number of profiles to fetch
  final int limit;

  /// If true, bypasses cache and fetches fresh data
  final bool forceRefresh;

  const LoadDiscoveryProfiles({
    this.limit = 20,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [limit, forceRefresh];
}

/// Event triggered when a user swipes on a profile card.
///
/// Handles three types of swipes:
/// - **Right**: Like action
/// - **Left**: Dislike action
/// - **Up**: Super Like action (premium feature)
///
/// **Parameters:**
/// - [direction]: The swipe direction (left/right/up)
///
/// **Usage:**
/// ```dart
/// // Like action
/// bloc.add(SwipeProfile(direction: SwipeDirection.right));
///
/// // Dislike action
/// bloc.add(SwipeProfile(direction: SwipeDirection.left));
///
/// // Super Like action
/// bloc.add(SwipeProfile(direction: SwipeDirection.up));
/// ```
///
/// **State Transitions:**
/// - DiscoveryLoaded → ProfileSwiping → DiscoveryLoaded (normal)
/// - DiscoveryLoaded → ProfileSwiping → MatchFound → DiscoveryLoaded (match)
/// - DiscoveryLoaded → DailyLimitReached (if limit exceeded)
/// - DiscoveryLoaded → DiscoveryError (if API call fails)
///
/// **Side Effects:**
/// - Calls backend API (like/dislike/super_like)
/// - Updates daily limit counter
/// - May trigger match detection
/// - Auto-loads more profiles when queue is low
class SwipeProfile extends DiscoveryEvent {
  /// The swipe direction (left/right/up)
  final SwipeDirection direction;

  const SwipeProfile({required this.direction});

  @override
  List<Object> get props => [direction];
}

/// Event to undo the last swipe action (Rewind feature).
///
/// This is a **premium-only feature** that allows users to undo their last
/// swipe action and bring back the previous profile.
///
/// **Limitations:**
/// - Only works if there's a previous swipe (canRewind = true)
/// - Premium subscription required
/// - Limited uses per day based on subscription tier
///
/// **Usage:**
/// ```dart
/// // Check if rewind is available
/// if (state is DiscoveryLoaded && state.canRewind) {
///   bloc.add(RewindLastSwipe());
/// }
/// ```
///
/// **State Transitions:**
/// - DiscoveryLoaded → DiscoveryLoaded (with previous profile restored)
/// - DiscoveryLoaded → DiscoveryError (if rewind fails or not allowed)
///
/// **API Call:**
/// - Endpoint: POST /api/v1/matches/rewind
class RewindLastSwipe extends DiscoveryEvent {}

/// Event to update discovery filters and reload profiles.
///
/// Triggers an immediate reload of profiles based on the new filter criteria.
/// Filters include age range, distance, relationship types, interests, and premium options.
///
/// **Parameters:**
/// - [filters]: The new filter configuration
///
/// **Usage:**
/// ```dart
/// final newFilters = SearchFilters(
///   ageMin: 25,
///   ageMax: 35,
///   maxDistance: 50,
///   verifiedOnly: true,
/// );
/// bloc.add(UpdateFilters(filters: newFilters));
/// ```
///
/// **State Transitions:**
/// - DiscoveryLoaded → DiscoveryLoading → DiscoveryLoaded (success)
/// - DiscoveryLoaded → DiscoveryError (if filter update fails)
///
/// **Side Effects:**
/// - Saves filters to backend and local storage
/// - Invalidates current profile queue
/// - Triggers fresh profile load with new criteria
class UpdateFilters extends DiscoveryEvent {
  /// The new filter configuration
  final SearchFilters filters;

  const UpdateFilters({required this.filters});

  @override
  List<Object> get props => [filters];
}

/// Event to load daily like limit information.
///
/// Fetches the current user's daily like quota (remaining likes, reset time).
/// This is automatically triggered in the background after profile load.
///
/// **Usage:**
/// ```dart
/// // Typically called internally by the BLoC
/// bloc.add(LoadDailyLimit());
/// ```
///
/// **State Transitions:**
/// - DiscoveryLoaded → DiscoveryLoaded (with updated daily limit info)
///
/// **Notes:**
/// - Non-blocking: Errors are silently ignored to avoid disrupting UX
/// - Updates the dailyLimit field in DiscoveryLoaded state
class LoadDailyLimit extends DiscoveryEvent {}

/// Event to load more profiles for pagination.
///
/// Triggered automatically when the profile queue is low (≤2 profiles remaining).
/// Can also be manually triggered for preloading.
///
/// **Parameters:**
/// - [limit]: Number of additional profiles to fetch (default: 20)
///
/// **Usage:**
/// ```dart
/// // Auto-triggered by BLoC when queue is low
/// // Or manually:
/// bloc.add(LoadMoreProfiles(limit: 10));
/// ```
///
/// **State Transitions:**
/// - DiscoveryLoaded → DiscoveryLoadingMore → DiscoveryLoaded (success)
/// - DiscoveryLoaded → DiscoveryLoaded (if load fails, reverts to previous state)
///
/// **Special Cases:**
/// - If limit = 0, just triggers a state update without fetching
/// - Prevents duplicate profiles using ID deduplication
///
/// **Notes:**
/// - Uses cursor-based pagination with lastProfileId
/// - Seamless UX: No interruption to current swipe session
class LoadMoreProfiles extends DiscoveryEvent {
  /// Number of additional profiles to fetch
  final int limit;

  const LoadMoreProfiles({this.limit = 20});

  @override
  List<Object> get props => [limit];
}

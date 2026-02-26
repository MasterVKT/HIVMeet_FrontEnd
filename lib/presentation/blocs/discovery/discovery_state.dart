// lib/presentation/blocs/discovery/discovery_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Base class for all Discovery page states.
///
/// All states extend [Equatable] to enable value-based equality comparisons
/// which are essential for BLoC pattern and preventing unnecessary widget rebuilds.
///
/// **State Flow:**
/// ```
/// DiscoveryInitial
///   ↓
/// DiscoveryLoading
///   ↓
/// DiscoveryLoaded ←→ ProfileSwiping ←→ MatchFound
///   ↓
/// NoMoreProfiles / DailyLimitReached / DiscoveryError
/// ```
abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the Discovery page is first opened.
///
/// This is the default state before any profiles are loaded.
/// The UI should show a splash or initialization indicator.
///
/// **Next States:**
/// - DiscoveryLoading (when LoadDiscoveryProfiles event is triggered)
class DiscoveryInitial extends DiscoveryState {}

/// Loading state while fetching initial discovery profiles.
///
/// Shown during the first profile load or when reloading all profiles.
/// The UI should display a full-screen loading indicator (skeleton UI preferred).
///
/// **Next States:**
/// - DiscoveryLoaded (if profiles successfully loaded)
/// - DiscoveryError (if profile loading fails)
/// - NoMoreProfiles (if no profiles match current filters)
class DiscoveryLoading extends DiscoveryState {}

/// Loading state while fetching additional profiles in the background.
///
/// Unlike [DiscoveryLoading], this state preserves the current UI to avoid
/// disrupting the user's swipe session. The UI should show a subtle loading
/// indicator (e.g., small banner at bottom).
///
/// **Properties:**
/// - [currentState]: The previous DiscoveryLoaded state to maintain in the UI
///
/// **Next States:**
/// - DiscoveryLoaded (when additional profiles are loaded)
///
/// **UI Behavior:**
/// - Keep showing current profile stack
/// - Display small "Loading more..." indicator at bottom
/// - Allow continued swiping on existing profiles
class DiscoveryLoadingMore extends DiscoveryState {
  /// The previous DiscoveryLoaded state to maintain UI continuity
  final DiscoveryLoaded currentState;

  const DiscoveryLoadingMore({required this.currentState});

  @override
  List<Object> get props => [currentState];
}

/// Main state when profiles are loaded and ready for swiping.
///
/// This is the primary state where users interact with profile cards.
/// Contains the current profile, preview of next profiles, and metadata.
///
/// **Properties:**
/// - [currentProfile]: The profile currently displayed to the user
/// - [nextProfiles]: Preview profiles shown behind (for smooth UX)
/// - [canRewind]: Whether the Rewind button should be enabled
/// - [dailyLimit]: User's daily like quota info (null if not loaded yet)
///
/// **UI Components:**
/// - Main profile card (swipeable)
/// - 0-2 preview cards in background (scaled/faded)
/// - Action buttons (like/dislike/super like)
/// - Rewind button (if canRewind = true)
/// - Daily limit indicator (if dailyLimit != null and user is free tier)
///
/// **Next States:**
/// - ProfileSwiping (when user swipes)
/// - DiscoveryLoadingMore (when fetching more profiles)
/// - DailyLimitReached (when free user exhausts daily likes)
/// - NoMoreProfiles (when profile queue is empty)
/// - DiscoveryError (on error with previousState preserved)
class DiscoveryLoaded extends DiscoveryState {
  /// The profile currently displayed to the user (front card)
  final DiscoveryProfile currentProfile;

  /// Preview profiles shown behind current profile (max 2)
  final List<DiscoveryProfile> nextProfiles;

  /// Whether the Rewind button should be enabled (true if user has swiped before)
  final bool canRewind;

  /// User's daily like quota (null if not loaded yet or unlimited for premium)
  final DailyLikeLimit? dailyLimit;

  const DiscoveryLoaded({
    required this.currentProfile,
    required this.nextProfiles,
    required this.canRewind,
    this.dailyLimit,
  });

  @override
  List<Object?> get props =>
      [currentProfile, nextProfiles, canRewind, dailyLimit];
}

/// Transient state while a swipe animation is in progress.
///
/// This state provides context for optimistic UI updates during the swipe gesture.
/// The UI should show the swipe animation while the backend API call is in flight.
///
/// **Properties:**
/// - [previousState]: The DiscoveryLoaded state before swiping
/// - [profile]: The profile being swiped
/// - [direction]: The swipe direction (left/right/up)
///
/// **Duration:**
/// - Very short (300ms animation + API response time)
///
/// **Next States:**
/// - DiscoveryLoaded (normal swipe, no match)
/// - MatchFound (mutual like detected)
/// - DiscoveryError (if API call fails)
///
/// **UI Behavior:**
/// - Show swipe animation (card flying off screen)
/// - Display feedback overlay (green heart / red X / gold star)
/// - Prepare next profile for reveal
class ProfileSwiping extends DiscoveryState {
  /// The DiscoveryLoaded state before this swipe
  final DiscoveryLoaded previousState;

  /// The profile being swiped
  final DiscoveryProfile profile;

  /// The swipe direction (left = dislike, right = like, up = super like)
  final SwipeDirection direction;

  const ProfileSwiping({
    required this.previousState,
    required this.profile,
    required this.direction,
  });

  @override
  List<Object> get props => [previousState, profile, direction];
}

/// State when a mutual match is detected.
///
/// Triggered when the user likes a profile that has already liked them.
/// The UI should show a celebratory full-screen modal with animations.
///
/// **Properties:**
/// - [matchedProfile]: The profile that matched
/// - [matchId]: Unique identifier for this match
///
/// **Duration:**
/// - ~3 seconds (auto-dismiss) or until user dismisses manually
///
/// **Next States:**
/// - DiscoveryLoaded (after modal is dismissed)
///
/// **UI Components:**
/// - Full-screen match modal
/// - Animations (hearts, confetti, profile photos)
/// - "It's a Match!" message
/// - "Send Message" button → navigate to conversation
/// - "Keep Swiping" button → dismiss modal and continue
///
/// **Side Effects:**
/// - May play celebratory sound (respects device settings)
/// - Haptic feedback
/// - Match is saved to backend (already done by API)
class MatchFound extends DiscoveryState {
  /// The profile that matched with the user
  final DiscoveryProfile matchedProfile;

  /// Unique identifier for this match
  final String matchId;

  const MatchFound({
    required this.matchedProfile,
    required this.matchId,
  });

  @override
  List<Object> get props => [matchedProfile, matchId];
}

/// State when there are no more profiles available.
///
/// Occurs when:
/// - All profiles in the current filter criteria have been swiped
/// - User is in a low-population area
/// - Filters are too restrictive
///
/// **Next States:**
/// - DiscoveryLoading → DiscoveryLoaded (if user adjusts filters or reloads)
///
/// **UI Components:**
/// - Empty state illustration
/// - "No more profiles" message
/// - "Adjust your filters" button → open filters modal
/// - "Try again" button → reload profiles
///
/// **Suggestions to User:**
/// - Expand age range
/// - Increase distance radius
/// - Remove restrictive filters (verified only, etc.)
/// - Check back later for new users
class NoMoreProfiles extends DiscoveryState {}

/// State when a free user has reached their daily like limit.
///
/// Free users are limited to 50 likes per day. This state prevents further
/// liking until the limit resets at midnight (server time).
///
/// **Properties:**
/// - [previousState]: The DiscoveryLoaded state before limit was reached
/// - [limitInfo]: Details about the daily limit (limit, remaining, reset time)
///
/// **Next States:**
/// - DiscoveryLoaded (if user upgrades to premium or limit resets)
///
/// **UI Components:**
/// - Limit reached illustration (heart with lock icon)
/// - "Daily limit reached" message
/// - Countdown to reset time
/// - "Upgrade to Premium" button → navigate to subscription page
/// - "Keep browsing" button → allow viewing profiles without liking
///
/// **Premium Users:**
/// - This state is never reached (unlimited likes)
class DailyLimitReached extends DiscoveryState {
  /// The DiscoveryLoaded state before limit was reached
  final DiscoveryLoaded previousState;

  /// Details about the daily limit
  final DailyLikeLimit limitInfo;

  const DailyLimitReached({
    required this.previousState,
    required this.limitInfo,
  });

  @override
  List<Object> get props => [previousState, limitInfo];
}

/// Error state when something goes wrong.
///
/// Can occur during:
/// - Network errors
/// - API failures
/// - Invalid responses
/// - Authentication issues
///
/// **Properties:**
/// - [message]: Localized error message to display to user
/// - [previousState]: Optional previous DiscoveryLoaded state to preserve UI
///
/// **Next States:**
/// - DiscoveryLoading → DiscoveryLoaded (if user retries)
/// - DiscoveryLoaded (if previousState exists, error shown as snackbar)
///
/// **UI Behavior:**
/// - If previousState exists: Show error as snackbar, keep current UI
/// - If previousState is null: Show full-screen error with retry button
///
/// **Error Types:**
/// - Network errors: "Connection error. Please check your internet."
/// - Server errors: "Something went wrong. Please try again."
/// - Auth errors: "Please log in again."
/// - Rate limiting: "Too many requests. Please wait a moment."
class DiscoveryError extends DiscoveryState {
  /// Localized error message to display to user
  final String message;

  /// Optional previous DiscoveryLoaded state to preserve UI
  final DiscoveryLoaded? previousState;

  const DiscoveryError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

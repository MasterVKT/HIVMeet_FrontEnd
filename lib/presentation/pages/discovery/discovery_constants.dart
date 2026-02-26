// lib/presentation/pages/discovery/discovery_constants.dart

/// Constants for Discovery page layout, animations, and interactions.
class DiscoveryConstants {
  // Private constructor to prevent instantiation
  DiscoveryConstants._();

  // ===== CARD DIMENSIONS =====
  /// Height ratio of card relative to screen height
  static const double cardHeightRatio = 0.75;

  /// Width ratio of card relative to screen width
  static const double cardWidthRatio = 0.9;

  /// Height ratio of photo section within card
  static const double photoSectionHeightRatio = 0.6;

  // ===== PREVIEW CARDS LAYOUT =====
  /// Top offset for first preview card
  static const double previewCardTopOffset = 50.0;

  /// Additional top offset per preview card index
  static const double previewCardTopOffsetIncrement = 20.0;

  /// Left offset for first preview card
  static const double previewCardLeftOffset = 50.0;

  /// Additional left offset per preview card index
  static const double previewCardLeftOffsetIncrement = 12.0;

  /// Base scale factor for preview cards
  static const double previewCardBaseScale = 0.85;

  /// Scale decrement per preview card index
  static const double previewCardScaleDecrement = 0.1;

  /// Base opacity for preview cards
  static const double previewCardBaseOpacity = 0.3;

  /// Opacity decrement per preview card index
  static const double previewCardOpacityDecrement = 0.15;

  /// Maximum number of preview cards to display
  static const int maxPreviewCards = 2;

  // ===== SWIPE GESTURES =====
  /// Minimum distance in pixels to trigger a swipe
  static const double swipeThreshold = 50.0;

  /// Divisor for calculating rotation angle during swipe
  static const double rotationDivisor = 300.0;

  /// Horizontal threshold as percentage of screen width
  static const double horizontalSwipeThreshold = 0.25;

  /// Vertical threshold as percentage of screen height
  static const double verticalSwipeThreshold = 0.15;

  // ===== ANIMATION DURATIONS =====
  /// Duration of swipe animation
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);

  /// Duration of pulse animation
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1000);

  /// Duration of super like animation
  static const Duration superLikeAnimationDuration = Duration(milliseconds: 1000);

  /// Duration of image fade-in animation
  static const Duration imageFadeInDuration = Duration(milliseconds: 200);

  /// Duration of match modal scale animation
  static const Duration matchScaleAnimationDuration = Duration(milliseconds: 600);

  /// Duration of match modal rotation animation
  static const Duration matchRotationAnimationDuration = Duration(milliseconds: 800);

  /// Duration of match modal fade animation
  static const Duration matchFadeAnimationDuration = Duration(milliseconds: 400);

  /// Delay before starting animations (for sequencing)
  static const Duration animationDelayShort = Duration(milliseconds: 200);

  /// Longer delay for animation sequences
  static const Duration animationDelayMedium = Duration(milliseconds: 400);

  /// Duration for general page transitions
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // ===== SPACING AND SIZES =====
  /// Bottom padding for action buttons area
  static const double actionButtonsBottomPadding = 80.0;

  /// Horizontal padding for action buttons area
  static const double actionButtonsHorizontalPadding = 20.0;

  /// Size of action buttons
  static const double actionButtonSize = 56.0;

  /// Top position for daily limit indicator
  static const double dailyLimitIndicatorTop = 70.0;

  /// Left padding for daily limit indicator
  static const double dailyLimitIndicatorLeft = 20.0;

  /// Right padding for daily limit indicator
  static const double dailyLimitIndicatorRight = 120.0;

  /// Bottom position for loading more indicator
  static const double loadingMoreIndicatorBottom = 200.0;

  /// Size of indicator dots in photo carousel
  static const double photoIndicatorDotSize = 8.0;

  /// Spacing between indicator dots
  static const double photoIndicatorDotSpacing = 4.0;

  /// Size of quick action buttons (common interests, etc.)
  static const double quickActionButtonSize = 40.0;

  // ===== PROFILE CARD CONTENT =====
  /// Maximum number of interests to show in preview
  static const int maxInterestsPreview = 3;

  /// Maximum number of interests to select in filters
  static const int maxInterestsSelection = 5;

  // ===== FILTERS =====
  /// Minimum age for age range filter
  static const int minAge = 18;

  /// Maximum age for age range filter
  static const int maxAge = 99;

  /// Number of divisions for age range slider
  static const int ageRangeDivisions = 81;

  /// Minimum distance for distance filter (km)
  static const int minDistance = 5;

  /// Maximum distance for distance filter (km)
  static const int maxDistance = 100;

  /// Number of divisions for distance slider
  static const int distanceDivisions = 19;

  // ===== LOADING LIMITS =====
  /// Default number of profiles to load initially
  static const int defaultProfileLoadLimit = 5;

  /// Number of profiles to load when paginating
  static const int paginationLoadLimit = 10;

  /// Minimum number of profiles before triggering auto-load
  static const int autoLoadThreshold = 2;

  // ===== MISC =====
  /// Maximum lines for bio text
  static const int maxBioLines = 3;

  /// Duration to show snackbar messages
  static const Duration snackBarDuration = Duration(seconds: 3);

  /// Duration to show reload success message
  static const Duration reloadMessageDuration = Duration(seconds: 2);
}

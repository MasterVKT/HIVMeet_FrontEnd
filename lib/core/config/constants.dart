// lib/core/config/constants.dart

class AppSpacing {
  // Espacement selon la grille de base 4px
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Espacements spécifiques
  static const double cardPadding = 16.0;
  static const double screenPadding = 16.0;
  static const double sectionSpacing = 32.0;
  static const double elementSpacing = 16.0;
  static const double itemSpacing = 8.0;
}

class AppSizes {
  // Tailles des boutons
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Tailles d'icônes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  // Rayons de bordure
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Tailles d'avatar
  static const double avatarSmall = 40.0;
  static const double avatarMedium = 56.0;
  static const double avatarLarge = 80.0;
  
  // Autres tailles
  static const double bottomNavHeight = 64.0;
  static const double appBarHeight = 56.0;
  static const double profileCardHeight = 600.0;
}

class AppDurations {
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration errorToastDuration = Duration(seconds: 4);
}

class AppLimits {
  static const int maxPhotosGratuit = 1;
  static const int maxPhotosPremium = 6;
  static const int maxBioLength = 500;
  static const int maxMessageLength = 1000;
  static const int maxInterests = 3;
  static const int minAge = 18;
  static const int maxAge = 99;
  static const int minDistance = 5;
  static const int maxDistance = 100;
  static const int dailyLikesGratuit = 20;
  static const int maxMessagesStoredGratuit = 50;
  static const int maxMessagesStoredPremium = 200;
  static const int callDurationLimit = 30; // minutes
}

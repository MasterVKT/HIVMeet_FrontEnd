import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryPurple =
      Color(0xFF8C2DDB); // Violet principal (Amethyst)
  static const Color primaryWhite = Color(0xFFF5F5F5); // Blanc (Snow)

  // Couleurs secondaires
  static const Color lightPurple = Color(0xFFB76AE8); // Violet clair (Lavender)
  static const Color darkPurple =
      Color(0xFF6211A8); // Violet foncé (Deep Purple)
  static const Color turquoise = Color(0xFF0CCAD8); // Turquoise (Aqua)
  static const Color coral = Color(0xFFFF6B6B); // Corail doux (Coral)

  // Couleurs neutres
  static const Color platinum = Color(0xFFE8E8E8); // Gris très clair (Platinum)
  static const Color silver = Color(0xFFC5C5C5); // Gris clair (Silver)
  static const Color slate = Color(0xFF7A7A7A); // Gris moyen (Slate)
  static const Color charcoal = Color(0xFF393939); // Gris foncé (Charcoal)

  // Couleurs fonctionnelles
  static const Color success = Color(0xFF2BD9A1); // Succès (Mint)
  static const Color warning = Color(0xFFFFB039); // Alerte (Amber)
  static const Color error = Color(0xFFE53E3E); // Erreur (Ruby)
  static const Color info = Color(0xFF4299E1); // Information (Sky)

  // Getters pour compatibilité avec les widgets existants
  static Color get primary => primaryPurple;
  static Color get secondary => turquoise;
  static Color get surface => Colors.white;
  static Color get onSurface => charcoal;
  static Color get outline => silver;

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, lightPurple],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [turquoise, success],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Couleurs de base
      primaryColor: AppColors.primaryPurple,
      primaryColorLight: AppColors.lightPurple,
      primaryColorDark: AppColors.darkPurple,
      scaffoldBackgroundColor: Colors.white,

      // Les nuances de couleurs
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.turquoise,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.charcoal,
        onError: Colors.white,
      ),

      // Typographie
      textTheme: TextTheme(
        displayLarge: GoogleFonts.openSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: AppColors.charcoal,
        ),
        displayMedium: GoogleFonts.openSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppColors.charcoal,
        ),
        displaySmall: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.charcoal,
        ),
        headlineMedium: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: AppColors.charcoal,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.charcoal,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.slate,
        ),
        labelSmall: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: AppColors.slate,
        ),
        labelLarge: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primaryPurple, width: 1),
          foregroundColor: AppColors.primaryPurple,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          foregroundColor: AppColors.primaryPurple,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.silver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.silver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        labelStyle: GoogleFonts.openSans(color: AppColors.slate),
        hintStyle: GoogleFonts.openSans(color: AppColors.slate),
        errorStyle: GoogleFonts.openSans(color: AppColors.error),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData get darkTheme {
    // Adaptations pour le thème sombre basé sur la charte graphique
    final ThemeData baseTheme = lightTheme;

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF212121),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.turquoise,
        surface: Color(0xFF2D2D2D),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.openSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.openSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
        displaySmall: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFB3B3B3), // Texte secondaire
        ),
        labelSmall: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: const Color(0xFFB3B3B3),
        ),
        labelLarge: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D2D2D),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        labelStyle: GoogleFonts.openSans(color: const Color(0xFFB3B3B3)),
        hintStyle: GoogleFonts.openSans(color: const Color(0xFFB3B3B3)),
        errorStyle: GoogleFonts.openSans(color: AppColors.error),
      ),
    );
  }
}

/// Extension pour remplacer withOpacity par withValues (non déprécié)
extension ColorOpacityExtension on Color {
  /// Remplace withOpacity par withValues pour éviter la dépréciation
  Color withOpacityValues(double opacity) {
    return withValues(alpha: opacity);
  }
}

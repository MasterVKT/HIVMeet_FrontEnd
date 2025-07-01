// lib/core/util/validators.dart

import 'package:hivmeet/presentation/blocs/register/register_state.dart';

class Validators {
  // Regex pour la validation d'email
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Regex pour la validation du mot de passe
  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // Regex pour le numéro de téléphone (format international)
  static final RegExp _phoneRegExp = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  /// Valide un email
  static bool isValidEmail(String email) {
    return _emailRegExp.hasMatch(email);
  }

  /// Valide un mot de passe
  static bool isValidPassword(String password) {
    return _passwordRegExp.hasMatch(password);
  }

  /// Calcule la force du mot de passe
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int strength = 0;

    // Longueur
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Complexité
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[@$!%*?&#]'))) strength++;

    if (strength <= 3) return PasswordStrength.weak;
    if (strength <= 5) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Valide le nom d'affichage
  static bool isValidDisplayName(String name) {
    return name.trim().length >= 3 && name.trim().length <= 30;
  }

  /// Vérifie si la personne a au moins 18 ans
  static bool isAdult(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final monthDiff = now.month - birthDate.month;
    final dayDiff = now.day - birthDate.day;

    if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  /// Valide un numéro de téléphone
  static bool isValidPhoneNumber(String phoneNumber) {
    return _phoneRegExp.hasMatch(phoneNumber);
  }

  /// Valide la longueur d'une bio
  static bool isValidBio(String bio) {
    return bio.length <= 500;
  }

  /// Valide le nombre d'intérêts
  static bool isValidInterestsCount(List<String> interests) {
    return interests.length <= 3;
  }

  /// Valide une URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Valide la distance maximale
  static bool isValidDistance(int distance) {
    return distance >= 5 && distance <= 100;
  }

  /// Valide une tranche d'âge
  static bool isValidAgeRange(int minAge, int maxAge) {
    return minAge >= 18 && maxAge <= 99 && minAge <= maxAge;
  }
}

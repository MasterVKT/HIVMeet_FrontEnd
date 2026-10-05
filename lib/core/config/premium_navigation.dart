/// Navigation de sortie d'un achat Premium. Seules ces destinations locales
/// sont acceptées; toute valeur provenant d'un deep link est ignorée.
abstract final class PremiumNavigation {
  static const Set<String> allowedReturnTargets = {
    '/discovery',
    '/likes-received',
    '/profile',
  };

  static String? sanitizeReturnTo(String? value) {
    final candidate = value?.trim();
    return allowedReturnTargets.contains(candidate) ? candidate : null;
  }

  static String location({String? returnTo}) {
    final safe = sanitizeReturnTo(returnTo);
    return Uri(
      path: '/premium',
      queryParameters: safe == null ? null : {'returnTo': safe},
    ).toString();
  }
}

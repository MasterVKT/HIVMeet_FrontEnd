import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';

@singleton
class LocalizationService extends ChangeNotifier {
  static const String _defaultLocale = 'fr';
  static const List<String> _supportedLocales = ['fr', 'en'];

  String _currentLocale = _defaultLocale;
  Map<String, dynamic> _localizedStrings = {};

  String get currentLocale => _currentLocale;
  List<String> get supportedLocales => _supportedLocales;

  /// Méthode statique pour accéder à l'instance singleton
  static LocalizationService get instance =>
      GetIt.instance<LocalizationService>();

  /// Méthode statique pour traduire
  static String translate(String key, {Map<String, dynamic>? params}) {
    return instance.translateKey(key, params: params);
  }

  /// Initialise le service avec la langue par défaut
  Future<void> initialize([String? locale]) async {
    _currentLocale = locale ?? _defaultLocale;
    await _loadLocalizedStrings(_currentLocale);
  }

  /// Change la langue de l'application
  Future<void> changeLocale(String locale) async {
    if (!_supportedLocales.contains(locale)) {
      throw ArgumentError('Locale $locale is not supported');
    }

    if (_currentLocale != locale) {
      _currentLocale = locale;
      await _loadLocalizedStrings(locale);
      notifyListeners();
    }
  }

  /// Charge les chaînes de traduction depuis le fichier JSON
  Future<void> _loadLocalizedStrings(String locale) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/translations/$locale.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
    } catch (e) {
      debugPrint('Error loading translations for $locale: $e');
      // Fallback vers la langue par défaut si erreur
      if (locale != _defaultLocale) {
        final String fallbackString = await rootBundle
            .loadString('assets/translations/$_defaultLocale.json');
        final Map<String, dynamic> fallbackMap = json.decode(fallbackString);
        _localizedStrings = fallbackMap;
      }
    }
  }

  /// Récupère une chaîne traduite
  String translateKey(String key, {Map<String, dynamic>? params}) {
    final String? value = _getValue(key);

    if (value == null) {
      debugPrint('Translation key not found: $key');
      return key; // Retourne la clé si traduction non trouvée
    }

    // Remplace les paramètres dans la chaîne
    if (params != null) {
      return _interpolateString(value, params);
    }

    return value;
  }

  /// Récupère une valeur depuis la map de traductions en utilisant la notation point
  String? _getValue(String key) {
    final List<String> keys = key.split('.');
    dynamic current = _localizedStrings;

    for (final String k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }

  /// Interpole les paramètres dans une chaîne
  String _interpolateString(String value, Map<String, dynamic> params) {
    String result = value;

    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    return result;
  }

  /// Vérifie si une clé de traduction existe
  bool hasTranslation(String key) {
    return _getValue(key) != null;
  }
}

/// Extension pour simplifier l'utilisation des traductions
extension LocalizationExtension on String {
  String tr({Map<String, dynamic>? params}) {
    // Cette extension sera utilisée avec un provider global
    // Pour l'instant, on retourne la clé
    return this;
  }
}

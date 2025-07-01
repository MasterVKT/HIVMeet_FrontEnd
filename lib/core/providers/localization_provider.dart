import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';

class LocalizationProvider extends ChangeNotifier {
  final LocalizationService _localizationService = getIt<LocalizationService>();

  LocalizationProvider() {
    _localizationService.addListener(_onLocaleChanged);
  }

  String get currentLocale => _localizationService.currentLocale;
  List<String> get supportedLocales => _localizationService.supportedLocales;

  void _onLocaleChanged() {
    notifyListeners();
  }

  String translate(String key, {Map<String, dynamic>? params}) {
    return _localizationService.translateKey(key, params: params);
  }

  Future<void> changeLocale(String locale) async {
    await _localizationService.changeLocale(locale);
  }

  @override
  void dispose() {
    _localizationService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // Méthode statique pour accès global
  static LocalizationProvider of(BuildContext context) {
    return Provider.of<LocalizationProvider>(context, listen: false);
  }

  // Méthode statique pour traductions rapides
  static String tr(BuildContext context, String key,
      {Map<String, dynamic>? params}) {
    return of(context).translate(key, params: params);
  }
}

class LocalizationWrapper extends StatelessWidget {
  final Widget child;

  const LocalizationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocalizationProvider(),
      child: child,
    );
  }
}

extension BuildContextLocalization on BuildContext {
  String get locale {
    try {
      final provider = Provider.of<LocalizationProvider>(this, listen: false);
      return provider.currentLocale;
    } catch (e) {
      return 'fr'; // Fallback
    }
  }

  String tr(String key, {Map<String, dynamic>? params}) {
    try {
      final provider = Provider.of<LocalizationProvider>(this, listen: false);
      return provider.translate(key, params: params);
    } catch (e) {
      return key; // Fallback
    }
  }
}

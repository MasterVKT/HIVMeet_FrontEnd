# Guide pour la Suppression des Logs Répétitifs

## Problème Identifié

Les logs de l'application Flutter/Dart contiennent de nombreuses entrées répétitives, particulièrement des messages EGL_emulation et app_time_stats, qui rendent difficile l'identification des véritables problèmes dans les logs.

Exemples de logs répétitifs :
```
D/EGL_emulation(13491): app_time_stats: avg=45.51ms min=13.51ms max=87.86ms count=22
D/EGL_emulation(13491): app_time_stats: avg=40.16ms min=13.12ms max=116.74ms count=24
```

## Solutions pour Supprimer ou Réduire ces Logs

### 1. Côté Android Emulator

#### Solution 1: Utiliser des filtres ADB
```bash
# Filtrer les messages EGL_emulation
adb logcat -v brief | grep -v "EGL_emulation"

# Créer un filtre spécifique pour ne voir que les logs Flutter
adb logcat | grep -E "(flutter|ERROR|FATAL|Exception)"
```

#### Solution 2: Désactiver les logs spécifiques dans l'émulateur
Ajouter ces paramètres dans les paramètres avancés de l'émulateur Android:
```
 -debug-no-gl-errors
 -debug-no-gl-checks
```

### 2. Côté Application Flutter

#### Solution 1: Filtrer les logs dans le code
Modifier le fichier `main.dart` pour filtrer les logs indésirables:

```dart
import 'dart:developer' as developer;

void main() {
  // Rediriger les logs pour filtrer les entrées indésirables
  developer.Timeline.startSync('App Start');
  
  // Initialiser l'application avec un filtre de logs personnalisé
  runApp(MyApp());
}

// Créer un logger personnalisé pour filtrer les entrées
class CustomLogFilter {
  static bool shouldLog(String message) {
    // Filtres pour ignorer les messages répétitifs
    final ignoredPatterns = [
      RegExp(r'EGL_emulation.*app_time_stats'),
      RegExp(r'D/EGL_emulation'),
      RegExp(r'app_time_stats: avg='),
      RegExp(r'device/generic/goldfish-opengl'),
      // Ajouter d'autres motifs selon les besoins
    ];
    
    return !ignoredPatterns.any((pattern) => pattern.hasMatch(message));
  }
  
  static void log(String message, {String? name, int? level}) {
    if (shouldLog(message)) {
      developer.log(message, name: name, level: level);
    }
  }
}
```

#### Solution 2: Utiliser un package de logging avec filtres
Ajouter au `pubspec.yaml`:
```yaml
dependencies:
  logger: ^2.0.2
```

Configuration dans `main.dart`:
```dart
import 'package:logger/logger.dart';

void main() {
  // Configurer un logger avec filtres
  Logger.level = Level.debug;
  
  final logger = Logger(
    filter: CustomFilter(), // Filtre personnalisé
    printer: PrettyPrinter(),
  );
  
  runApp(MyApp());
}

class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    final message = event.message.toString();
    
    // Ne pas logger les messages contenant ces motifs
    final ignoredPatterns = [
      'EGL_emulation',
      'app_time_stats',
      'goldfish-opengl',
      'GL error',
    ];
    
    return !ignoredPatterns.any((pattern) => message.contains(pattern));
  }
}
```

### 3. Côté Backend Django

#### Solution 1: Configurer les logs dans settings.py
```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        # Filtrer les logs spécifiques
        'django.server': {
            'handlers': ['console'],
            'level': 'WARNING',  # Réduire le niveau de verbosité
            'propagate': False,
        },
    },
}
```

### 4. Solution Complète pour le Projet HIVMeet

#### Étape 1: Créer un service de logging centralisé

Créer `lib/core/utils/log_service.dart`:
```dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LogService {
  static const bool _enableVerboseLogs = kDebugMode;
  static const List<String> _filteredMessages = [
    'EGL_emulation',
    'app_time_stats',
    'goldfish-opengl',
    'GL error',
    'eglCodecCommon',
    'HostConnection',
  ];

  static void log(dynamic message, {String? name, int? level = 0}) {
    if (!_enableVerboseLogs) return;
    
    final messageStr = message.toString();
    
    // Vérifier si le message contient un motif à filtrer
    if (_filteredMessages.any((filter) => messageStr.contains(filter))) {
      return; // Ne pas logger les messages filtrés
    }
    
    developer.log(messageStr, name: name, level: level);
  }
  
  static void debug(dynamic message, {String? name}) {
    log(message, name: name, level: 500); // Level debug
  }
  
  static void info(dynamic message, {String? name}) {
    log(message, name: name, level: 400); // Level info
  }
  
  static void warning(dynamic message, {String? name}) {
    log(message, name: name, level: 300); // Level warning
  }
  
  static void error(dynamic message, {String? name}) {
    log(message, name: name, level: 200); // Level error
  }
}
```

#### Étape 2: Remplacer les appels à debugPrint et print

Dans tous les fichiers, remplacer:
- `debugPrint('message')` par `LogService.debug('message')`
- `print('message')` par `LogService.info('message')`
- Les erreurs spécifiques par `LogService.error('message')`

#### Étape 3: Mise à jour de la configuration de logging

Mettre à jour `lib/core/config/logging_config.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../utils/log_service.dart';

class LoggingConfig {
  static void init() {
    // Désactiver les logs Flutter verbeux en mode release
    if (!kDebugMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
    
    // Configurer le logger avec nos filtres
    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      LogService.log(
        '${record.level.name}: ${record.loggerName}: ${record.message}',
        name: record.loggerName,
        level: _mapLevel(record.level),
      );
    });
  }
  
  static int _mapLevel(Level level) {
    if (level <= Level.FINE) return 500;
    if (level <= Level.INFO) return 400;
    if (level <= Level.WARNING) return 300;
    return 200; // error
  }
}
```

## Commandes Utiles

### Pour filtrer les logs en temps réel
```bash
# Filtrer les logs Flutter uniquement
flutter logs | grep -v -E "(EGL_emulation|app_time_stats|goldfish)"

# Filtrer les erreurs uniquement
flutter logs | grep -E "(ERROR|Exception|FATAL)"

# Utiliser un tag spécifique pour filtrer
flutter logs --output-dir ./logs
```

### Pour filtrer les logs backend
```bash
# Lancer le backend avec un niveau de log spécifique
python manage.py runserver --verbosity=1

# Ou avec un fichier de configuration des logs
python manage.py runserver 0.0.0.0:8000 --settings=hivmeet_backend.settings_dev
```

## Recommandations

1. **Immédiat**: Mettre en place le service de logging centralisé avec filtres
2. **Court terme**: Remplacer tous les appels à print/debugPrint par les méthodes du service de logging
3. **Moyen terme**: Configurer des profils de logging différents pour développement, staging et production
4. **Long terme**: Intégrer une solution de monitoring externe (comme Sentry) pour les erreurs critiques

## Fichiers à Modifier

- `lib/core/config/logging_config.dart` - Configuration centrale des logs
- `lib/core/utils/log_service.dart` - Service de logging avec filtres
- Tous les fichiers qui contiennent des appels à print() ou debugPrint()

## Avantages de cette Solution

1. Réduction significative du bruit dans les logs
2. Meilleure lisibilité des véritables problèmes
3. Conservation des logs utiles pour le débogage
4. Flexibilité pour adapter les filtres selon les besoins
5. Approche centralisée et maintenable
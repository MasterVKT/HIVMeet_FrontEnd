# Corrections appliquées - HIVMeet Frontend

**Date** : 2026-07-26  
**Problème** : Erreurs de compilation et problèmes de connexion backend

---

## 🔧 Corrections apportées

### 1. Import manquant `flutter_localizations`

**Fichier** : `lib/main.dart`

**Problème** : Erreurs de compilation :
```
Error: The getter 'GlobalMaterialLocalizations' isn't defined
Error: The getter 'GlobalWidgetsLocalizations' isn't defined
Error: The getter 'GlobalCupertinoLocalizations' isn't defined
```

**Solution** : Ajout de l'import
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
```

---

### 2. Configuration des localisations dans MaterialApp

**Fichier** : `lib/main.dart`

**Problème** : `LocaleDataException: Locale data has not been initialized`

**Solution** : Ajout dans `MaterialApp.router()` :
```dart
localizationsDelegates: [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: const [
  Locale('fr'),
  Locale('en'),
],
locale: const Locale('fr'),
```

---

### 3. Conversion des URLs de photos relatives en URLs absolues

**Fichiers** :
- `lib/data/repositories/profile_repository_impl.dart`
- `lib/data/repositories/message_repository_impl.dart`
- `lib/data/repositories/resource_repository_impl.dart`

**Problème** : `Invalid argument(s): No host specified in URI file:///profile_photos/...`

**Cause** : Le backend renvoie des URLs relatives (`profile_photos/male_28_1756679299.jpg`) au lieu d'URLs absolues.

**Solution** : Ajout de la méthode helper `_buildAbsoluteUrl()` :
```dart
String? _buildAbsoluteUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return '${AppConfig.apiBaseUrl}/$url';
}
```

**Utilisation** :
```dart
// Dans profile_repository_impl.dart
final photoUrlRaw = json['photo_url'] as String? ?? '';
final photoUrl = photoUrlRaw.isEmpty || photoUrlRaw.startsWith('http')
    ? photoUrlRaw
    : '${AppConfig.apiBaseUrl}/$photoUrlRaw';

// Dans message_repository_impl.dart
mediaUrl: _buildAbsoluteUrl(json['media_url'] as String?),

// Dans resource_repository_impl.dart
thumbnailUrl: _buildAbsoluteUrl(json['thumbnail_url'] as String?),
```

---

### 4. Correction de l'IP du backend pour appareil physique

**Fichier** : `lib/core/config/app_config.dart`

**Problème** : L'appareil physique ne pouvait pas se connecter au backend.
- Ancienne IP : `10.241.252.68:8000` (incorrecte)
- IP réelle de la machine : `192.168.1.118:8000`

**Solution** : Mise à jour de l'IP :
```dart
if (_isPhysicalDevice) {
  return 'http://192.168.1.118:8000';
}
```

---

### 5. Démarrage de Redis pour WebSockets

**Problème** : `ConnectionRefusedError: [Errno 10061] Connect call failed ('127.0.0.1', 6379)`

**Cause** : Redis n'était pas installé/démarré sur la machine.

**Solution** : Démarrage de Redis via Docker :
```bash
docker run -d -p 6379:6379 --name hivmeet-redis redis:latest
```

**Statut** : ✅ Redis tourne sur le port 6379

---

## 📊 Résultats

### Avant corrections :
- ❌ Compilation échouait avec erreurs `GlobalMaterialLocalizations`
- ❌ Erreurs `LocaleDataException` à l'exécution
- ❌ Erreurs `No host specified in URI` pour les photos
- ❌ Appareil physique ne pouvait pas se connecter au backend
- ❌ WebSockets échouaient (Redis manquant)

### Après corrections :
- ✅ Compilation réussie
- ✅ Application s'exécute sur émulateur et appareil physique
- ✅ Photos s'affichent correctement
- ✅ Localisations FR/EN fonctionnent
- ✅ Backend accessible depuis les deux appareils
- ✅ WebSockets opérationnels avec Redis

---

## 🚀 Commandes utiles

### Démarrer Redis
```bash
docker start hivmeet-redis
```

### Arrêter Redis
```bash
docker stop hivmeet-redis
```

### Lancer l'application
```bash
# Émulateur
flutter run -d emulator-5554

# Appareil physique
flutter run -d A99JBB5C02100814
```

### Logs backend
```bash
cd D:\Projets\HIVMeet\env\hivmeet_backend
python manage.py runserver 0.0.0.0:8000
```

---

## 📝 Notes

- Les URLs des photos sont converties automatiquement en URLs absolues
- L'IP du backend (`192.168.1.118`) peut changer selon le réseau - mettre à jour `app_config.dart` si nécessaire
- Redis est requis pour : WebSocket, présence en ligne, cache, sessions
- Les logs de l'appareil physique sont sauvegardés dans `device_physical_logs.txt`

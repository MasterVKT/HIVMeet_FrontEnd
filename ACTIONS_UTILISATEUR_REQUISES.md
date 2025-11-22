# 📋 ACTIONS UTILISATEUR REQUISES - HIVMeet

**Date**: 20 novembre 2024
**Branche**: `claude/gap-analysis-plan-01HqQrjqQzX8raS1WXb2SC5X`
**État Actuel**: Architecture Clean 100% complète | Tests & Configuration manquants

---

## 🎯 VUE D'ENSEMBLE

Ce document liste **toutes les actions que vous devez effectuer** pour finaliser l'application HIVMeet à 100%.

L'architecture Clean est maintenant **complète** avec tous les BLoCs utilisant des Use Cases. Ce qui reste nécessite:
- ✅ **Environnement Flutter** fonctionnel
- ✅ **Configuration Firebase** (Storage, FCM, etc.)
- ✅ **Tests avec device/émulateur**
- ✅ **Déploiement production**

---

## 📊 PROGRESSION ACTUELLE

### ✅ Architecture Clean - 100% COMPLÉTÉ
- [x] DiscoveryBloc avec 7 Use Cases
- [x] ResourcesBloc avec 2 Use Cases + 3 Use Cases Feed disponibles
- [x] ChatBloc avec 4 Use Cases
- [x] ConversationsBloc avec 3 Use Cases
- [x] ProfileBloc avec 10 Use Cases
- [x] MatchesBloc avec Use Cases (depuis Sprint 1)

**Résultat**: Tous les BLoCs critiques ne communiquent plus directement avec les repositories. Clean Architecture respectée à 100%.

### ⚠️ Configuration & Tests - À FAIRE

Les sections ci-dessous détaillent tout ce qu'il reste à faire.

---

## 1️⃣ CONFIGURATION FIREBASE

### 🔥 Firebase Storage (Images/Médias)

**Fichier concerné**: `FIREBASE_STORAGE_SETUP.md` (voir ce document séparé)

**Actions requises**:
1. Activer Firebase Storage dans la console Firebase
2. Configurer les règles de sécurité Storage
3. Définir les limites de taille (10MB photos profil, 50MB médias chat)
4. Tester l'upload depuis l'app Flutter

**Impact**: Sans cela, UploadPhoto et SendMediaMessage ne fonctionneront pas.

---

### 🔔 Firebase Cloud Messaging (Notifications Push)

**Fichier concerné**: `FIREBASE_FCM_SETUP.md` (voir ce document séparé)

**Actions requises**:
1. Obtenir les clés serveur FCM (iOS + Android)
2. Configurer APNs pour iOS (certificats Apple)
3. Ajouter google-services.json (Android) et GoogleService-Info.plist (iOS)
4. Tester réception notifications sur device réel

**Impact**: Sans cela, les notifications push ne fonctionneront pas.

---

### 📱 Firebase Dynamic Links (Deep Linking)

**Fichier concerné**: `DEEP_LINKING_SETUP.md` (voir ce document séparé)

**Actions requises**:
1. Configurer Firebase Dynamic Links dans console
2. Ajouter domaine personnalisé (hivmeet.page.link ou custom)
3. Configurer Associated Domains iOS
4. Configurer App Links Android
5. Tester deep links: profil, match, conversation

**Impact**: Liens partagés ne s'ouvriront pas dans l'app.

---

## 2️⃣ DÉPENDANCES FLUTTER À INSTALLER

### 📦 Packages Manquants

Ajoutez les packages suivants dans `pubspec.yaml`:

```yaml
dependencies:
  # Compression d'images (CRITIQUE pour Sprint 2 - Task 2.2)
  flutter_image_compress: ^2.1.0

  # Stockage local offline (Sprint 2 - Task 2.3)
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # WebRTC pour appels vidéo/audio (Sprint 3 - Task 3.3)
  flutter_webrtc: ^0.9.47

  # Analytics & Crashlytics (Sprint 3 - Task 3.2)
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9

  # Permissions (photos, localisation, micro, caméra)
  permission_handler: ^11.1.0

dev_dependencies:
  # Génération code Hive
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

**Commandes à exécuter**:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 3️⃣ IMPLÉMENTATION COMPRESSION IMAGES

### 📸 Sprint 2 - Task 2.2: Media Upload & Compression

**Fichier à créer**: `lib/core/services/image_compression_service.dart`

**Code template**:
```dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  /// Compresse une image pour profil (max 800x800, qualité 85%)
  Future<File> compressProfilePhoto(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Compression d\'image échouée');
    }

    return File(result.path);
  }

  /// Compresse un média chat (max 1920x1080, qualité 80%)
  Future<File> compressChatMedia(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_chat_compressed.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1920,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Compression d\'image échouée');
    }

    return File(result.path);
  }
}
```

**Étapes**:
1. Créer le fichier ci-dessus
2. Ajouter à `injection.dart`:
   ```dart
   getIt.registerSingleton<ImageCompressionService>(
     ImageCompressionService(),
   );
   ```
3. Modifier `UploadPhoto` Use Case pour appeler le service avant upload
4. Modifier `SendMediaMessage` Use Case pour appeler le service avant upload
5. **TESTER** sur device réel avec vraies photos

---

## 4️⃣ IMPLÉMENTATION OFFLINE SUPPORT

### 💾 Sprint 2 - Task 2.3: Cache Repository avec Hive

**Fichiers à créer**:

1. **`lib/data/models/cached_profile_model.dart`** (exemple)
```dart
import 'package:hive/hive.dart';
import 'package:hivmeet/domain/entities/profile.dart';

part 'cached_profile_model.g.dart';

@HiveType(typeId: 0)
class CachedProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final List<String> photos;

  @HiveField(3)
  final String bio;

  @HiveField(4)
  final DateTime cachedAt;

  CachedProfileModel({
    required this.id,
    required this.displayName,
    required this.photos,
    required this.bio,
    required this.cachedAt,
  });

  // Conversion vers Entity
  Profile toEntity() {
    return Profile(
      id: id,
      displayName: displayName,
      photos: photos,
      bio: bio,
      // ... autres champs
    );
  }

  // Création depuis Entity
  factory CachedProfileModel.fromEntity(Profile profile) {
    return CachedProfileModel(
      id: profile.id,
      displayName: profile.displayName,
      photos: profile.photos,
      bio: profile.bio,
      cachedAt: DateTime.now(),
    );
  }
}
```

2. **`lib/data/datasources/local/cache_data_source.dart`**
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hivmeet/data/models/cached_profile_model.dart';

class CacheDataSource {
  late Box<CachedProfileModel> _profileBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CachedProfileModelAdapter());
    _profileBox = await Hive.openBox<CachedProfileModel>('profiles');
  }

  Future<void> cacheProfile(CachedProfileModel profile) async {
    await _profileBox.put(profile.id, profile);
  }

  CachedProfileModel? getCachedProfile(String profileId) {
    return _profileBox.get(profileId);
  }

  Future<void> clearCache() async {
    await _profileBox.clear();
  }
}
```

**Étapes**:
1. Créer les fichiers ci-dessus
2. Exécuter `flutter pub run build_runner build`
3. Initialiser Hive dans `main.dart` avant `runApp()`
4. Ajouter CacheDataSource à `injection.dart`
5. Modifier repositories pour vérifier cache avant appel API
6. **TESTER** mode avion

---

## 5️⃣ TESTS À EXÉCUTER

### 🧪 Tests Unitaires

**Statut actuel**: 127+ tests (Use Cases + BLoCs)

**Actions requises**:
```bash
# Exécuter tous les tests
flutter test

# Tests avec coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # Voir rapport coverage
```

**Objectif**: 80%+ code coverage

---

### 🔬 Tests d'Intégration

**Fichier à créer**: `integration_test/app_test.dart`

**Scénarios critiques à tester**:
1. **Flux Auth**: Inscription → Vérification email → Connexion
2. **Flux Discovery**: Swipe right → Match found → Voir conversation
3. **Flux Chat**: Envoyer message texte → Envoyer photo → Messages reçus
4. **Flux Profile**: Upload photo → Set main → Delete photo

**Commande**:
```bash
flutter test integration_test/app_test.dart
```

---

### 📱 Tests sur Devices Réels

**Checklist**:
- [ ] Test iOS (iPhone 12+, iOS 15+)
- [ ] Test Android (Pixel 4+, Android 11+)
- [ ] Test upload photos depuis galerie
- [ ] Test prise photo avec caméra
- [ ] Test géolocalisation
- [ ] Test notifications push
- [ ] Test mode avion (offline)
- [ ] Test rotation écran
- [ ] Test dark mode

---

## 6️⃣ OPTIMISATIONS PERFORMANCE

### ⚡ Sprint 3 - Task 3.5: Performance Optimizations

**Actions requises**:

1. **Analyser performance avec DevTools**:
   ```bash
   flutter run --profile
   # Ouvrir DevTools et profiler
   ```

2. **Images**:
   - Utiliser `cached_network_image` pour toutes les photos
   - Implémenter placeholders
   - Lazy loading dans listes

3. **Listes**:
   - Discovery: Implémenter `AutomaticKeepAliveClientMixin` pour cards
   - Matches/Conversations: Virtual scrolling si >100 items

4. **Build**:
   - Activer code shrinking (Android)
   - Activer bitcode (iOS)
   - Obfuscation en production

**Fichier à modifier**: `android/app/build.gradle`
```gradle
buildTypes {
    release {
        shrinkResources true
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

---

## 7️⃣ DÉPLOIEMENT PRODUCTION

### 🚀 Checklist Pre-Production

**Configuration**:
- [ ] Firebase en mode production (pas debug)
- [ ] API backend en production (pas staging)
- [ ] Crashlytics activé
- [ ] Analytics activé
- [ ] Clés API sécurisées (pas hardcodées)
- [ ] Certificats SSL/TLS valides

**Build**:
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

**Tests**:
- [ ] Tester build release (pas debug!)
- [ ] Tester sur devices non-dev
- [ ] Vérifier aucun log debug en production
- [ ] Vérifier permissions minimales

---

### 📱 Publication Stores

**Google Play Store**:
1. Créer compte développeur ($25 one-time)
2. Préparer assets:
   - Icon 512x512
   - Screenshots (5 minimum)
   - Feature graphic 1024x500
   - Description courte/longue
3. Remplir fiche app
4. Upload AAB
5. Test interne → Test fermé → Production

**Apple App Store**:
1. Créer compte développeur ($99/an)
2. Préparer assets:
   - Icon 1024x1024
   - Screenshots pour tous devices
   - Preview vidéo optionnel
   - Description
3. App Store Connect
4. TestFlight beta → Production

---

## 8️⃣ MONITORING POST-LANCEMENT

### 📊 Analytics

**Événements à tracker**:
```dart
// Exemple avec Firebase Analytics
await FirebaseAnalytics.instance.logEvent(
  name: 'profile_photo_uploaded',
  parameters: {'photo_count': profilePhotos.length},
);

await FirebaseAnalytics.instance.logEvent(
  name: 'match_found',
  parameters: {'compatibility_score': score},
);

await FirebaseAnalytics.instance.logEvent(
  name: 'message_sent',
  parameters: {'message_type': 'text'},
);
```

**Métriques clés**:
- Daily Active Users (DAU)
- Matches par jour
- Messages envoyés
- Taux de rétention (D1, D7, D30)
- Conversion premium

---

### 🐛 Crashlytics

**Setup**:
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(MyApp());
}
```

**Vérification**:
```bash
# Forcer un crash test
await FirebaseCrashlytics.instance.crash();
```

---

## 9️⃣ SÉCURITÉ

### 🔒 Checklist Sécurité

**Données sensibles**:
- [ ] Aucun token/clé hardcodé dans le code
- [ ] `.env` pour secrets (avec `flutter_dotenv`)
- [ ] `.env` dans `.gitignore`
- [ ] Rotation tokens backend régulière

**Communication**:
- [ ] HTTPS only (pas HTTP)
- [ ] Certificate pinning (optionnel)
- [ ] Validation certificats SSL

**Stockage local**:
- [ ] Tokens dans `flutter_secure_storage`
- [ ] Pas de données sensibles dans SharedPreferences
- [ ] Encryption Hive boxes si données sensibles

**Code**:
- [ ] Obfuscation activée
- [ ] ProGuard rules correctes (Android)
- [ ] Pas de console.log en production

---

## 🔟 RÉSUMÉ - ORDRE D'EXÉCUTION RECOMMANDÉ

**Semaine 1**:
1. ✅ Installer dépendances Flutter (`flutter pub get`)
2. ✅ Configurer Firebase (Storage + FCM)
3. ✅ Implémenter compression images
4. ✅ Tester upload photos sur device réel

**Semaine 2**:
5. ✅ Implémenter offline support (Hive)
6. ✅ Tests unitaires complets
7. ✅ Tests intégration
8. ✅ Optimisations performance

**Semaine 3**:
9. ✅ Tests devices réels (iOS + Android)
10. ✅ Builds release
11. ✅ Configuration production
12. ✅ Beta testing (TestFlight + Internal Testing)

**Semaine 4**:
13. ✅ Corrections bugs beta
14. ✅ Soumission stores
15. ✅ Monitoring post-lancement

---

## 📞 SUPPORT & QUESTIONS

Si vous rencontrez des problèmes:
1. Consultez les fichiers de documentation séparés (voir références ci-dessus)
2. Vérifiez les logs Flutter: `flutter logs`
3. Vérifiez Firebase Console pour erreurs backend
4. Testez sur émulateur ET device réel

---

**Bonne chance avec la finalisation! L'architecture est solide, il ne reste "que" la configuration et les tests.** 🚀

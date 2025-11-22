# 🔗 FIREBASE DYNAMIC LINKS - CONFIGURATION COMPLÈTE

**Date**: 20 novembre 2024
**Application**: HIVMeet
**Plateforme**: Flutter (iOS + Android)

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble](#1-vue-densemble)
2. [Configuration Firebase Console](#2-configuration-firebase-console)
3. [Configuration Android](#3-configuration-android)
4. [Configuration iOS](#4-configuration-ios)
5. [Implémentation Flutter](#5-implémentation-flutter)
6. [Types de liens HIVMeet](#6-types-de-liens-hivmeet)
7. [Tests et validation](#7-tests-et-validation)
8. [Génération de liens depuis l'app](#8-génération-de-liens-depuis-lapp)
9. [Backend - Génération serveur](#9-backend---génération-serveur)
10. [Dépannage](#10-dépannage)

---

## 1️⃣ VUE D'ENSEMBLE

### Qu'est-ce que Firebase Dynamic Links?

Firebase Dynamic Links permet de créer des **liens intelligents** qui:
- ✅ S'ouvrent dans l'app si installée
- ✅ Redirigent vers App Store/Google Play si app non installée
- ✅ Fonctionnent même après réinstallation (attribution)
- ✅ Survivent au processus d'installation
- ✅ Trackent les conversions et sources

### Cas d'usage HIVMeet

1. **Partage de profil**: `https://hivmeet.page.link/profile/user123`
   - Ouvre profil directement dans l'app
   - Si app non installée: télécharge puis ouvre profil

2. **Invitation de match**: `https://hivmeet.page.link/match/match456`
   - Notification "Vous avez un nouveau match!"
   - Ouvre directement la conversation

3. **Partage de ressource**: `https://hivmeet.page.link/resource/article789`
   - Partage d'articles, guides santé
   - Tracking de viralité

4. **Référral**: `https://hivmeet.page.link/invite?ref=user123`
   - Programme de parrainage
   - Attribution de nouveaux utilisateurs

---

## 2️⃣ CONFIGURATION FIREBASE CONSOLE

### Étape 1: Activer Dynamic Links

1. **Aller dans Firebase Console**: https://console.firebase.google.com
2. Sélectionner votre projet **HIVMeet**
3. Aller dans **Engagement** → **Dynamic Links**
4. Cliquer **Get Started**

### Étape 2: Choisir votre domaine

**Option A - Domaine gratuit Firebase** (recommandé pour développement):
```
https://hivmeet.page.link
```

**Option B - Domaine personnalisé** (recommandé pour production):
```
https://go.hivmeet.com
```

Pour utiliser domaine personnalisé:
1. Posséder le domaine (ex: hivmeet.com)
2. Ajouter enregistrements DNS (fournis par Firebase)
3. Vérifier la propriété du domaine

### Étape 3: Configurer les URL prefixes

Dans Firebase Console → Dynamic Links:
1. Cliquer **Add URL prefix**
2. Entrer: `hivmeet` (si utilisant .page.link)
3. Résultat: `https://hivmeet.page.link`

---

## 3️⃣ CONFIGURATION ANDROID

### android/app/build.gradle

Ajoutez dans `dependencies`:

```gradle
dependencies {
    // ... autres dépendances

    // Firebase Dynamic Links
    implementation 'com.google.firebase:firebase-dynamic-links-ktx:21.1.0'
    implementation 'com.google.firebase:firebase-analytics-ktx:21.3.0'
}
```

### android/app/src/main/AndroidManifest.xml

Ajoutez l'intent filter pour Deep Links:

```xml
<manifest ...>
    <application ...>
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Deep Links - Firebase Dynamic Links -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>

                <!-- Domaine Firebase Dynamic Links -->
                <data
                    android:scheme="https"
                    android:host="hivmeet.page.link"/>

                <!-- Domaine personnalisé (si configuré) -->
                <data
                    android:scheme="https"
                    android:host="go.hivmeet.com"/>
            </intent-filter>

            <!-- Custom URL Scheme (fallback) -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>

                <data
                    android:scheme="hivmeet"
                    android:host="open"/>
            </intent-filter>

            <!-- Autres intent filters... -->
        </activity>
    </application>
</manifest>
```

### Vérification App Links (Android 6.0+)

Créez le fichier `.well-known/assetlinks.json` sur votre domaine:

1. **Générer le fichier**:
   - Aller dans Firebase Console → Dynamic Links → Verify
   - Télécharger `assetlinks.json`

2. **Héberger le fichier**:
   ```
   https://hivmeet.com/.well-known/assetlinks.json
   ```

3. **Contenu exemple**:
   ```json
   [{
     "relation": ["delegate_permission/common.handle_all_urls"],
     "target": {
       "namespace": "android_app",
       "package_name": "com.hivmeet.app",
       "sha256_cert_fingerprints": [
         "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
       ]
     }
   }]
   ```

**Obtenir SHA-256**:
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/release.keystore -alias your-alias
```

---

## 4️⃣ CONFIGURATION iOS

### ios/Runner/Info.plist

Ajoutez Associated Domains:

```xml
<dict>
    <!-- Autres configurations... -->

    <!-- Associated Domains pour Dynamic Links -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>hivmeet</string>
            </array>
        </dict>
    </array>

    <!-- Firebase Dynamic Links -->
    <key>FirebaseDynamicLinksCustomDomains</key>
    <array>
        <string>https://hivmeet.page.link</string>
        <string>https://go.hivmeet.com</string>
    </array>
</dict>
```

### Xcode - Associated Domains

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Sélectionner target **Runner**
3. Aller dans **Signing & Capabilities**
4. Cliquer **+ Capability**
5. Ajouter **Associated Domains**
6. Ajouter les domaines:
   ```
   applinks:hivmeet.page.link
   applinks:go.hivmeet.com
   ```

### Apple App Site Association (AASA)

Firebase génère automatiquement le fichier AASA. Vérifier qu'il est accessible:

```
https://hivmeet.page.link/.well-known/apple-app-site-association
```

Pour domaine personnalisé, créez:
```
https://go.hivmeet.com/.well-known/apple-app-site-association
```

**Contenu AASA**:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.hivmeet.app",
        "paths": ["*"]
      }
    ]
  }
}
```

**Obtenir Team ID**: Xcode → Project → Signing → Team (10 caractères alphanumériques)

---

## 5️⃣ IMPLÉMENTATION FLUTTER

### pubspec.yaml

Ajoutez la dépendance:

```yaml
dependencies:
  firebase_dynamic_links: ^5.4.0
```

Puis:
```bash
flutter pub get
```

### Créer DynamicLinksService

**Fichier**: `lib/core/services/dynamic_links_service.dart`

```dart
import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';

class DynamicLinksService {
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;

  // Stream des liens reçus (pour écoute dans l'app)
  final _linkStreamController = StreamController<Uri>.broadcast();
  Stream<Uri> get linkStream => _linkStreamController.stream;

  /// Initialiser le service au démarrage de l'app
  Future<void> initialize() async {
    // 1. Récupérer le lien initial (si app ouverte via un lien)
    final PendingDynamicLinkData? initialLink =
        await _dynamicLinks.getInitialLink();

    if (initialLink != null) {
      _handleDeepLink(initialLink.link);
    }

    // 2. Écouter les liens pendant que l'app est ouverte
    _dynamicLinks.onLink.listen(
      (PendingDynamicLinkData dynamicLinkData) {
        _handleDeepLink(dynamicLinkData.link);
      },
      onError: (error) {
        debugPrint('Erreur Dynamic Link: $error');
      },
    );
  }

  /// Gère la navigation selon le deep link
  void _handleDeepLink(Uri deepLink) {
    debugPrint('Deep Link reçu: $deepLink');

    // Broadcaster le lien pour que l'app le gère
    _linkStreamController.add(deepLink);
  }

  /// Créer un lien court pour partager un profil
  Future<Uri> createProfileLink(String userId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://hivmeet.page.link',
      link: Uri.parse('https://hivmeet.com/profile?userId=$userId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.hivmeet.app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.hivmeet.app',
        minimumVersion: '1.0.0',
        appStoreId: '123456789', // TODO: Remplacer par vrai App Store ID
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Voir ce profil sur HIVMeet',
        description: 'Rejoignez-moi sur HIVMeet!',
        imageUrl: Uri.parse('https://hivmeet.com/og-image.png'),
      ),
    );

    final ShortDynamicLink shortLink =
        await _dynamicLinks.buildShortLink(parameters);

    return shortLink.shortUrl;
  }

  /// Créer un lien pour un match
  Future<Uri> createMatchLink(String matchId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://hivmeet.page.link',
      link: Uri.parse('https://hivmeet.com/match?matchId=$matchId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.hivmeet.app',
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.hivmeet.app',
        appStoreId: '123456789',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Vous avez un nouveau match!',
        description: 'Ouvrez HIVMeet pour voir votre match',
      ),
    );

    final ShortDynamicLink shortLink =
        await _dynamicLinks.buildShortLink(parameters);

    return shortLink.shortUrl;
  }

  /// Créer un lien de parrainage
  Future<Uri> createReferralLink(String referrerId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://hivmeet.page.link',
      link: Uri.parse('https://hivmeet.com/invite?ref=$referrerId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.hivmeet.app',
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.hivmeet.app',
        appStoreId: '123456789',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Rejoignez HIVMeet',
        description: 'Votre ami vous invite à rejoindre HIVMeet',
      ),
      // Analytics
      googleAnalyticsParameters: const GoogleAnalyticsParameters(
        campaign: 'referral',
        medium: 'social',
        source: 'app',
      ),
    );

    final ShortDynamicLink shortLink =
        await _dynamicLinks.buildShortLink(parameters);

    return shortLink.shortUrl;
  }

  /// Nettoyer les ressources
  void dispose() {
    _linkStreamController.close();
  }
}
```

### Enregistrer dans injection.dart

Ajoutez dans `lib/injection.dart`:

```dart
import 'package:hivmeet/core/services/dynamic_links_service.dart';

Future<void> configureDependencies() async {
  // ... autres services

  // Dynamic Links Service
  getIt.registerSingleton<DynamicLinksService>(DynamicLinksService());

  // Initialiser au démarrage
  await getIt<DynamicLinksService>().initialize();
}
```

### Gérer la navigation dans main.dart

**Fichier**: `lib/main.dart`

```dart
import 'package:hivmeet/core/services/dynamic_links_service.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DynamicLinksService _dynamicLinksService;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _dynamicLinksService = getIt<DynamicLinksService>();

    // Écouter les deep links
    _linkSubscription = _dynamicLinksService.linkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path;
    final params = uri.queryParameters;

    // Routing selon le type de lien
    if (path.contains('/profile')) {
      final userId = params['userId'];
      if (userId != null) {
        // Navigation vers profil
        context.go('/profile/$userId');
      }
    } else if (path.contains('/match')) {
      final matchId = params['matchId'];
      if (matchId != null) {
        // Navigation vers match
        context.go('/matches/$matchId');
      }
    } else if (path.contains('/invite')) {
      final referrerId = params['ref'];
      if (referrerId != null) {
        // Enregistrer le referrer pour attribution
        // TODO: Envoyer au backend pour attribution
        context.go('/signup?ref=$referrerId');
      }
    } else if (path.contains('/resource')) {
      final resourceId = params['resourceId'];
      if (resourceId != null) {
        context.go('/resources/$resourceId');
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      // ...
    );
  }
}
```

---

## 6️⃣ TYPES DE LIENS HIVMEET

### 1. Lien de profil

**Format**: `https://hivmeet.page.link/profile?userId=abc123`

**Usage**:
```dart
final DynamicLinksService service = getIt<DynamicLinksService>();
final Uri link = await service.createProfileLink('user123');
// Partager ce lien via Share
```

**Navigation**:
```dart
// Ouvre le profil directement
context.go('/profile/user123');
```

### 2. Lien de match

**Format**: `https://hivmeet.page.link/match?matchId=match456`

**Usage**: Envoyé par notification push quand nouveau match

**Navigation**:
```dart
// Ouvre la conversation du match
context.go('/matches/match456');
```

### 3. Lien de ressource

**Format**: `https://hivmeet.page.link/resource?resourceId=article789`

**Usage**: Partage d'articles, guides santé

**Navigation**:
```dart
// Ouvre l'article
context.go('/resources/article789');
```

### 4. Lien de parrainage

**Format**: `https://hivmeet.page.link/invite?ref=user123`

**Usage**: Programme de parrainage, attribution de nouveaux users

**Backend attribution**:
```dart
// Enregistrer le referrer
await apiClient.post('/referrals', {
  'referrerId': 'user123',
  'newUserId': currentUserId,
});
```

---

## 7️⃣ TESTS ET VALIDATION

### Test 1: App installée

1. **Générer un lien** depuis l'app ou Firebase Console
2. **Envoyer le lien** (email, SMS, WhatsApp)
3. **Cliquer sur le lien** depuis un device avec l'app installée
4. **Vérifier**: L'app s'ouvre et navigue correctement

### Test 2: App non installée

1. **Générer un lien**
2. **Cliquer depuis un device sans l'app**
3. **Vérifier**: Redirige vers App Store/Google Play
4. **Installer l'app**
5. **Ouvrir l'app**
6. **Vérifier**: La navigation se fait vers la bonne page (attribution)

### Test 3: Partage social

1. **Partager un lien** sur Facebook/Twitter
2. **Vérifier**: Preview card affiche titre, description, image (socialMetaTagParameters)

### Test 4: Analytics

Firebase Console → Dynamic Links → Analytics:
- Clics totaux
- Conversions (installations)
- Sources (d'où viennent les clics)

### Commandes de test

**Android - ADB**:
```bash
# Simuler un deep link
adb shell am start -a android.intent.action.VIEW \
  -d "https://hivmeet.page.link/profile?userId=test123" \
  com.hivmeet.app
```

**iOS - xcrun**:
```bash
# Simuler un deep link
xcrun simctl openurl booted "https://hivmeet.page.link/profile?userId=test123"
```

---

## 8️⃣ GÉNÉRATION DE LIENS DEPUIS L'APP

### Bouton "Partager mon profil"

**UI**: `lib/presentation/pages/profile/profile_detail_page.dart`

```dart
import 'package:share_plus/share_plus.dart';
import 'package:hivmeet/core/services/dynamic_links_service.dart';

class ProfileDetailPage extends StatelessWidget {
  final DynamicLinksService _dynamicLinksService = getIt<DynamicLinksService>();

  Future<void> _shareProfile(String userId) async {
    // Afficher loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Générer le lien
      final Uri link = await _dynamicLinksService.createProfileLink(userId);

      // Fermer loading
      Navigator.pop(context);

      // Partager
      await Share.share(
        'Découvrez mon profil sur HIVMeet: ${link.toString()}',
        subject: 'Mon profil HIVMeet',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProfile(currentUserId),
          ),
        ],
      ),
      // ...
    );
  }
}
```

### Installer share_plus

```yaml
dependencies:
  share_plus: ^7.2.1
```

---

## 9️⃣ BACKEND - GÉNÉRATION SERVEUR

### Node.js + firebase-admin

**Installer**:
```bash
npm install firebase-admin
```

**Code**:
```javascript
const admin = require('firebase-admin');
admin.initializeApp();

async function createMatchNotificationLink(matchId) {
  const link = await admin.dynamicLinks().createShortLink({
    dynamicLinkInfo: {
      domainUriPrefix: 'https://hivmeet.page.link',
      link: `https://hivmeet.com/match?matchId=${matchId}`,
      androidInfo: {
        androidPackageName: 'com.hivmeet.app',
      },
      iosInfo: {
        iosBundleId: 'com.hivmeet.app',
        iosAppStoreId: '123456789',
      },
      socialMetaTagInfo: {
        socialTitle: 'Nouveau match!',
        socialDescription: 'Vous avez un nouveau match sur HIVMeet',
        socialImageLink: 'https://hivmeet.com/match-notification.png',
      },
    },
  });

  return link.shortLink;
}

// Usage: Envoyer dans notification push
async function sendMatchNotification(userId, matchId) {
  const link = await createMatchNotificationLink(matchId);

  await admin.messaging().send({
    token: userDeviceToken,
    notification: {
      title: 'Nouveau match!',
      body: 'Vous avez un nouveau match',
    },
    data: {
      type: 'match',
      matchId: matchId,
      deepLink: link, // Lien pour ouvrir dans l'app
    },
  });
}
```

---

## 🔟 DÉPANNAGE

### Problème: Lien n'ouvre pas l'app

**Android**:
1. Vérifier `AndroidManifest.xml` → intent-filter correct
2. Vérifier `assetlinks.json` accessible à `https://domaine/.well-known/assetlinks.json`
3. Vérifier SHA-256 correspond au keystore utilisé
4. Commande de test:
   ```bash
   adb shell pm get-app-links com.hivmeet.app
   ```

**iOS**:
1. Vérifier Associated Domains dans Xcode
2. Vérifier `apple-app-site-association` accessible
3. Vérifier Team ID correct
4. Tester sur device réel (simulateur parfois ne marche pas)

### Problème: Attribution ne fonctionne pas

**Cause**: Lien cliqué mais app ne reçoit pas les params

**Solution**:
1. Vérifier `getInitialLink()` appelé dans `initialize()`
2. Vérifier listener `onLink` activé
3. Logs dans `_handleDeepLink()` pour debug

### Problème: Preview social ne s'affiche pas

**Cause**: `socialMetaTagParameters` mal configuré

**Solution**:
1. Vérifier URL image accessible publiquement
2. Taille image: minimum 200x200px, recommandé 1200x630px
3. Tester avec Facebook Debugger: https://developers.facebook.com/tools/debug/

### Problème: Lien trop long

**Cause**: `buildLink()` au lieu de `buildShortLink()`

**Solution**:
```dart
// ❌ Long
final Uri longLink = await parameters.buildLink();

// ✅ Court
final ShortDynamicLink shortLink = await _dynamicLinks.buildShortLink(parameters);
final Uri shortUrl = shortLink.shortUrl;
```

### Vérifier configuration

**Test URL**:
```
https://hivmeet.page.link?link=https://hivmeet.com/test&apn=com.hivmeet.app&ibi=com.hivmeet.app
```

Cliquer depuis un device → doit ouvrir l'app

---

## ✅ CHECKLIST FINALE

### Configuration Firebase
- [ ] Dynamic Links activé dans Firebase Console
- [ ] Domaine configuré (page.link ou custom)
- [ ] Prefix URL défini

### Android
- [ ] `firebase-dynamic-links-ktx` dans build.gradle
- [ ] Intent filters ajoutés dans AndroidManifest.xml
- [ ] `assetlinks.json` hébergé et accessible
- [ ] SHA-256 correct

### iOS
- [ ] Associated Domains ajoutés dans Xcode
- [ ] CFBundleURLSchemes dans Info.plist
- [ ] `apple-app-site-association` accessible
- [ ] Team ID correct

### Flutter
- [ ] `firebase_dynamic_links` installé
- [ ] `DynamicLinksService` créé
- [ ] Service initialisé dans injection.dart
- [ ] Navigation gérée dans main.dart
- [ ] `share_plus` installé pour partages

### Tests
- [ ] Test avec app installée (navigation directe)
- [ ] Test avec app non installée (install puis navigation)
- [ ] Test preview social (Facebook, Twitter)
- [ ] Test analytics dans Firebase Console

### Backend (optionnel)
- [ ] Génération serveur implémentée (Node.js)
- [ ] Attribution de referrals trackée
- [ ] Liens dans notifications push

---

## 📚 RESSOURCES

- [Firebase Dynamic Links Docs](https://firebase.google.com/docs/dynamic-links)
- [Flutter Package](https://pub.dev/packages/firebase_dynamic_links)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)

---

**Fin du guide Firebase Dynamic Links**

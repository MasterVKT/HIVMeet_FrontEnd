# 🔧 Correction des Endpoints Frontend - HIVMeet

## 📋 Vue d'Ensemble

Ce document identifie tous les endpoints incorrects utilisés dans le frontend Flutter et propose les corrections nécessaires pour les aligner avec la documentation complète du backend Django.

## ❌ Endpoints Incorrects Identifiés

### 1. **Authentification - Refresh Token**

**❌ Endpoint incorrect utilisé :**
```dart
// lib/core/services/token_manager.dart:297
'auth/refresh/'

// lib/core/network/api_client.dart:59
'auth/refresh/'

// lib/data/datasources/remote/auth_api.dart:500
'/auth/refresh'
```

**✅ Endpoint correct selon la documentation :**
```
POST /api/v1/auth/refresh-token
```

**📝 Correction nécessaire :**
- Remplacer `auth/refresh/` par `auth/refresh-token/`
- Mettre à jour tous les fichiers concernés

---

### 2. **Authentification - Firebase Exchange**

**❌ Endpoint incorrect utilisé :**
```dart
// lib/data/datasources/remote/auth_api.dart:488
'/auth/firebase-exchange'

// lib/core/network/api_client.dart:56
'auth/firebase-exchange/'
```

**✅ Endpoint correct selon la documentation :**
```
POST /api/v1/auth/firebase-exchange/
```

**📝 Correction nécessaire :**
- Ajouter le slash final : `auth/firebase-exchange/`
- Vérifier la cohérence dans tous les fichiers

---

### 3. **Profils Utilisateurs - Endpoints Manquants**

**❌ Endpoints incorrects utilisés :**
```dart
// lib/data/datasources/remote/profile_api.dart
'/profiles/me'           // ❌ Incorrect
'/profiles/{id}'         // ❌ Incorrect
'/profiles/me/photos'    // ❌ Incorrect
'/verification/submit'   // ❌ Incorrect
'/verification/status'   // ❌ Incorrect
```

**✅ Endpoints corrects selon la documentation :**
```
GET    /api/v1/user-profiles/me/
PUT    /api/v1/user-profiles/me/
GET    /api/v1/user-profiles/{user_id}/
POST   /api/v1/user-profiles/me/photos/
DELETE /api/v1/user-profiles/me/photos/{photo_id}/
GET    /api/v1/user-profiles/me/verification/
POST   /api/v1/user-profiles/me/verification/submit-documents/
```

**📝 Correction nécessaire :**
- Remplacer `/profiles/` par `/user-profiles/`
- Ajouter les chemins complets avec `/api/v1/`
- Corriger les endpoints de vérification

---

### 4. **Découverte et Matching - Endpoints Incorrects**

**❌ Endpoints incorrects utilisés :**
```dart
// lib/data/datasources/remote/matching_api.dart
'/discovery/'                    // ❌ Incorrect
'/discovery/filters'             // ❌ Incorrect
'/matches/'                      // ❌ Incorrect
'/matches/super-like'            // ❌ Incorrect
'/matches/rewind'                // ❌ Incorrect
'/matches/who-liked-me'          // ❌ Incorrect
'/likes/dislike'                 // ❌ Incorrect
```

**✅ Endpoints corrects selon la documentation :**
```
GET    /api/v1/discovery/profiles
POST   /api/v1/discovery/interactions/like
POST   /api/v1/discovery/interactions/dislike
POST   /api/v1/discovery/interactions/superlike
POST   /api/v1/discovery/interactions/rewind
GET    /api/v1/discovery/interactions/liked-me
POST   /api/v1/discovery/boost/activate
GET    /api/v1/matches/
DELETE /api/v1/matches/{match_id}
```

**📝 Correction nécessaire :**
- Restructurer complètement les endpoints de découverte
- Utiliser la structure `/discovery/interactions/` pour les actions
- Corriger les endpoints de matching

---

### 5. **Messagerie - Endpoints Incorrects**

**❌ Endpoints incorrects utilisés :**
```dart
// lib/data/datasources/remote/messaging_api.dart
'/conversations/'                                    // ❌ Incorrect
'/conversations/{conversation_id}/messages'          // ❌ Incorrect
'/conversations/{conversation_id}/messages'          // ❌ Incorrect
'/conversations/{conversation_id}/messages/media'    // ❌ Incorrect
'/conversations/{conversation_id}/messages/read'     // ❌ Incorrect
```

**✅ Endpoints corrects selon la documentation :**
```
GET    /api/v1/conversations/
GET    /api/v1/conversations/{conversation_id}/messages/
POST   /api/v1/conversations/{conversation_id}/messages/
POST   /api/v1/conversations/{conversation_id}/messages/media/
PUT    /api/v1/conversations/{conversation_id}/messages/mark-as-read/
DELETE /api/v1/conversations/{conversation_id}/messages/{message_id}/
```

**📝 Correction nécessaire :**
- Ajouter le préfixe `/api/v1/`
- Corriger l'endpoint de marquage comme lu

---

### 6. **Ressources - Endpoints Incorrects**

**❌ Endpoints incorrects utilisés :**
```dart
// lib/data/datasources/remote/resources_api.dart
'/resources'                     // ❌ Incorrect
'/resources/categories'          // ❌ Incorrect
'/resources/{id}'                // ❌ Incorrect
'/resources/favorites'           // ❌ Incorrect
```

**✅ Endpoints corrects selon la documentation :**
```
GET    /api/v1/content/resource-categories
GET    /api/v1/content/resources
GET    /api/v1/content/resources/{resource_id}
POST   /api/v1/content/resources/{resource_id}/favorite
GET    /api/v1/content/favorites
```

**📝 Correction nécessaire :**
- Remplacer `/resources/` par `/content/resources/`
- Ajouter le préfixe `/api/v1/`
- Corriger les endpoints de catégories

---

### 7. **Abonnements Premium - Endpoints Incorrects**

**❌ Endpoints incorrects utilisés :**
```dart
// lib/data/datasources/remote/subscriptions_api.dart
'/subscriptions/plans'           // ❌ Incorrect
'/subscriptions/current'         // ❌ Incorrect
'/subscriptions'                 // ❌ Incorrect
'/subscriptions/boost'           // ❌ Incorrect
'/subscriptions/super-like'      // ❌ Incorrect
```

**✅ Endpoints corrects selon la documentation :**
```
GET    /api/v1/subscriptions/plans/
GET    /api/v1/subscriptions/current/
POST   /api/v1/subscriptions/purchase/
POST   /api/v1/subscriptions/current/cancel/
POST   /api/v1/subscriptions/current/reactivate/
```

**📝 Correction nécessaire :**
- Ajouter le préfixe `/api/v1/`
- Corriger les endpoints de boost et super-like
- Utiliser les endpoints corrects pour les abonnements

---

## 🔧 Plan de Correction Détaillé

### Phase 1 : Configuration Centrale

**Fichier :** `lib/core/config/app_config.dart`

```dart
// ✅ NOUVELLE CONFIGURATION CORRIGÉE
class AppConfig {
  // Authentification
  static const String authBase = '/auth';
  static String get firebaseExchange => '$authBase/firebase-exchange/';
  static String get login => '$authBase/login/';
  static String get register => '$authBase/register/';
  static String get refreshToken => '$authBase/refresh-token/'; // ✅ CORRIGÉ

  // Profils Utilisateurs
  static const String userProfilesBase = '/user-profiles';
  static String get userProfile => '$userProfilesBase/me/';
  static String get userProfileById => '$userProfilesBase/{id}/';
  static String get userPhotos => '$userProfilesBase/me/photos/';
  static String get userVerification => '$userProfilesBase/me/verification/';

  // Découverte
  static const String discoveryBase = '/discovery';
  static String get discoveryProfiles => '$discoveryBase/profiles';
  static String get discoveryInteractions => '$discoveryBase/interactions';
  static String get discoveryBoost => '$discoveryBase/boost/activate';

  // Matching
  static String get matches => '/matches/';

  // Messagerie
  static const String conversationsBase = '/conversations';
  static String get conversations => '$conversationsBase/';
  static String get conversationMessages => '$conversationsBase/{id}/messages/';

  // Ressources
  static const String contentBase = '/content';
  static String get resources => '$contentBase/resources';
  static String get resourceCategories => '$contentBase/resource-categories';

  // Abonnements
  static const String subscriptionsBase = '/subscriptions';
  static String get subscriptionPlans => '$subscriptionsBase/plans/';
  static String get currentSubscription => '$subscriptionsBase/current/';
}
```

### Phase 2 : Correction des APIs

**Fichier :** `lib/data/datasources/remote/auth_api.dart`

```dart
// ✅ CORRECTION
Future<Response<Map<String, dynamic>>> refreshToken({
  required String refreshToken,
}) async {
  final data = {
    'refresh_token': refreshToken,
  };

  // ✅ CORRIGÉ : Utiliser le bon endpoint
  return await _apiClient.post('/auth/refresh-token/', data: data);
}
```

**Fichier :** `lib/data/datasources/remote/profile_api.dart`

```dart
// ✅ CORRECTION
Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
  // ✅ CORRIGÉ : Utiliser le bon endpoint
  return await _apiClient.get('/user-profiles/$profileId/');
}

Future<Response<Map<String, dynamic>>> updateProfile({
  required Map<String, dynamic> profileData,
}) async {
  // ✅ CORRIGÉ : Utiliser le bon endpoint
  return await _apiClient.put('/user-profiles/me/', data: profileData);
}
```

### Phase 3 : Correction des Services

**Fichier :** `lib/core/services/token_manager.dart`

```dart
// ✅ CORRECTION
final response = await _apiClient.post(
  'auth/refresh-token/', // ✅ CORRIGÉ
  data: {'refresh': refreshToken},
);
```

**Fichier :** `lib/core/network/api_client.dart`

```dart
// ✅ CORRECTION
static const List<String> _excludedEndpoints = [
  'auth/firebase-exchange/', // ✅ CORRIGÉ
  'auth/refresh-token/',     // ✅ CORRIGÉ
  'auth/login/',
  'auth/register/',
];
```

## 📊 Résumé des Corrections

| Module | Endpoints Incorrects | Endpoints Corrects | Fichiers à Modifier |
|--------|---------------------|-------------------|-------------------|
| **Auth** | 2 | 2 | 4 fichiers |
| **Profiles** | 8 | 8 | 3 fichiers |
| **Discovery** | 7 | 7 | 2 fichiers |
| **Messaging** | 5 | 5 | 2 fichiers |
| **Resources** | 4 | 4 | 1 fichier |
| **Subscriptions** | 5 | 5 | 1 fichier |
| **Total** | **31** | **31** | **13 fichiers** |

## 🚀 Instructions de Mise en Œuvre

### 1. **Sauvegarde**
```bash
git add .
git commit -m "Sauvegarde avant correction des endpoints"
git branch backup-endpoints
```

### 2. **Correction Progressive**
1. Commencer par `app_config.dart`
2. Corriger `auth_api.dart`
3. Corriger `profile_api.dart`
4. Corriger `matching_api.dart`
5. Corriger `messaging_api.dart`
6. Corriger `resources_api.dart`
7. Corriger `subscriptions_api.dart`

### 3. **Tests**
```bash
flutter test
flutter run --debug
```

### 4. **Validation**
- Vérifier que tous les endpoints correspondent à la documentation
- Tester chaque fonctionnalité
- Valider les réponses du backend

## ⚠️ Points d'Attention

1. **Cohérence** : S'assurer que tous les endpoints utilisent le même format
2. **Versioning** : Tous les endpoints doivent inclure `/api/v1/`
3. **Slash final** : Respecter la convention avec ou sans slash final
4. **Paramètres** : Vérifier que les paramètres correspondent à la documentation
5. **Réponses** : Adapter le parsing des réponses si nécessaire

## 📝 Notes Importantes

- **Backend requis** : Ces corrections supposent que le backend Django implémente tous les endpoints documentés
- **Tests** : Effectuer des tests complets après chaque correction
- **Documentation** : Mettre à jour la documentation frontend si nécessaire
- **Migration** : Prévoir une période de transition si le backend n'est pas encore prêt

---

*Document généré le : 2024-12-19*
*Version : 1.0*
*Statut : À implémenter* 
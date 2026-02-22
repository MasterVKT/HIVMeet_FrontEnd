# Guide de Bascule vers l'API Réelle - Historique d'Interactions

## 📋 Vue d'ensemble

Le frontend de l'historique d'interactions a été développé avec **deux implémentations** :
1. **Mock Repository** : Données fictives pour le développement (actuellement actif)
2. **API Repository** : Connexion au backend Django (prêt à être activé)

Ce guide explique comment basculer du mode mock vers l'API réelle.

---

## 🔄 Activation de l'API Réelle

### Étape 1 : Vérifier que le Backend est Disponible

Assurez-vous que le backend Django est démarré et accessible :

```bash
# Vérifier le backend
curl http://localhost:8000/api/v1/discovery/interactions/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse attendue** : Status 200 avec les statistiques

### Étape 2 : Modifier le Fichier d'Injection

Ouvrir [`lib/injection.dart`](../lib/injection.dart) et localiser la section **"13. Interaction History Repository"** (environ ligne 375).

**Configuration actuelle (MOCK)** :
```dart
// 13. Interaction History Repository
// TOGGLE: Décommenter la ligne suivante pour utiliser l'API réelle
// getIt.registerLazySingleton<InteractionHistoryRepository>(
//   () => InteractionHistoryRepositoryImpl(getIt<Dio>()),
// );

// MOCK: Commenter cette ligne une fois le backend prêt
getIt.registerLazySingleton<InteractionHistoryRepository>(
  () => InteractionHistoryRepositoryMock(),
);
```

**Configuration pour API RÉELLE** :
```dart
// 13. Interaction History Repository
// TOGGLE: API réelle activée
getIt.registerLazySingleton<InteractionHistoryRepository>(
  () => InteractionHistoryRepositoryImpl(getIt<Dio>()),
);

// MOCK: Désactivé - Backend prêt
// getIt.registerLazySingleton<InteractionHistoryRepository>(
//   () => InteractionHistoryRepositoryMock(),
// );
```

### Étape 3 : Hot Restart de l'Application

⚠️ **Important** : Un simple Hot Reload ne suffit pas !

```bash
# Dans le terminal Flutter
flutter run

# OU dans la console Flutter DevTools
R  (Shift + R pour Hot Restart)
```

### Étape 4 : Vérification

Après le restart, tester les fonctionnalités :

✅ **Mes Likes** : Les profils likés proviennent du backend
✅ **Mes Passes** : Les profils passés proviennent du backend  
✅ **Révocation** : L'annulation d'une interaction appelle l'API
✅ **Statistiques** : Les chiffres reflètent les vraies données

**Logs attendus** dans la console :
```
I/flutter: 🔄 DEBUG InteractionHistoryRepositoryImpl: Fetching likes from API
I/flutter: ✅ DEBUG InteractionHistoryRepositoryImpl: Received 12 likes
```

---

## 🔍 Différences entre Mock et API

### Mock Repository
- ✅ **Avantages** :
  - Fonctionne sans backend
  - Données prédictibles (40 profils générés)
  - Pas de latence réseau
  - Idéal pour le développement UI

- ❌ **Limitations** :
  - Données en mémoire (perdues au restart)
  - Pas de synchronisation avec le backend
  - Ne reflète pas les vraies interactions

### API Repository
- ✅ **Avantages** :
  - Données réelles persistantes
  - Synchronisé avec le backend
  - Reflète les vraies interactions utilisateur
  - Partage les données entre appareils

- ⚠️ **Prérequis** :
  - Backend Django démarré
  - Authentification Firebase valide
  - Connexion réseau stable

---

## 🐛 Dépannage

### Erreur 401 : Non authentifié
```
ServerFailure: Non authentifié
```

**Cause** : Token Firebase expiré ou invalide

**Solution** :
1. Se déconnecter de l'app
2. Se reconnecter
3. Le token sera rafraîchi automatiquement

### Erreur 500 : Erreur serveur
```
ServerFailure: Erreur serveur
```

**Cause** : Problème côté backend Django

**Solution** :
1. Vérifier les logs backend : `python manage.py runserver`
2. Vérifier que la migration est appliquée : `python manage.py migrate`
3. Vérifier les données de test : `python manage.py shell`

### Pas de données retournées
```
Liste vide alors que des interactions existent
```

**Cause** : Filtrage ou pagination incorrecte

**Solution** :
1. Vérifier les paramètres de requête dans les logs
2. Tester l'endpoint directement avec curl/Postman
3. Vérifier la base de données Django

### Timeout / Connexion impossible
```
ServerFailure: Erreur de connexion. Vérifiez votre connexion Internet.
```

**Cause** : Backend inaccessible ou URL incorrecte

**Solution** :
1. Vérifier que le backend tourne : `http://localhost:8000/admin`
2. Vérifier l'URL de base dans `.env` :
   ```
   API_BASE_URL=http://10.0.2.2:8000  # Pour émulateur Android
   API_BASE_URL=http://localhost:8000  # Pour iOS Simulator
   ```
3. Sur appareil physique, utiliser l'IP locale de votre machine

---

## 📊 Mapping des Données

### Champs Backend → Frontend

Le repository implémente un mapping automatique :

| Backend (API) | Frontend (Entity) |
|---------------|-------------------|
| `id` | `id` |
| `interaction_type` ("like", "super_like", "dislike") | `type` (enum InteractionType) |
| `profile.user_id` | `profile.id` |
| `profile.username` | `profile.displayName` |
| `profile.profile_photo` | `profile.mainPhotoUrl` |
| `is_match` | `isMatched` |
| `created_at` | `timestamp` |
| `is_revoked` | Inversé → `canRevoke` |

### Champs Manquants

Certains champs ne sont pas retournés par le backend dans la liste :
- `profile.otherPhotosUrls` → Défini à `[]`
- `profile.distance` → Défini à `null`
- `profile.country` → Défini à `'France'`
- `profile.interests` → Défini à `[]`
- `profile.compatibilityScore` → Défini à `0`

**Note** : Ces champs sont disponibles dans l'endpoint de détail du profil.

---

## 🔧 Configuration Dio

L'implémentation utilise l'instance Dio déjà configurée dans l'app :

```dart
// Base URL définie dans api_client.dart
baseUrl = 'http://10.0.2.2:8000'  // Android Emulator
baseUrl = 'http://localhost:8000'  // iOS Simulator

// Endpoints interaction history
/api/v1/discovery/interactions/my-likes
/api/v1/discovery/interactions/my-passes
/api/v1/discovery/interactions/{id}/revoke
/api/v1/discovery/interactions/stats
```

**Intercepteurs actifs** :
- Token d'authentification Firebase
- Gestion des erreurs (401, 403, 404, 500)
- Logging des requêtes (debug mode)

---

## 📈 Tests de Validation

### Test Manuel Complet

1. **Lancer le backend** :
   ```bash
   cd hivmeet_backend
   python manage.py runserver
   ```

2. **Activer l'API** dans `injection.dart` (voir Étape 2)

3. **Redémarrer l'app** (Hot Restart)

4. **Test Sequence** :
   - ✅ Aller dans Matches → Icône historique
   - ✅ Ouvrir "Mes Likes" → Vérifier que des profils s'affichent
   - ✅ Cliquer sur un profil → Détail s'ouvre
   - ✅ Annuler un like → Profil disparaît de la liste
   - ✅ Ouvrir "Mes Passes" → Vérifier les passes
   - ✅ Annuler un pass → Profil disparaît
   - ✅ Ouvrir "Statistiques" → Chiffres cohérents

### Test avec curl

Tester directement l'API backend :

```bash
# Obtenir un token Firebase (depuis l'app ou Firebase Console)
export TOKEN="eyJhbGc..."

# Test des likes
curl http://localhost:8000/api/v1/discovery/interactions/my-likes \
  -H "Authorization: Bearer $TOKEN"

# Test des statistiques
curl http://localhost:8000/api/v1/discovery/interactions/stats \
  -H "Authorization: Bearer $TOKEN"

# Test de révocation
curl -X POST http://localhost:8000/api/v1/discovery/interactions/<interaction_id>/revoke \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔄 Retour au Mode Mock

Si vous devez revenir au mock (ex: backend en maintenance) :

1. **Réactiver le mock** dans `injection.dart` :
   ```dart
   // Commenter l'API réelle
   // getIt.registerLazySingleton<InteractionHistoryRepository>(
   //   () => InteractionHistoryRepositoryImpl(getIt<Dio>()),
   // );
   
   // Décommenter le mock
   getIt.registerLazySingleton<InteractionHistoryRepository>(
     () => InteractionHistoryRepositoryMock(),
   );
   ```

2. **Hot Restart** l'application

3. ✅ Le mock est réactivé avec les 40 profils de test

---

## 📝 Checklist de Déploiement

Avant de déployer en production avec l'API réelle :

- [ ] Backend déployé et accessible
- [ ] Endpoints testés avec Postman/curl
- [ ] Base de données migrée (`python manage.py migrate`)
- [ ] Authentification Firebase configurée
- [ ] Variables d'environnement correctes (`.env`)
- [ ] Tests manuels effectués sur appareil physique
- [ ] Gestion d'erreurs testée (401, 404, 500)
- [ ] Latence réseau acceptable (< 2s)
- [ ] Logs de debugging désactivés en production

---

## 📚 Références

- **API Documentation** : [`INTERACTION_HISTORY_API_DOCUMENTATION.md`](../guides/INTERACTION_HISTORY_API_DOCUMENTATION.md)
- **Backend Spec** : [`BACKEND_ACTIONS_REQUISES_INTERACTION_HISTORY.md`](../docs/BACKEND_ACTIONS_REQUISES_INTERACTION_HISTORY.md)
- **Repository Implementation** : [`interaction_history_repository_impl.dart`](../lib/data/repositories/interaction_history_repository_impl.dart)
- **Dependency Injection** : [`injection.dart`](../lib/injection.dart)

---

**Document créé le** : 29 décembre 2025  
**Dernière mise à jour** : 29 décembre 2025  
**Version** : 1.0

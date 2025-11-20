# 🔧 Corrections Module Matching et Discovery - HIVMeet

## 📋 Analyse des Endpoints Incorrects

### ❌ **Endpoints Incorrects Identifiés**

| Endpoint Frontend | Endpoint Backend Correct | Problème | Fichier |
|-------------------|-------------------------|----------|---------|
| `/discovery/` | `/api/v1/discovery/profiles` | Mauvais préfixe et endpoint | matching_api.dart:15 |
| `/discovery/filters` | `/api/v1/user-profiles/me/` | Endpoint inexistant, utiliser PUT /me/ | matching_api.dart:35, 150, 160 |
| `/matches/` | `/api/v1/discovery/interactions/like` | Mauvais endpoint | matching_api.dart:55 |
| `/matches/` | `/api/v1/matches/` | Mauvais préfixe | matching_api.dart:70 |
| `/matches/super-like` | `/api/v1/discovery/interactions/superlike` | Mauvais endpoint | matching_api.dart:85 |
| `/matches/rewind` | `/api/v1/discovery/interactions/rewind` | Mauvais endpoint | matching_api.dart:95 |
| `/matches/who-liked-me` | `/api/v1/discovery/interactions/liked-me` | Mauvais endpoint | matching_api.dart:105 |
| `/likes/dislike` | `/api/v1/discovery/interactions/dislike` | Mauvais endpoint | matching_api.dart:120 |
| `/likes/received` | `/api/v1/user-profiles/likes-received/` | Mauvais endpoint | matching_api.dart:135 |
| `/likes/received/count` | `/api/v1/user-profiles/likes-received/` | Endpoint inexistant | matching_api.dart:145 |
| `/matches/boost/status` | `/api/v1/user-profiles/premium-status/` | Mauvais endpoint | matching_api.dart:155 |
| `/likes/daily-limit` | Endpoint inexistant | Endpoint inexistant | matching_api.dart:170 |
| `/matches/boost` | `/api/v1/discovery/boost/activate` | Mauvais endpoint | matching_api.dart:175 |

### ✅ **Endpoints Corrects Identifiés**

Aucun endpoint correct identifié dans ce module.

---

## 🔧 **Corrections à Implémenter**

### 1. **Correction des Endpoints de Découverte**

```dart
// ❌ Incorrect
return await _apiClient.get('/discovery/', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/discovery/profiles', queryParameters: queryParams);
```

### 2. **Correction des Endpoints d'Interactions**

```dart
// ❌ Incorrect
return await _apiClient.post('/matches/', data: data);

// ✅ Correct
return await _apiClient.post('/api/v1/discovery/interactions/like', data: data);
```

### 3. **Correction des Endpoints de Matches**

```dart
// ❌ Incorrect
return await _apiClient.get('/matches/', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/matches/', queryParameters: queryParams);
```

### 4. **Correction des Endpoints Premium**

```dart
// ❌ Incorrect
return await _apiClient.get('/matches/who-liked-me', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/discovery/interactions/liked-me', queryParameters: queryParams);
```

---

## 📊 **Impact des Corrections**

### **Endpoints à Supprimer (Inexistants dans le Backend)**
- `/discovery/filters` → Utiliser PUT `/api/v1/user-profiles/me/`
- `/likes/received/count` → Utiliser GET `/api/v1/user-profiles/likes-received/`
- `/likes/daily-limit` → Endpoint inexistant
- `/matches/boost/status` → Utiliser GET `/api/v1/user-profiles/premium-status/`

### **Endpoints à Corriger**
- Tous les endpoints de discovery → `/api/v1/discovery/`
- Tous les endpoints de matches → `/api/v1/matches/`
- Tous les endpoints d'interactions → `/api/v1/discovery/interactions/`

---

## 🎯 **Plan d'Implémentation**

1. **Phase 1 : Correction des Endpoints de Découverte** (Priorité Critique)
2. **Phase 2 : Correction des Endpoints d'Interactions** (Priorité Critique)
3. **Phase 3 : Correction des Endpoints de Matches** (Priorité Haute)
4. **Phase 4 : Correction des Endpoints Premium** (Priorité Moyenne)
5. **Phase 5 : Suppression des Endpoints Inexistants** (Priorité Basse)

---

## 📝 **Notes Importantes**

- Les filtres de découverte sont gérés via le profil utilisateur
- Les interactions (like, dislike, superlike) sont dans le module discovery
- Les matches sont un module séparé
- Certains endpoints nécessitent des permissions premium
- Les paramètres de requête doivent correspondre exactement à ceux du backend 
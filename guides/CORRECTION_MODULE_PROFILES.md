# 🔧 Corrections Module Profils Utilisateurs - HIVMeet

## 📋 Analyse des Endpoints Incorrects

### ❌ **Endpoints Incorrects Identifiés**

| Endpoint Frontend | Endpoint Backend Correct | Problème | Fichier |
|-------------------|-------------------------|----------|---------|
| `/profiles/{id}` | `/api/v1/user-profiles/{user_id}/` | Mauvais préfixe et structure | profile_api.dart:13 |
| `/profiles/me` | `/api/v1/user-profiles/me/` | Mauvais préfixe | profile_api.dart:19, 25, 130 |
| `/profiles/me/photos` | `/api/v1/user-profiles/me/photos/` | Mauvais préfixe | profile_api.dart:32 |
| `/profiles/me/photos/{photoId}` | `/api/v1/user-profiles/me/photos/{photo_id}/` | Mauvais préfixe | profile_api.dart:42 |
| `/profiles/me/location` | `/api/v1/user-profiles/me/` | Endpoint inexistant, utiliser PUT /me/ | profile_api.dart:50 |
| `/profiles/me/privacy` | `/api/v1/user-settings/privacy-preferences` | Mauvais module | profile_api.dart:58 |
| `/verification/submit` | `/api/v1/user-profiles/me/verification/submit-documents/` | Mauvais préfixe | profile_api.dart:66 |
| `/verification/status` | `/api/v1/user-profiles/me/verification/` | Mauvais préfixe | profile_api.dart:78 |
| `/discovery/nearby` | `/api/v1/discovery/profiles` | Mauvais endpoint | profile_api.dart:84 |
| `/profiles/{profileId}/report` | `/api/v1/user-profiles/{user_id}/report/` | Mauvais préfixe | profile_api.dart:105 |
| `/profiles/{profileId}/block` | `/api/v1/user-settings/blocks/{user_id}` | Mauvais module | profile_api.dart:118, 125 |
| `/profiles/blocked` | `/api/v1/user-settings/blocks` | Mauvais module | profile_api.dart:132 |
| `/profiles/me/photos/order` | `/api/v1/user-profiles/me/photos/{photo_id}/set-main/` | Endpoint différent | profile_api.dart:140 |
| `/profiles/me/stats` | `/api/v1/user-profiles/me/` | Endpoint inexistant | profile_api.dart:147 |
| `/user-profiles/` | `/api/v1/user-profiles/me/` | Endpoint de création inexistant | profile_api.dart:155 |
| `/user-profiles/{profileId}` | `/api/v1/user-profiles/{user_id}/` | Mauvais préfixe | profile_api.dart:170 |
| `/user-profiles/photos/{photoId}` | `/api/v1/user-profiles/me/photos/{photo_id}/` | Mauvais préfixe | profile_api.dart:180 |
| `/user-profiles/verification/request` | `/api/v1/user-profiles/me/verification/generate-upload-url/` | Endpoint différent | profile_api.dart:190 |
| `/user-profiles/verification/upload` | `/api/v1/user-profiles/me/verification/submit-documents/` | Endpoint différent | profile_api.dart:200 |
| `/user-profiles/search-preferences` | `/api/v1/user-profiles/me/` | Endpoint inexistant | profile_api.dart:215 |
| `/user-profiles/visibility-settings` | `/api/v1/user-settings/privacy-preferences` | Mauvais module | profile_api.dart:230 |
| `/user-profiles/suggestions` | `/api/v1/discovery/profiles` | Endpoint différent | profile_api.dart:245 |
| `/user-profiles/search` | `/api/v1/discovery/profiles` | Endpoint différent | profile_api.dart:255 |
| `/user-profiles/statistics` | `/api/v1/user-profiles/me/` | Endpoint inexistant | profile_api.dart:275 |

### ✅ **Endpoints Corrects Identifiés**

| Endpoint Frontend | Endpoint Backend | Statut | Fichier |
|-------------------|-----------------|--------|---------|
| `/user-profiles/{profileId}` | `/api/v1/user-profiles/{user_id}/` | ✅ Correct | profile_api.dart:170 |

---

## 🔧 **Corrections à Implémenter**

### 1. **Correction des Préfixes d'API**

Tous les endpoints doivent utiliser le préfixe `/api/v1/` :

```dart
// ❌ Incorrect
'/profiles/me'

// ✅ Correct  
'/api/v1/user-profiles/me/'
```

### 2. **Correction des Endpoints de Profils**

```dart
// ❌ Incorrect
Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
  return await _apiClient.get('/profiles/$profileId');
}

// ✅ Correct
Future<Response<Map<String, dynamic>>> getProfile(String profileId) async {
  return await _apiClient.get('/api/v1/user-profiles/$profileId/');
}
```

### 3. **Correction des Endpoints de Photos**

```dart
// ❌ Incorrect
return await _apiClient.post('/profiles/me/photos', data: formData);

// ✅ Correct
return await _apiClient.post('/api/v1/user-profiles/me/photos/', data: formData);
```

### 4. **Correction des Endpoints de Vérification**

```dart
// ❌ Incorrect
return await _apiClient.post('/verification/submit', data: formData);

// ✅ Correct
return await _apiClient.post('/api/v1/user-profiles/me/verification/submit-documents/', data: formData);
```

### 5. **Correction des Endpoints de Découverte**

```dart
// ❌ Incorrect
return await _apiClient.get('/discovery/nearby', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/discovery/profiles', queryParameters: queryParams);
```

### 6. **Correction des Endpoints de Paramètres**

```dart
// ❌ Incorrect
return await _apiClient.put('/profiles/me/privacy', data: settings);

// ✅ Correct
return await _apiClient.put('/api/v1/user-settings/privacy-preferences', data: settings);
```

---

## 📊 **Impact des Corrections**

### **Endpoints à Supprimer (Inexistants dans le Backend)**
- `/profiles/me/location` → Utiliser PUT `/api/v1/user-profiles/me/`
- `/profiles/me/stats` → Utiliser GET `/api/v1/user-profiles/me/`
- `/user-profiles/search-preferences` → Utiliser PUT `/api/v1/user-profiles/me/`
- `/user-profiles/visibility-settings` → Utiliser `/api/v1/user-settings/privacy-preferences`
- `/user-profiles/suggestions` → Utiliser `/api/v1/discovery/profiles`
- `/user-profiles/search` → Utiliser `/api/v1/discovery/profiles`
- `/user-profiles/statistics` → Utiliser GET `/api/v1/user-profiles/me/`

### **Endpoints à Déplacer vers d'Autres Modules**
- Endpoints de blocage → Module `user-settings`
- Endpoints de confidentialité → Module `user-settings`

---

## 🎯 **Plan d'Implémentation**

1. **Phase 1 : Correction des Préfixes** (Priorité Critique)
2. **Phase 2 : Correction des Endpoints de Photos** (Priorité Haute)
3. **Phase 3 : Correction des Endpoints de Vérification** (Priorité Haute)
4. **Phase 4 : Correction des Endpoints de Découverte** (Priorité Moyenne)
5. **Phase 5 : Déplacement des Endpoints de Paramètres** (Priorité Moyenne)
6. **Phase 6 : Suppression des Endpoints Inexistants** (Priorité Basse)

---

## 📝 **Notes Importantes**

- Tous les endpoints doivent se terminer par `/` selon la documentation Django
- Les paramètres de requête doivent correspondre exactement à ceux du backend
- Les formats de données doivent respecter les spécifications du backend
- Certains endpoints nécessitent des permissions premium selon la documentation 
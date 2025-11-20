# 🔧 Corrections Module Messagerie - HIVMeet

## 📋 Analyse des Endpoints Incorrects

### ❌ **Endpoints Incorrects Identifiés**

| Endpoint Frontend | Endpoint Backend Correct | Problème | Fichier |
|-------------------|-------------------------|----------|---------|
| `/conversations/` | `/api/v1/conversations/` | Mauvais préfixe | messaging_api.dart:15 |
| `/conversations/{id}/messages` | `/api/v1/conversations/{id}/messages/` | Mauvais préfixe | messaging_api.dart:30 |
| `/conversations/{id}/messages` | `/api/v1/conversations/{id}/messages/` | Mauvais préfixe | messaging_api.dart:50 |
| `/conversations/{id}/messages` | `/api/v1/conversations/{id}/messages/media/` | Endpoint différent pour média | messaging_api.dart:70 |
| `/conversations/{id}/messages/{id}/read` | `/api/v1/conversations/{id}/messages/mark-as-read/` | Endpoint différent | messaging_api.dart:85 |
| `/calls/` | `/api/v1/calls/initiate` | Endpoint différent | messaging_api.dart:95 |
| `/calls/{id}/answer` | `/api/v1/calls/{id}/answer` | Mauvais préfixe | messaging_api.dart:110 |
| `/calls/{id}/end` | `/api/v1/calls/{id}/terminate` | Endpoint différent | messaging_api.dart:125 |
| `/conversations/{id}/typing` | Endpoint inexistant | Endpoint inexistant | messaging_api.dart:140, 200 |
| `/conversations/{id}/presence` | Endpoint inexistant | Endpoint inexistant | messaging_api.dart:155 |
| `/conversations/{id}` | `/api/v1/conversations/{id}/` | Mauvais préfixe | messaging_api.dart:165 |
| `/conversations/{id}/read` | `/api/v1/conversations/{id}/messages/mark-as-read/` | Endpoint différent | messaging_api.dart:220 |
| `/conversations/{id}/messages/{id}` | `/api/v1/conversations/{id}/messages/{id}/` | Mauvais préfixe | messaging_api.dart:235 |

### ✅ **Endpoints Corrects Identifiés**

Aucun endpoint correct identifié dans ce module.

---

## 🔧 **Corrections à Implémenter**

### 1. **Correction des Endpoints de Conversations**

```dart
// ❌ Incorrect
return await _apiClient.get('/conversations/', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/conversations/', queryParameters: queryParams);
```

### 2. **Correction des Endpoints de Messages**

```dart
// ❌ Incorrect
return await _apiClient.get('/conversations/$conversationId/messages', queryParameters: queryParams);

// ✅ Correct
return await _apiClient.get('/api/v1/conversations/$conversationId/messages/', queryParameters: queryParams);
```

### 3. **Correction des Endpoints d'Appels**

```dart
// ❌ Incorrect
return await _apiClient.post('/calls/', data: data);

// ✅ Correct
return await _apiClient.post('/api/v1/calls/initiate', data: data);
```

### 4. **Correction des Endpoints de Lecture**

```dart
// ❌ Incorrect
return await _apiClient.put('/conversations/$conversationId/messages/$messageId/read');

// ✅ Correct
return await _apiClient.put('/api/v1/conversations/$conversationId/messages/mark-as-read/', data: {
  'message_ids': [messageId],
});
```

---

## 📊 **Impact des Corrections**

### **Endpoints à Supprimer (Inexistants dans le Backend)**
- `/conversations/{id}/typing` → Endpoint inexistant
- `/conversations/{id}/presence` → Endpoint inexistant

### **Endpoints à Corriger**
- Tous les endpoints de conversations → `/api/v1/conversations/`
- Tous les endpoints de messages → `/api/v1/conversations/{id}/messages/`
- Tous les endpoints d'appels → `/api/v1/calls/`

---

## 🎯 **Plan d'Implémentation**

1. **Phase 1 : Correction des Endpoints de Conversations** (Priorité Critique)
2. **Phase 2 : Correction des Endpoints de Messages** (Priorité Critique)
3. **Phase 3 : Correction des Endpoints d'Appels** (Priorité Haute)
4. **Phase 4 : Correction des Endpoints de Lecture** (Priorité Moyenne)
5. **Phase 5 : Suppression des Endpoints Inexistants** (Priorité Basse)

---

## 📝 **Notes Importantes**

- Les endpoints de messages doivent se terminer par `/`
- Les endpoints d'appels ont des noms spécifiques (initiate, answer, terminate)
- Les endpoints de lecture utilisent un format différent (mark-as-read avec message_ids)
- Les endpoints de frappe et présence n'existent pas dans le backend
- Les paramètres de requête doivent correspondre exactement à ceux du backend 
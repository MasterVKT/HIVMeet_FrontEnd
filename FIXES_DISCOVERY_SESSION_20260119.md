# 🔧 Correctifs Discovery - Session 19 Janvier 2026

## 🎯 Problèmes Identifiés

### 1. ❌ Duplication de profils dans la liste
**Symptôme :** pierre.garcia apparaît DEUX FOIS avec des timestamps différents  
**Cause :** `_loadMoreProfiles()` ajoutait les nouveaux profils SANS vérifier les doublons  
**Timestamp logs :** 
- Première apparition : `2026-01-19 09:56:57.176926`
- Deuxième apparition : `2026-01-19 09:57:50.977588`

### 2. ❌ Profils ne disparaissent pas immédiatement après swipe
**Symptôme :** Après un like/dislike, le profil reste visible jusqu'à reload  
**Cause :** Le code incrémentait `_currentIndex` mais restait dans la même liste, permettant de reswiper  
**Impact :** Possibilité de dislike 2x le même profil

### 3. ❌ Erreur 400 Bad Request sur 6e dislike
```
WARNING 2026-01-19 10:58:07,067 log 15060 13896 Bad Request: /api/v1/discovery/interactions/dislike
```
**Cause probable :** Backend rejette dislike si profil déjà dans une interaction active

---

## ✅ Fixes Appliqués (Frontend)

### Fix 1: Retirer immédiatement le profil après swipe
**Fichier :** `lib/presentation/blocs/discovery/discovery_bloc.dart`  
**Méthode :** `_onSwipeProfile()`

```dart
// ✅ IMPORTANT: Retirer le profil immédiatement de la liste pour l'UI
// Cela évite de reswiper le même profil et de créer des doublons
_profiles.removeAt(_currentIndex);
print('🗑️ DEBUG DiscoveryBloc: Profil ${currentProfile.id} retiré de la liste. Reste ${_profiles.length} profils.');
```

**Bénéfice :** 
- Profil disparaît instantanément après swipe ✅
- Impossible de reswiper le même profil ✅
- UI reste synchronisée avec l'état ✅

### Fix 2: Éviter les doublons au chargement
**Fichier :** `lib/presentation/blocs/discovery/discovery_bloc.dart`  
**Méthode :** `_loadMoreProfiles()`

```dart
// ✅ Éviter les doublons : vérifier que les nouveaux profils ne sont pas déjà dans la liste
final existingIds = _profiles.map((p) => p.id).toSet();
final uniqueNewProfiles =
    newProfilesList.where((p) => !existingIds.contains(p.id));

_profiles.addAll(uniqueNewProfiles);
print('📥 DEBUG DiscoveryBloc: ${newProfilesList.length} nouveaux profils chargés, ${uniqueNewProfiles.length} ajoutés (${existingIds.length} doublons ignorés). Total: ${_profiles.length}');
```

**Bénéfice :**
- Aucun doublon dans la liste ✅
- Logs clairs sur les filtrage ✅
- Permet de détecter les problèmes de pagination ✅

---

## ⚠️ Problème Restant: Erreur 400 Bad Request (Backend)

**Erreur :**
```
POST /api/v1/discovery/interactions/dislike → 400 Bad Request
```

**Contexte :** Se produit lors du dislike répété sur le même profil après rechargement

**Hypothèses :**
1. Backend rejette dislike si interaction (like/dislike) déjà existe et n'est pas révoquée
2. Validation du payload incomplete ou stricte
3. Backend n'a pas de protection contre interactions dupliquées

**À investiguer :**
- Logs backend détaillés sur la validation de dislike
- Endpoint POST `/api/v1/discovery/interactions/dislike` - payload validation
- Vérifier si backend filtre les profils avec interactions actives côté API

**Action recommandée :**
```bash
# Sur le backend:
# 1. Ajouter logging détaillé dans la validation du dislike
# 2. Retourner 409 Conflict au lieu de 400 Bad Request si interaction existe
# 3. Ajouter message d'erreur explicite dans la réponse
```

---

## 📊 Résultats Attendus

### Avant Fixes
❌ Profils restent visibles après swipe  
❌ Doublons dans la liste  
❌ Possibilité de reswiper → 400 Bad Request  
❌ Erreur 400 affichée à l'utilisateur  

### Après Fixes  
✅ Profil disparaît immédiatement après swipe  
✅ Aucun doublon, liste propre  
✅ Impossible de reswiper le même profil  
✅ Chargement fluide du prochain profil  
✅ Swipe jusqu'à la fin sans erreur (si backend OK)  

---

## 🧪 Test Plan

### Test 1: Suppression immédiate
1. Lancer l'app
2. Swiper 1 profil à droite (like)
3. **Vérifier :** Profil disparaît instantanément ✅ vs reste visible ❌

### Test 2: Pas de doublon
1. Swiper tous les profils visibles (5)
2. Regarder les logs BLoC: `📥 DEBUG DiscoveryBloc: ... doublons ignorés`
3. **Vérifier :** Le nombre de doublons = 0 ✅ vs > 0 ❌

### Test 3: Pas d'erreur 400
1. Swiper tous les 8 profils (5 initiaux + 3 rechargés)
2. **Vérifier :** Pas de ❌ DEBUG DiscoveryBloc: Dislike failed - ServerFailure 400 ✅

### Test 4: Integration avec My Likes
1. Like 3 profils
2. Aller dans "My Likes"
3. Revenir à Discovery
4. **Vérifier :** Ces 3 profils n'apparaissent pas ✅

---

## 📝 Notes Techniques

**Changement architectural :**
- AVANT: `_currentIndex` augmente, mais profil reste dans la liste
- APRÈS: Le profil est **retiré** de la liste, `_currentIndex` reste le même (pointe au suivant automatiquement)

Cela rend la liste plus **immédiate** et **prévisible** pour l'utilisateur.

**Logging ajouté :**
```dart
🗑️ DEBUG DiscoveryBloc: Profil retiré...
📥 DEBUG DiscoveryBloc: X nouveaux profils chargés, Y ajoutés (Z doublons ignorés)
```

---

## 🔗 Fichiers Modifiés
- `lib/presentation/blocs/discovery/discovery_bloc.dart`
  - `_onSwipeProfile()` : Suppression immédiate du profil
  - `_loadMoreProfiles()` : Vérification des doublons

---

**Date :** 19 janvier 2026  
**Status :** ✅ Corrigé et prêt au test

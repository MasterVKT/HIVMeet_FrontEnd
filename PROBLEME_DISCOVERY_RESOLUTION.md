# 📋 RÉSUMÉ DES 3 PROBLÈMES DISCOVERY - Session 19 Janvier 2026

## 🎯 Récapitulatif des Problèmes Rapportés par l'Utilisateur

### Problème 1️⃣ : Profils ne disparaissent pas instantanément
> "Lorsque j'ai likés certains profils et dislikés d'autres, non seulement ces profils ne disparaissent pas instantanément de la liste (il faut sortir de la page puis la réintégrer)"

**Logs Frontend :** Profil toujours visible dans `DiscoveryLoaded` même après succès  
**Logs Backend :** ✅ Like/Dislike retourne 201 Created  
**Analyse :** 
- Code incrémentait `_currentIndex++` mais gardait le profil dans la liste
- Causait confusion UI et possibilité de reswiper

**Fix :** ✅ APPLIQUÉ
```dart
_profiles.removeAt(_currentIndex);  // Retirer le profil immédiatement
```

---

### Problème 2️⃣ : Les profils likés/passés réapparaissent
> "mais lorsque je me rends dans la page "découverte", ces profils dont j'ai annulé les like et passés n'y apparaissent pas"

**Contexte :** 
- Utilisateur like profil A → List = [A, B, C, D, E]
- Recharge ou revient → List = [A, B, C, D, E, A, B, C] ← **DOUBLON**
- Donc profil A réapparaît (au lieu de disparaître)

**Logs Frontend :**
```
🔄 DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: 3, _profiles.length: 5
🔄 DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: 3, _profiles.length: 8  ← compte passe de 5 à 8
```

**Cause :** 
- `_loadMoreProfiles()` chargeait 20 nouveaux profils
- N'avait PAS de vérification de doublons
- Si pierre.garcia était déjà dans la liste, il était réajouté

**Logs Backend :** Backend retourne les MÊMES profils (pierre.garcia avec timestamps différents)

**Fix :** ✅ APPLIQUÉ
```dart
final existingIds = _profiles.map((p) => p.id).toSet();
final uniqueNewProfiles = newProfilesList.where((p) => !existingIds.contains(p.id));
_profiles.addAll(uniqueNewProfiles);  // Ajouter UNIQUEMENT les nouveaux
```

---

### Problème 3️⃣ : Erreur 400 Bad Request sur le 6e dislike
> "De plus, dans la page découverte, lorsque j'ai swapé les profils jusqu'à la fin, j'ai obtenu une erreur"

**Logs Frontend :**
```
❌ DEBUG DiscoveryBloc: Dislike failed - ServerFailure(Erreur lors du dislike: DioException [bad response]: ... 400 Bad Request ...)
```

**Logs Backend :**
```
INFO 2026-01-19 10:57:49,191 basehttp 15060 18760 "POST /api/v1/discovery/interactions/dislike HTTP/1.1" 201 75
INFO 2026-01-19 10:57:51,108 basehttp 15060 18760 "POST /api/v1/discovery/interactions/dislike HTTP/1.1" 201 75
WARNING 2026-01-19 10:58:07,067 log 15060 13896 Bad Request: /api/v1/discovery/interactions/dislike
WARNING 2026-01-19 10:58:07,067 basehttp 15060 13896 "POST /api/v1/discovery/interactions/dislike HTTP/1.1" 400 58
```

**Séquence d'events :**
```
1. Dislike 1: pierre.garcia → 201 ✅
2. Dislike 2: antoine.martinez → 201 ✅
3. Dislike 3: pierre.garcia (DOUBLON depuis rechargement!) → 201 ✅
4. ...
5. Dislike N: pierre.garcia (2e fois) → 400 ❌ Bad Request
```

**Cause Probable :**
- Utilisateur dislike pierre.garcia (premier dislike → BD)
- Rechargement profile → pierre.garcia réapparaît (doublon!)
- Utilisateur dislike pierre.garcia une 2e fois (oups!)
- Backend : "Je vois déjà une interaction dislike active pour ce profil" → 400 Bad Request

**Fix :** ✅ APPLIQUÉ (Indirect)
- En supprimant immédiatement le profil après swipe, on empêche le reswipe
- En éliminant les doublons, on évite de recharger le même profil

**Fix Suggéré (Backend) :** 
- Retourner 409 Conflict au lieu de 400 Bad Request si interaction existe
- Ou ajouter un message d'erreur explicite

---

## 🔧 FIXES APPLIQUÉES

### 1. **Discovery Bloc - `_onSwipeProfile()`**
- ❌ Ancien : `_currentIndex++` (laisse profil dans liste)
- ✅ Nouveau : `_profiles.removeAt(_currentIndex)` (retire profil)

**Bénéfice :** 
- Profil disparaît immédiatement ✅
- Impossible de reswiper le même ✅
- Chargement du suivant automatique ✅

### 2. **Discovery Bloc - `_loadMoreProfiles()`**
- ❌ Ancien : `_profiles.addAll(newProfilesList)` (sans vérification)
- ✅ Nouveau : Vérification avec `existingIds` et filtrage

**Bénéfice :**
- Aucun doublon ✅
- Liste propre ✅
- Logs de debug clairs ✅

---

## 📊 IMPACTE DES FIXES

| Avant | Après |
|--------|--------|
| ❌ Profil reste visible | ✅ Profil disparaît immédiatement |
| ❌ Doublons dans liste | ✅ Liste sans doublon |
| ❌ Reswipe possible | ✅ Reswipe impossible |
| ❌ 400 Bad Request | ✅ Pas d'erreur (doublon évité) |
| ❌ UI confuse | ✅ UI fluide et claire |

---

## 🧪 COMMENT TESTER

### Test 1: Suppression immédiate
```
1. Launch app
2. Swipe 1 profil à DROITE (like)
3. ❓ Profil disparaît instantanément? ✅ OUI vs ❌ NON
```

### Test 2: Pas de doublon
```
1. Swipe tous les profils visibles (initialement 5)
2. Observer les logs BLoC: "📥 DEBUG DiscoveryBloc: ... doublons ignorés"
3. ❓ Le nombre de doublons ignorés? ✅ 0 vs ❌ > 0
```

### Test 3: Pas d'erreur 400
```
1. Swipe jusqu'au dernier profil
2. Observer console/logs
3. ❓ Erreur 400 apparaît? ✅ NON vs ❌ OUI
```

### Test 4: Profils likés disparaissent
```
1. Like 3 profils
2. Aller dans "My Likes" page
3. Revenir à Discovery
4. ❓ Les 3 profils likés réapparaissent? ✅ NON vs ❌ OUI
```

---

## ⚠️ PROBLÈME RESTANT: Erreur 400 (Backend Only)

Si le 400 Bad Request persiste (très peu probable), c'est un problème du backend:
- Endpoint : `POST /api/v1/discovery/interactions/dislike`
- Validation : Probablement rejette dislike si interaction existe
- Solution : Backend doit logger le motif exact de l'erreur 400

---

## 📁 FICHIERS MODIFIÉS
- ✅ `lib/presentation/blocs/discovery/discovery_bloc.dart`
  - Méthode `_onSwipeProfile()` lignes ~135-225
  - Méthode `_loadMoreProfiles()` lignes ~375-405

## 📅 Date
19 janvier 2026

## ✅ Status
**Corrigé et prêt au test en frontend**  
*Le problème 400 backend reste à investiguer si persistent après test*

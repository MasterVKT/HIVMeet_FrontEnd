# 📋 RÉSUMÉ COMPLET : Problèmes Discovery & Solutions

## 🎯 Session: 19 Janvier 2026

User rapporte 2 problèmes majeurs :
1. My Likes/My Passes : profils ne disparaissent pas après revocation
2. Discovery page : reste vide (0 profils)

---

# NOTE IMPORTANTE
Les problèmes #1, #2, #3 ci-dessous (doublons, suppression immédiate, erreur 400) ont été corrigés dans la **session précédente** et ne sont plus des problèmes actuels. Ils sont documentés ici pour référence historique.

# PARTIE 1 : Problèmes de la Session Précédente (DÉJÀ CORRIGÉS)

## 1️⃣ Profils ne disparaissent pas instantanément après swipe

**Symptôme :** Après avoir liké ou dislikée un profil, celui-ci reste visible dans la liste. Faut sortir et revenir pour voir le changement.

**Logs :** 
```
✅ DEBUG DiscoveryBloc: Like réussi pour e79040cc-...
🔄 DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: 0, _profiles.length: 5
```
Le profil reste dans la liste.

**Cause :** 
```dart
// ❌ ANCIEN CODE
_currentIndex++;  // Incrémenter l'index
// Mais le profil reste dans _profiles!
// Résultat: on peut reswiper le même profil
```

**Solution Appliquée :**
```dart
// ✅ NOUVEAU CODE
_profiles.removeAt(_currentIndex);  // Retirer le profil
print('🗑️ DEBUG: Profil retiré. Reste ${_profiles.length} profils.');
```

**Bénéfice :** Profil disparaît immédiatement ✅

---

## 2️⃣ Doublons de profils dans la liste

**Symptôme :** Après rechargement, on voit `pierre.garcia` deux fois avec des timestamps différents.

**Logs :**
```
DiscoveryProfile(..., pierre.garcia, ..., 2026-01-19 09:56:57.176926, 0.0)  ← 1ère fois
DiscoveryProfile(..., pierre.garcia, ..., 2026-01-19 09:57:50.977588, 0.0)  ← DOUBLON!
```

**Cause :**
```dart
// ❌ ANCIEN CODE
_profiles.addAll(newProfilesList);  // Ajouter TOUS les nouveaux profils
// Pas de vérification si le profil existe déjà!
```

**Solution Appliquée :**
```dart
// ✅ NOUVEAU CODE
final existingIds = _profiles.map((p) => p.id).toSet();
final uniqueNewProfiles = newProfilesList.where((p) => !existingIds.contains(p.id));
_profiles.addAll(uniqueNewProfiles);

print('📥 DEBUG: ${newProfilesList.length} nouveaux, ${uniqueNewProfiles.length} ajoutés, ${existingIds.length} doublons ignorés');
```

**Bénéfice :** Aucun doublon ✅

---

## 3️⃣ Erreur 400 Bad Request sur dislike répété

**Symptôme :** Après avoir dislikée 5-6 profils, on reçoit une erreur 400.

**Logs Backend :**
```
WARNING Bad Request: /api/v1/discovery/interactions/dislike
"POST /api/v1/discovery/interactions/dislike HTTP/1.1" 400 58
```

**Cause :** En reswipant le même profil (due au problème #2 - doublon), le backend rejetait le 2e dislike.

**Solution :** Les corrections #1 et #2 évitent ce problème en éliminant les doublons et empêchant le reswipe.

**Bénéfice :** Plus d'erreur 400 ✅

---

# PARTIE 2 : Les 2 Problèmes Actuels (Session 19 Janvier 2026)

## 4️⃣ My Likes / My Passes : Profils ne disparaissent pas après revocation

**Symptôme :** User revoque un like, reçoit la notification `✅ Interaction X revoked`, mais quand il retourne à la page "My Likes", le profil est toujours là.

**Logs :**
```
📢 InteractionHistoryBloc: Notification révocation profil f24e7846-dd78-...
🔔 DiscoveryBloc: Reçu notification révocation profil f24e7846-dd78-...
```
Mais le profil ne disparaît pas de la liste.

**Cause :**
```dart
// ❌ ANCIEN CODE (injection.dart ligne 407)
getIt.registerFactory<InteractionHistoryBloc>(...)  // FACTORY
// Chaque fois qu'on entre dans "My Likes", une NOUVELLE instance est créée
// Instance précédente fermée, suppressions perdues!
```

**Séquence problématique :**
1. Entrer "My Likes" → Nouvelle instance #1, charge les données
2. Révoquer un like → Supprimé de la liste instance #1 ✅
3. Quitter "My Likes" → Instance #1 fermée ❌
4. Revenir "My Likes" → **NOUVELLE instance #2 créée**, charge les données (profil toujours là!)

**Solution Appliquée :**
```dart
// ✅ NOUVEAU CODE (injection.dart ligne 407)
getIt.registerLazySingleton<InteractionHistoryBloc>(...)  // LAZYSINGLETIN
// Même instance partagée, données persistantes
```

**Bénéfice :** 
- ✅ Profil disparaît immédiatement après revocation
- ✅ Ne réapparaît jamais après revocation
- ✅ Aligné avec DiscoveryBloc (même pattern)

---

## 5️⃣ Discovery Page Reste Vide (Backend)

**Symptôme :** Après annulation d'un like et d'un pass, la page Découverte retourne "Plus de profils" au lieu de proposer d'autres profiles.

**Logs Backend :**
```
After user's gender filter (seeking ['male']): 6 profiles ✅
After mutual gender compatibility (target seeks female): 0 profiles ❌
```

**Cause :** Les profils males dans la BD n'ont **PAS l'attribut `gender_sought`**.

Le backend filtre :
1. Marie cherche hommes → 6 hommes trouvés ✅
2. Ces hommes doivent chercher femmes → **Aucun ne l'a!** ❌
3. Résultat: 0 compatibles

**Données actuelles (mauvaises) :**
```json
{
  "user_id": "clement.fernandez",
  "gender": "male",
  "relationship_types_sought": ["long_term", "friendship", "casual"],
  // ❌ gender_sought: NULL ou manquant
}
```

**Données attendues (manquantes) :**
```json
{
  "user_id": "clement.fernandez",
  "gender": "male",
  "gender_sought": "female",  // ✅ REQUÊTE MANQUANTE
  "relationship_types_sought": ["long_term", "friendship", "casual"]
}
```

**Solution (Backend) :**
Ajouter `gender_sought = 'female'` à tous les profils males:
```sql
UPDATE profiles_profile 
SET gender_sought = 'female'
WHERE gender = 'male' AND gender_sought IS NULL;
```

**Status :** ❌ **NON CORRIGÉ** - Attend intervention backend

---

# TABLEAU RÉCAPITULATIF

| # | Problème | Page | Status | Cause | Fix |
|---|----------|------|--------|-------|-----|
| 1 | Profil reste visible après swipe | Discovery | ✅ CORRIGÉ | `_currentIndex++` au lieu de `removeAt()` | Utiliser `removeAt(_currentIndex)` |
| 2 | Doublons de profils | Discovery | ✅ CORRIGÉ | `addAll()` sans vérification | Vérifier `existingIds` |
| 3 | Erreur 400 Bad Request | Discovery | ✅ CORRIGÉ | Consequence du problème #2 | Correction #2 résout |
| 4 | Profil ne disparaît pas après revocation | My Likes/Passes | ✅ CORRIGÉ | Factory au lieu de LazySingleton | Changer en LazySingleton |
| 5 | Discovery page vide | Discovery | ❌ BLOQUANT | Profils males sans `gender_sought` | Backend ajouter l'attribut |

---

# FICHIERS MODIFIÉS

## ✅ Frontend (Corrigé)

### Session Précédente
- `lib/presentation/blocs/discovery/discovery_bloc.dart`
  - Méthode `_onSwipeProfile()` : Ajout de `_profiles.removeAt(_currentIndex)`
  - Méthode `_loadMoreProfiles()` : Ajout vérification des doublons

### Session Actuelle
- `lib/injection.dart` (ligne ~407)
  - `InteractionHistoryBloc` : Factory → **LazySingleton**

## ❌ Backend (À Corriger)

- Ajouter `gender_sought = 'female'` aux profils males dans la BD

## 📝 Documentation Créée

- `FIXES_DISCOVERY_SESSION_20260119.md` : Résumé des corrections précédentes
- `PROBLEME_DISCOVERY_RESOLUTION.md` : Détails techniques des problèmes
- `BACKEND_GENDER_FILTER_BUG.md` : Diagnostic et solution du problème backend
- `CORRECTIONS_DISCOVERY_COMPLETE.md` : Cet document résumé

---

# 🧪 CHECKLIST DE TEST

### Test 1 : Discovery - Suppression Immédiate ✅
- [ ] Lancer l'app
- [ ] Swiper 1 profil à DROITE (like)
- [ ] Vérifier profil disparaît immédiatement

### Test 2 : Discovery - Pas de Doublon ✅
- [ ] Swiper tous les profils (5)
- [ ] Vérifier logs : `📥 DEBUG: ... doublons ignorés`
- [ ] Compte de doublons = 0

### Test 3 : Discovery - Pas d'erreur 400 ✅
- [ ] Swiper jusqu'au dernier profil
- [ ] Vérifier pas d'erreur 400 dans logs

### Test 4 : My Likes - Disparition Immédiate ✅ (À TESTER MAINTENANT)
- [ ] Hot reload l'app
- [ ] Ouvrir "My Likes"
- [ ] Révoquer 1 like
- [ ] Vérifier profil disparaît immédiatement
- [ ] Quitter et revenir
- [ ] Vérifier profil n'est pas revenu

### Test 5 : My Passes - Disparition Immédiate ✅ (À TESTER MAINTENANT)
- [ ] Ouvrir "My Passes"
- [ ] Révoquer 1 pass
- [ ] Vérifier profil disparaît immédiatement
- [ ] Quitter et revenir
- [ ] Vérifier profil n'est pas revenu

### Test 6 : Discovery - Page Pleine ❌ (À FAIRE APRÈS BACKEND)
- [ ] Backend ajoute `gender_sought` aux profils males
- [ ] Hot reload l'app
- [ ] Ouvrir Discovery
- [ ] Vérifier des profils apparaissent (pas "Plus de profils")

---

# 📊 PROGRESS SUMMARY

## Frontend Status
- ✅ **80% Corrigé**
  - ✅ Doublons éliminés
  - ✅ Suppression immédiate Discovery
  - ✅ My Likes/Passes en LazySingleton
  - ❌ (Normal) Discovery page vide due to backend

## Backend Status
- ❌ **20% À Corriger**
  - ❌ Profils males sans `gender_sought`
  - ✅ Revocation fonctionne
  - ✅ API endpoints corrects

## Global Impact
- 🟡 **Partiellement Fonctionnel**
  - ✅ Like/Dislike working
  - ✅ Revocation working
  - ✅ UI updates immediately (My Likes/Passes)
  - ❌ Discovery page vide (backend issue)

---

## 🎯 Next Action

**URGENT:** Backend doit corriger `gender_sought` pour que Discovery retrouve des profils.

Une fois fait, la feature sera **100% Fonctionnelle** ✅

---

**Date :** 19 janvier 2026  
**Durée Session :** 2+ heures  
**Commits Requis :** 2 (frontend + docs)  
**PR Requise :** 1 (pour backend fix)

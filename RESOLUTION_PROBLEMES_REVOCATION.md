# 🔧 Résolution des Problèmes de Révocation - HIVMeet

## 📋 Problèmes Résolus

### ❌ Problème 1 : Le profil ne disparaît pas instantanément de la liste

**Symptôme** : Après avoir annulé un like ou un pass, le profil reste visible dans la liste. Il faut retourner en arrière puis revenir sur la page pour constater sa disparition.

**Cause Racine** : Dans `InteractionHistoryBloc`, la méthode `_onRevokeInteraction` utilisait `removeWhere()` qui modifiait la liste en place. Flutter (avec Equatable) ne détectait pas le changement car la référence de la liste restait la même.

**Solution Appliquée** ✅ :
- Remplacement de `removeWhere()` par `where().toList()` qui crée une **nouvelle instance de liste**
- Ajout de logs de débogage pour suivre les suppressions
- Fichier modifié : [lib/presentation/blocs/interaction_history/interaction_history_bloc.dart](lib/presentation/blocs/interaction_history/interaction_history_bloc.dart)

**Code Avant** :
```dart
_allLikes.removeWhere((l) => l.id != event.interactionId);
emit(LikesLoaded(likes: _allLikes, ...));
```

**Code Après** :
```dart
_allLikes = _allLikes.where((l) => l.id != event.interactionId).toList();
print('🔄 InteractionHistoryBloc: Liste likes mise à jour - ${_allLikes.length} restants');
emit(LikesLoaded(likes: _allLikes, ...));
```

---

### ❌ Problème 2 : Le profil ne retourne pas dans la découverte

**Symptôme** : Après avoir annulé un like ou un pass, le profil ne réapparaît pas dans la page de découverte.

**Cause Racine** : Le backend exclut **tous** les profils qui ont déjà eu une interaction (même révoquée) via les "Legacy likes" et "Legacy dislikes", au lieu d'exclure uniquement les interactions **actives** (`is_revoked=False`).

**Solution Requise** 📝 :
- Le fichier backend `services.py` doit être modifié
- Les requêtes "Legacy likes/dislikes" doivent filtrer par `is_revoked=False`
- Documentation complète fournie dans : [CORRECTION_REVOCATION_BACKEND.md](CORRECTION_REVOCATION_BACKEND.md)

**Backend à Modifier** (Django) :
```python
# ❌ AVANT
legacy_likes = UserInteraction.objects.filter(
    user=user,
    interaction_type='like'
).values_list('target_user_id', flat=True)

# ✅ APRÈS
legacy_likes = UserInteraction.objects.filter(
    user=user,
    interaction_type='like',
    is_revoked=False  # ← AJOUTER CETTE CONDITION
).values_list('target_user_id', flat=True)
```

---

## 🧪 Tests à Effectuer

### Test 1 : Disparition Instantanée du Profil ✅ (Frontend corrigé)

1. Ouvrir l'application Flutter
2. Aller dans "Profils likés" ou "Passes"
3. Cliquer sur "Annuler ce like/pass" sur un profil
4. **Vérification** : Le profil doit disparaître **immédiatement** de la liste sans avoir à quitter/revenir

**Logs Attendus** :
```
I/flutter: 🔄 InteractionHistoryBloc: Liste likes mise à jour - 5 restants
I/flutter: 📢 InteractionHistoryBloc: Notification révocation profil xxx
```

---

### Test 2 : Réapparition dans la Découverte ⏳ (Backend à corriger)

**Après avoir appliqué la correction backend** :

1. Liker un profil dans la découverte
2. Aller dans "Profils likés"
3. Annuler le like
4. Retourner dans "Découverte"
5. **Vérification** : Le profil doit **réapparaître** dans la liste des profils à découvrir

**Logs Backend Attendus** :
```
INFO views_history ✅ Interaction xxx revoked successfully
INFO services 🚫 Excluding X profiles:
INFO services    - Active interactions (is_revoked=False): 13  ← Diminue de 1
INFO services    - Legacy likes: 13  ← Diminue de 1 (ou 0 si migration complète)
```

---

## 📊 Flux de Révocation Complet

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Utilisateur clique "Annuler ce like"                        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. my_likes_page.dart appelle bloc.add(RevokeInteractionEvent) │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. InteractionHistoryBloc._onRevokeInteraction()                │
│     - Appelle backend POST /api/v1/discovery/interactions/{id}/│
│       revoke                                                     │
│     - Backend marque is_revoked=True                            │
│     - Backend répond 200 OK                                     │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Frontend (succès)                                            │
│     ✅ Crée nouvelle liste sans le profil révoqué               │
│     ✅ Émet LikesLoaded avec liste mise à jour                  │
│     ✅ Notifie AppEvents.notifyInteractionRevoked(profileId)    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. UI (BlocConsumer dans my_likes_page.dart)                    │
│     ✅ Reçoit nouveau state LikesLoaded                         │
│     ✅ Rebuild avec liste mise à jour                           │
│     ✅ Le profil DISPARAÎT immédiatement                        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. DiscoveryBloc (écoute AppEvents)                             │
│     ✅ Reçoit notification révocation                           │
│     ⏳ Attend 500ms                                             │
│     ✅ Recharge profils discovery avec forceRefresh=true        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. Backend GET /api/v1/discovery/profiles                       │
│     ⏳ APRÈS CORRECTION: N'exclut que is_revoked=False          │
│     ✅ Retourne le profil révoqué dans les résultats            │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. UI Discovery                                                 │
│     ✅ Le profil RÉAPPARAÎT dans la découverte                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 Fichiers Modifiés

### Frontend ✅ (Déjà corrigé)
- [lib/presentation/blocs/interaction_history/interaction_history_bloc.dart](lib/presentation/blocs/interaction_history/interaction_history_bloc.dart)
  - Méthode `_onRevokeInteraction()` : Utilise `where().toList()` au lieu de `removeWhere()`
  - Ajout de logs de débogage

### Backend ⏳ (À corriger - Documentation fournie)
- Voir [CORRECTION_REVOCATION_BACKEND.md](CORRECTION_REVOCATION_BACKEND.md)
- Fichier probable : `hivmeet_backend/discovery/services.py` ou `hivmeet_backend/matching/services.py`
- Fonction : `get_recommendations()`
- Modification : Ajouter filtre `is_revoked=False` aux requêtes Legacy likes/dislikes

---

## ✅ Statut

| Problème | Solution | Statut | Fichiers |
|----------|----------|--------|----------|
| Profil ne disparaît pas de la liste | Créer nouvelle liste au lieu de modifier en place | ✅ **Corrigé** | `interaction_history_bloc.dart` |
| Profil ne retourne pas en découverte | Filtrer Legacy interactions par `is_revoked=False` | ⏳ **Documentation fournie** | Backend `services.py` |

---

## 🚀 Prochaines Étapes

1. **Tester la correction frontend** :
   ```bash
   flutter run
   ```
   - Vérifier que le profil disparaît instantanément après révocation

2. **Appliquer la correction backend** :
   - Ouvrir le projet backend Django
   - Suivre les instructions dans [CORRECTION_REVOCATION_BACKEND.md](CORRECTION_REVOCATION_BACKEND.md)
   - Tester avec les scénarios fournis

3. **Tester le flux complet** :
   - Liker un profil → Annuler → Vérifier disparition de la liste (✅ devrait fonctionner)
   - Vérifier réapparition en découverte (⏳ après correction backend)

---

## 🐛 Débogage Additionnel

Si le profil ne disparaît toujours pas après la correction frontend, vérifiez :

1. **Que le BlocProvider utilise bien le singleton** :
```dart
// my_likes_page.dart ligne 20-23
BlocProvider.value(
  value: getIt<InteractionHistoryBloc>(), // ✅ Singleton
  child: const _MyLikesPageContent(),
)
```

2. **Que le bloc est enregistré comme LazySingleton** :
```dart
// injection.dart
getIt.registerLazySingleton<InteractionHistoryBloc>(...) // ✅
```

3. **Les logs Flutter** :
```
I/flutter: 🔄 InteractionHistoryBloc: Liste likes mise à jour - X restants
```
Doivent apparaître après la révocation.

---

## 📞 Support

Si les problèmes persistent après ces corrections :
1. Vérifier les logs Flutter et Backend
2. Consulter la documentation complète dans [CORRECTION_REVOCATION_BACKEND.md](CORRECTION_REVOCATION_BACKEND.md)
3. S'assurer que la migration de données a été effectuée si nécessaire

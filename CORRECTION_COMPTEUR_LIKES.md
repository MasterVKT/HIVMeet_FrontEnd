# Correction du Compteur de Likes Restants

## Problème Identifié

Le compteur de likes restants affiché en haut à gauche de l'écran de découverte restait bloqué à **10 likes** sans diminuer après chaque swipe à droite (like).

### Symptômes
- ✅ Les likes fonctionnent correctement (API répond 200 OK)
- ✅ Les matchs sont créés
- ❌ Le compteur affiché reste à 10 sans changer
- ❌ L'utilisateur n'a pas de visibilité sur ses likes restants

### Cause Racine

Le backend retourne bien le nombre de likes restants dans la réponse du like, mais le frontend ne les utilisait pas :

1. **Ligne 271 de `match_repository_impl.dart`** : La méthode `getDailyLikeLimit()` retournait une valeur hardcodée `remainingLikes: 10`
2. **Lignes 77-96 de `match_repository_impl.dart`** : La méthode `likeProfile()` ignorait `daily_likes_remaining` de la réponse API
3. **Ligne 198 de `discovery_bloc.dart`** : Après chaque like, le bloc appelait `getDailyLikeLimit()` qui retournait toujours 10

## Solution Implémentée

### 1. Ajout de `remainingLikes` à `SwipeResult`

**Fichier:** `lib/domain/entities/match.dart`

```dart
class SwipeResult extends Equatable {
  final bool isMatch;
  final String? matchId;
  final Profile? matchedProfile;
  final int? remainingLikes;           // ✅ NOUVEAU
  final int? remainingSuperLikes;      // ✅ NOUVEAU

  const SwipeResult({
    required this.isMatch,
    this.matchId,
    this.matchedProfile,
    this.remainingLikes,               // ✅ NOUVEAU
    this.remainingSuperLikes,          // ✅ NOUVEAU
  });
  
  // ... fromJson et toJson mis à jour
}
```

### 2. Extraction des Valeurs du Backend

**Fichier:** `lib/data/repositories/match_repository_impl.dart`

**Avant:**
```dart
return Right(SwipeResult(
  isMatch: isMatch,
  matchId: isMatch ? (data['match_id'] as String?) : null,
));
```

**Après:**
```dart
return Right(SwipeResult(
  isMatch: isMatch,
  matchId: isMatch ? (data['match_id'] as String?) : null,
  remainingLikes: data['daily_likes_remaining'] as int?,      // ✅ NOUVEAU
  remainingSuperLikes: data['super_likes_remaining'] as int?, // ✅ NOUVEAU
));
```

### 3. Mise à Jour du Compteur dans le BLoC

**Fichier:** `lib/presentation/blocs/discovery/discovery_bloc.dart`

**Avant:**
```dart
// Mettre à jour la limite quotidienne (si disponible via backend)
if (event.direction == SwipeDirection.right) {
  final limitEither = await _getDailyLikeLimit();  // ❌ Retourne toujours 10
  _dailyLimit = limitEither.fold((l) => _dailyLimit, (r) => r);
}
```

**Après:**
```dart
// Mettre à jour la limite quotidienne avec les valeurs du backend
if (result.remainingLikes != null && _dailyLimit != null) {
  _dailyLimit = _dailyLimit!.copyWith(
    remainingLikes: result.remainingLikes!,  // ✅ Utilise la valeur réelle du backend
  );
}
```

### 4. Ajout de `copyWith` à `DailyLikeLimit`

**Fichier:** `lib/domain/entities/match.dart`

```dart
class DailyLikeLimit extends Equatable {
  // ... propriétés existantes
  
  DailyLikeLimit copyWith({       // ✅ NOUVEAU
    int? remainingLikes,
    int? totalLikes,
    DateTime? resetAt,
  }) {
    return DailyLikeLimit(
      remainingLikes: remainingLikes ?? this.remainingLikes,
      totalLikes: totalLikes ?? this.totalLikes,
      resetAt: resetAt ?? this.resetAt,
    );
  }
}
```

## Flux de Données Après Correction

### Avant (❌ Incorrect)
```
1. Utilisateur swipe right (like)
2. API POST /discovery/interactions/like
3. Backend répond: { result: "like_sent", daily_likes_remaining: 9 }
4. Frontend ignore daily_likes_remaining ❌
5. Frontend appelle getDailyLikeLimit() → retourne toujours 10 ❌
6. Compteur reste à 10 ❌
```

### Après (✅ Correct)
```
1. Utilisateur swipe right (like)
2. API POST /discovery/interactions/like
3. Backend répond: { result: "like_sent", daily_likes_remaining: 9 }
4. Frontend extrait daily_likes_remaining = 9 ✅
5. Frontend met à jour _dailyLimit.remainingLikes = 9 ✅
6. Compteur affiche 9 ✅
```

## Réponse API Attendue

Selon la documentation `docs/FRONTEND_MATCHING_API.md`, le backend doit retourner:

```json
{
  "result": "match",               // ou "like_sent"
  "match_id": "uuid",             // si match
  "daily_likes_remaining": 8,     // ✅ Utilisé maintenant
  "super_likes_remaining": 2,     // ✅ Utilisé maintenant
  "message": "It's a match!"
}
```

## Tests à Effectuer

### ✅ Test 1 : Compteur diminue après swipe right
1. Noter le nombre initial de likes (ex: 10)
2. Swiper à droite sur un profil
3. Vérifier que le compteur affiche 9

### ✅ Test 2 : Compteur ne change pas après swipe left
1. Noter le nombre de likes
2. Swiper à gauche (dislike)
3. Vérifier que le compteur reste identique

### ✅ Test 3 : Compteur diminue avec le bouton coeur
1. Noter le nombre de likes
2. Cliquer sur le bouton coeur (like)
3. Vérifier que le compteur diminue

### ✅ Test 4 : Compteur atteint 0
1. Liker jusqu'à épuiser tous les likes
2. Vérifier l'affichage de la limite atteinte
3. Vérifier que les swipes right sont bloqués

## Fichiers Modifiés

- ✅ `lib/domain/entities/match.dart`
  - Ajout de `remainingLikes` et `remainingSuperLikes` à `SwipeResult`
  - Ajout de la méthode `copyWith` à `DailyLikeLimit`

- ✅ `lib/data/repositories/match_repository_impl.dart`
  - Extraction de `daily_likes_remaining` dans `likeProfile()`
  - Extraction de `super_likes_remaining` dans `superLikeProfile()`

- ✅ `lib/presentation/blocs/discovery/discovery_bloc.dart`
  - Mise à jour de `_dailyLimit` avec la valeur retournée par l'API
  - Suppression de l'appel inutile à `getDailyLikeLimit()`

## Notes Techniques

### Pourquoi ne pas appeler `getDailyLikeLimit()` ?

**Ancien système** (❌ Inefficace):
- Après chaque like, appelle GET `/api/v1/discovery/limits` (endpoint qui n'existe peut-être pas)
- Double requête réseau inutile
- Retournait une valeur hardcodée de 10

**Nouveau système** (✅ Efficace):
- Backend retourne déjà `daily_likes_remaining` dans la réponse du like
- Pas de requête supplémentaire nécessaire
- Valeur toujours à jour et synchronisée avec le serveur

### Gestion des Super-Likes

Le même mécanisme a été appliqué aux super-likes:
- `remainingSuperLikes` extrait de `super_likes_remaining`
- Peut être utilisé pour afficher un compteur de super-likes
- Utile pour les fonctionnalités premium

## État Après Correction

✅ **Résolu** : Le compteur de likes diminue correctement après chaque like
✅ **Résolu** : Les valeurs proviennent maintenant du backend réel
✅ **Résolu** : Pas de requête API supplémentaire nécessaire
✅ **Amélioré** : Support des super-likes également ajouté

## TODO Restants

- [ ] Implémenter l'endpoint GET `/api/v1/discovery/limits` dans le backend si besoin de rafraîchir la limite
- [ ] Afficher un compteur de super-likes si fonctionnalité premium activée
- [ ] Tester le comportement quand `daily_likes_remaining` n'est pas retourné par le backend (cas d'erreur)
- [ ] Ajouter une animation de décrémentation du compteur pour meilleur feedback UX

# Rapport d'audit & spécification d'implémentation — Super Like (HIVMeet)

**Périmètre** : frontend Flutter (`d:\Projets\HIVMeet\hivmeet`) + backend Django (`d:\Projets\HIVMeet\env\hivmeet_backend`)
**Date** : 2026-09-21
**Objet** : décrire (1) ce qu'un Super Like **doit** être, (2) ce qui est **réellement implémenté**, (3) **tous les écarts** avec preuves `fichier:ligne`, (4) un **plan d'implémentation actionnable** frontend + backend, (5) les **critères d'acceptation**.
**Public cible** : tout agent IA (ou développeur) devant corriger/compléter la fonctionnalité Super Like. Aucune étape ne dépend d'un contexte non écrit dans ce document.

> 📘 **Document compagnon obligatoire** : `RAPPORT_SUPERLIKE_ANNEXE_IMPLEMENTATION.md`
> Il contient le **code prescriptif exact** (signatures, diffs, ordre d'exécution, tests, pièges) pour chaque lot de la Partie D. **Lire les deux documents ensemble** : le présent rapport dit *quoi* et *pourquoi*, l'annexe dit *comment*. L'annexe est autosuffisante pour l'implémentation.

> ⚠️ Convention de lecture : les sections **A = cible normative** (ce qui doit être vrai à la fin), **B = état constaté**, **C = écarts**, **D = plan**, **E/F = validation**.

---

## 0. Méthode & niveau de preuve

Toutes les affirmations de la section B/C sont issues de la lecture directe du code (chemins + numéros de ligne fournis). Les points **non vérifiables** (comportement d'exécution, données en base réelle) sont explicitement marqués `⚠️ non vérifié à l'exécution`.

Points d'entrée du code explorés :

| Composant | Fichiers lus |
|---|---|
| Frontend — découverte | `lib/presentation/pages/discovery/discovery_page.dart`, `lib/presentation/blocs/discovery/discovery_bloc.dart`, `lib/presentation/widgets/cards/swipe_card.dart` |
| Frontend — données | `lib/data/datasources/remote/matching_api.dart`, `lib/data/datasources/remote/subscriptions_api.dart`, `lib/data/datasources/remote/profile_api.dart`, `lib/data/repositories/match_repository_impl.dart`, `lib/data/repositories/premium_repository_impl.dart` |
| Frontend — domain | `lib/domain/usecases/match/super_like_profile.dart`, `lib/domain/entities/match.dart`, `lib/domain/entities/premium.dart`, `lib/domain/entities/interaction_history.dart`, `lib/domain/entities/app_notification.dart` |
| Frontend — réception | `lib/presentation/pages/likes_received/likes_received_page.dart`, `lib/presentation/blocs/matches/matches_bloc.dart`, `lib/presentation/pages/interaction_history/{my_likes_page,stats_page}.dart`, `lib/presentation/widgets/notifications/notification_card.dart`, `lib/presentation/pages/notifications/notifications_page.dart`, `lib/data/services/notification_service.dart` |
| Backend — discovery/matching | `matching/views_discovery.py`, `matching/services.py`, `matching/daily_likes_service.py`, `matching/models.py`, `matching/serializers.py`, `matching/signals.py`, `matching/interaction_service.py`, `matching/urls_discovery.py`, `matching/urls.py`, `matching/urls/matches.py` |
| Backend — premium | `subscriptions/utils.py`, `subscriptions/models.py`, `subscriptions/services.py`, `subscriptions/urls.py`, `subscriptions/management/commands/init_subscription_plans.py` |
| Backend — profils/notifs | `profiles/views_premium.py`, `profiles/urls.py`, `profiles/serializers.py`, `notifications/models.py` |
| Backend — infra | `hivmeet_backend/api_urls.py`, `hivmeet_backend/urls.py`, `hivmeet_backend/security.py` |
| Specs projet | `docs/Document de Spécification Interface - HIVMeet.txt`, `docs/Description Détaillé des Écrans et Navigation -HIVMeet.txt`, `docs/Spécifications Fonctionnelles Frontend - HIVMeet.txt`, `API_DOCUMENTATION.md` |

---

## 1. Résumé exécutif

Le Super Like **existe** et fonctionne techniquement de bout en bout sur le chemin nominal : bouton étoile → `POST /api/v1/discovery/interactions/superlike` → création d'un `Like(like_type='super')` + `InteractionHistory(super_like)` → notification distincte (`type='super_like'`) → affichage spécifique dans l'historique et les notifications de l'émetteur.

**Mais** le Super Like actuel n'est qu'un **« like premium étiqueté »** : il n'apporte **aucun des avantages fonctionnels** qu'un Super Like doit procurer.

| Attente produit | Implémenté ? | Preuve |
|---|---|---|
| Remonter l'émetteur dans le deck du destinataire | ❌ **Non** | Tri backend = boost/vérif/complétude uniquement — `matching/services.py:239-262` |
| Distinguer visuellement le super like reçu dans la liste des likes | ❌ **Non** | `profiles/serializers.py:PublicProfileSerializer` ne renvoie pas le type ; `profiles/views_premium.py:42-64` mélange tout |
| Endpoint dédié super likes reçus exploité par l'UI | ❌ **Non** | `lib/data/datasources/remote/profile_api.dart:138` défini, **jamais appelé** |
| Compteur de super likes restants visible avant l'erreur | ❌ **Non** | Aucun widget ; `discovery_bloc.dart` n'expose pas le quota super like |
| Quota = source de vérité unique | ❌ **Non** | 2 sources divergentes (historique vs compteur d'abonnement) |
| Upgrade d'un like existant en super like | ❌ **Non** | `matching/services.py:379-403` : retour idempotent sans promotion |
| Message d'erreur adapté en cas de quota épuisé | ❌ **Non** | Branches de code mortes — `discovery_bloc.dart:330-350` vs backend |
| Traçabilité « match issu d'un super like » persistée | ❌ **Non** | `matched_with_superlike` n'existe que dans la réponse HTTP, jamais stocké |
| Chemin premium `use-super-like` | ❌ **Cassé** | Route absente de `subscriptions/urls.py` → **404** |

**Conclusion** : la fonctionnalité est **fonctionnelle mais vidée de sa valeur**. La suite de ce rapport donne le correctif complet.

---

## PARTIE A — Ce qu'un Super Like DOIT être (cible normative)

### A.1 Définition

Un **Super Like** est une **interaction premium à quota dédié** qui se distingue d'un like classique sur **trois axes obligatoires** :

1. **Priorité de visibilité** — le profil de l'émetteur est mis en avant dans le deck de découverte du destinataire.
2. **Signal explicite** — le destinataire reçoit un signal non ambigu (notification, badge, section dédiée), distinct d'un like.
3. **Traçabilité** — le type `super_like` est persisté, propagé dans tous les contrats et restitué dans l'UI des deux côtés (émetteur et destinataire), y compris après rechargement.

Un Super Like qui ne remplit pas les axes 1 et 2 **n'est pas un Super Like** : c'est un like payant. C'est exactement l'état actuel (section B), et c'est pourquoi le libellé d'upsell actuel est trompeur (section C.5).

### A.2 Parcours attendu — émetteur

1. L'utilisateur premium voit le bouton étoile **avec un compteur** (`X Super Likes restants aujourd'hui`).
2. S'il n'est pas premium → le bouton est verrouillé, un dialogue d'upsell explique **le bénéfice concret** (pas seulement « vous démarquer »).
3. Si premium et quota > 0 → le super like part ; le compteur décrémente **immédiatement** (optimistic UI) puis est réconcilié avec la valeur serveur.
4. Si quota = 0 → le bouton est **désactivé** avec l'heure de réinitialisation affichée (pas d'appel réseau inutile).
5. En cas de match → écran de match avec message **spécifique** super like.
6. L'interaction apparaît dans l'historique avec un **badge « Super Like »** (étoile) et est comptée dans les statistiques.
7. Révocation : un super like **non converti en match actif** est révocable ; après révocation le quota n'est **pas** restitué (aligné sur la règle actuelle des swipes, `daily_likes_service.py:104-107`).

### A.3 Parcours attendu — destinataire

1. Notification **distincte** (`type='super_like'`, étoile ambre) avec titre explicite.
2. **Premium** : le destinataire voit **qui** l'a super liké, dans une **section dédiée** (ou un badge dans la liste des likes) et peut interagir directement.
3. **Non-premium** : le destinataire **sait qu'il a reçu un super like** (compteur + libellé explicite) mais **ne voit pas l'identité** → upsell. Cela suppose que le compteur de super likes reçus soit **exposé sans l'identité** (contrainte : ne jamais fuiter l'identité hors premium).
4. Dans le deck de découverte, le profil qui a super liké apparaît **en tête** (ou avec un badge « vous a Super Liké ») — c'est l'avantage n°1.

### A.4 Avantages normalement procurés à l'utilisateur

| # | Avantage (émetteur) | Nature | Comment le garantir |
|---|---|---|---|
| 1 | **Multiplier les chances de match** en étant vu en priorité | Algorithme | Annotation de tri `has_super_liked_me` avant `is_boosted` / `last_active` |
| 2 | **Attirer l'attention** du destinataire | Notification + UI | Notification dédiée + badge étoile + section dédiée |
| 3 | **Signaler une intention forte** (crédibilité) | Produit | Type persisté, restitué côté destinataire (badge « vous a Super Liké ») |
| 4 | **Mesurer l'efficacité** de son super like | Données | Statistiques : super likes envoyés, taux de match des super likes vs likes |
| 5 | **Contrôle** (savoir ce qu'il reste, quand ça reset) | UX | Compteur + `reset_at` + bouton désactivé |

| # | Avantage (destinataire) | Nature | Comment le garantir |
|---|---|---|---|
| 6 | **Voir qui est vraiment intéressé** sans ambiguïté | Premium | `/super-likes-received/` exploité par l'UI |
| 7 | **Prioriser ses réponses** aux intentions les plus fortes | UX | Section/tri dédié dans la liste des likes |
| 8 | **Savoir qu'il a un super like en attente** même sans premium | Monétisation honnête | Compteur de super likes reçus exposé, identité masquée |

### A.5 Règles métier cibles

| Règle | Valeur cible | Justification |
|---|---|---|
| Accès | Premium uniquement (aucun super like gratuit) | Aligné backend actuel (`FREE_DAILY_SUPER_LIKES_LIMIT = 0`) |
| Quota premium | **Piloté par `SubscriptionPlan.daily_super_likes_count`** (actuellement 5) | Le quota doit être **donnée de plan**, pas constante en dur |
| Reset | **Minuit UTC**, `reset_at` renvoyé par l'API | Aligné `DailyLikesService.get_next_reset_time()` |
| Consommation | 1 super like = 1 unité du quota super like **et** 1 unité du quota de swipes partagé (premium = illimité de toute façon) | Cohérence du compteur de swipes |
| Idempotence | Un super like sur un profil déjà liké (like régulier) → **promotion** du like en super like, consommation du quota, réponse `upgraded: true`. Sur un super like déjà envoyé → no-op succès sans re-consommation | Empêche la perte silencieuse |
| Rate limiting | Cohérent avec le quota : le rate limit horaire ne doit pas être plus restrictif que le quota utile, ou doit renvoyer `Retry-After` | Éviter les 429 incompréhensibles |
| Révocation | Super like révocable si pas de match actif ; quota non restitué | Aligné existant |
| Persistance de l'origine | `Match` doit porter `origin` (`like` \| `super_like`) | Permet l'analytics et l'UI post-rechargement |
| Confidentialité | Identité de l'émetteur **jamais** renvoyée à un destinataire non-premium ; jamais de donnée de santé dans les payloads de découverte | Règles projet |

### A.6 Contrats API cibles (normatifs)

Ces contrats sont **la référence** ; toute implémentation doit s'y conformer.

#### A.6.1 Envoyer un super like

`POST /api/v1/discovery/interactions/superlike`
Corps : `{ "target_user_id": "<uuid>" }`
Auth : Bearer.

**201 Created** — envoyé, pas de match :
```json
{
  "status": "superliked",
  "upgraded": false,
  "daily_likes_remaining": 10,
  "super_likes_remaining": 4,
  "super_likes_limit": 5,
  "super_likes_reset_at": "2026-09-22T00:00:00Z",
  "message": "Super like envoyé avec succès"
}
```

**200 OK** — envoyé **et** match :
```json
{
  "status": "matched_with_superlike",
  "match_id": "<uuid>",
  "matched_user_info": { "user_id": "<uuid>", "display_name": "...", "main_photo_url": "..." },
  "super_likes_remaining": 4,
  "super_likes_limit": 5,
  "super_likes_reset_at": "2026-09-22T00:00:00Z"
}
```

**Erreurs** (le champ `code` est **la** clé de branchement côté client ; `error` reste un booléen) :

| HTTP | `code` | Cas |
|---|---|---|
| 403 | `premium_required` | Utilisateur non premium |
| 403 | `no_active_subscription` | Premium expiré / abonnement inactif |
| 429 | `super_like_limit` | Quota super like épuisé (`super_likes_reset_at` inclus) |
| 429 | `daily_limit` | Quota de swipes épuisé |
| 404 | — | `target_user_id` inexistant |
| 409 | `already_interacted` | Dislike existant ou cible invalide (self/blocked) |

#### A.6.2 Statut des quotas

`GET /api/v1/discovery/interactions/status` doit renvoyer :
```json
{
  "daily_likes_remaining": 10,
  "daily_likes_limit": 10,
  "super_likes_remaining": 4,
  "super_likes_limit": 5,
  "super_likes_reset_at": "2026-09-22T00:00:00Z",
  "is_premium": true
}
```
*(Déjà renvoyé aujourd'hui par `DailyLikesService.get_status_summary` — `matching/daily_likes_service.py:355-380` — sauf `super_likes_reset_at` qui doit être ajouté nommément.)*

#### A.6.3 Likes reçus (distinction du type)

`GET /api/v1/user-profiles/likes-received/` — chaque item doit exposer :
```json
{
  "id": "<profile uuid>", "display_name": "...", "age": 34, "photos": [...],
  "interaction_type": "like" | "super_like",
  "is_super_like": true,
  "liked_at": "2026-09-20T18:12:00Z"
}
```
Un paramètre optionnel `?interaction_type=super_like` permet le filtrage.

`GET /api/v1/user-profiles/super-likes-received/` (premium) — liste dédiée, même forme. Un **compteur non-premium** doit aussi être disponible (endpoint séparé ou champ dans `premium-status`) pour alimenter l'upsell sans exposer l'identité.

#### A.6.4 Découverte (badge « vous a Super Liké »)

Dans `GET /api/v1/discovery/profiles`, chaque profil doit exposer :
```json
{ "user_id": "...", "has_super_liked_me": true, "has_liked_you": true }
```
`has_liked_you` / `has_super_liked_me` restent `null` pour un utilisateur non-premium (pas de fuite).

#### A.6.5 Matches

`GET /api/v1/matches/` doit exposer l'origine :
```json
{ "id": "<uuid>", "matched_user": {...}, "origin": "super_like", "created_at": "..." }
```

---

## PARTIE B — État actuel constaté

### B.1 Frontend — chaîne nominale (fonctionnelle)

```
[Étoile] discovery_page.dart:316-345
   └─ si !isPremium → _showPremiumSuperLikeDialog()  (discovery_page.dart:484-513) — i18n OK
   └─ sinon → SwipeCard.triggerSwipe(SwipeDirection.up)   (swipe_card.dart:125-165)
        └─ animation dédiée : _superLikeAnimController / fade + glow + scale (swipe_card.dart:64-118)
   └─ DiscoveryBloc.on<SwipeProfile> → case SwipeDirection.up (discovery_bloc.dart:318-360)
        └─ SuperLikeProfileParams → SuperLikeProfile usecase
             └─ MatchRepositoryImpl.superLikeProfile (match_repository_impl.dart:127-145)
                  └─ MatchingApi.superLikeProfile → POST /discovery/interactions/superlike (matching_api.dart:103-112)
                       └─ isMatch = (status == 'matched_with_superlike')
```

Détails utiles :

- `lib/core/config/constants.dart:110-111` : `superLikesPerDay = 1`, `premiumSuperLikesPerDay = 5` — **`superLikesPerDay` ne correspond à aucune règle backend** (gratuit = 0). ⚠️ Ces constantes ne sont **référencées nulle part** dans `lib/` (vérifié par recherche) → impact fonctionnel nul mais documentation trompeuse.
- `lib/presentation/widgets/cards/swipe_card.dart:36-118` : animations dédiées super like (`_superLikeFadeAnimation`, `_superLikeGlowAnimation`, `_superLikeScaleAnimation`, `_isSuperLikeAnimating`) → l'effet visuel « spécial » demandé par les specs existe (`docs/Spécifications Fonctionnelles Frontend - HIVMeet.txt:181`).
- Gestion d'erreur `discovery_bloc.dart:322-356` : messages **hardcodés en français**, avec des tests de sous-chaîne qui ne correspondent pas au backend :
  - `failure.message.contains('no_active_subscription')` → le backend renvoie un **message traduit**, jamais ce code dans `message` ; le code est dans `response.data['code']`.
  - `failure.message.contains('no_super_likes_remaining')` → **jamais renvoyé** par `views_discovery.superlike_profile` (le backend renvoie `code = 'super_like_limit'`).
  - `_isRateLimitFailure` (`discovery_bloc.dart:73-77`) ne détecte `'rate_limited'` (code produit uniquement pour HTTP 429 **dans le repository** — `match_repository_impl.dart:_failureFromDio`) ; or le backend super like renvoie `code='super_like_limit'` → **pas** reconnu comme limite.
- `_emitDailyLimitIfNeeded` (`discovery_bloc.dart:79-97`) ne se déclenche que sur `code == 'daily_limit'` → le quota **super like** n'a **aucun** traitement dédié (ni état, ni UI, ni i18n).
- `_failureFromDio` (dans `match_repository_impl.dart`) teste `data['error'] == 'premium_required'` ; le backend renvoie `'error': true` (booléen) et `'code': 'premium_required'` → **`PremiumRequiredFailure` n'est jamais produit pour le super like**.

### B.2 Frontend — chemin premium parallèle (mort)

| Élément | Fichier:ligne | Statut |
|---|---|---|
| `SubscriptionsApi.useSuperLike` → `POST /subscriptions/use-super-like` | `lib/data/datasources/remote/subscriptions_api.dart:74-82` | **Route inexistante au backend** → 404 |
| `PremiumRepositoryImpl.useSuperLike` | `lib/data/repositories/premium_repository_impl.dart:279-297` | Lit `data['success'] as bool` et `data['super_likes_remaining'] as int` **non nullables** → exception si clé absente |
| `PremiumRepository.useSuperLike` (interface) | `lib/domain/repositories/premium_repository.dart:53` | Déclaré |
| `PremiumBloc._onUseSuperLike` | `lib/presentation/blocs/premium/premium_bloc.dart:335-347` | Gestionnaire enregistré (`premium_bloc.dart:44`) |
| `UseSuperLike` event | `lib/presentation/blocs/premium/premium_event.dart:48-52` | **Jamais dispatché** depuis l'UI (vérifié : seul le `on<>` l'utilise) |
| `SuperLikeUsed` state | `lib/presentation/blocs/premium/premium_state.dart:150` | **Jamais émis** en pratique |

Même constat pour `useBoost()`, `getPremiumStats()`, `getFeaturesUsage()`, `getAvailableFeatures()` : les routes `POST /subscriptions/use-boost`, `GET /subscriptions/premium-stats`, `GET /subscriptions/features-usage`, `GET /subscriptions/available-features` **sont absentes** de `subscriptions/urls.py` (liste complète : `plans/`, `payment-capabilities/`, `current/`, `purchase/`, `payments/<uuid>/`, `payment-return/*`, `current/cancel/`, `current/reactivate/`, `current/modify/`).
→ **Conséquence** : `premium_repository_impl.dart` contient un bloc de méthodes mortes, dont `useSuperLike`. Le seul chemin réellement utilisé est `/discovery/interactions/superlike`.

### B.3 Frontend — réception du super like

| Fonction | Implémentation | Preuve |
|---|---|---|
| Notification in-app | Type `super_like` → `AppNotificationType.superLike` | `lib/domain/entities/app_notification.dart:7,102-110` |
| Icône | Étoile ambre (`Icons.star`, `Colors.amber`) | `lib/presentation/widgets/notifications/notification_card.dart:105-108` |
| Titre/corps | **Fournis par le backend** (`notification.title` / `notification.body`) | `notification_card.dart:53-65` |
| Navigation au tap | `from_user_id` non vide (premium) → `/profile/<id>` ; vide (non-premium) → `/likes-received` (upsell) | `lib/presentation/pages/notifications/notifications_page.dart:136-145` |
| Temps réel WS | `RealtimeEventType.superLikeReceived` | `lib/core/realtime/realtime_event.dart:13`, `realtime_event_bus.dart:100`, `lib/core/services/notification_websocket_service.dart:188`, `lib/data/services/notification_service.dart:351-353` |
| Popup supprimé si l'utilisateur est déjà sur `/notifications` ou `/likes-received` | `notification_service.dart:274-281` |
| BLoC notifications | `notifications_bloc.dart:397,471-475` (reconstruit `data['type'] = 'super_like'`) |
| Compteur « non lus » | `lib/presentation/blocs/unread/unread_cubit.dart:49` |
| **Liste des likes reçus** | Mélange likes + super likes **sans distinction** : `LikesReceivedPage` → `MatchesBloc.LoadLikesReceived` → `MatchRepositoryImpl.getLikesReceived` → `GET /user-profiles/likes-received/` → `PublicProfileSerializer` | `lib/presentation/pages/likes_received/likes_received_page.dart:82-127`, `lib/presentation/blocs/matches/matches_bloc.dart:179-196`, `lib/data/repositories/match_repository_impl.dart:263-292` |
| **Endpoint dédié existant mais inutilisé** | `ProfileApi.getSuperLikesReceived` → `GET /user-profiles/super-likes-received/` | `lib/data/datasources/remote/profile_api.dart:138-146` — **aucun appelant** |
| Historique émetteur | Badge étoile « Super Like » | `lib/presentation/pages/interaction_history/my_likes_page.dart:250-278` |
| Statistiques | `totalSuperLikes` (sous-titre « X Super Likes inclus ») | `lib/presentation/pages/interaction_history/stats_page.dart:100-108`, `lib/domain/entities/interaction_history.dart:96-112` |
| Mapping API → domaine | `'super_like'` → `InteractionType.superLike` | `lib/data/repositories/interaction_history_repository_impl.dart:259-261` |

### B.4 Frontend — i18n

| Clé | Valeur FR | Fichier |
|---|---|---|
| `discovery.super_like` | « Super Like » | `assets/translations/fr.json:36` |
| `notifications.new_super_like_title` | « Nouveau super like » | `assets/translations/fr.json:159` |
| `notifications.super_like_received` | « Quelqu'un vous a envoyé un super like » | `assets/translations/fr.json:160` |
| `premium.super_like_locked_title` | « Super Like Premium » | `assets/translations/fr.json:452` |
| `premium.super_like_locked_message` | « Passez à Premium pour envoyer des Super Likes **et vous démarquer**. » | `assets/translations/fr.json:453` |

**Manquant** : aucune clé pour « X Super Likes restants », « quota super like atteint », « réinitialisation dans … », « il vous a Super Liké », « match grâce à un Super Like ».

**Violations i18n constatées** :
- `discovery_bloc.dart:330-350` : 3 messages d'erreur en **français codé en dur** (« Vous devez avoir un abonnement actif… », « Vous n'avez plus de Super Likes disponibles aujourd'hui… », « Trop de requêtes… »).
- `lib/presentation/widgets/notifications/notification_card.dart:71` : `timeago.format(..., locale: 'fr')` **figé**.
- `lib/presentation/pages/interaction_history/stats_page.dart:104,117` et `my_likes_page.dart:268-272` : libellés FR en dur (« Total Likes », « $n Super Likes inclus »).
- `lib/data/repositories/premium_repository_impl.dart:369-377` : libellés premium FR en dur.
- Backend `matching/signals.py:237-244` : **corps et titres de notification en français codés en dur** (`'Quelqu'un vous a Super Liké ! Passez Premium pour voir qui'`), alors que le reste du backend utilise `gettext_lazy`.

### B.5 Backend — chaîne nominale

```
POST /api/v1/discovery/interactions/superlike
  └─ matching/urls_discovery.py:20-21  (2 alias : 'superlike' et 'super-like')
       └─ matching/views_discovery.py:269-380  superlike_profile()
            ├─ check_feature_availability(user,'super_like')          [subscriptions/utils.py:104-160]
            │    └─ si !available && reason != 'limit_reached' → 403 {error:true, code:'premium_required'}
            ├─ DailyLikesService.can_user_super_like(user)            [matching/daily_likes_service.py:324-334]
            │    └─ si false → 429 {error:true, code:'super_like_limit'}
            ├─ LikeActionSerializer (validation target_user_id)
            ├─ MatchingService.like_profile(is_super_like=True)       [matching/services.py:361-470]
            │    ├─ re-check check_feature_availability → code 'super_like_limit' | 'premium_required'
            │    ├─ Like existant ? → idempotent (pas de promotion)   [services.py:379-403]
            │    ├─ can_user_swipe (quota partagé)                    [services.py:411-415]
            │    ├─ can_user_super_like (quota dédié)                  [services.py:417-421]
            │    ├─ DailyLikeLimit.super_likes_count += 1 (legacy)     [services.py:424-429]
            │    ├─ Like.objects.create(like_type=SUPER)               [services.py:445-449]
            │    ├─ InteractionHistory.create_or_reactivate(SUPER_LIKE)[services.py:451-456]
            │    └─ like mutuel ? → Match.get_or_create(ACTIVE)        [services.py:458-490]
            └─ Réponses : 200 matched_with_superlike | 201 superliked  [views_discovery.py:352-380]

Effets de bord (signaux)
  like_type == SUPER → matching/signals.py:187-207  → consume_premium_feature(user,'super_like')
                                                      → subscription.super_likes_remaining -= 1
  Like créé (like ou super) → matching/signals.py:225-296
      ├─ Notification(type='super_like'|'like')  — titre/corps FR en dur
      ├─ from_user_id vide si le destinataire n'est pas premium
      └─ dispatch_group_event(f"user_{to_user.id}", {type, notification_id, from_user_id, like_id, is_super})
```

### B.6 Backend — quotas et sources de vérité

| Source | Fichier:ligne | Valeur / logique |
|---|---|---|
| Constante `FREE_DAILY_SUPER_LIKES_LIMIT` | `matching/daily_likes_service.py:33` | `0` |
| Constante `PREMIUM_DAILY_SUPER_LIKES_LIMIT` | `matching/daily_likes_service.py:34` | `5` |
| Comptage réel | `daily_likes_service.py:140-169` | `max(InteractionHistory(super_like, aujourd'hui), Like(super, aujourd'hui))` |
| Quota restant (canonique de fait) | `daily_likes_service.py:195-211` | `limit - sent`, borné `[0, limit]` |
| Reset | `daily_likes_service.py:341-350` | **minuit UTC** |
| **2e source** : compteur d'abonnement | `subscriptions/models.py:296-310` (`super_likes_remaining`), `default=0` |
| Initialisation | `subscriptions/management/commands/init_subscription_plans.py:47,78` | `daily_super_likes_count = 5` pour les deux plans semés |
| `reset_daily_counters` | `subscriptions/models.py:363-370` | `super_likes_remaining = plan.daily_super_likes_count` |
| Déclencheur de reset | `subscriptions/services.py:check_and_reset_counters` | `(now - last_super_likes_reset).days >= 1` → **≈24 h glissantes**, pas minuit |
| Consommation du compteur | `subscriptions/utils.py:162-215` `consume_premium_feature` → `Subscription.use_super_like()` (`models.py:381-386`) |
| Appel de consommation | `matching/signals.py:187-207` (signal `Like` + `like_type == SUPER`) |
| **Gating #1** | `subscriptions/utils.py:104-160` `check_feature_availability('super_like')` → lit `subscription.super_likes_remaining > 0` |
| **Gating #2** | `daily_likes_service.py:324-334` `can_user_super_like` → lit l'historique |

→ **Deux gatings indépendants** dans le **même** endpoint (`views_discovery.py:284-296`) : le #1 sur le compteur d'abonnement, le #2 sur l'historique. Si les deux divergent (reset, upgrade de plan, données historiques, super like créés hors API), l'un bloque l'autre avec un message incohérent.

### B.7 Backend — absence d'avantage de visibilité (preuve)

`matching/services.py:234-262` — tri du deck :
```python
).order_by(
    '-is_boosted',
    '-user__last_active',
    '-has_verified',
    '-profile_completeness',
    'user__date_joined'
).distinct()
```
Les seules annotations créées sont `is_boosted`, `has_verified`, `profile_completeness` (`services.py:239-258`). **Aucune référence à `Like` / `like_type` / super like reçu.** → Le Super Like n'a **aucun** effet sur l'ordre de découverte. Seul `Boost` (payant, distinct) procure un avantage de visibilité.

### B.8 Backend — code legacy cassé ou mort

| Élément | Fichier:ligne | Problème | Atteignable ? |
|---|---|---|---|
| `SendSuperLikeView` | `matching/views_premium.py:82-156` | Utilise `Like.objects.filter(user=…, target_user=…)` puis `Like.objects.create(user=…, target_user=…, is_like=…, is_super_like=…)` — champs **inexistants** (`Like` expose `from_user`, `to_user`, `like_type` — `matching/models.py:15-60`). Idem `LikeSerializer.target_user_id` (`serializers.py:20-28`, `source='target_user.id'`). | **Non** : le routeur `matching/urls.py` qui le déclare (`urls.py:22`) **n'est inclus nulle part**. `hivmeet_backend/api_urls.py` ne monte que `matching.urls.discovery` et `matching.urls.matches`. → code mort qui masque un bug 500 |
| `matching/urls.py` | `matching/urls.py` (tout le fichier) | Redéclare `discovery/`, `like/`, `rewind/`, `boost/`, `likes-received/`, `get_matches` — doublons du routeur réellement monté. **De plus, ce fichier est masqué par le paquet `matching/urls/`** (`matching/urls/__init__.py` existe) : en Python 3 le paquet prime sur le module, donc `matching.urls` résout vers le package et `matching/urls.py` n'est **jamais** importé | **Non monté et non importable** |
| `RecommendedProfileSerializer` | `matching/serializers.py:62-130` | `get_has_liked_you` utilise `Like.objects.filter(user=…, target_user=…)` → champs inexistants. Expose aussi `hiv_status` (`serializers.py:78`) | Non : aucune instanciation trouvée dans les vues (le serializer utilisé est `DiscoveryProfileSerializer`) |
| `LikeSerializer` | `matching/serializers.py:17-28` | `target_user_id` → `source='target_user.id'` **inexistant** (`Like` a `from_user`/`to_user`). Vérifié : **aucune autre occurrence** de `LikeSerializer` dans tout le backend (hors sa définition) | Non référencé (dead code à 500 garanti) |
| `matching/tasks.py:56,84` | `is_super_like` paramètre | À vérifier lors de l'implémentation (utilisé par `send_like_notification`) | Oui (celery) |

### B.9 Backend — autres observations

- **Rate limiting** : `hivmeet_backend/security.py:32` → `'discovery/interactions/superlike': (10, 3600)` (10/heure) alors que le quota est de 5/jour : le rate limit est **inopérant comme garde-fou** et son message 429 est **indistinguable** du quota épuisé côté client (les deux renvoient 429).
- **Types de notifications** : `'super_like'` est bien déclaré dans `notifications/models.py:17` → la persistance est valide.
- **`profiles/urls.py:22`** : `path('super-likes-received/', SuperLikesReceivedView…)` existe et fonctionne (`profiles/views_premium.py:66-104`, premium-only, `premium_required_response()` sinon).
- **`profiles/views_premium.py:42-64` `LikesReceivedView`** : renvoie `PublicProfileSerializer` (+ `liked_at`) → **aucun champ indiquant le type d'interaction**. Un super like reçu est indiscernable d'un like.
- **`matching/services.py:379-403`** : si un `Like` existe déjà, la fonction retourne `True, is_match, None, None` **sans** consulter `is_super_like` → un super like sur un profil déjà liké **ne devient jamais un super like** (et ne consomme pas le quota : ni `DailyLikesService`, ni le compteur legacy, ni `Like.like_type`).
- **`matching/signals.py:231-244`** : le titre/corps de notification est en français codé en dur (`'Vous avez reçu un Super Like !'`, `'Quelqu\'un vous a Super Liké ! Passez Premium pour voir qui'`) — viole la règle i18n du projet (le reste utilise `gettext_lazy`).
- **Persistance de l'origine du match** : `Match` (`matching/models.py:132-190`) n'a pas de champ d'origine ; `matched_with_superlike` n'existe qu'au niveau de la réponse HTTP (`views_discovery.py:357`). Après rechargement (GET /matches), l'origine est **irrécupérable**.
- **Conformité doc** : `API_DOCUMENTATION.md:220-221` documente l'endpoint sans préciser les quotas/avantages ; `docs/Document de Spécification Interface - HIVMeet.txt:495-515` définit les statuts `superliked` / `matched_with_superlike` (respectés) et `403/429` (respectés).
- **Contradiction documentaire** : `docs/Description Détaillé des Écrans et Navigation -HIVMeet.txt:992` annonce « Super Likes (3/jour) » (onglet Premium) alors que le backend implémente **5/jour**. `docs/Plan de Développement…` non consulté ligne à ligne `⚠️ non vérifié`.

---

## PARTIE C — Écarts détaillés

Sévérités : **P0** = la fonctionnalité ne remplit pas sa promesse / casse ; **P1** = incohérence fonctionnelle ou contractuelle ; **P2** = dette technique / UX dégradée ; **P3** = finition.

### C.1 Écarts fonctionnels majeurs (P0)

| ID | Écart | Preuve | Impact utilisateur | Correctif attendu |
|---|---|---|---|---|
| **G1** | **Aucun avantage de visibilité** : le super like n'influence pas l'ordre du deck du destinataire | `matching/services.py:234-262` (tri sans `Like`) | L'utilisateur paie et n'obtient **aucun** des bénéfices annoncés | Ajouter l'annotation `has_super_liked_me` (super like actif reçu < N jours) et la placer **avant** `-is_boosted` dans `order_by` ; exposer le flag dans la sérialisation |
| **G2** | **Le destinataire ne peut pas distinguer un super like** d'un like dans la liste des likes reçus | `profiles/serializers.py:PublicProfileSerializer` (pas de champ type) ; `profiles/views_premium.py:42-64` | Le signal fort est noyé → l'avantage n°2/n°6 est nul | Exposer `interaction_type` / `is_super_like` dans la réponse ; trier les super likes en tête |
| **G3** | **Endpoint dédié jamais appelé** par l'app | `lib/data/datasources/remote/profile_api.dart:138-146` (défini, 0 appelant) vs `likes_received_page.dart:82-127` (appelle `/likes-received/`) | Un endpoint premium existe dans le vide | Câbler `getSuperLikesReceived` dans un onglet/section « Super Likes reçus », ou fusionner avec `likes-received` (au choix, un seul contrat) |

### C.2 Écarts de contrat (P0/P1)

| ID | Écart | Preuve | Impact | Correctif |
|---|---|---|---|---|
| **G4** | **`POST /subscriptions/use-super-like` inexistant** (404) : chemin premium mort | `lib/data/datasources/remote/subscriptions_api.dart:74-82` vs `subscriptions/urls.py` (route absente) | Code mort, risque de divergence, faux sentiment de dualité | **Supprimer** le chemin mort (`subscriptions_api.useSuperLike`, `premium_repository_impl.useSuperLike`, `PremiumBloc._onUseSuperLike`, event `UseSuperLike`, state `SuperLikeUsed`) — un seul chemin officiel : `/discovery/interactions/superlike` |
| **G5** | Idem pour `use-boost`, `premium-stats`, `features-usage`, `available-features` | `subscriptions/urls.py` | Méthodes mortes dans `premium_repository_impl.dart:279-395` | Même décision : supprimer ou implémenter (hors périmètre super like, à tracer) |
| **G6** | **Détection du 403 premium cassée** : le front lit `data['error']` attendu `== 'premium_required'`, le backend renvoie `error: true` + `code: 'premium_required'` | `match_repository_impl.dart:470-490` (`_failureFromDio`) vs `matching/views_discovery.py:284-291` | `PremiumRequiredFailure` jamais produit pour le super like → mauvaise UX | Lire `data['code']` en priorité |
| **G7** | **Codes d'erreur du quota non reconnus** : front teste `message.contains('no_super_likes_remaining')` / `'no_active_subscription'` ; backend renvoie `code='super_like_limit'` + message traduit | `discovery_bloc.dart:330-350` vs `views_discovery.py:293-300` (gating) et `329-345` (mapping) | Messages génériques, aucun affichage de l'heure de reset | Brancher sur `code` (`super_like_limit`, `daily_limit`, `premium_required`, `no_active_subscription`) et sur un champ `super_likes_reset_at` |
| **G8** | **Limite super like non traitée comme limite** : `_isRateLimitFailure` cherche `rate_limited`/`429`/`too many requests` | `discovery_bloc.dart:73-77` | Pas d'auto-dismiss / pas de message dédié | Ajouter `super_like_limit` à la détection et créer un état/message dédié |
| **G9** | `matched_with_superlike` **non persisté** | `views_discovery.py:357` (réponse seulement) ; `Match` sans champ d'origine (`matching/models.py:132-190`) | Après rechargement, l'origine du match est perdue ; analytics impossibles | Ajouter `Match.origin` (choices `like`/`super_like`) + l'exposer dans les sérialiseurs de match |
| **G10** | Pas de **promotion** like → super like (idempotence silencieuse) | `matching/services.py:379-403` | Un acheteur premium qui a déjà liké **ne peut pas** super liker ; quota non consommé ; `Like.like_type` reste `regular` | Si `existing_like.like_type == REGULAR` et requête super like → `like_type = SUPER`, consommer le quota, `InteractionHistory` promu, réponse `upgraded: true` |
| **G11** | `super_likes_reset_at` absent de toutes les réponses super like | `views_discovery.py:352-380` (`get_status_summary` le calcule mais l'endpoint ne le renvoie pas) | Impossible d'informer l'utilisateur | Ajouter le champ aux réponses 201/200/429 |

### C.3 Cohérence des quotas (P1)

| ID | Écart | Preuve | Impact | Correctif |
|---|---|---|---|---|
| **G12** | **Double source de vérité** : gating #1 = `subscription.super_likes_remaining` (compteur), gating #2 = historique du jour | `subscriptions/utils.py:104-160` + `daily_likes_service.py:195-234` | Blocages/messages incohérents ; si le compteur est à 0 alors que l'historique dit 4, l'utilisateur est bloqué à tort (et inversement) | **Canonique = historique du jour** (`DailyLikesService`). `subscription.super_likes_remaining` devient un **miroir d'affichage**, recalculé (`limit - sent_today`) et **jamais décrémenté en aveugle** |
| **G13** | **Sémantiques de reset divergentes** : minuit UTC (canonique) vs `(now - last_reset).days >= 1` (≈24 h glissantes) | `daily_likes_service.py:341-350` vs `subscriptions/services.py:check_and_reset_counters` | Fenêtre de divergence quotidienne | Aligner le compteur miroir sur minuit UTC |
| **G14** | **Double consommation potentielle** : `consume_premium_feature` dans le signal + quota legacy `DailyLikeLimit.super_likes_count` + historique | `matching/signals.py:202` + `matching/services.py:424-429` + `daily_likes_service.py:140-169` | Si un signal échoue, incohérence silencieuse (« Could not synchronize… » loggé, non remonté) | Une seule écriture de quota ; les autres deviennent des miroirs idempotents |
| **G15** | Quota **en dur** (constante 5) au lieu d'être lu depuis le plan | `daily_likes_service.py:34` vs `SubscriptionPlan.daily_super_likes_count` (`subscriptions/models.py:119`, semé à 5) | Impossible de différencier les offres ; incohérence si un plan définit 10 | Lire le quota depuis le plan actif, fallback constante |
| **G16** | **Rate limit 10/h incohérent** avec le quota 5/jour, et 429 indistinguable | `hivmeet_backend/security.py:32` | 429 trompeur | Ajuster le rate limit ou renvoyer un `code` distinct + `Retry-After` |

### C.4 Documentation produit (P1)

| ID | Écart | Preuve |
|---|---|---|
| **G17** | Libellé d'upsell **promet un avantage non implémenté** : « et vous démarquer » | `assets/translations/fr.json:453` vs `matching/services.py:234-262` |
| **G18** | **Contradiction de quota** : docs « 3/jour » vs backend 5/jour | `docs/Description Détaillé des Écrans et Navigation -HIVMeet.txt:992` vs `daily_likes_service.py:34` |
| **G19** | **Constante frontend fausse** : `superLikesPerDay = 1` (gratuit), non utilisée | `lib/core/config/constants.dart:110` |
| **G20** | `API_DOCUMENTATION.md:220-221` : décrit le super like sans quotas, sans avantage, sans codes d'erreur | `API_DOCUMENTATION.md` |

### C.5 i18n & confidentialité (P1)

| ID | Écart | Preuve | Correctif |
|---|---|---|---|
| **G21** | Messages d'erreur super like **hardcodés FR** dans le BLoC | `discovery_bloc.dart:330-350` | Clés i18n + `LocalizationService.translate` |
| **G22** | Titres/corps de notification **hardcodés FR** côté backend | `matching/signals.py:237-244` | Le backend doit renvoyer un `type` + des **données structurées** (`is_super`, `from_user_id`, `like_id`) et laisser le client composer le texte, **ou** utiliser `gettext` avec la locale de l'utilisateur |
| **G23** | `timeago` figé en `locale: 'fr'` | `notification_card.dart:71` | Utiliser la locale active |
| **G24** | Libellés FR en dur dans stats / historique / features premium | `stats_page.dart:96-118`, `my_likes_page.dart:266-272`, `premium_repository_impl.dart:369-377` | Clés i18n |
| **G25** | ⚠️ **Confidentialité** : `hiv_status` exposé dans un serializer de découverte (`RecommendedProfileSerializer`, `matching/serializers.py:78`) ; identité du liker doit rester masquée hors premium | `matching/serializers.py:62-130`, `signals.py:231-244` | Retirer `hiv_status` de tout payload de découverte ; conserver la règle `from_user_id` vide si destinataire non premium |

### C.6 Code mort / bugs latents (P2)

| ID | Écart | Preuve | Risque |
|---|---|---|---|
| **G26** | `SendSuperLikeView` : champs `Like` inexistants (`user`, `target_user`, `is_like`, `is_super_like`) → **500 garanti** | `matching/views_premium.py:82-156` | Danger si la route est un jour montée |
| **G27** | `matching/urls.py` non monté (routeur fantôme, doublon) | `matching/urls.py` vs `hivmeet_backend/api_urls.py` | Confusion, faux positifs lors des audits |
| **G28** | `RecommendedProfileSerializer.get_has_liked_you` : champs inexistants | `matching/serializers.py:104-113` | 500 si instancié |
| **G29** | `LikeSerializer.target_user_id` : source inexistante | `matching/serializers.py:25` | 500 si sérialisé |
| **G30** | `PremiumRepositoryImpl.useSuperLike` : cast non nullable (`as bool`, `as int`) + ignore `data['code']` | `premium_repository_impl.dart:279-297` | Crash si la clé manque |
| **G31** | Aucun compteur super like dans l'UI découverte | `discovery_page.dart:316-345` (aucun compteur) | L'utilisateur découvre son quota par un 429 |
| **G32** | `_emitDailyLimitIfNeeded` ne couvre pas `super_like_limit` → pas d'état `DailyLimitReached` pour le super like | `discovery_bloc.dart:79-97` | UX incomplète |
| **G33** | `DiscoveryProfile` / `SwipeResult` ne portent pas `hasSuperLikedMe` ni l'origine du match | `lib/domain/entities/match.dart:290-400` | Impossible d'afficher le badge (section A.6.4) |

---

## PARTIE D — Plan d'implémentation

**Principe directeur** : un seul chemin officiel (`POST /api/v1/discovery/interactions/superlike`), une seule source de vérité de quota (historique du jour), et trois avantages concrets implémentés (priorité, signal, traçabilité).

> 📘 **Le code exact de chaque lot est dans `RAPPORT_SUPERLIKE_ANNEXE_IMPLEMENTATION.md`.** Correspondance :

| Lot (ce rapport) | Section de l'annexe | Fiche `BACKEND_*.md` à produire |
|---|---|---|
| D.1 — Quota source unique | `B-1` | `BACKEND_SUPERLIKE_QUOTA_SINGLE_SOURCE.md` |
| D.2 — Priorité de visibilité | `B-2` | `BACKEND_SUPERLIKE_PRIORITY_RANKING.md` |
| D.3 — Distinction reçue | `B-3` | `BACKEND_LIKES_RECEIVED_INTERACTION_TYPE.md` |
| D.4 — Idempotence/origine | `B-4` | `BACKEND_SUPERLIKE_UPGRADE_IDEMPOTENT.md` + `BACKEND_MATCH_ORIGIN_FIELD.md` |
| D.5 — Erreurs/rate limit | `B-5` | `BACKEND_SUPERLIKE_ERROR_CODES_CONTRACT.md` |
| (nettoyage) | `B-6` | `BACKEND_SUPERLIKE_LEGACY_CLEANUP.md` |
| D.6 — Compteur/quota/erreurs | `F-1`, `F-2`, `F-3` | — |
| D.7 — Réception | `F-4` | — |
| D.8 — Nettoyage chemin mort | `F-6` | — |
| D.9 — Match super like | `F-5` | — |
| D.10 — i18n | `F-7` | — |
| Migration/données | `B-1.6`, `B-4.3` | — |
| Checklist de preuve | Annexe Partie 3.1 | — |
| Décisions à acter | Annexe Partie 4 | — |
| Pièges connus | Annexe Partie 5 | — |

### D.1 Backend — Lot B1 : source de vérité unique du quota (P1)

**Objectif** : `check_feature_availability('super_like')` et `can_user_super_like` ne peuvent plus diverger.

1. `matching/daily_likes_service.py`
   - Ajouter `get_super_likes_limit(user)` : lit le plan actif (`user.subscription.plan.daily_super_likes_count`) si premium, sinon `FREE_DAILY_SUPER_LIKES_LIMIT`. Fallback sur `PREMIUM_DAILY_SUPER_LIKES_LIMIT`.
   - `get_super_likes_remaining` utilise `get_super_likes_limit`.
   - Ajouter `sync_subscription_super_like_counter(user)` : `subscription.super_likes_remaining = get_super_likes_remaining(user)` (miroir, jamais décrément).
2. `subscriptions/utils.py`
   - `check_feature_availability('super_like')` → déléguer à `DailyLikesService.get_super_likes_remaining(user) > 0` (ou appeler le miroir si on veut conserver les compteurs), avec `reason='limit_reached'` si 0.
   - Conserver `reason='premium_required'` si non premium.
3. `matching/signals.py:187-207`
   - Remplacer `consume_premium_feature(...)` par `sync_subscription_super_like_counter(user)` (idempotent, aucun décrément).
4. `subscriptions/services.py:check_and_reset_counters`
   - Aligner sur minuit UTC via `DailyLikesService.get_next_reset_time()` plutôt que `.days >= 1`.
5. `matching/services.py:417-429`
   - Conserver le compteur legacy `DailyLikeLimit.super_likes_count` uniquement comme statistique (ne pas le lire pour le gating).

**Tests** : utilisateur premium, 5 super likes envoyés → 6e = 429 `super_like_limit` ; compteur d'abonnement = 0 dans les deux sources ; reset à minuit UTC.

### D.2 Backend — Lot B2 : avantage de visibilité (P0, cœur de la valeur)

1. `matching/services.py` (`RecommendationService`)
   - Avant `order_by`, annoncer :
     ```python
     active_super_likes = Like.objects.filter(
         to_user=user, like_type=Like.SUPER,
         created_at__gte=timezone.now() - timedelta(days=SUPER_LIKE_PRIORITY_WINDOW_DAYS),
     ).values_list('from_user_id', flat=True)
     ```
   - Ajouter l'annotation :
     ```python
     has_super_liked_me=Case(
         When(user_id__in=active_super_likes, then=Value(1)),
         default=Value(0), output_field=IntegerField(),
     )
     ```
   - `order_by('-has_super_liked_me', '-is_boosted', '-user__last_active', '-has_verified', '-profile_completeness', 'user__date_joined')`
   - Constante documentée : `SUPER_LIKE_PRIORITY_WINDOW_DAYS = 7` (à valider produit).
2. `matching/serializers.py` (`DiscoveryProfileSerializer`)
   - Ajouter `has_super_liked_me = SerializerMethodField()`.
   - Premium uniquement → `True/False` ; non-premium → `None` (pas de fuite) ; aligner `has_liked_you` sur la **même** règle.
3. Documenter l'effet dans `API_DOCUMENTATION.md` (§ Découverte).

**Tests** : avec 3 profils A (super like reçu), B (boosté), C (normal) → A doit précéder B ; un non-premium ne reçoit pas `has_super_liked_me=true` (→ `null`).

### D.3 Backend — Lot B3 : distinction du super like reçu (P0)

1. `profiles/serializers.py` — nouveau `LikesReceivedItemSerializer` (ou extension de `PublicProfileSerializer`) exposant `interaction_type`, `is_super_like`, `liked_at` (déjà annoté par `Latest like timestamp`).
2. `profiles/views_premium.py:LikesReceivedView.get_queryset`
   - Annoter le type : sous-requête sur `Like.like_type` la plus récente par `from_user`.
   - Trier `-is_super_like`, `-liked_at`.
   - Paramètre optionnel `?interaction_type=super_like|like`.
3. `profiles/views_premium.py:SuperLikesReceivedView` — inchangé fonctionnellement, ajouter `is_super_like: true` constant pour l'uniformité de contrat.
4. Exposer un **compteur** de super likes reçus accessible aux non-premium (sans identité), p.ex. dans `GET /user-profiles/premium-status/` : `"super_likes_received_count": 3`. Alimente l'upsell « 3 personnes vous ont Super Liké ».

**Tests** : un super like + un like → la liste renvoie 2 items avec les bons types et le super like en tête ; non-premium → 403 sur la liste mais compteur disponible.

### D.4 Backend — Lot B4 : idempotence, promotion, origine du match (P1)

1. `matching/services.py:379-403` (branche `existing_like`)
   - Si `is_super_like and existing_like.like_type != Like.SUPER` :
     - vérifier `can_user_swipe` + `can_user_super_like` ;
     - `existing_like.like_type = Like.SUPER; save(update_fields=['like_type'])` ;
     - `InteractionHistory.create_or_reactivate(..., SUPER_LIKE)` ;
     - incrémenter le compteur legacy + synchroniser le miroir ;
     - retourner un flag `upgraded=True` (étendre la signature en tuple 5-éléments ou retourner un dataclass — **attention** : la signature actuelle `Tuple[bool,bool,Optional[str],Optional[str]]` est utilisée par 3 vues ; introduire un dataclass `LikeOutcome` et adapter `views_discovery.like_profile`, `dislike` non concerné, `views_premium`).
   - Si `existing_like.like_type == Like.SUPER` → no-op succès, **pas** de consommation.
2. `matching/models.py:132-190` (`Match`) — ajouter :
   ```python
   ORIGIN_LIKE = 'like'; ORIGIN_SUPER_LIKE = 'super_like'
   origin = models.CharField(max_length=16, choices=..., default=ORIGIN_LIKE, db_index=True)
   ```
   → **migration** obligatoire.
3. `matching/services.py:458-490` — passer `defaults={'status': Match.ACTIVE, 'origin': Match.ORIGIN_SUPER_LIKE if is_super_like else Match.ORIGIN_LIKE}` ; en cas de réactivation, mettre à jour `origin`.
4. `matching/serializers.py:MatchSerializer` — exposer `origin`.
5. `matching/views_premium.py:82-156` — **supprimer** `SendSuperLikeView` (doublon cassé) ou le réécrire avec les bons champs ; dans tous les cas retirer l'entrée de `matching/urls.py` et supprimer/supprimer l'inclusion fantôme de `matching/urls.py`.

**Tests** : like régulier puis super like → `upgraded=True`, `Like.like_type='super'`, quota −1, historique `super_like` ; super like sur super like → no-op sans consommation ; match → `origin='super_like'`.

### D.5 Backend — Lot B5 : erreurs, reset, rate limit (P1)

1. `matching/views_discovery.py:352-380` — ajouter `super_likes_limit` et `super_likes_reset_at` aux réponses 201/200 ; ajouter `super_likes_reset_at` à la réponse 429 (`super_like_limit`) ; ajouter `upgraded`.
2. Ajouter une réponse 409 explicite (`code='already_interacted'`) si un `Dislike` actif existe pour la cible.
3. `hivmeet_backend/security.py:32` — remplacer `(10, 3600)` par une valeur cohérente (p.ex. `(30, 3600)`) **et** faire renvoyer `code='rate_limited'` + `Retry-After` par le middleware pour distinguer du quota.
4. Aligner les codes d'erreur sur le tableau A.6.1 (une seule nomenclature).

### D.6 Frontend — Lot F1 : compteur, quota, erreurs (P1)

1. `lib/domain/entities/match.dart` — étendre `SwipeResult` avec `remainingSuperLikes` (déjà présent) + `superLikesLimit`, `superLikesResetAt`, `upgraded`.
2. `lib/data/repositories/match_repository_impl.dart:127-145` — mapper les nouveaux champs ; `getSuperLikesRemaining()` déjà présent (`:343`) à réutiliser.
3. `lib/presentation/blocs/discovery/discovery_bloc.dart`
   - Charger le quota super like au `LoadProfiles` (via `getInteractionStatus` ou `getSuperLikesRemaining`).
   - Nouvel état (ou champ dans `DiscoveryLoaded`) : `superLikesRemaining`, `superLikesLimit`, `superLikesResetAt`.
   - `_failureFromDio` / mapping : brancher sur `code` ∈ {`premium_required`, `no_active_subscription`, `super_like_limit`, `daily_limit`} ; ajouter `super_like_limit` à `_isRateLimitFailure` ; créer `SuperLikeLimitReached` (ou émettre `DailyLimitReached` avec un type).
   - Retirer les 3 messages FR hardcodés → clés i18n.
4. `lib/presentation/pages/discovery/discovery_page.dart:316-345`
   - Afficher le compteur (`discovery.super_likes_remaining`) au-dessus/à côté du bouton étoile.
   - `onPressed` : si premium && quota == 0 → afficher un dialogue « quota épuisé, réinitialisation à HH:mm » (i18n) au lieu d'appeler l'API.
5. `lib/core/config/constants.dart:110` — corriger `superLikesPerDay` (0) ou **supprimer** la constante si le quota vient du serveur (recommandé : supprimer pour éviter une 3e source de vérité).

### D.7 Frontend — Lot F2 : réception et distinction (P0)

1. `lib/domain/entities/match.dart` (ou `profile.dart`) — ajouter `interactionType` / `isSuperLike` au profil reçu.
2. `lib/data/datasources/remote/matching_api.dart:152-160` — conserver ; `match_repository_impl.getLikesReceived` — mapper `interaction_type`/`is_super_like`.
3. `lib/presentation/pages/likes_received/likes_received_page.dart` — badge étoile sur les cartes super like ; tri (le backend trie déjà) ; optionnel : onglets « Tous / Super Likes ».
4. Décider du sort de `ProfileApi.getSuperLikesReceived` (`lib/data/datasources/remote/profile_api.dart:138`) :
   - **Option A (recommandée)** : l'utiliser pour un onglet « Super Likes » (premium), et laisser `likes-received` tout afficher avec badges.
   - **Option B** : le supprimer et tout gérer via `likes-received` enrichi.
   Dans les deux cas, **aucun code mort ne doit rester**.
5. `lib/presentation/widgets/cards/swipe_card.dart` — badge « Vous a Super Liké » si `hasSuperLikedMe == true` (premium) ; sinon rien.
6. `lib/domain/entities/match.dart:290-400` — mapper `has_super_liked_me` depuis la découverte.

### D.8 Frontend — Lot F3 : nettoyage du chemin mort (P1)

Supprimer (ou implémenter si décision produit) :
- `lib/data/datasources/remote/subscriptions_api.dart:74-82` (`useSuperLike`) ;
- `lib/data/repositories/premium_repository_impl.dart:279-297` (`useSuperLike`) ;
- `lib/domain/repositories/premium_repository.dart:53` ;
- `lib/presentation/blocs/premium/premium_bloc.dart:44,335-347` ;
- `lib/presentation/blocs/premium/premium_event.dart:48-52` ;
- `lib/presentation/blocs/premium/premium_state.dart:150-160`.
Puis `flutter analyze` doit rester propre (aucun import orphelin).

### D.9 Frontend — Lot F4 : match « super like » (P2)

1. `discovery_bloc.dart:362-370` — `MatchFound` doit porter `isSuperLike` (dérivé de `status == 'matched_with_superlike'`).
2. `MatchFoundModal` — titre/message spécifiques (`discovery.match_from_super_like_title` / `_message`, FR/EN).
3. `lib/presentation/blocs/matches/*` — mapper `origin` du match (liste des matches) pour badge éventuel.

### D.10 i18n — clés à créer (FR + EN)

| Clé | FR | EN |
|---|---|---|
| `discovery.super_likes_remaining` | `{count} Super Likes restants` | `{count} Super Likes left` |
| `discovery.super_like_limit_reached_title` | `Super Likes épuisés` | `No Super Likes left` |
| `discovery.super_like_limit_reached_message` | `Vos Super Likes seront réinitialisés à {time}.` | `Your Super Likes reset at {time}.` |
| `discovery.super_like_requires_premium_title` | `Super Like Premium` | `Premium Super Like` |
| `discovery.super_like_requires_premium_message` | `Un Super Like place votre profil en tête de la file d'attente de la personne et lui envoie une notification dédiée.` | `A Super Like puts your profile at the top of their queue and sends a dedicated notification.` |
| `discovery.has_super_liked_you` | `Vous a Super Liké` | `Super Liked you` |
| `discovery.match_from_super_like_title` | `Match grâce à un Super Like !` | `Matched from a Super Like!` |
| `discovery.match_from_super_like_message` | `Votre Super Like a porté ses fruits.` | `Your Super Like paid off.` |
| `likes_received.super_likes_tab` | `Super Likes` | `Super Likes` |
| `likes_received.super_likes_count` | `{count} personnes vous ont Super Liké` | `{count} people Super Liked you` |
| `errors.rate_limited` | `Trop de requêtes, réessayez dans quelques secondes.` | `Too many requests, try again shortly.` |

Et remplacer les libellés FR en dur identifiés en C.5.

### D.11 Migration & données

1. `python manage.py makemigrations matching && migrate` pour `Match.origin`.
2. Backfill optionnel : `Match.origin='like'` par défaut (valeur par défaut déjà couvrante).
3. `sync_subscription_super_like_counter` : commande de rattrapage (`subscriptions/management/commands/sync_super_like_counters.py`) — optionnel mais recommandé si des compteurs sont déjà désynchronisés.

---

## PARTIE E — Validation & non-régression

### E.1 Matrice de tests backend

| Cas | Attendu |
|---|---|
| Non-premium → superlike | 403 `premium_required` |
| Premium, 5 déjà envoyés → 6e | 429 `super_like_limit` + `super_likes_reset_at` |
| Premium, quota 1 → envoi | 201 `superliked`, `super_likes_remaining: 0` |
| Cible inexistante | 404 |
| Cible = soi-même / bloquée | 409 `already_interacted` |
| Dislike actif existant sur la cible | 409 |
| Like régulier existant puis super like | 200/201 `upgraded: true`, `Like.like_type='super'`, quota −1 |
| Super like déjà envoyé | no-op succès, quota inchangé, `upgraded: false` |
| Super like → like mutuel | 200 `matched_with_superlike`, `Match.origin='super_like'` |
| Deck : A super liké / B boosté / C normal | A avant B avant C |
| Non-premium : `has_super_liked_me` | `null` |
| `likes-received` (premium) | super like en tête avec `is_super_like: true` |
| `likes-received` (non-premium) | 403 `premium_required` |
| Compteur super likes reçus (non-premium) | disponible sans identité |
| Reset à minuit UTC | quota restauré, miroir = quota du plan |
| Rate limit horaire | 429 `rate_limited` + `Retry-After`, distinct du quota |

### E.2 Matrice de tests frontend

| Cas | Attendu |
|---|---|
| Bloc `discovery_bloc` sur `super_like_limit` | état dédié, message i18n, auto-dismiss |
| `premium_required` (403, `code`) | `PremiumRequiredFailure` → dialogue d'upsell |
| Compteur visible (premium) | `X Super Likes restants` décrémente après envoi |
| Compteur à 0 | bouton désactivé + heure de reset, **aucun appel réseau** |
| Non-premium | dialogue d'upsell, aucun appel réseau |
| `SwipeResult.upgraded == true` | message « super like envoyé » (pas de doublon d'interaction) |
| Liste des likes reçus | badge étoile + super likes en premier |
| Badge « Vous a Super Liké » | visible si `hasSuperLikedMe == true` |
| Notifications | type `super_like`, icône étoile, tap → profil (premium) / upsell (non-premium) |
| Historique | badge « Super Like » + statistiques |

### E.3 Non-régression à vérifier explicitement

- Like / dislike : inchangés (le lot B4 modifie une signature partagée → vérifier `views_discovery.like_profile`, `dislike_profile`, `rewind`).
- Quota de swipes gratuit (10/jour) : la consommation partagée ne doit pas être doublée.
- Boost : le tri doit garder `-is_boosted` prioritaire **sauf** super like (ordre A.6 validé).
- Notifications : non-régression des types `like`, `new_match`, `new_message`.
- Premium/abonnement : `premium-status` et achat inchangés.
- `flutter analyze` propre, tests widget/BLoC existants verts (`test/data/repositories/match_repository_impl_filters_test.dart` couvre déjà `superLikeProfile`).

> ⚠️ **Pièges connus à lire avant de coder** : Annexe Partie 5 (12 pièges, dont `LikeOutcome.__iter__` obligatoire pour ne pas casser ~7 tests, et le shadowing de `matching/urls.py` par le paquet `matching/urls/`).

### E.4 Commandes

```powershell
# Frontend
flutter analyze
flutter test test/data/repositories/match_repository_impl_filters_test.dart
flutter test

# Backend
cd d:\Projets\HIVMeet\env\hivmeet_backend
python manage.py makemigrations matching
python manage.py migrate
python manage.py test matching profiles subscriptions
python test_super_like.py          # test manuel existant
```

---

## PARTIE F — Critères d'acceptation (Definition of Done)

La fonctionnalité Super Like est considérée **conforme** quand **tous** les points suivants sont vrais :

1. [ ] Un super like **modifie l'ordre du deck** du destinataire (annotation `has_super_liked_me`) — vérifiable par test.
2. [ ] Le destinataire **premium** voit une liste/section dédiée des super likes reçus ; le **non-premium** voit un compteur sans identité.
3. [ ] `likes-received` expose `interaction_type` / `is_super_like` et met les super likes en tête.
4. [ ] Un **seul** gating de quota (historique du jour) ; `subscription.super_likes_remaining` est un miroir recalculé ; reset = minuit UTC.
5. [ ] Le quota est lu depuis `SubscriptionPlan.daily_super_likes_count`.
6. [ ] `upgraded` (like → super like) fonctionne et consomme le quota.
7. [ ] `Match.origin` est persisté et exposé ; le frontend distingue un match issu d'un super like.
8. [ ] Les réponses super like incluent `super_likes_limit` et `super_likes_reset_at`.
9. [ ] Les codes d'erreur backend sont **stables et documentés** (`premium_required`, `no_active_subscription`, `super_like_limit`, `daily_limit`, `rate_limited`, `already_interacted`) et le client branche **sur `code`**, jamais sur le texte.
10. [ ] Compteur de super likes restants visible dans la découverte ; bouton désactivé à 0 avec heure de reset ; aucun appel réseau quand le quota est nul.
11. [ ] **Aucune** chaîne affichée en dur : tout passe par les ARB FR/EN (`fr.json`, `en.json`) ; clés listées en D.10.
12. [ ] Le libellé d'upsell décrit un **avantage réellement implémenté**.
13. [ ] Le chemin mort `useSuperLike` (frontend) est supprimé, ou l'endpoint backend est créé — aucun 404 résiduel.
14. [ ] `SendSuperLikeView`, `RecommendedProfileSerializer`, `LikeSerializer.target_user_id` et `matching/urls.py` sont supprimés ou corrigés ; plus aucun 500 latent.
15. [ ] `hiv_status` n'est exposé dans aucun payload de découverte ; identité du liker masquée hors premium.
16. [ ] Rate limit super like cohérent avec le quota, et 429 distinguable.
17. [ ] `API_DOCUMENTATION.md` mis à jour (quotas, avantages, codes d'erreur, champ `origin`, `has_super_liked_me`).
18. [ ] Les docs projet « 3/jour » vs 5/jour sont réconciliés (une seule valeur).
19. [ ] `flutter analyze` propre, tests backend + frontend verts, non-régression E.3 validée.

---

## PARTIE G — Fiches backend à créer (convention projet `BACKEND_*.md`)

Le **code exact** de chaque fiche est fourni dans la section homonyme de `RAPPORT_SUPERLIKE_ANNEXE_IMPLEMENTATION.md` (colonne de droite).

| Fichier à créer | Contenu |
|---|---|
| `BACKEND_SUPERLIKE_PRIORITY_RANKING.md` | Annotation `has_super_liked_me`, fenêtre de priorité, ordre de tri cible, exposition premium-only |
| `BACKEND_SUPERLIKE_QUOTA_SINGLE_SOURCE.md` | Canonique = historique, miroir d'abonnement, reset minuit UTC, quota lu depuis le plan |
| `BACKEND_LIKES_RECEIVED_INTERACTION_TYPE.md` | Ajout `interaction_type`/`is_super_like`, tri, filtre, compteur non-premium |
| `BACKEND_SUPERLIKE_UPGRADE_IDEMPOTENT.md` | Promotion like → super like, `LikeOutcome`/dataclass, impact signature partagée |
| `BACKEND_MATCH_ORIGIN_FIELD.md` | `Match.origin`, migration, sérialisation, backfill |
| `BACKEND_SUPERLIKE_ERROR_CODES_CONTRACT.md` | Table de codes, `super_likes_reset_at`, 409, `rate_limited` + `Retry-After` |
| `BACKEND_SUPERLIKE_LEGACY_CLEANUP.md` | `SendSuperLikeView`, `matching/urls.py`, `RecommendedProfileSerializer`, `LikeSerializer`, `hiv_status` |

---

## Annexe A — Cartographie rapide (super like)

### Frontend

| Concern | Fichier | Lignes |
|---|---|---|
| Bouton / gate premium | `lib/presentation/pages/discovery/discovery_page.dart` | 316-345, 484-513, 684-692 |
| Animation | `lib/presentation/widgets/cards/swipe_card.dart` | 36-118, 125-165 |
| Orchestration | `lib/presentation/blocs/discovery/discovery_bloc.dart` | 73-97, 318-370 |
| UseCase | `lib/domain/usecases/match/super_like_profile.dart` | 1-30 |
| Repository | `lib/data/repositories/match_repository_impl.dart` | 127-145, 263-292, 343 |
| API | `lib/data/datasources/remote/matching_api.dart` | 103-112, 152-160 |
| Chemin mort premium | `subscriptions_api.dart:74`, `premium_repository_impl.dart:279`, `premium_repository.dart:53`, `premium_bloc.dart:44,335`, `premium_event.dart:48`, `premium_state.dart:150` | — |
| Réception | `notification_card.dart:105-108`, `notifications_page.dart:136-145`, `app_notification.dart:102-110` | — |
| Likes reçus | `likes_received_page.dart:82-127`, `matches_bloc.dart:179-196`, `profile_api.dart:138` | — |
| Historique/stats | `my_likes_page.dart:250-278`, `stats_page.dart:96-118`, `interaction_history.dart:74-112` | — |
| Constantes | `lib/core/config/constants.dart` | 110-111 |
| i18n | `assets/translations/fr.json` / `en.json` | 36, 159-160, 452-453 |

### Backend

| Concern | Fichier | Lignes |
|---|---|---|
| Route | `matching/urls_discovery.py` | 20-21 |
| Vue | `matching/views_discovery.py` | 269-380 |
| Service | `matching/services.py` | 361-490 (tri : 234-262) |
| Quota | `matching/daily_likes_service.py` | 33-34, 140-211, 324-334, 341-350, 355-380 |
| Gating premium | `subscriptions/utils.py` | 104-160, 162-215 |
| Compteurs | `subscriptions/models.py` | 119, 296-310, 363-386 |
| Reset | `subscriptions/services.py` | `check_and_reset_counters` |
| Signaux | `matching/signals.py` | 187-207, 225-296 |
| Modèles | `matching/models.py` | 15-60, 132-190, 387, 434-440 |
| Likes reçus | `profiles/views_premium.py`, `profiles/urls.py:22`, `profiles/serializers.py` | 42-104 |
| Legacy cassé | `matching/views_premium.py:82-156`, `matching/urls.py` (masqué par le paquet `matching/urls/`), `matching/serializers.py:17-28, 62-130` | — |
| Rate limit | `hivmeet_backend/security.py` | 32 |

## Annexe B — Décisions ouvertes à trancher par le produit

1. **Fenêtre de priorité** d'un super like dans le deck : 7 jours ? jusqu'à interaction ? (impacte B2).
2. **Quota** : confirmer **5/jour** (backend) et corriger la doc « 3/jour », ou aligner le backend sur 3.
3. **Badge destinataire non-premium** : simple compteur (recommandé) ou notification « X personnes vous ont Super Liké ».
4. **Likes reçus** : onglets séparés (Option A) ou liste unifiée avec badges (Option B) — décider avant D.7.
5. **Chemin premium `/subscriptions/use-super-like`** : supprimer (recommandé) ou implémenter comme alias du chemin découverte.

---

**Fin du rapport.** Toute implémentation doit être validée contre la Partie F et tracée dans un des fichiers de la Partie G pour les changements backend.

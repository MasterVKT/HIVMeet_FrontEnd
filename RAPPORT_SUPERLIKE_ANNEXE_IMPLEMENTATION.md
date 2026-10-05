# Annexe — Guide d'implémentation complet Super Like (code prescriptif)

> **Document compagnon de** : `RAPPORT_SUPERLIKE_ECARTS_IMPLEMENTATION.md`
> **Objet** : fournir à l'agent IA implémenteur **le code exact à écrire**, lot par lot, avec les signatures, les diffs, l'ordre d'exécution, les impacts et les tests. Ce document est **autosuffisant** : il se lit de haut en bas sans revenir au rapport d'audit.
> **Règle** : toute modification qui touche un contrat API doit produire une fiche `BACKEND_*.md` conformément à `.claude/rules/`. Les noms de fichiers de fiches sont donnés au fil des lots.

---

## 0. Pré-vol

### 0.1 Arborescence des deux racines

| Rôle | Chemin |
|---|---|
| Frontend | `d:\Projets\HIVMeet\hivmeet` |
| Backend | `d:\Projets\HIVMeet\env\hivmeet_backend` |
| Carte projet | `d:\Projets\HIVMeet\hivmeet\.agents\project-map.json` (`peer_root` = `../../env/hivmeet_backend`) |

### 0.2 Règles projet à respecter (rappel non négociable)

1. **Clean Architecture** : `presentation` → `domain` (usecases) → `data` (repositories/datasources/apis). Aucun appel réseau hors `data/datasources`.
2. **BLoC/Cubit** : un état = une instance immuable ; pas de logique métier dans les widgets.
3. **i18n obligatoire** : toute chaîne affichée passe par `LocalizationService.translate` avec clés `assets/translations/fr.json` + `en.json`. Aucun français/anglais en dur dans le code.
4. **Confidentialité** : jamais d'identité de liker exposée à un non-premium ; jamais `hiv_status` dans un payload de découverte ; jamais de jeton/PII dans les logs.
5. **Un seul chemin API** par fonctionnalité : `POST /api/v1/discovery/interactions/superlike`.
6. **Ne pas écraser** les modifications non liées présentes dans le dépôt.

### 0.3 Ordre d'exécution obligatoire

```
Backend : B-1 (quota) → B-2 (priorité) → B-3 (réception) → B-4 (idempotence/origine) → B-5 (erreurs/rate limit) → B-6 (nettoyage)
Frontend : F-1 (contrat+repo) → F-2 (erreurs+état) → F-3 (UI quota) → F-4 (réception) → F-5 (match) → F-6 (nettoyage) → F-7 (i18n)
```

Chaque lot backend est **indépendamment déployable** si les contrats additifs sont respectés (nouvelles clés uniquement, pas de suppression de clé existante avant que le frontend ait migré).

### 0.4 Matrice de compatibilité ascendante à préserver

| Champ existant | Ne jamais retirer avant | Raison |
|---|---|---|
| `status` (`superliked` / `matched_with_superlike`) | fin de vie de l'API v1 | Utilisé par `match_repository_impl.dart:134` |
| `daily_likes_remaining` / `super_likes_remaining` | idem | Utilisé par `SwipeResult` |
| `error: true` (booléen) + `message` | idem | Utilisé par `_extractServerErrorMessage` |
| `type: 'super_like'` dans les notifications | idem | `AppNotificationType.superLike` |
| `from_user_id` (vide si non premium) | idem | Règle de confidentialité |

---

## PARTIE 1 — BACKEND

### B-1 — Source de vérité unique du quota

**Fiche à créer** : `BACKEND_SUPERLIKE_QUOTA_SINGLE_SOURCE.md`

#### B-1.1 `matching/daily_likes_service.py`

**Imports déjà présents** (`daily_likes_service.py:9-17`) : `timezone`, `timedelta`, `Like`, `InteractionHistory`, `has_active_premium`. **Ajouter** : `from django.db.models import Case, When, IntegerField` (si non présent ; actuellement `Count, Q` sont importés ligne 11).

**Ajouter** ces trois méthodes statiques dans `DailyLikesService`, **immédiatement après** `get_super_likes_remaining` (actuellement `daily_likes_service.py:195-211`) :

```python
    @staticmethod
    def get_super_likes_limit(user) -> int:
        """Return the user's super-like daily entitlement.

        Premium: read the plan (single source of truth with the purchase flow).
        Free: FREE_DAILY_SUPER_LIKES_LIMIT (0).
        Falls back to the constant when no plan is reachable.
        """
        if not DailyLikesService.is_premium_user(user):
            return DailyLikesService.FREE_DAILY_SUPER_LIKES_LIMIT

        try:
            plan = user.subscription.plan
            limit = getattr(plan, 'daily_super_likes_count', None)
            if isinstance(limit, int) and limit > 0:
                return limit
        except Exception:  # Subscription.DoesNotExist, missing related plan, ...
            pass

        return DailyLikesService.PREMIUM_DAILY_SUPER_LIKES_LIMIT

    @staticmethod
    def get_super_likes_reset_at():
        """Single owner of the super-like reset timestamp (midnight UTC)."""
        return DailyLikesService.get_next_reset_time()

    @staticmethod
    def sync_subscription_super_like_counter(user) -> None:
        """Mirror the canonical entitlement onto Subscription.super_likes_remaining.

        The canonical value is derived from today's InteractionHistory.
        This method must NEVER decrement the mirror: it recomputes it, so it is
        safe to call from any signal or view, as many times as needed.
        """
        try:
            subscription = user.subscription
        except Exception:
            return

        remaining = DailyLikesService.get_super_likes_remaining(user)
        if subscription.super_likes_remaining != remaining:
            subscription.super_likes_remaining = remaining
            subscription.save(update_fields=['super_likes_remaining'])
```

> ⚠️ **Ne pas se contenter de `subscription.save()`** : utiliser `update_fields` évite d'écraser des colonnes concurrentes.

**Remplacer** le corps de `get_super_likes_remaining` (`daily_likes_service.py:195-211`) par :

```python
    @staticmethod
    def get_super_likes_remaining(user) -> int:
        limit = DailyLikesService.get_super_likes_limit(user)
        sent = DailyLikesService.count_super_likes_today(user)
        remaining = limit - sent
        return max(0, min(remaining, limit))
```

**Ajouter** `super_likes_reset_at` au dict de `get_status_summary` (`daily_likes_service.py:355-380`), à côté de `super_likes_remaining` :

```python
            'super_likes_limit': DailyLikesService.get_super_likes_limit(user),
            'super_likes_reset_at': DailyLikesService.get_super_likes_reset_at().isoformat(),
            'super_likes_used_today': DailyLikesService.count_super_likes_today(user),
```

> Le dict contient déjà `super_likes_limit` calculé via la constante ; **remplacer** ce calcul par `get_super_likes_limit(user)` et **conserver `super_likes_limit`** dans le dict de sortie.

#### B-1.2 `subscriptions/utils.py`

**Modifier** `check_feature_availability` (`subscriptions/utils.py:104-160`) : la branche `super_like` de `feature_checks` (ligne 143 `'super_like': lambda s: s.super_likes_remaining > 0`) doit utiliser la source canonique. Remplacer la lambda par une fonction dédiée **définie juste avant** `feature_checks` :

```python
    def _super_like_available(subscription) -> bool:
        """Delegate to the canonical entitlement, not to the mirror counter."""
        from matching.daily_likes_service import DailyLikesService
        return DailyLikesService.get_super_likes_remaining(subscription.user) > 0

    feature_checks = {
        # ...existing entries...
        'super_like': _super_like_available,
        # ...existing entries...
    }
```

> L'import est fait **dans** la fonction pour éviter un cycle `subscriptions ↔ matching` (`matching/daily_likes_service.py:17` importe déjà `subscriptions.utils`).

**Conserver** la logique `reason` existante (`utils.py:147-156`) : `'limit_reached'` si `boost`/`super_like` indisponible par quota, sinon `'feature_not_included'`.

#### B-1.3 `matching/signals.py`

**Remplacer** le contenu de `handle_super_like_sent` (`signals.py:187-207`) par :

```python
@receiver(post_save, sender=Like)
def handle_super_like_sent(sender, instance, created, **kwargs):
    """Mirror the canonical super-like counter after a super like is stored.

    The canonical entitlement is derived from InteractionHistory; the
    Subscription counter is only a read-optimised mirror. Never decrement it
    here: recompute it, so a lost/replayed signal stays harmless.
    """
    if not created or instance.like_type != Like.SUPER:
        return

    from subscriptions.models import Subscription
    from .daily_likes_service import DailyLikesService

    try:
        instance.from_user.subscription
    except Subscription.DoesNotExist:
        return

    try:
        DailyLikesService.sync_subscription_super_like_counter(instance.from_user)
    except Exception:
        logger.warning("Could not synchronize the Premium super-like counter")
```

> **Retirer** l'import `consume_premium_feature` de cette fonction. Vérifier qu'il n'est pas utilisé ailleurs dans le fichier (il reste utilisé par `handle_boost_activation`, `signals.py:210-221` — le conserver dans cet autre récepteur).

#### B-1.4 `subscriptions/services.py`

Dans `PremiumFeatureService.check_and_reset_counters`, **remplacer** le test glissant (`(now - subscription.last_super_likes_reset).days >= 1`) par une comparaison de **jours calendaires UTC** :

```python
    @staticmethod
    def check_and_reset_counters(subscription):
        """Reset daily/monthly counters if the UTC calendar day changed."""
        from matching.daily_likes_service import DailyLikesService

        now = timezone.now()
        start_of_day = DailyLikesService.get_start_of_day()

        # Daily super likes: calendar-day comparison, not a rolling 24h window.
        if subscription.last_super_likes_reset < start_of_day:
            subscription.reset_daily_counters()

        # Monthly boosts (unchanged semantics)
        if subscription.plan.billing_interval == SubscriptionPlan.INTERVAL_MONTH:
            if (now - subscription.last_boosts_reset).days >= 30:
                subscription.reset_monthly_counters()
```

#### B-1.5 `matching/services.py`

Dans `like_profile`, la branche super like (`services.py:417-429`) met à jour le compteur legacy `DailyLikeLimit.super_likes_count`. **Le conserver** (statistique / dashboards admin) mais **ajouter un commentaire d'invariant** et un appel de synchronisation du miroir après création :

```python
            # Legacy dashboard counter: informational only, never read for gating.
            limit, created = DailyLikeLimit.objects.get_or_create(
                user=from_user, date=today
            )
            limit.super_likes_count += 1
            limit.save(update_fields=['super_likes_count'])
```

> Aucun autre changement dans ce lot pour `services.py` (le gating reste `can_user_swipe` + `can_user_super_like`, désormais adossés à `get_super_likes_limit`).

#### B-1.6 Migration de données (recommandée)

Créer `subscriptions/management/commands/sync_super_like_counters.py` :

```python
"""One-shot repair: realign the Subscription mirror with the canonical count."""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

from matching.daily_likes_service import DailyLikesService


class Command(BaseCommand):
    help = "Recompute Subscription.super_likes_remaining from InteractionHistory."

    def handle(self, *args, **options):
        User = get_user_model()
        fixed = 0
        for user in User.objects.filter(subscription__isnull=False).iterator():
            before = getattr(user.subscription, 'super_likes_remaining', None)
            DailyLikesService.sync_subscription_super_like_counter(user)
            user.subscription.refresh_from_db(fields=['super_likes_remaining'])
            if before != user.subscription.super_likes_remaining:
                fixed += 1
        self.stdout.write(self.style.SUCCESS(f"Counters realigned: {fixed}"))
```

#### B-1.7 Tests B-1

```python
# matching/tests_superlike_quota.py
from django.test import TestCase
from django.utils import timezone
from matching.daily_likes_service import DailyLikesService
from matching.services import MatchingService


class SuperLikeQuotaTests(TestCase):
    def test_free_user_has_zero_super_likes(self):
        self.assertEqual(DailyLikesService.get_super_likes_limit(self.free_user), 0)

    def test_premium_limit_comes_from_plan(self):
        self.plan.daily_super_likes_count = 7
        self.plan.save()
        self.assertEqual(DailyLikesService.get_super_likes_limit(self.premium_user), 7)

    def test_sixth_super_like_is_rejected(self):
        for target in self.five_targets:
            ok, _, _, code = MatchingService.like_profile(
                self.premium_user, target, is_super_like=True)
            self.assertTrue(ok, code)
        ok, _, msg, code = MatchingService.like_profile(
            self.premium_user, self.sixth_target, is_super_like=True)
        self.assertFalse(ok)
        self.assertEqual(code, 'super_like_limit')

    def test_mirror_never_decrements_below_canonical(self):
        DailyLikesService.sync_subscription_super_like_counter(self.premium_user)
        self.premium_user.subscription.refresh_from_db()
        self.assertEqual(
            self.premium_user.subscription.super_likes_remaining,
            DailyLikesService.get_super_likes_remaining(self.premium_user),
        )
```

**Tests existants impactés** : `matching/tests_discovery_filters.py:422-458` (assertions sur `FREE_DAILY_SUPER_LIKES_LIMIT` / premium 5) doivent rester verts — ils utilisent des plans semés à `daily_super_likes_count = 5`, ce qui correspond au nouveau comportement.

---

### B-2 — Avantage de visibilité (cœur de la valeur)

**Fiche à créer** : `BACKEND_SUPERLIKE_PRIORITY_RANKING.md`

#### B-2.1 Constante

Dans `matching/services.py`, **à côté des autres constantes de classe** (avant `RecommendationService`), ajouter :

```python
# A super like keeps priority while it is "fresh". Older ones fall back to the
# normal ranking so the deck does not fossilise around stale signals.
SUPER_LIKE_PRIORITY_WINDOW_DAYS = 7
```

#### B-2.2 Annotation dans `RecommendationService`

Dans `matching/services.py`, la méthode qui construit le queryset de découverte — **juste avant** `# Apply boost priority` (actuellement ligne 234) — insérer :

```python
        # Apply super-like priority: profiles that super liked *me* recently.
        # This is the core value of a Super Like: it buys queue position.
        super_like_cutoff = timezone.now() - timedelta(
            days=SUPER_LIKE_PRIORITY_WINDOW_DAYS
        )
        super_likers = Like.objects.filter(
            to_user=user,
            like_type=Like.SUPER,
            created_at__gte=super_like_cutoff,
        ).values_list('from_user_id', flat=True)
```

Puis **modifier** le bloc `.annotate(...)` (lignes 239-258) pour ajouter `has_super_liked_me` en **première** position :

```python
        query = query.annotate(
            has_super_liked_me=Case(
                When(user_id__in=super_likers, then=Value(1)),
                default=Value(0),
                output_field=IntegerField(),
            ),
            is_boosted=Case(
                When(user_id__in=active_boosts, then=Value(1)),
                default=Value(0),
                output_field=IntegerField()
            ),
            # ...existing has_verified / profile_completeness annotations...
        ).order_by(
            '-has_super_liked_me',
            '-is_boosted',
            '-user__last_active',
            '-has_verified',
            '-profile_completeness',
            'user__date_joined'
        ).distinct()
```

**Justification de l'ordre** : `has_super_liked_me` **avant** `is_boosted` → le signal direct adressé à l'utilisateur prime sur un boost générique (payant mais non adressé). Si le produit tranche l'inverse, il suffit d'échanger les deux premières lignes : documenter la décision retenue dans la fiche.

> ⚠️ **`values_list(...).flat=True` évalué paresseusement** : Django le transformera en sous-requête. Vérifier avec `str(query.query)` qu'aucune requête N+1 n'est générée. En cas de volume important, remplacer par une sous-requête `Exists()` :
> ```python
> from django.db.models import Exists, OuterRef
> super_like_exists = Like.objects.filter(
>     to_user=user, from_user=OuterRef('user'), like_type=Like.SUPER,
>     created_at__gte=super_like_cutoff,
> )
> query = query.annotate(has_super_liked_me=Exists(super_like_exists))
> ```
> `Exists()` est **recommandé** et doit être privilégié. Adapter l'`order_by` : `'-has_super_liked_me'` fonctionne avec un booléen.

#### B-2.3 Exposer le flag dans la sérialisation

`DiscoveryProfileSerializer` (`matching/serializers.py:210-275`) est un `serializers.Serializer` (pas `ModelSerializer`) → ajouter explicitement le champ :

```python
class DiscoveryProfileSerializer(serializers.Serializer):
    # ...existing fields...
    has_super_liked_me = serializers.SerializerMethodField()
    has_liked_you = serializers.SerializerMethodField()

    def get_has_super_liked_me(self, obj):
        """Premium only: reveals whether this profile super liked the viewer.

        Returns None (not False) for non-premium users so the client can tell
        "unknown / upgrade to see" apart from "definitely no".
        """
        request = self.context.get('request')
        if not request or not request.user:
            return None
        from subscriptions.utils import is_premium_user
        if not is_premium_user(request.user):
            return None
        return bool(getattr(obj, 'has_super_liked_me', False))

    def get_has_liked_you(self, obj):
        request = self.context.get('request')
        if not request or not request.user:
            return None
        from subscriptions.utils import is_premium_user
        if not is_premium_user(request.user):
            return None
        from .models import Like
        return Like.objects.filter(
            from_user=obj.user, to_user=request.user
        ).exists()
```

> `get_has_liked_you` **ajouté ici** remplace l'implémentation cassée de `RecommendedProfileSerializer.get_has_liked_you` (`matching/serializers.py:104-113`, champs inexistants) — voir B-6.

#### B-2.4 Réponse de découverte

`matching/views_discovery.py:78-99` renvoie déjà `super_likes_remaining` mais pas le contexte complet. **Ajouter** dans le dict de réponse (après `'super_likes_remaining'`) :

```python
        'super_likes_limit': daily_likes_info.get('super_likes_limit'),
        'super_likes_reset_at': daily_likes_info.get('super_likes_reset_at'),
```

> ⚠️ La pagination actuelle (`views_discovery.py:83-89`) calcule `offset = (page - 1) * page_size` puis passe `limit`/`offset` au **service**. `count` = `len(profiles)` (taille de page, **pas** le total). C'est un défaut préexistant ; **ne pas** le corriger dans ce lot (hors périmètre), mais le **noter** dans la fiche.

#### B-2.5 Tests B-2

```python
class SuperLikeRankingTests(TestCase):
    def test_super_liker_ranks_first(self):
        # A super liked me 1h ago, B is boosted, C is plain.
        Like.objects.create(from_user=self.user_a, to_user=self.me, like_type=Like.SUPER)
        Boost.objects.create(user=self.user_b, is_active=True,
                             expires_at=timezone.now() + timedelta(hours=1))
        results = RecommendationService.get_recommendations(self.me, limit=10)
        ids = [p.user_id for p in results]
        self.assertEqual(ids[0], self.user_a.id)   # super like wins over boost
        self.assertEqual(ids[1], self.user_b.id)

    def test_old_super_like_no_longer_wins(self):
        old = Like.objects.create(from_user=self.user_a, to_user=self.me, like_type=Like.SUPER)
        Like.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - timedelta(days=30))
        results = RecommendationService.get_recommendations(self.me, limit=10)
        self.assertNotEqual(results[0].user_id, self.user_a.id)

    def test_non_premium_gets_null_not_false(self):
        data = DiscoveryProfileSerializer(
            self.profile_a, context={'request': self.free_request}).data
        self.assertIsNone(data['has_super_liked_me'])
```

---

### B-3 — Distinction du super like reçu

**Fiche à créer** : `BACKEND_LIKES_RECEIVED_INTERACTION_TYPE.md`

#### B-3.1 Nouveau serializer d'item

Dans `profiles/serializers.py`, **ajouter après** `PublicProfileSerializer` :

```python
class SuperLikeBadgeMixin(serializers.Serializer):
    """Adds the interaction type to a "who liked me" item.

    The `interaction_type` annotation is provided by the view queryset.
    """
    interaction_type = serializers.SerializerMethodField()
    is_super_like = serializers.SerializerMethodField()

    def get_interaction_type(self, obj):
        return getattr(obj, 'interaction_type', 'like') or 'like'

    def get_is_super_like(self, obj):
        return self.get_interaction_type(obj) == 'super_like'


class LikesReceivedItemSerializer(SuperLikeBadgeMixin, PublicProfileSerializer):
    """Public profile plus the like type, for LikesReceived / SuperLikesReceived."""
    class Meta(PublicProfileSerializer.Meta):
        fields = PublicProfileSerializer.Meta.fields + [
            'interaction_type', 'is_super_like',
        ]
```

> `PublicProfileSerializer.Meta.fields` contient déjà `liked_at` (`profiles/serializers.py`), ce qui évite un doublon.

#### B-3.2 Annoter le type dans la vue

`profiles/views_premium.py:32-64` (`LikesReceivedView`) : remplacer le calcul `latest_like` par une annotation qui porte **à la fois** la date et le type.

**Imports à ajouter** en tête de fichier : `from django.db.models import Case, When, IntegerField` (le fichier importe déjà `OuterRef, Subquery` ligne 7).

```python
    serializer_class = LikesReceivedItemSerializer

    def get_queryset(self):
        user = self.request.user
        if not is_premium_user(user):
            return Profile.objects.none()

        latest_like = Like.objects.filter(
            to_user=user, from_user=OuterRef('user'),
        ).order_by('-created_at').values('created_at')[:1]

        latest_type = Like.objects.filter(
            to_user=user, from_user=OuterRef('user'),
        ).order_by('-created_at').values('like_type')[:1]

        qs = (
            Profile.objects.filter(
                user__in=Like.objects.filter(to_user=user)
                .values_list('from_user', flat=True)
            )
            .select_related('user')
            .annotate(
                liked_at=Subquery(latest_like),
                interaction_type=Subquery(latest_type),
            )
            .order_by('-interaction_type', '-liked_at')
        )

        requested = self.request.query_params.get('interaction_type')
        if requested in ('like', 'super_like'):
            qs = qs.filter(interaction_type=requested)

        return qs
```

> ⚠️ **Vérification obligatoire** : `order_by('-interaction_type')` trie lexicalement `'super_like'` avant `'like'` — c'est **exactement** l'effet voulu (`s` > `l` sur la première lettre distinguante : `'super_like'` > `'like'`). Écrire un test qui l'affirme (`test_super_like_first`) ; si un jour la valeur change, migrer vers un `Case/When` explicite `super_like → 1, like → 0` trié `-super_first`.

#### B-3.3 Vue dédiée super likes

`profiles/views_premium.py:66-104` (`SuperLikesReceivedView`) : annoncer `interaction_type` pour garantir un contrat **uniforme** entre les deux listes (le client doit pouvoir traiter les deux endpoints avec le même code).

**Import à ajouter** dans `profiles/views_premium.py` : `from django.db.models import Value, CharField` (en plus de `Case/When/IntegerField` de B-3.2).

```python
    serializer_class = LikesReceivedItemSerializer

    def get_queryset(self):
        user = self.request.user
        if not is_premium_user(user):
            return Profile.objects.none()

        latest_super_like = Like.objects.filter(
            to_user=user, from_user=OuterRef('user'), like_type=Like.SUPER,
        ).order_by('-created_at').values('created_at')[:1]

        return (
            Profile.objects.filter(
                user__in=Like.objects.filter(
                    to_user=user, like_type=Like.SUPER,
                ).values_list('from_user', flat=True)
            )
            .select_related('user')
            .annotate(
                liked_at=Subquery(latest_super_like),
                interaction_type=Value('super_like', output_field=CharField()),
            )
            .order_by('-liked_at')
        )
```

#### B-3.4 Compteur accessible aux non-premium

Objectif : alimenter l'upsell « N personnes vous ont Super Liké » **sans** exposer d'identité.

Dans `profiles/views_premium.py` (`PremiumFeaturesStatusView`, `profiles/views_premium.py:106+`), ajouter au payload :

```python
        super_likes_received_count = Like.objects.filter(
            to_user=user, like_type=Like.SUPER
        ).count()
        # ...dans le dict de réponse...
        'super_likes_received_count': super_likes_received_count,
```

Et dans le sérialiseur de `matching/serializers.py` lié à `premium-status` s'il existe (`matching/serializers.py:160-185` expose `super_likes_remaining`) → ajouter le champ symétrique `super_likes_received_count = serializers.IntegerField()`.

> **Contrainte de confidentialité** : ce compteur ne doit **jamais** être accompagné d'un `from_user_id`, d'un nom ou d'une photo. Test dédié obligatoire.

#### B-3.5 Tests B-3

```python
class LikesReceivedTypingTests(TestCase):
    def test_super_like_listed_first_with_type(self):
        # one super like + one regular like received
        data = self.client.get('/api/v1/user-profiles/likes-received/').json()
        first = data['results'][0]
        self.assertEqual(first['interaction_type'], 'super_like')
        self.assertTrue(first['is_super_like'])

    def test_filter_by_interaction_type(self):
        data = self.client.get(
            '/api/v1/user-profiles/likes-received/?interaction_type=super_like'
        ).json()
        self.assertTrue(all(r['is_super_like'] for r in data['results']))

    def test_non_premium_gets_403_but_count_is_available(self):
        status = self.free_client.get('/api/v1/user-profiles/premium-status/').json()
        self.assertIn('super_likes_received_count', status)
        for key in ('from_user_id', 'display_name', 'photos'):
            self.assertNotIn(key, status)
```

---

### B-4 — Idempotence, promotion, origine du match

**Fiche à créer** : `BACKEND_SUPERLIKE_UPGRADE_IDEMPOTENT.md` (+ `BACKEND_MATCH_ORIGIN_FIELD.md`)

#### B-4.1 Résultat structuré (au lieu d'un tuple)

`MatchingService.like_profile` est appelé **2 fois en production** (`views_discovery.py:142` et `:322`) + 5 fois dans les tests. Le tuple à 4 éléments ne peut pas porter `upgraded` proprement. **Introduire un dataclass** dans `matching/services.py` :

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class LikeOutcome:
    """Result of a like/super-like attempt."""
    success: bool
    is_match: bool = False
    error_message: Optional[str] = None
    error_code: Optional[str] = None
    upgraded: bool = False          # regular like promoted to super like
    match_origin: Optional[str] = None
```

**Contrainte de compatibilité** : les tests existants déballent `success, is_match, error, code = MatchingService.like_profile(...)` (`matching/tests_discovery_filters.py:429,449,464`, `test_daily_swipe_quota.py:93,122,149`). Deux options :

- **Option retenue (moindre churn)** : `LikeOutcome` implémente `__iter__` pour rester déballable à 4 éléments :
  ```python
      def __iter__(self):
          return iter((self.success, self.is_match, self.error_message, self.error_code))
  ```
  → les tests legacy continuent de fonctionner sans modification.
- Option alternative : renvoyer le tuple et **passer `upgraded` via un paramètre mutable** — à rejeter (moche, non testable).

**Adapter** les deux appels de production pour utiliser les attributs nommés (plus lisible, et débloque `upgraded`) :

```python
outcome = MatchingService.like_profile(from_user=request.user, to_user=target_user)
if not outcome.success:
    http_status = _error_status_map.get(outcome.error_code, status.HTTP_400_BAD_REQUEST)
    return Response({'error': True, 'message': outcome.error_message,
                     'code': outcome.error_code}, status=http_status)
```

#### B-4.2 Promotion like → super like

Dans `matching/services.py`, la branche « already liked » (actuellement `services.py:379-403`) : remplacer par la logique suivante.

**Avant** la branche `existing_like`, capturer le quota **déjà validé** plus haut (`services.py:365-375` fait le `check_feature_availability` ; `services.py:411-421` fait `can_user_swipe` + `can_user_super_like`). **L'ordre actuel est : existing_like (379) AVANT les checks de quota (411+)** → il faut **déplacer** le bloc de quota **avant** `existing_like`, sinon la promotion contournerait le quota.

Bloc réordonné :

```python
        # 1) Shared swipe quota (free accounts) — applies to every stored action.
        from .daily_likes_service import DailyLikesService
        can_swipe, error_msg = DailyLikesService.can_user_swipe(from_user)
        if not can_swipe:
            return LikeOutcome(False, error_code='daily_limit', error_message=error_msg)

        # 2) Super-like dedicated quota.
        if is_super_like:
            can_super_like, error_msg = DailyLikesService.can_user_super_like(from_user)
            if not can_super_like:
                return LikeOutcome(
                    False, error_code='super_like_limit', error_message=error_msg)

        # 3) Already liked → idempotent, but allow a regular→super promotion.
        existing_like = Like.objects.filter(from_user=from_user, to_user=to_user).first()
        if existing_like:
            upgraded = False
            if is_super_like and existing_like.like_type != Like.SUPER:
                existing_like.like_type = Like.SUPER
                existing_like.save(update_fields=['like_type'])
                upgraded = True

                today = date.today()
                legacy, _ = DailyLikeLimit.objects.get_or_create(user=from_user, date=today)
                legacy.super_likes_count += 1
                legacy.save(update_fields=['super_likes_count'])

            InteractionHistory.create_or_reactivate(
                user=from_user,
                target_user=to_user,
                interaction_type=(
                    InteractionHistory.SUPER_LIKE
                    if existing_like.like_type == Like.SUPER
                    else InteractionHistory.LIKE
                ),
            )
            DailyLikesService.sync_subscription_super_like_counter(from_user)

            is_match = Like.objects.filter(from_user=to_user, to_user=from_user).exists()
            if is_match:
                u1, u2 = (from_user, to_user) if from_user.id < to_user.id else (to_user, from_user)
                match, created = Match.objects.get_or_create(
                    user1=u1, user2=u2, defaults={'status': Match.ACTIVE},
                )
                if not created and match.status != Match.ACTIVE:
                    match.status = Match.ACTIVE
                    match.save(update_fields=['status'])
            return LikeOutcome(True, is_match=is_match, upgraded=upgraded)
```

> **Attention** : le quota est désormais consommé **avant** la détection d'idempotence → un super like répété sur le **même** profil consommerait le quota. C'est pourquoi la promotion est **la seule** branche qui consomme ; un super like sur un profil **déjà super liké** retombe dans `existing_like` avec `like_type == SUPER` → `upgraded=False` et **aucune** écriture de compteur. **Vérifier par test.**

#### B-4.3 Champ `Match.origin`

Dans `matching/models.py`, classe `Match` (après `STATUS_CHOICES`, ligne ~142) :

```python
    # Match origins
    ORIGIN_LIKE = 'like'
    ORIGIN_SUPER_LIKE = 'super_like'

    ORIGIN_CHOICES = [
        (ORIGIN_LIKE, _('Regular like')),
        (ORIGIN_SUPER_LIKE, _('Super like')),
    ]
```

et après le champ `status` :

```python
    origin = models.CharField(
        max_length=16,
        choices=ORIGIN_CHOICES,
        default=ORIGIN_LIKE,
        db_index=True,
        verbose_name=_('Origin'),
    )
```

Puis :

```powershell
cd d:\Projets\HIVMeet\env\hivmeet_backend
python manage.py makemigrations matching
python manage.py migrate
```

**Le champ ayant une valeur par défaut, la migration est sûre sur une base existante** (pas de `null=True` nécessaire).

#### B-4.4 Propager l'origine

`matching/services.py` — les deux créations de match (`services.py:458-490` et la branche promotion B-4.2) :

```python
            match, created = Match.objects.get_or_create(
                user1=u1, user2=u2,
                defaults={
                    'status': Match.ACTIVE,
                    'origin': Match.ORIGIN_SUPER_LIKE if is_super_like else Match.ORIGIN_LIKE,
                },
            )
```

`like_profile` doit retourner `match_origin` dans `LikeOutcome` (utiliser `Outcome(match_origin=match.origin)`).

`matching/serializers.py:MatchSerializer` (lignes 30-58) : ajouter `'origin'` à `Meta.fields`.

#### B-4.5 Tests B-4

```python
class SuperLikeUpgradeTests(TestCase):
    def test_regular_like_then_super_like_upgrades(self):
        MatchingService.like_profile(self.premium, self.target)          # regular
        outcome = MatchingService.like_profile(
            self.premium, self.target, is_super_like=True)
        self.assertTrue(outcome.upgraded)
        self.assertEqual(
            Like.objects.get(from_user=self.premium, to_user=self.target).like_type,
            Like.SUPER)
        self.assertEqual(
            InteractionHistory.objects.get(
                user=self.premium, target_user=self.target).interaction_type,
            InteractionHistory.SUPER_LIKE)

    def test_super_like_twice_is_noop(self):
        MatchingService.like_profile(self.premium, self.target, is_super_like=True)
        before = DailyLikesService.get_super_likes_remaining(self.premium)
        outcome = MatchingService.like_profile(
            self.premium, self.target, is_super_like=True)
        self.assertTrue(outcome.success)
        self.assertFalse(outcome.upgraded)
        self.assertEqual(
            DailyLikesService.get_super_likes_remaining(self.premium), before)

    def test_match_origin_is_persisted(self):
        MatchingService.like_profile(self.target, self.premium)          # reverse first
        outcome = MatchingService.like_profile(
            self.premium, self.target, is_super_like=True)
        self.assertTrue(outcome.is_match)
        self.assertEqual(
            Match.objects.get(user1__in=[self.premium, self.target],
                              user2__in=[self.premium, self.target]).origin,
            Match.ORIGIN_SUPER_LIKE)
```

**Non-régression obligatoire** : `matching/test_daily_swipe_quota.py`, `matching/tests_discovery_filters.py`, `matching/tests_interaction_persistence.py` doivent rester verts (l'`__iter__` de `LikeOutcome` garantit la compatibilité).

---

### B-5 — Erreurs, reset, rate limit

**Fiche à créer** : `BACKEND_SUPERLIKE_ERROR_CODES_CONTRACT.md`

#### B-5.1 Contrat de réponse unifié

`matching/views_discovery.py:269-380` (`superlike_profile`) : enrichir les réponses.

**201 (succès sans match)** :

```python
    return Response({
        'status': 'superliked',
        'upgraded': outcome.upgraded,
        'daily_likes_remaining': daily_likes_remaining,
        'super_likes_remaining': super_likes_remaining,
        'super_likes_limit': DailyLikesService.get_super_likes_limit(request.user),
        'super_likes_reset_at': DailyLikesService.get_super_likes_reset_at().isoformat(),
        'message': _("Super like sent successfully"),
    }, status=status.HTTP_201_CREATED)
```

**200 (match)** : ajouter les mêmes `super_likes_limit` / `super_likes_reset_at` (**conserver** `matched_user_info` et `message`).

**429 quota super like** (bloc `can_super_like`, `views_discovery.py:293-300`) : ajouter l'heure de reset :

```python
    if not can_super_like:
        return Response({
            'error': True,
            'message': error_msg,
            'code': 'super_like_limit',
            'super_likes_remaining': 0,
            'super_likes_limit': DailyLikesService.get_super_likes_limit(request.user),
            'super_likes_reset_at': DailyLikesService.get_super_likes_reset_at().isoformat(),
        }, status=status.HTTP_429_TOO_MANY_REQUESTS)
```

**409 conflit** : ajouter une vérification **avant** l'appel au service :

```python
    from .models import Dislike
    if Dislike.objects.filter(
        from_user=request.user, to_user=target_user,
        expires_at__gt=timezone.now(),
    ).exists():
        return Response({
            'error': True,
            'message': _('You already passed this profile.'),
            'code': 'already_interacted',
        }, status=status.HTTP_409_CONFLICT)
    if target_user.id == request.user.id:
        return Response({
            'error': True, 'message': _('Invalid target.'), 'code': 'already_interacted',
        }, status=status.HTTP_409_CONFLICT)
```

**Mapper `upgraded`** : `_error_status_map` (`views_discovery.py:329-334`) doit rester inchangé en dehors de l'ajout éventuel de `'already_interacted': 409`.

#### B-5.2 `GET /discovery/interactions/status`

`views_discovery.get_interaction_status` renvoie `DailyLikesService.get_status_summary(user)` — après B-1, `super_likes_limit` et `super_likes_reset_at` y sont présents automatiquement. **Vérifier** que la vue ne filtre pas les clés (lire `views_discovery.py:382+` avant de conclure) et ajouter les deux clés si elle construit un dict explicite.

#### B-5.3 Rate limiting

`hivmeet_backend/security.py:32` :

```python
        'discovery/interactions/superlike': (30, 3600),  # 30 superlikes/hour
```

**Justification** : 5/jour de quota → un rate limit à 10/h ne borne rien d'utile mais produit des 429 **avant** le quota si l'utilisateur teste. 30/h laisse la marge nécessaire tout en bornant l'abus.

**Ajouter un code distinct** dans la réponse du middleware (`security.py:63-67`) pour que le client distingue « trop de requêtes » de « quota épuisé » :

```python
                    return JsonResponse({
                        'error': 'rate_limit_exceeded',
                        'code': 'rate_limited',
                        'message': 'Too many requests. Please try again later.',
                        'retry_after': window,
                    }, status=429)
```

et ajouter l'en-tête HTTP standard :

```python
                    response = JsonResponse({...}, status=429)
                    response['Retry-After'] = str(window)
                    return response
```

> **Note d'environnement** : `should_rate_limit` (`security.py:70-83`) renvoie `False` si `settings.DEBUG` → le rate limit est **inopérant en dev**. Les tests doivent donc soit forcer `RATELIMIT_ENABLE` + `DEBUG=False`, soit tester le middleware directement.

#### B-5.4 Tests B-5

```python
class SuperLikeErrorContractTests(TestCase):
    def test_quota_exhausted_returns_reset_at(self):
        r = self.premium_client.post(self.url, {'target_user_id': self.sixth.id})
        self.assertEqual(r.status_code, 429)
        self.assertEqual(r.json()['code'], 'super_like_limit')
        self.assertIn('super_likes_reset_at', r.json())

    def test_success_returns_limit_and_reset(self):
        r = self.premium_client.post(self.url, {'target_user_id': self.free_target.id})
        self.assertEqual(r.status_code, 201)
        body = r.json()
        self.assertIn('super_likes_limit', body)
        self.assertIn('super_likes_reset_at', body)
        self.assertIn('upgraded', body)

    def test_dislike_then_superlike_is_conflict(self):
        MatchingService.dislike_profile(self.premium, self.target)
        r = self.premium_client.post(self.url, {'target_user_id': self.target.id})
        self.assertEqual(r.status_code, 409)
        self.assertEqual(r.json()['code'], 'already_interacted')

    def test_rate_limit_code_is_distinct(self):
        # force the middleware path with DEBUG=False
        ...
        self.assertEqual(r.json()['code'], 'rate_limited')
        self.assertIn('Retry-After', r.headers)
```

---

### B-6 — Nettoyage du legacy

**Fiche à créer** : `BACKEND_SUPERLIKE_LEGACY_CLEANUP.md`

| Action | Fichier / symbole | Justification |
|---|---|---|
| **Supprimer** | `matching/views_premium.py:82-156` (`SendSuperLikeView`) | Champs `Like` inexistants → 500 garanti ; non routable (voir ci-dessous). Le remplacer par **rien** : le chemin officiel est `/discovery/interactions/superlike` |
| **Supprimer** | `matching/urls.py` (fichier entier) | Masqué par le paquet `matching/urls/` (Python 3 : le paquet prime) ; routeur fantôme contenant le doublon `super-like` |
| **Supprimer** | `matching/serializers.py` `LikeSerializer` (lignes 17-28) | `source='target_user.id'` inexistant ; **aucune** référence dans tout le backend (vérifié par grep) |
| **Supprimer ou corriger** | `matching/serializers.py:62-130` (`RecommendedProfileSerializer`) | `get_has_liked_you` utilise `Like(user=…, target_user=…)` (champs inexistants) ; **retirer `hiv_status`** du payload (fuite de donnée de santé) ; si le serializer est conservé, réécrire `get_has_liked_you` avec `from_user`/`to_user` |
| **Vérifier** | `matching/urls_discovery.py:21` (`interactions/super-like` alias) | Alias conservé uniquement si un client l'utilise ; sinon supprimer pour éviter deux contrats |
| **Corriger** | `matching/views_premium.py` imports (`SendSuperLikeView`) | Retirer de `matching/urls.py` supprimé — vérifier aussi `validate_premium_final.py:36` qui l'importe (fichier de script, à nettoyer ou laisser tel quel en le signalant) |

**Après suppression**, exécuter :

```powershell
cd d:\Projets\HIVMeet\env\hivmeet_backend
python manage.py check
python -c "import django,os; os.environ.setdefault('DJANGO_SETTINGS_MODULE','hivmeet_backend.settings'); django.setup(); import matching.views_discovery; print('OK')"
```

---

## PARTIE 2 — FRONTEND

### F-1 — Contrats & couche data

#### F-1.1 Entités (`lib/domain/entities/match.dart`)

**Enrichir `SwipeResult`** (`match.dart:340-400`) — conserver tous les champs existants, **ajouter** :

```dart
class SwipeResult extends Equatable {
  final bool isMatch;
  final String? matchId;
  final Profile? matchedProfile;
  final int? remainingLikes;
  final int? remainingSuperLikes;
  // ...existing code...
  final int? superLikesLimit;
  final DateTime? superLikesResetAt;
  final bool upgraded;
  final String? matchOrigin;

  const SwipeResult({
    // ...existing params...
    this.superLikesLimit,
    this.superLikesResetAt,
    this.upgraded = false,
    this.matchOrigin,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    final resetAt = json['super_likes_reset_at'] as String?;
    return SwipeResult(
      // ...existing mapping...
      superLikesLimit: json['super_likes_limit'] as int?,
      superLikesResetAt: resetAt != null ? DateTime.tryParse(resetAt) : null,
      upgraded: json['upgraded'] as bool? ?? false,
      matchOrigin: json['origin'] as String?,
    );
  }
  // ...existing code...
  @override
  List<Object?> get props => [
        // ...existing props...
        superLikesLimit, superLikesResetAt, upgraded, matchOrigin,
      ];
}
```

**Enrichir `DiscoveryProfile`** (`match.dart:72-200`) — ajouter les flags de réception :

```dart
  final bool? hasSuperLikedMe;   // null = non premium / inconnu
  final bool? hasLikedYou;
```
Avec `copyWith`, `props` et le mapping `fromJson` (`has_super_liked_me`, `has_liked_you` en `bool?`).

**Enrichir `Match`** (`match.dart:8-60`) — ajouter :

```dart
  final String? origin;   // 'like' | 'super_like'
```
+ `copyWith`, `props`.

**Ajouter** un quota typé, symétrique de `DailyLikeLimit` (`match.dart:304-338`) :

```dart
class SuperLikeQuota extends Equatable {
  final int remaining;
  final int limit;
  final DateTime? resetAt;

  const SuperLikeQuota({
    required this.remaining,
    required this.limit,
    this.resetAt,
  });

  bool get hasReachedLimit => remaining <= 0;
  bool get isUnlimited => limit < 0;

  factory SuperLikeQuota.fromJson(Map<String, dynamic> json) {
    final reset = (json['super_likes_reset_at'] ?? json['reset_at']) as String?;
    return SuperLikeQuota(
      remaining: json['super_likes_remaining'] as int? ?? 0,
      limit: json['super_likes_limit'] as int? ?? 0,
      resetAt: reset != null ? DateTime.tryParse(reset) : null,
    );
  }

  @override
  List<Object?> get props => [remaining, limit, resetAt];
}
```

#### F-1.2 Interface repository

`lib/domain/repositories/match_repository.dart` — **remplacer** `getSuperLikesRemaining()` (ligne 45) par `getSuperLikeQuota()`.

> ✅ **Vérifié** : `getSuperLikesRemaining()` n'a **aucun appelant** (seules occurrences : sa déclaration `match_repository.dart:45` et ses deux implémentations `match_repository_impl.dart:343` / `match_repository_mock.dart:189`). C'est du **code mort** : le remplacer, ne pas le conserver, sinon on ajoute une méthode morte de plus.

```dart
  /// Quota super like complet (restant, plafond, heure de reset).
  /// `SuperLikeQuota` porte l'heure de réinitialisation, indispensable pour
  /// l'afficher à l'utilisateur au lieu d'un simple compteur.
  Future<Either<Failure, SuperLikeQuota>> getSuperLikeQuota();
```

**Supprimer** les trois occurrences de `getSuperLikesRemaining` (interface + impl réelle + mock) et implémenter la nouvelle méthode dans les deux implémentations.

`match_repository_impl.dart` — **à la place** de l'ancien `getSuperLikesRemaining` (ligne 343-354) :

```dart
  @override
  Future<Either<Failure, SuperLikeQuota>> getSuperLikeQuota() async {
    try {
      final response = await _matchingApi.getInteractionStatus();
      return Right(SuperLikeQuota.fromJson(response.data!));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement du quota super like: $e'));
    }
  }
```

#### F-1.3 Usecase

Créer `lib/domain/usecases/match/get_super_like_quota.dart` (calqué sur `get_daily_like_limit.dart`) :

```dart
// lib/domain/usecases/match/get_super_like_quota.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

@injectable
class GetSuperLikeQuota implements UseCase<SuperLikeQuota, NoParams> {
  final MatchRepository repository;

  GetSuperLikeQuota(this.repository);

  @override
  Future<Either<Failure, SuperLikeQuota>> call(NoParams params) {
    return repository.getSuperLikeQuota();
  }
}
```

**Enregistrement** dans `lib/injection.dart` — **après** `GetDailyLikeLimit` (ligne ~337) :

```dart
  getIt.registerSingleton<GetSuperLikeQuota>(
    GetSuperLikeQuota(getIt<MatchRepository>()),
  );
```

> ⚠️ **Vérifier** si le projet utilise `@injectable` + génération (`injection.config.dart`) **ou** un enregistrement manuel. `lib/injection.dart` fait de l'enregistrement manuel (`getIt.registerSingleton<...>`), mais les usecases portent `@injectable`. Suivre le style du fichier : ajouter l'appel manuel **et** vérifier qu'aucun `*.g.dart` n'a besoin d'être régénéré (`flutter pub run build_runner build`).

#### F-1.4 Mapper découverte

`match_repository_impl.dart` (`_mapJsonToDiscoveryProfile`) et `DiscoveryProfile.fromJson` (`match.dart:106+`) : ajouter le mapping `has_super_liked_me` / `has_liked_you` en `bool?` (`json['x'] as bool?`).

#### F-1.5 Mapper likes reçus

`match_repository_impl.dart:263-292` (`getLikesReceived`) : mapper le type d'interaction.

```dart
      final profiles = list.map<DiscoveryProfile>((json) {
        final map = json as Map<String, dynamic>;
        final profile = _mapJsonToDiscoveryProfile(map);
        return profile.copyWith(
          hasSuperLikedMe: map['is_super_like'] == true,
        );
      }).toList();
```

> **Décision de contrat** : `interaction_type` est la source de vérité ; `is_super_like` est un raccourci. Utiliser `map['interaction_type'] == 'super_like' || map['is_super_like'] == true` pour la robustesse.

#### F-1.6 Tests F-1

`test/data/repositories/match_repository_impl_filters_test.dart` contient déjà des tests `superLikeProfile` (ligne 201). Ajouter :

```dart
    test('getSuperLikeQuota maps limit and reset_at', () async {
      when(() => mockMatchingApi.getInteractionStatus()).thenAnswer((_) async => Response(
        data: {
          'super_likes_remaining': 3,
          'super_likes_limit': 5,
          'super_likes_reset_at': '2026-09-22T00:00:00Z',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/discovery/interactions/status'),
      ));
      final result = await repository.getSuperLikeQuota();
      result.fold((l) => fail('expected Right'), (q) {
        expect(q.remaining, 3);
        expect(q.limit, 5);
        expect(q.resetAt, isNotNull);
      });
    });

    test('superLikeProfile maps upgraded flag', () async {
      when(() => mockMatchingApi.superLikeProfile(profileId: 'p1')).thenAnswer((_) async => Response(
        data: {'status': 'superliked', 'upgraded': true, 'super_likes_remaining': 4},
        statusCode: 201,
        requestOptions: RequestOptions(path: '/discovery/interactions/superlike'),
      ));
      final result = await repository.superLikeProfile('p1');
      result.fold((l) => fail('expected Right'), (r) => expect(r.upgraded, isTrue));
    });
```

---

### F-2 — Erreurs & état du BLoC

#### F-2.1 Mapping des erreurs par `code` (règle absolue)

`match_repository_impl.dart:_failureFromDio` (ligne 470+) : **corriger** la détection premium et centraliser.

```dart
  Failure _failureFromDio(
    DioException error, [
    String fallback = 'Erreur serveur',
  ]) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;

    if (data is Map<String, dynamic>) {
      // The backend exposes a stable `code`; `error` is a boolean flag.
      final code = data['code']?.toString();

      if (code == 'premium_required' || code == 'no_active_subscription') {
        return const PremiumRequiredFailure();
      }
      if (code == 'super_like_limit') {
        return ServerFailure(
          message: data['message']?.toString() ?? fallback,
          code: 'super_like_limit',
        );
      }
      if (code == 'daily_limit') {
        return ServerFailure(
          message: data['message']?.toString() ?? fallback,
          code: 'daily_limit',
        );
      }
      if (code == 'rate_limited') {
        return ServerFailure(
          message: data['message']?.toString() ?? fallback,
          code: 'rate_limited',
        );
      }

      final message = data['message']?.toString() ??
          data['detail']?.toString() ??
          (data['error'] is String ? data['error'] as String : null);
      return ServerFailure(
        message: message ?? error.message ?? fallback,
        code: code ?? (statusCode == 429 ? 'rate_limited' : null),
      );
    }

    return ServerFailure(
      message: error.message ?? fallback,
      code: statusCode == 429 ? 'rate_limited' : null,
    );
  }
```

> **Régression à éviter** : l'ancienne implémentation testait `data['error'] == 'premium_required'`. Le backend renvoie `error: true` (booléen). La nouvelle version lit `code` — **compatible avec les deux** puisque `(data['error'] is String ? ... : null)` ne retient plus la branche booléenne.

#### F-2.2 États du BLoC

`lib/presentation/blocs/discovery/discovery_state.dart` :

1. **Ajouter** dans `DiscoveryLoaded` (ligne ~35) :

```dart
  final SuperLikeQuota? superLikeQuota;
```
+ constructeur (`this.superLikeQuota`) + `props`.

2. **Ajouter** un état dédié (symétrique de `DailyLimitReached`, ligne ~79) :

```dart
class SuperLikeLimitReached extends DiscoveryState {
  final DiscoveryLoaded previousState;
  final SuperLikeQuota quota;
  final int promptSequence;

  const SuperLikeLimitReached({
    required this.previousState,
    required this.quota,
    this.promptSequence = 0,
  });

  @override
  List<Object?> get props => [previousState, quota, promptSequence];
}
```

3. **Ajouter** `isSuperLike` à `MatchFound` (ligne ~60) :

```dart
  final bool isSuperLike;
  // const MatchFound({..., this.isSuperLike = false});
```

#### F-2.3 Injection du quota dans le BLoC

`lib/presentation/blocs/discovery/discovery_bloc.dart` :

1. **Champ** : `SuperLikeQuota? _superLikeQuota;` + `int _superLikeLimitPromptSequence = 0;`
2. **Constructeur** : ajouter `required GetSuperLikeQuota getSuperLikeQuota` → champ `final GetSuperLikeQuota _getSuperLikeQuota;`
3. **Dans `_onLoadDiscoveryProfiles`** (après le bloc `dailyLimitResult.fold`, ligne ~238) :

```dart
          final quotaResult = await _getSuperLikeQuota(const NoParams());
          quotaResult.fold(
            (failure) => _superLikeQuota = null,
            (quota) => _superLikeQuota = quota,
          );
```

4. **Dans `_emitLoaded`** (signature actuelle : `void _emitLoaded(Emitter<DiscoveryState> emit)`, `discovery_bloc.dart:~245`) : la méthode construit l'état `DiscoveryLoaded` en fin de corps. Ajouter la ligne :

```dart
  emit(DiscoveryLoaded(
    currentProfile: _profiles[_currentIndex],
    nextProfiles: _profiles.sublist(
      _currentIndex + 1,
      (_currentIndex + 3).clamp(0, _profiles.length),
    ),
    canRewind: _lastSwipedProfile != null,
    dailyLimit: _dailyLimit,
    superLikeQuota: _superLikeQuota,   // <-- ajout
  ));
```

> `_emitLoaded` ne prend **aucun** paramètre de quota : elle lit les champs du BLoC. Comme `_superLikeQuota` est renseigné **avant** l'appel dans `_onLoadDiscoveryProfiles` (étape 3 ci-dessus), aucune modification de signature n'est nécessaire.
5. **Dans `MatchFound`** (ligne ~362) :

```dart
    if (result.isMatch) {
      emit(MatchFound(
        matchedProfile: currentProfile,
        matchId: result.matchId!,
        isSuperLike: event.direction == SwipeDirection.up,
      ));
      await Future.delayed(const Duration(seconds: 3));
    }
```

6. **Après un swipe réussi** (là où `result.remainingSuperLikes` est lu, ligne ~400+) : rafraîchir le quota :

```dart
    if (result.remainingSuperLikes != null) {
      _superLikeQuota = SuperLikeQuota(
        remaining: result.remainingSuperLikes!,
        limit: result.superLikesLimit ?? _superLikeQuota?.limit ?? 0,
        resetAt: result.superLikesResetAt ?? _superLikeQuota?.resetAt,
      );
    }
```

#### F-2.4 Détection de limite & messages i18n

Remplacer les helpers (`discovery_bloc.dart:62-97`) :

```dart
  bool _isRateLimitFailure(Failure? failure) {
    return failure?.code == 'rate_limited' ||
        failure?.code == 'super_like_limit' ||
        failure?.code == 'daily_limit' ||
        (failure?.message.toLowerCase().contains('too many requests') ?? false);
  }

  bool _emitDailyLimitIfNeeded(Emitter<DiscoveryState> emit, Failure? failure) {
    if (failure?.code != 'daily_limit') return false;
    // ...existing body unchanged...
  }

  /// Emits the super-like specific limit state (dedicated message + reset time).
  bool _emitSuperLikeLimitIfNeeded(
    Emitter<DiscoveryState> emit,
    Failure? failure,
  ) {
    if (failure?.code != 'super_like_limit') return false;
    final previousState = _safePreviousState();
    if (previousState == null) return false;

    _superLikeLimitPromptSequence += 1;
    emit(SuperLikeLimitReached(
      previousState: previousState,
      quota: _superLikeQuota ??
          SuperLikeQuota(remaining: 0, limit: 0, resetAt: null),
      promptSequence: _superLikeLimitPromptSequence,
    ));
    return true;
  }
```

**Dans le `case SwipeDirection.up`** (`discovery_bloc.dart:318-360`), remplacer le bloc de messages hardcodés par :

```dart
      case SwipeDirection.up:
        final params = SuperLikeProfileParams(profileId: currentProfile.id);
        final either = await _superLikeProfile(params);
        if (either.isLeft()) {
          final failure = either.fold((l) => l, (r) => null);
          _debugLog('DEBUG DiscoveryBloc: SuperLike failed - ${failure?.toString()}');

          if (_emitSuperLikeLimitIfNeeded(emit, failure)) return;
          if (_emitDailyLimitIfNeeded(emit, failure)) return;

          if (failure is PremiumRequiredFailure) {
            _emitSwipeError(
              emit,
              LocalizationService.translate(
                'discovery.super_like_requires_premium_message'),
            );
            return;
          }

          _emitSwipeError(
            emit,
            _mapFailureToMessage(
              LocalizationService.translate('discovery.super_like_error_prefix'),
              failure,
            ),
            autoDismiss: _isRateLimitFailure(failure),
          );
          return;
        }
        result = either.getOrElse(() => const SwipeResult(isMatch: false));
        break;
```

**Imports à ajouter** : `package:hivmeet/core/services/localization_service.dart`.

> **Contrainte** : un BLoC qui appelle `LocalizationService.translate` est acceptable ici puisque le projet utilise déjà ce service (pattern observé dans `discovery_page.dart`). Alternative plus rigoureuse : émettre un état portant une **clé** + `params`, et laisser la page traduire. **Choisir l'option « clé dans l'état »** si l'équipe veut garder les BLoCs sans dépendance de présentation :
> ```dart
> class SuperLikeLimitReached extends DiscoveryState { /* ... */ }
> class DiscoveryError extends DiscoveryState { final String? messageKey; final Map<String,String>? params; }
> ```
> ⚠️ **Vérifier le style existant** avant de trancher : `discovery_bloc.dart` **traduit déjà en dur** (`'Trop de requetes...'`, ligne 67) → l'option la moins invasive est `LocalizationService` dans le BLoC. **Documenter le choix dans la fiche.**

#### F-2.5 Tests F-2

```dart
    blocTest<DiscoveryBloc, DiscoveryState>(
      'emits SuperLikeLimitReached on super_like_limit',
      build: () {
        when(() => mockSuperLike(any)).thenAnswer((_) async => const Left(
          ServerFailure(message: 'quota', code: 'super_like_limit')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SwipeProfile(direction: SwipeDirection.up)),
      expect: () => [
        isA<ProfileSwiping>(),
        isA<SuperLikeLimitReached>(),
      ],
    );

    blocTest<DiscoveryBloc, DiscoveryState>(
      'emits PremiumRequiredFailure dialog path for premium_required',
      ...
      expect: () => [isA<ProfileSwiping>(), isA<DiscoveryError>()],
    );
```

---

### F-3 — UI quota & verrouillage

#### F-3.1 Compteur super like

`lib/presentation/pages/discovery/discovery_page.dart` — dans la méthode qui construit la barre d'actions (~ligne 316), **au-dessus** du bouton étoile, insérer un indicateur (symétrique de `_buildDailyLimitIndicator`, ligne 352) :

```dart
  Widget _buildSuperLikeQuotaBadge(SuperLikeQuota? quota) {
    if (quota == null || quota.isUnlimited) return const SizedBox.shrink();
    final isExhausted = quota.hasReachedLimit;
    return Positioned(
      top: 112,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isExhausted ? AppColors.slate : AppColors.warning)
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              LocalizationService.translate(
                'discovery.super_likes_remaining',
                params: {'count': quota.remaining.toString()},
              ),
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
```

**Appel** : dans le `Stack` de la page, à côté de `_buildDailyLimitIndicator(...)`.

#### F-3.2 Bouton étoile : bloquer avant l'appel réseau

`discovery_page.dart:316-345` — le bouton appelle aujourd'hui `_showPremiumSuperLikeDialog()` **uniquement** si `!isPremium`. Ajouter la gestion du quota épuisé :

```dart
          ActionButton(
            icon: Icons.star,
            color: AppColors.warning,
            onPressed: () {
              if (_discoveryBloc.state is DiscoveryError) return;
              if (!isPremium) {
                _showPremiumSuperLikeDialog();
                return;
              }
              final quota = _currentSuperLikeQuota();   // lit DiscoveryLoaded.superLikeQuota
              if (quota != null && quota.hasReachedLimit) {
                _showSuperLikeLimitDialog(quota);        // aucun appel réseau
                return;
              }
              final swipeCardState = _swipeCardKey.currentState;
              if (swipeCardState != null) {
                try {
                  (swipeCardState as dynamic).triggerSwipe(SwipeDirection.up);
                } catch (_) {
                  _handleSwipe(SwipeDirection.up);
                }
              } else {
                _handleSwipe(SwipeDirection.up);
              }
            },
            size: 68,
            isPremium: true,
          ),
```

Même garde dans `_handleSwipe` (`discovery_page.dart:684-692`) pour couvrir le geste « swipe vers le haut » :

```dart
  void _handleSwipe(SwipeDirection direction) {
    if (direction == SwipeDirection.up) {
      final authState = context.read<AuthBlocSimple>().state;
      final isPremium =
          authState is Authenticated && authState.user.isPremiumActive;
      if (!isPremium) {
        _showPremiumSuperLikeDialog();
        return;
      }
      final quota = _currentSuperLikeQuota();
      if (quota != null && quota.hasReachedLimit) {
        _showSuperLikeLimitDialog(quota);
        return;
      }
    }
    _discoveryBloc.add(SwipeProfile(direction: direction));
  }
```

Ajouter le helper et le dialogue :

```dart
  SuperLikeQuota? _currentSuperLikeQuota() {
    final s = _discoveryBloc.state;
    if (s is DiscoveryLoaded) return s.superLikeQuota;
    if (s is ProfileSwiping) return s.previousState.superLikeQuota;
    if (s is SuperLikeLimitReached) return s.previousState.superLikeQuota;
    if (s is DiscoveryError) return s.previousState?.superLikeQuota;
    return null;
  }

  Future<void> _showSuperLikeLimitDialog(SuperLikeQuota quota) async {
    final resetAt = quota.resetAt?.toLocal();
    final time = resetAt != null
        ? '${resetAt.hour.toString().padLeft(2, '0')}:'
          '${resetAt.minute.toString().padLeft(2, '0')}'
        : '--:--';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocalizationService.translate(
          'discovery.super_like_limit_reached_title')),
        content: Text(LocalizationService.translate(
          'discovery.super_like_limit_reached_message',
          params: {'time': time},
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocalizationService.translate('common.close')),
          ),
        ],
      ),
    );
  }
```

#### F-3.3 Écoute de `SuperLikeLimitReached`

Dans `_handleStateChanges` (`discovery_page.dart:666-684`), ajouter :

```dart
    if (state is SuperLikeLimitReached) {
      _showSuperLikeLimitDialog(state.quota);
    }
```

> ⚠️ **Éviter le double affichage** : le bouton **et** l'état peuvent déclencher le dialogue. Choisir **un seul** canal : recommandé = **l'état** (couvre aussi le swipe gestuel et une limite découverte côté serveur), et le bouton se contente de bloquer sans dialogue s'il connaît déjà le quota. Adapter en conséquence (retirer le `_showSuperLikeLimitDialog` du `onPressed` si l'état est déjà écouté **avant** l'appel).

#### F-3.4 Tests F-3

```dart
  testWidgets('super like button opens quota dialog without network call', (tester) async {
    // DiscoveryLoaded with superLikeQuota.remaining == 0
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();
    expect(find.text('Super Likes épuisés'), findsOneWidget);
    verifyNever(() => mockSuperLike(any));
  });

  testWidgets('super like counter is displayed for premium users', (tester) async {
    expect(find.textContaining('Super Likes restants'), findsOneWidget);
  });
```

---

### F-4 — Réception du super like

#### F-4.1 Badge dans la liste des likes reçus

`lib/presentation/pages/likes_received/likes_received_page.dart:170-260` (`_LikeProfileCard`) : ajouter un badge conditionnel sur la photo.

```dart
        // dans le Stack de la carte, après l'image
        if (profile.hasSuperLikedMe == true)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Super Like',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
```

> **i18n** : remplacer le `Text('Super Like')` par `LocalizationService.translate('discovery.super_like')` (clé existante `fr.json:36`).

#### F-4.2 Onglet ou section Super Likes (Option A recommandée)

Décision produit à acter. Implémentation minimale si **Option B** (liste unifiée + badges) : rien de plus que F-4.1.

Implémentation si **Option A** :
1. `lib/domain/repositories/match_repository.dart` : ajouter `Future<Either<Failure, List<DiscoveryProfile>>> getSuperLikesReceived({int limit = 20, String? lastProfileId});`
2. `match_repository_impl.dart` : implémenter via `ProfileApi.getSuperLikesReceived` (`lib/data/datasources/remote/profile_api.dart:138-146`) — **attention** : ce datasource est `ProfileApi`, pas `MatchingApi` ; vérifier son injection dans `MatchRepositoryImpl` (actuellement seul `MatchingApi` est injecté, `match_repository_impl.dart:23-25`). Si `ProfileApi` n'est pas injectable ici, migrer l'appel vers `MatchingApi` (ajouter `getSuperLikesReceived` dans `matching_api.dart` sur `/user-profiles/super-likes-received/`).
3. `lib/presentation/blocs/matches/` : nouvel event `LoadSuperLikesReceived` + état `SuperLikesReceivedLoaded`.
4. `likes_received_page.dart` : `TabBar` à deux onglets.
5. **Supprimer** l'endpoint dupliqué non utilisé si Option B.

> ⚠️ **Ne pas laisser les deux implémentations** (c'est l'écart G3 actuel) : soit `profile_api.getSuperLikesReceived` est câblé, soit il est supprimé.

#### F-4.3 Badge « Vous a Super Liké » dans la découverte

`lib/presentation/widgets/cards/swipe_card.dart` — afficher un badge (premium uniquement, car `hasSuperLikedMe` est `null` sinon) :

```dart
  Widget _buildSuperLikedYouBadge() {
    if (widget.profile.hasSuperLikedMe != true) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              LocalizationService.translate('discovery.has_super_liked_you'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
```

Insérer l'appel dans le `Stack` de la carte (à côté du badge vérifié/premium existant).

#### F-4.4 Upsell destinataire non-premium

`likes_received_page.dart:56-80` (bloc `if (!isPremium)`) : exploiter `super_likes_received_count` (B-3.4) si disponible dans `premium-status` :

```dart
            body: _ErrorState(
              icon: Icons.workspace_premium_outlined,
              title: _tr('profile.likes_premium_title'),
              subtitle: receivedCount > 0
                  ? _tr('likes_received.super_likes_count')
                      .replaceFirst('{count}', receivedCount.toString())
                  : _tr('profile.likes_premium_message'),
              // ...
            ),
```

> `_tr` est le helper local de la page ; vérifier qu'il accepte des `params` (sinon utiliser `LocalizationService.translate(..., params: {...})`).

---

### F-5 — Match issu d'un super like

1. `discovery_page.dart` : `_showMatchFoundModal(state)` reçoit `MatchFound` → afficher un titre conditionnel.
2. Créer dans le modal :

```dart
  final titleKey = state.isSuperLike
      ? 'discovery.match_from_super_like_title'
      : 'discovery.its_a_match';
  final bodyKey = state.isSuperLike
      ? 'discovery.match_from_super_like_message'
      : 'discovery.match_message';
```

3. `lib/presentation/blocs/matches/*` : mapper `origin` (B-4.4) sur `Match` ; optionnellement afficher un badge étoile sur la liste des matches.

---

### F-6 — Nettoyage du chemin mort

**Supprimer, dans cet ordre**, puis `flutter analyze` :

| Fichier | Symbole | Lignes |
|---|---|---|
| `lib/data/datasources/remote/subscriptions_api.dart` | `useSuperLike` | 74-82 |
| `lib/data/repositories/premium_repository_impl.dart` | `useSuperLike` | 279-297 |
| `lib/domain/repositories/premium_repository.dart` | `useSuperLike` | 53 |
| `lib/presentation/blocs/premium/premium_bloc.dart` | `on<UseSuperLike>` + `_onUseSuperLike` | 44, 335-347 |
| `lib/presentation/blocs/premium/premium_event.dart` | classe `UseSuperLike` | 48-52 |
| `lib/presentation/blocs/premium/premium_state.dart` | classe `SuperLikeUsed` | 150-160 |
| Tests associés | références à `premium_repository_modify_test.dart` | vérifier |

**Ne pas supprimer** `SuperLikeResult` (`lib/domain/entities/premium.dart:195-220`) s'il est utilisé ailleurs → vérifier par grep avant.

**Alternative** (si décision contraire) : créer la route backend. Dans ce cas, ajouter à `subscriptions/urls.py` :

```python
    path('use-super-like', views.UseSuperLikeView.as_view(), name='use-super-like'),
```
et implémenter `UseSuperLikeView` comme **délégateur** vers `MatchingService.like_profile(is_super_like=True)` (jamais une seconde implémentation de la logique).

---

### F-7 — i18n

#### F-7.1 Clés à ajouter dans `assets/translations/fr.json` et `en.json`

Section `discovery` :

```json
    "super_likes_remaining": "{count} Super Likes restants",
    "super_like_limit_reached_title": "Super Likes épuisés",
    "super_like_limit_reached_message": "Vos Super Likes seront réinitialisés à {time}.",
    "super_like_requires_premium_title": "Super Like Premium",
    "super_like_requires_premium_message": "Un Super Like place votre profil en tête de la file d'attente de la personne et lui envoie une notification dédiée.",
    "super_like_error_prefix": "Erreur super like",
    "has_super_liked_you": "Vous a Super Liké",
    "match_from_super_like_title": "Match grâce à un Super Like !",
    "match_from_super_like_message": "Votre Super Like a porté ses fruits."
```

Anglais :

```json
    "super_likes_remaining": "{count} Super Likes left",
    "super_like_limit_reached_title": "No Super Likes left",
    "super_like_limit_reached_message": "Your Super Likes reset at {time}.",
    "super_like_requires_premium_title": "Premium Super Like",
    "super_like_requires_premium_message": "A Super Like puts your profile at the top of their queue and sends them a dedicated notification.",
    "super_like_error_prefix": "Super like error",
    "has_super_liked_you": "Super Liked you",
    "match_from_super_like_title": "Matched from a Super Like!",
    "match_from_super_like_message": "Your Super Like paid off."
```

**Section `likes_received`** (à créer si absente) :

```json
    "super_likes_tab": "Super Likes",
    "super_likes_count": "{count} personnes vous ont Super Liké"
```

#### F-7.2 Libellé d'upsell à corriger

`assets/translations/fr.json:453` et `en.json:455` — remplacer « et vous démarquer » / « and stand out » par un **avantage réel** :

- FR : `"Passez à Premium pour envoyer des Super Likes : ils placent votre profil en tête de la file d'attente et envoient une notification dédiée."`
- EN : `"Upgrade to Premium to send Super Likes: they move your profile to the top of their queue and send a dedicated notification."`

> ⚠️ Cette modification n'est **valide** qu'**après** le déploiement de B-2. La faire dans le même lot de livraison que B-2, pas avant.

#### F-7.3 Chaînes FR en dur à extraire

| Fichier:ligne | Chaîne | Clé cible |
|---|---|---|
| `discovery_bloc.dart:67` | `'Trop de requetes...'` | `errors.rate_limited` |
| `discovery_bloc.dart:330-350` | 3 messages premium/quota | `discovery.super_like_*` |
| `notification_card.dart:71` | `locale: 'fr'` | locale active (`Localizations.localeOf(context)`) |
| `stats_page.dart:104,117` | `'Total Likes'`, `'$n Super Likes inclus'` | `stats.total_likes`, `stats.super_likes_included` |
| `my_likes_page.dart:268-272` | `'Super Like'`, `'Like'` | `discovery.super_like`, `interaction.like` |
| `premium_repository_impl.dart:369-377` | libellés premium | `data/*` (données, pas d'UI : **déplacer** dans la couche présentation ou i18n) |

**Section ARB `errors`** (si absente) :

```json
    "rate_limited": "Trop de requêtes, réessayez dans quelques secondes."
```

---

## PARTIE 3 — Journal de vérification & preuves d'exécution

### 3.1 Checklist de preuve à remplir par l'agent implémenteur

| # | Preuve attendue | Commande / artefact |
|---|---|---|
| 1 | Migrations générées | `python manage.py makemigrations matching` → fichier `000X_match_origin.py` |
| 2 | Aucune erreur de configuration Django | `python manage.py check` |
| 3 | Suite backend verte | `python manage.py test matching profiles subscriptions` |
| 4 | Aucune régression tuple | `python manage.py test matching.test_daily_swipe_quota matching.tests_discovery_filters` |
| 5 | Tri vérifié en base | Test `test_super_liker_ranks_first` |
| 6 | Quota canonique | Test `test_sixth_super_like_is_rejected` + `test_mirror_never_decrements_below_canonical` |
| 7 | Confidentialité | Test `test_non_premium_gets_null_not_false` + `test_non_premium_gets_403_but_count_is_available` |
| 8 | Frontend compile | `flutter analyze` (0 issue) |
| 9 | Tests frontend | `flutter test` |
| 10 | Chaîne i18n | grep `fr.json` / `en.json` : chaque clé de F-7.1 présente **dans les deux** fichiers |
| 11 | Aucun code mort | grep `useSuperLike` → 0 occurrence ; grep `SendSuperLikeView` → 0 occurrence |
| 12 | Contrats documentés | `API_DOCUMENTATION.md` mis à jour (voir 3.2) |

### 3.2 Mise à jour obligatoire de `API_DOCUMENTATION.md`

Section « Découverte et Matching », entrée `POST /api/v1/discovery/interactions/superlike` — remplacer la ligne actuelle (« Super-like (Premium) ») par :

```markdown
### POST `/api/v1/discovery/interactions/superlike`
- **Description** : Super-like (Premium). Place le profil de l'émetteur en tête
  de la file d'attente du destinataire (fenêtre de priorité : 7 jours) et lui
  envoie une notification dédiée.
- **Quota** : `SubscriptionPlan.daily_super_likes_count` (5/jour par défaut),
  reset à minuit UTC. Aucun super like pour les comptes gratuits.
- **Corps** : `{ "target_user_id": "uuid" }`
- **Réponses** :
  - `201` `{ status: "superliked", upgraded, super_likes_remaining, super_likes_limit, super_likes_reset_at }`
  - `200` `{ status: "matched_with_superlike", match_id, matched_user_info, super_likes_remaining, super_likes_limit, super_likes_reset_at }`
  - `403 code=premium_required` / `code=no_active_subscription`
  - `409 code=already_interacted`
  - `429 code=super_like_limit` (quota) / `code=rate_limited` (débit)
```

Ajouter aussi les entrées : `GET /user-profiles/likes-received/` (champs `interaction_type`, `is_super_like`), `GET /user-profiles/super-likes-received/`, `GET /matches/` (champ `origin`).

---

## PARTIE 4 — Décisions à acter avant codage

| # | Décision | Options | Impact si non tranché |
|---|---|---|---|
| 1 | Priorité super like vs boost | (a) super like d'abord *(recommandé)* — (b) boost d'abord | L'ordre `order_by` de B-2.2 |
| 2 | Fenêtre de priorité | 7 jours *(recommandé)* / 3 / 14 / jusqu'à interaction | Constante `SUPER_LIKE_PRIORITY_WINDOW_DAYS` |
| 3 | Quota officiel | 5/jour (backend actuel) / 3/jour (doc) | `init_subscription_plans.py` + doc |
| 4 | Compteur non-premium | disponible *(recommandé)* / masqué | B-3.4 |
| 5 | Likes reçus | (a) liste unifiée + badges *(moins de code)* — (b) onglets séparés | F-4.2 |
| 6 | Chemin `/subscriptions/use-super-like` | (a) supprimer *(recommandé)* — (b) implémenter en délégateur | F-6 |
| 7 | Messages d'erreur dans le BLoC | (a) `LocalizationService` dans le BLoC *(moins invasif, aligné sur l'existant)* — (b) clés dans l'état | F-2.4 |

---

## PARTIE 5 — Pièges identifiés (à lire avant d'écrire une ligne)

1. **`MatchingService.like_profile` est appelé par les tests avec déballage à 4 éléments** → implémenter `LikeOutcome.__iter__`, sinon ~7 tests cassent.
2. **Les deux gatings de quota** : si on ne fait que B-1 partiellement (p. ex. seulement `check_feature_availability`), la divergence persiste. **B-1 est atomique.**
3. **`matching/urls.py` est masqué par le package `matching/urls/`** : ne pas « corriger » `matching/urls.py` en pensant qu'il est actif ; il faut le **supprimer**.
4. **`DiscoveryProfileSerializer` est un `Serializer` simple**, pas un `ModelSerializer` : les champs doivent être déclarés explicitement, et `get_has_liked_you` a besoin de `obj.user`.
5. **`order_by('-interaction_type')` repose sur l'ordre lexical** (`'super_like' > 'like'`) : fragile mais fonctionnel ; tester explicitement.
6. **`security.py` renvoie `None` si `DEBUG=True`** → le rate limit n'est pas testable en dev sans forcer les settings.
7. **`ProfileApi` n'est pas injecté dans `MatchRepositoryImpl`** (seul `MatchingApi` l'est) → F-4.2 doit soit changer l'injection, soit passer par `MatchingApi`.
8. **La constante `Constants.superLikesPerDay = 1`** n'est référencée nulle part : la **supprimer** plutôt que la corriger, pour ne pas créer une 3ᵉ source de vérité. Idem `getSuperLikesRemaining()` (frontend) : 0 appelant → remplacer par `getSuperLikeQuota()`, ne pas conserver les deux.
9. **`_getMainFeatures`** dans `plan_card.dart:233` affiche `X Super Likes/jour` depuis le **plan** — déjà cohérent avec B-1.5 ; ne pas le transformer en constante.
10. **L'ordre d'affichage des limites** dans la page découverte : `_buildDailyLimitIndicator` est en `top: 70` (`discovery_page.dart:353`) → placer le badge super like à `top: 112` pour éviter le chevauchement.
11. **`_emitLoaded` construit `DiscoveryLoaded` en fin de corps** (pas de paramètre de quota) : ajouter `superLikeQuota: _superLikeQuota` à l'`emit(DiscoveryLoaded(...))` — lire les champs du BLoC suffit, aucun changement de signature.
12. **Ne jamais déployer F-7.2 (libellé d'upsell)** avant B-2 : sinon la promesse redevient fausse dans l'autre sens.

---

**Fin de l'annexe.** Application stricte de l'ordre de la section 0.3, puis remplissage de la checklist 3.1. Toute divergence entre ce guide et le code rencontré doit être signalée plutôt que contournée.

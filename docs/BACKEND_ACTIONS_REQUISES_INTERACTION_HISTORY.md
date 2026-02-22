# Actions Backend Requises - Historique d'Interactions

## 📋 Résumé Exécutif

Le frontend de l'historique d'interactions est **complètement implémenté** avec un mock repository. Pour activer cette fonctionnalité en production, le backend Django doit implémenter 4 endpoints API.

**État actuel** : Mock repository fonctionnel (40 profils de test)
**État requis** : API REST complète avec persistance en base de données

---

## 🔴 Problèmes Identifiés

### 1. **Aucun Endpoint Backend Implémenté**
Les logs backend montrent uniquement :
```
INFO views_discovery - Discovery request
INFO basehttp - GET /api/v1/matches/?page=1&page_size=20
```

**Aucun appel** à `/api/v1/interactions/` car les endpoints n'existent pas encore.

### 2. **Frontend Utilise Mock Data**
Le frontend fonctionne avec `InteractionHistoryRepositoryMock` :
- 15 likes générés (3 super likes, 4 matches)
- 25 passes générés
- Données en mémoire uniquement

---

## 🎯 Endpoints à Implémenter

### 1. **GET /api/v1/interactions/likes/**
**Description** : Récupérer la liste des profils likés par l'utilisateur

**Paramètres Query** :
```python
{
    "page": 1,              # Numéro de page (défaut: 1)
    "page_size": 20,        # Nombre d'éléments par page (défaut: 20)
    "include_matched": true # Inclure les likes qui sont devenus des matches
}
```

**Réponse Success (200)** :
```json
{
  "count": 42,
  "next": "http://api/v1/interactions/likes/?page=2",
  "previous": null,
  "results": [
    {
      "id": "interaction-uuid-1",
      "profile": {
        "id": "profile-uuid-1",
        "display_name": "Sophie",
        "age": 28,
        "main_photo_url": "https://...",
        "other_photos_urls": ["https://...", "https://..."],
        "bio": "Passionnée de voyage...",
        "city": "Paris",
        "country": "France",
        "distance": 5.2,
        "interests": ["Voyage", "Sport", "Cinéma"],
        "relationship_type": "casual",
        "is_verified": true,
        "is_premium": false,
        "last_active": "2025-12-29T08:00:00Z",
        "compatibility_score": 85.5
      },
      "type": "like",           // ou "super_like"
      "timestamp": "2025-12-28T15:30:00Z",
      "is_matched": true,
      "match_id": "match-uuid-1", // null si pas de match
      "can_revoke": false        // false si c'est un match actif
    }
  ]
}
```

**Logique Métier** :
```python
# Requête SQL approximative
SELECT 
    i.id,
    i.profile_id,
    i.interaction_type,
    i.created_at,
    m.id as match_id,
    CASE WHEN m.id IS NOT NULL THEN true ELSE false END as is_matched,
    CASE WHEN m.id IS NULL THEN true ELSE false END as can_revoke
FROM interactions i
LEFT JOIN matches m ON i.profile_id = m.profile_id AND m.user_id = i.user_id
WHERE i.user_id = <current_user_id>
  AND i.interaction_type IN ('like', 'super_like')
  AND (i.include_matched = true OR m.id IS NULL)
ORDER BY i.created_at DESC
LIMIT <page_size> OFFSET <(page-1)*page_size>
```

**Permissions** :
- Utilisateur authentifié uniquement
- Ne peut voir que ses propres interactions

**Codes d'Erreur** :
- 401 : Non authentifié
- 403 : Non autorisé
- 500 : Erreur serveur

---

### 2. **GET /api/v1/interactions/passes/**
**Description** : Récupérer la liste des profils passés (disliked) par l'utilisateur

**Paramètres Query** :
```python
{
    "page": 1,        # Numéro de page
    "page_size": 20   # Nombre d'éléments par page
}
```

**Réponse Success (200)** :
```json
{
  "count": 125,
  "next": "http://api/v1/interactions/passes/?page=2",
  "previous": null,
  "results": [
    {
      "id": "interaction-uuid-50",
      "profile": {
        "id": "profile-uuid-50",
        "display_name": "Marc",
        "age": 32,
        "main_photo_url": "https://...",
        "other_photos_urls": ["https://..."],
        "bio": "Amateur de...",
        "city": "Lyon",
        "country": "France",
        "distance": 12.5,
        "interests": ["Sport", "Musique"],
        "relationship_type": "serious",
        "is_verified": false,
        "is_premium": false,
        "last_active": "2025-12-27T10:00:00Z",
        "compatibility_score": 45.0
      },
      "type": "dislike",
      "timestamp": "2025-12-29T07:15:00Z",
      "is_matched": false,
      "match_id": null,
      "can_revoke": true
    }
  ]
}
```

**Logique Métier** :
```python
# Requête SQL approximative
SELECT 
    i.id,
    i.profile_id,
    i.interaction_type,
    i.created_at,
    true as can_revoke
FROM interactions i
WHERE i.user_id = <current_user_id>
  AND i.interaction_type = 'dislike'
ORDER BY i.created_at DESC
LIMIT <page_size> OFFSET <(page-1)*page_size>
```

**Permissions** : Identiques à `/likes/`

---

### 3. **DELETE /api/v1/interactions/{interaction_id}/revoke/**
**Description** : Annuler une interaction (like ou pass) pour que le profil réapparaisse en découverte

**Paramètres URL** :
- `interaction_id` : UUID de l'interaction à révoquer

**Body** : Aucun

**Réponse Success (204 No Content)** :
```json
{}
```

**Réponse Erreur (400)** :
```json
{
  "error": "cannot_revoke_matched",
  "message": "Impossible de révoquer un like qui a abouti à un match actif"
}
```

**Réponse Erreur (404)** :
```json
{
  "error": "not_found",
  "message": "Interaction non trouvée"
}
```

**Logique Métier** :
```python
def revoke_interaction(interaction_id, user_id):
    # 1. Vérifier que l'interaction existe et appartient à l'utilisateur
    interaction = Interaction.objects.get(
        id=interaction_id,
        user_id=user_id
    )
    
    # 2. Vérifier qu'il n'y a pas de match actif (si c'est un like)
    if interaction.interaction_type in ['like', 'super_like']:
        match_exists = Match.objects.filter(
            user_id=user_id,
            profile_id=interaction.profile_id,
            status='active'
        ).exists()
        
        if match_exists:
            raise ValidationError("Cannot revoke matched interaction")
    
    # 3. Supprimer l'interaction
    interaction.delete()
    
    # 4. Optionnel : Réinitialiser le flag dans discovery_state
    # pour que le profil réapparaisse
    DiscoveryState.objects.filter(
        user_id=user_id,
        profile_id=interaction.profile_id
    ).delete()
    
    return Response(status=204)
```

**Side Effects** :
1. L'interaction est supprimée de la table `interactions`
2. Le profil réapparaît dans le flux de découverte
3. Si c'était un match pending, le match est supprimé

**Permissions** :
- Utilisateur authentifié
- Ne peut révoquer que ses propres interactions
- Ne peut pas révoquer un like qui est devenu un match actif

---

### 4. **GET /api/v1/interactions/stats/**
**Description** : Obtenir les statistiques d'interactions de l'utilisateur

**Paramètres** : Aucun

**Réponse Success (200)** :
```json
{
  "total_likes": 45,
  "total_super_likes": 8,
  "total_dislikes": 120,
  "total_matches": 12,
  "match_rate": 26.67,           // (matches / total_likes) * 100
  "total_interactions_today": 5,
  "total_interactions_week": 28,
  "total_interactions": 173,      // likes + super_likes + dislikes
  "profile": {
    "likes_given": 53,            // total_likes + total_super_likes
    "likes_received": 87,
    "matches": 12,
    "conversations_started": 8
  }
}
```

**Logique Métier** :
```python
def get_interaction_stats(user_id):
    from django.db.models import Count, Q, F
    from datetime import datetime, timedelta
    
    # Compteurs par type
    stats = Interaction.objects.filter(
        user_id=user_id
    ).aggregate(
        total_likes=Count('id', filter=Q(interaction_type='like')),
        total_super_likes=Count('id', filter=Q(interaction_type='super_like')),
        total_dislikes=Count('id', filter=Q(interaction_type='dislike')),
    )
    
    # Compteur de matches
    total_matches = Match.objects.filter(
        user_id=user_id,
        status='active'
    ).count()
    
    # Interactions récentes
    today = datetime.now().date()
    week_ago = today - timedelta(days=7)
    
    today_count = Interaction.objects.filter(
        user_id=user_id,
        created_at__date=today
    ).count()
    
    week_count = Interaction.objects.filter(
        user_id=user_id,
        created_at__gte=week_ago
    ).count()
    
    # Calcul du taux de match
    total_likes = stats['total_likes'] + stats['total_super_likes']
    match_rate = (total_matches / total_likes * 100) if total_likes > 0 else 0
    
    return {
        'total_likes': stats['total_likes'],
        'total_super_likes': stats['total_super_likes'],
        'total_dislikes': stats['total_dislikes'],
        'total_matches': total_matches,
        'match_rate': round(match_rate, 2),
        'total_interactions_today': today_count,
        'total_interactions_week': week_count,
        'total_interactions': total_likes + stats['total_dislikes'],
    }
```

**Permissions** : Utilisateur authentifié uniquement

---

## 🗄️ Modèle de Données Requis

### Table `interactions`
```python
class Interaction(models.Model):
    """Historique de toutes les interactions utilisateur"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='interactions')
    profile = models.ForeignKey('Profile', on_delete=models.CASCADE, related_name='received_interactions')
    
    interaction_type = models.CharField(
        max_length=20,
        choices=[
            ('like', 'Like'),
            ('super_like', 'Super Like'),
            ('dislike', 'Dislike/Pass'),
        ]
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Metadata optionnel
    location = models.JSONField(null=True, blank=True)  # Où l'interaction a eu lieu
    device_type = models.CharField(max_length=50, null=True, blank=True)
    
    class Meta:
        db_table = 'interactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'interaction_type', '-created_at']),
            models.Index(fields=['user', 'profile']),
            models.Index(fields=['created_at']),
        ]
        unique_together = [['user', 'profile']]  # Une seule interaction par couple user/profile
    
    def __str__(self):
        return f"{self.user.email} - {self.interaction_type} - {self.profile.display_name}"
```

### Migration SQL
```sql
-- Création de la table
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    interaction_type VARCHAR(20) NOT NULL CHECK (interaction_type IN ('like', 'super_like', 'dislike')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    location JSONB NULL,
    device_type VARCHAR(50) NULL,
    UNIQUE(user_id, profile_id)
);

-- Index pour performance
CREATE INDEX idx_interactions_user_type_date ON interactions(user_id, interaction_type, created_at DESC);
CREATE INDEX idx_interactions_user_profile ON interactions(user_id, profile_id);
CREATE INDEX idx_interactions_date ON interactions(created_at DESC);
CREATE INDEX idx_interactions_profile ON interactions(profile_id);

-- Trigger pour updated_at
CREATE TRIGGER update_interactions_updated_at
    BEFORE UPDATE ON interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔧 Implémentation Django Recommandée

### 1. **Serializers**

```python
# hivmeet_backend/apps/interactions/serializers.py

from rest_framework import serializers
from .models import Interaction
from apps.profiles.serializers import DiscoveryProfileSerializer

class InteractionHistorySerializer(serializers.ModelSerializer):
    """Serializer pour l'historique d'interactions"""
    
    profile = DiscoveryProfileSerializer(read_only=True)
    is_matched = serializers.SerializerMethodField()
    match_id = serializers.SerializerMethodField()
    can_revoke = serializers.SerializerMethodField()
    
    class Meta:
        model = Interaction
        fields = [
            'id',
            'profile',
            'type',
            'timestamp',
            'is_matched',
            'match_id',
            'can_revoke',
        ]
    
    def get_is_matched(self, obj):
        """Vérifie si l'interaction a abouti à un match"""
        if obj.interaction_type not in ['like', 'super_like']:
            return False
        
        from apps.matches.models import Match
        return Match.objects.filter(
            user=obj.user,
            profile=obj.profile,
            status='active'
        ).exists()
    
    def get_match_id(self, obj):
        """Retourne l'ID du match si existe"""
        if not self.get_is_matched(obj):
            return None
        
        from apps.matches.models import Match
        match = Match.objects.filter(
            user=obj.user,
            profile=obj.profile,
            status='active'
        ).first()
        return str(match.id) if match else None
    
    def get_can_revoke(self, obj):
        """Indique si l'interaction peut être révoquée"""
        # Ne peut pas révoquer un like qui est devenu un match
        return not self.get_is_matched(obj)


class InteractionStatsSerializer(serializers.Serializer):
    """Serializer pour les statistiques"""
    
    total_likes = serializers.IntegerField()
    total_super_likes = serializers.IntegerField()
    total_dislikes = serializers.IntegerField()
    total_matches = serializers.IntegerField()
    match_rate = serializers.FloatField()
    total_interactions_today = serializers.IntegerField()
    total_interactions_week = serializers.IntegerField()
    total_interactions = serializers.IntegerField()
```

### 2. **Views**

```python
# hivmeet_backend/apps/interactions/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Q
from datetime import datetime, timedelta
from .models import Interaction
from .serializers import InteractionHistorySerializer, InteractionStatsSerializer

class InteractionHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour gérer l'historique d'interactions
    
    Endpoints:
    - GET /api/v1/interactions/likes/ - Liste des likes
    - GET /api/v1/interactions/passes/ - Liste des passes
    - DELETE /api/v1/interactions/{id}/revoke/ - Révoquer une interaction
    - GET /api/v1/interactions/stats/ - Statistiques
    """
    
    permission_classes = [IsAuthenticated]
    serializer_class = InteractionHistorySerializer
    
    def get_queryset(self):
        """Retourne uniquement les interactions de l'utilisateur connecté"""
        return Interaction.objects.filter(
            user=self.request.user
        ).select_related('profile')
    
    @action(detail=False, methods=['get'], url_path='likes')
    def get_likes(self, request):
        """
        Récupère la liste des profils likés
        
        Query params:
        - page: numéro de page (défaut: 1)
        - page_size: taille de page (défaut: 20)
        - include_matched: inclure les matches (défaut: false)
        """
        include_matched = request.query_params.get('include_matched', 'false').lower() == 'true'
        
        queryset = self.get_queryset().filter(
            interaction_type__in=['like', 'super_like']
        )
        
        # Filtrer les matches si nécessaire
        if not include_matched:
            from apps.matches.models import Match
            matched_profile_ids = Match.objects.filter(
                user=request.user,
                status='active'
            ).values_list('profile_id', flat=True)
            
            queryset = queryset.exclude(profile_id__in=matched_profile_ids)
        
        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], url_path='passes')
    def get_passes(self, request):
        """Récupère la liste des profils passés (disliked)"""
        queryset = self.get_queryset().filter(
            interaction_type='dislike'
        )
        
        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['delete'], url_path='revoke')
    def revoke_interaction(self, request, pk=None):
        """
        Révoque une interaction pour que le profil réapparaisse en découverte
        
        Returns:
        - 204: Interaction révoquée avec succès
        - 400: Impossible de révoquer (match actif)
        - 404: Interaction non trouvée
        """
        try:
            interaction = self.get_queryset().get(pk=pk)
        except Interaction.DoesNotExist:
            return Response(
                {'error': 'not_found', 'message': 'Interaction non trouvée'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Vérifier qu'il n'y a pas de match actif
        if interaction.interaction_type in ['like', 'super_like']:
            from apps.matches.models import Match
            if Match.objects.filter(
                user=request.user,
                profile=interaction.profile,
                status='active'
            ).exists():
                return Response(
                    {
                        'error': 'cannot_revoke_matched',
                        'message': 'Impossible de révoquer un like qui a abouti à un match actif'
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Supprimer l'interaction
        profile_id = interaction.profile_id
        interaction.delete()
        
        # Réinitialiser l'état de découverte (optionnel)
        from apps.discovery.models import DiscoveryState
        DiscoveryState.objects.filter(
            user=request.user,
            profile_id=profile_id
        ).delete()
        
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=False, methods=['get'], url_path='stats')
    def get_stats(self, request):
        """Retourne les statistiques d'interactions de l'utilisateur"""
        user = request.user
        
        # Compteurs par type
        interaction_stats = Interaction.objects.filter(
            user=user
        ).aggregate(
            total_likes=Count('id', filter=Q(interaction_type='like')),
            total_super_likes=Count('id', filter=Q(interaction_type='super_like')),
            total_dislikes=Count('id', filter=Q(interaction_type='dislike')),
        )
        
        # Matches
        from apps.matches.models import Match
        total_matches = Match.objects.filter(
            user=user,
            status='active'
        ).count()
        
        # Interactions récentes
        today = datetime.now().date()
        week_ago = today - timedelta(days=7)
        
        today_count = Interaction.objects.filter(
            user=user,
            created_at__date=today
        ).count()
        
        week_count = Interaction.objects.filter(
            user=user,
            created_at__gte=week_ago
        ).count()
        
        # Calculs
        total_likes = interaction_stats['total_likes'] + interaction_stats['total_super_likes']
        match_rate = (total_matches / total_likes * 100) if total_likes > 0 else 0
        
        stats_data = {
            'total_likes': interaction_stats['total_likes'],
            'total_super_likes': interaction_stats['total_super_likes'],
            'total_dislikes': interaction_stats['total_dislikes'],
            'total_matches': total_matches,
            'match_rate': round(match_rate, 2),
            'total_interactions_today': today_count,
            'total_interactions_week': week_count,
            'total_interactions': total_likes + interaction_stats['total_dislikes'],
        }
        
        serializer = InteractionStatsSerializer(stats_data)
        return Response(serializer.data)
```

### 3. **URLs**

```python
# hivmeet_backend/apps/interactions/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import InteractionHistoryViewSet

router = DefaultRouter()
router.register(r'interactions', InteractionHistoryViewSet, basename='interaction')

urlpatterns = [
    path('', include(router.urls)),
]
```

```python
# hivmeet_backend/hivmeet_backend/urls.py

urlpatterns = [
    # ... autres patterns
    path('api/v1/', include('apps.interactions.urls')),
]
```

### 4. **Tests**

```python
# hivmeet_backend/apps/interactions/tests.py

from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.authentication.models import User
from apps.profiles.models import Profile
from .models import Interaction

class InteractionHistoryTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@test.com',
            password='Test123!'
        )
        self.client.force_authenticate(user=self.user)
        
        # Créer des profils de test
        self.profile1 = Profile.objects.create(...)
        self.profile2 = Profile.objects.create(...)
    
    def test_get_likes(self):
        """Test récupération des likes"""
        # Créer des interactions
        Interaction.objects.create(
            user=self.user,
            profile=self.profile1,
            interaction_type='like'
        )
        
        response = self.client.get('/api/v1/interactions/likes/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
    
    def test_revoke_interaction(self):
        """Test révocation d'une interaction"""
        interaction = Interaction.objects.create(
            user=self.user,
            profile=self.profile1,
            interaction_type='dislike'
        )
        
        response = self.client.delete(
            f'/api/v1/interactions/{interaction.id}/revoke/'
        )
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(
            Interaction.objects.filter(id=interaction.id).exists()
        )
    
    def test_cannot_revoke_matched_interaction(self):
        """Test qu'on ne peut pas révoquer un like qui est un match"""
        from apps.matches.models import Match
        
        interaction = Interaction.objects.create(
            user=self.user,
            profile=self.profile1,
            interaction_type='like'
        )
        
        Match.objects.create(
            user=self.user,
            profile=self.profile1,
            status='active'
        )
        
        response = self.client.delete(
            f'/api/v1/interactions/{interaction.id}/revoke/'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('cannot_revoke_matched', response.data['error'])
```

---

## 🔄 Migration des Données Existantes

Si des interactions existent déjà dans d'autres tables, créer un script de migration :

```python
# scripts/migrate_interactions.py

from django.core.management.base import BaseCommand
from apps.interactions.models import Interaction
from apps.discovery.models import Swipe  # Ancienne table

class Command(BaseCommand):
    help = 'Migre les anciennes interactions vers la nouvelle table'
    
    def handle(self, *args, **options):
        # Migrer les swipes existants
        swipes = Swipe.objects.all()
        
        for swipe in swipes:
            interaction_type = {
                'right': 'like',
                'super': 'super_like',
                'left': 'dislike',
            }.get(swipe.direction, 'dislike')
            
            Interaction.objects.get_or_create(
                user=swipe.user,
                profile=swipe.profile,
                defaults={
                    'interaction_type': interaction_type,
                    'created_at': swipe.created_at,
                }
            )
        
        self.stdout.write(
            self.style.SUCCESS(f'Migré {swipes.count()} interactions')
        )
```

---

## 📝 Checklist d'Implémentation

### Phase 1 : Modèle de Données
- [ ] Créer le modèle `Interaction`
- [ ] Créer la migration Django
- [ ] Appliquer la migration en dev
- [ ] Vérifier les index et contraintes
- [ ] Créer des données de test

### Phase 2 : API Endpoints
- [ ] Implémenter `GET /interactions/likes/`
- [ ] Implémenter `GET /interactions/passes/`
- [ ] Implémenter `DELETE /interactions/{id}/revoke/`
- [ ] Implémenter `GET /interactions/stats/`
- [ ] Ajouter la pagination
- [ ] Ajouter les filtres

### Phase 3 : Tests
- [ ] Tests unitaires pour le modèle
- [ ] Tests d'intégration pour chaque endpoint
- [ ] Tests de permissions
- [ ] Tests de performance (pagination)
- [ ] Tests de révocation

### Phase 4 : Intégration Frontend
- [ ] Remplacer `InteractionHistoryRepositoryMock` par `InteractionHistoryRepositoryImpl`
- [ ] Mapper les réponses API vers les entités Dart
- [ ] Tester la pagination infinie
- [ ] Tester la révocation avec rafraîchissement
- [ ] Tester la navigation vers les profils

### Phase 5 : Documentation & Déploiement
- [ ] Documenter les endpoints dans Swagger/OpenAPI
- [ ] Mettre à jour le README du backend
- [ ] Préparer le script de migration
- [ ] Déployer en staging
- [ ] Tests de charge
- [ ] Déploiement en production

---

## 🚀 Commandes de Développement

```bash
# Créer l'app Django
cd hivmeet_backend
python manage.py startapp interactions

# Créer et appliquer les migrations
python manage.py makemigrations interactions
python manage.py migrate

# Créer des données de test
python manage.py shell
>>> from scripts.create_test_interactions import create_test_data
>>> create_test_data()

# Lancer les tests
python manage.py test apps.interactions

# Vérifier les endpoints
python manage.py show_urls | grep interactions
```

---

## 📊 Estimations

| Tâche | Temps Estimé | Priorité |
|-------|--------------|----------|
| Modèle de données + migrations | 2h | Haute |
| Endpoints GET (likes, passes, stats) | 3h | Haute |
| Endpoint DELETE (revoke) | 1h | Haute |
| Tests unitaires | 2h | Moyenne |
| Tests d'intégration | 2h | Moyenne |
| Migration données existantes | 1h | Basse |
| Documentation | 1h | Moyenne |
| **TOTAL** | **12h** | |

---

## 🔗 Références

- [Spécification Backend Complète](./BACKEND_INTERACTION_HISTORY_SPECIFICATION.md) - 500+ lignes avec détails SQL, Python, tests
- [Django REST Framework - ViewSets](https://www.django-rest-framework.org/api-guide/viewsets/)
- [PostgreSQL - Indexes](https://www.postgresql.org/docs/current/indexes.html)

---

**Document créé le** : 29 décembre 2025  
**Dernière mise à jour** : 29 décembre 2025  
**Auteur** : GitHub Copilot (Claude Sonnet 4.5)  
**Version** : 1.0

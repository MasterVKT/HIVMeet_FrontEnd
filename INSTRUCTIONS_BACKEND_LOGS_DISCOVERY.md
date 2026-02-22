0# 🔧 Instructions Backend : Ajouter Logs pour Diagnostiquer count=0

## 📋 Problème Constaté

**Frontend logs :**
```
🔄 DEBUG MatchRepositoryImpl: Payload complet: {count: 0, next: null, previous: null, results: []}
   📊 Count backend: 0
```

**Diagnostic backend :**
```
✅ Profils disponibles pour Marie: 26
🎯 Profils révoqués actifs: 6 (tous disponibles)
✅ is_revoked=False filtre fonctionne correctement
```

**Conclusion** : Le backend filtre les interactions révoquées correctement, MAIS applique d'autres filtres qui retournent 0 profils.

---

## 🛠️ Modifications Requises

### 1. Ajouter des logs détaillés dans `matching/views_discovery.py`

**Fichier** : `matching/views_discovery.py`  
**Fonction** : `get_discovery_profiles(request)`

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_discovery_profiles(request):
    user = request.user
    
    # LOG 1: Utilisateur
    logger.info(f"🔍 Discovery request - User: {user.first_name} ({user.email})")
    logger.info(f"🔍 Is authenticated: {user.is_authenticated}")
    
    # Récupérer les paramètres de pagination
    page = int(request.query_params.get('page', 1))
    page_size = min(int(request.query_params.get('page_size', 10)), 50)
    
    try:
        # Récupérer le profil utilisateur
        user_profile = Profile.objects.get(user=user)
        
        # LOG 2: Préférences utilisateur
        logger.info(f"📋 User preferences:")
        logger.info(f"   - Age range: {user_profile.age_min_preference}-{user_profile.age_max_preference}")
        logger.info(f"   - Max distance: {user_profile.distance_max_km}km")
        logger.info(f"   - Genders sought: {user_profile.genders_sought}")
        logger.info(f"   - Verified only: {user_profile.verified_only}")
        logger.info(f"   - Online only: {user_profile.online_only}")
        
        # Appeler le service de recommandation
        profiles = get_recommendations(
            user=user,
            limit=page_size,
            offset=(page - 1) * page_size
        )
        
        # LOG 3: Résultats
        logger.info(f"✅ Recommendations service returned: {len(profiles)} profiles")
        
        # Sérialiser les résultats
        serializer = DiscoveryProfileSerializer(profiles, many=True, context={'request': request})
        
        # LOG 4: Réponse finale
        logger.info(f"📤 Sending response - count: {len(profiles)}")
        
        return Response({
            'count': len(profiles),
            'next': None,
            'previous': None,
            'results': serializer.data
        })
        
    except Profile.DoesNotExist:
        logger.error(f"❌ Profile not found for user {user.email}")
        return Response({'error': 'Profile not found'}, status=404)
    except Exception as e:
        logger.error(f"❌ Error getting discovery profiles: {str(e)}")
        return Response({'error': str(e)}, status=500)
```

### 2. Ajouter des logs dans `matching/services.py`

**Fichier** : `matching/services.py`  
**Fonction** : `get_recommendations(user, limit, offset)`

```python
def get_recommendations(user, limit=20, offset=0):
    """
    Récupère les profils recommandés pour un utilisateur.
    """
    logger = logging.getLogger(__name__)
    
    # LOG 1: Début
    logger.info(f"🔍 get_recommendations - User: {user.email}, limit: {limit}, offset: {offset}")
    
    try:
        # Récupérer le profil utilisateur
        user_profile = Profile.objects.get(user=user)
        
        # LOG 2: Profils déjà interactés (is_revoked=False UNIQUEMENT)
        interacted_user_ids = InteractionHistory.objects.filter(
            user=user,
            is_revoked=False  # ✅ Filtre correct
        ).values_list('target_user_id', flat=True)
        
        logger.info(f"🚫 Excluding {len(interacted_user_ids)} profiles (active interactions)")
        logger.info(f"   Excluded IDs: {list(interacted_user_ids)[:5]}..." if len(interacted_user_ids) > 5 else f"   Excluded IDs: {list(interacted_user_ids)}")
        
        # LOG 3: Requête base
        profiles_qs = Profile.objects.exclude(
            user=user  # Exclure soi-même
        ).exclude(
            user_id__in=interacted_user_ids  # Exclure interactions actives
        )
        
        logger.info(f"📊 After exclusions: {profiles_qs.count()} profiles")
        
        # LOG 4: Appliquer filtres utilisateur
        # Filtrer par âge
        if user_profile.age_min_preference and user_profile.age_max_preference:
            from datetime import date
            from dateutil.relativedelta import relativedelta
            
            max_birth_date = date.today() - relativedelta(years=user_profile.age_min_preference)
            min_birth_date = date.today() - relativedelta(years=user_profile.age_max_preference + 1)
            
            profiles_qs = profiles_qs.filter(
                user__date_of_birth__lte=max_birth_date,
                user__date_of_birth__gte=min_birth_date
            )
            logger.info(f"   After age filter ({user_profile.age_min_preference}-{user_profile.age_max_preference}): {profiles_qs.count()} profiles")
        
        # Filtrer par genre
        if user_profile.genders_sought:
            profiles_qs = profiles_qs.filter(gender__in=user_profile.genders_sought)
            logger.info(f"   After gender filter ({user_profile.genders_sought}): {profiles_qs.count()} profiles")
        
        # Filtrer verified_only
        if user_profile.verified_only:
            profiles_qs = profiles_qs.filter(user__is_verified=True)
            logger.info(f"   After verified_only filter: {profiles_qs.count()} profiles")
        
        # Filtrer online_only
        if user_profile.online_only:
            from datetime import datetime, timedelta
            recent_threshold = datetime.now() - timedelta(minutes=30)
            profiles_qs = profiles_qs.filter(user__last_active__gte=recent_threshold)
            logger.info(f"   After online_only filter: {profiles_qs.count()} profiles")
        
        # Filtrer par distance
        if user_profile.latitude and user_profile.longitude and user_profile.distance_max_km:
            # TODO: Ajouter filtre distance géographique
            logger.info(f"   Distance filter: max {user_profile.distance_max_km}km (NOT IMPLEMENTED)")
        
        # Filtrer allow_profile_in_discovery
        profiles_qs = profiles_qs.filter(allow_profile_in_discovery=True)
        logger.info(f"   After allow_profile_in_discovery filter: {profiles_qs.count()} profiles")
        
        # LOG 5: Pagination
        profiles = list(profiles_qs[offset:offset + limit])
        logger.info(f"✅ Final result after pagination [{offset}:{offset+limit}]: {len(profiles)} profiles")
        
        return profiles
        
    except Profile.DoesNotExist:
        logger.error(f"❌ Profile not found for user {user.email}")
        return []
    except Exception as e:
        logger.error(f"❌ Error in get_recommendations: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return []
```

---

## 🎯 Test Après Modifications

1. **Redémarrer le serveur Django**
2. **Depuis le frontend, déclencher une découverte**
3. **Vérifier les logs backend**

**Logs attendus :**
```
INFO 🔍 Discovery request - User: Marie (marie.claire@test.com)
INFO 📋 User preferences:
INFO    - Age range: 20-40
INFO    - Max distance: 50km
INFO    - Genders sought: ['female', 'other']
INFO    - Verified only: True  ← CAUSE PROBABLE DU PROBLÈME
INFO    - Online only: False
INFO 🔍 get_recommendations - User: marie.claire@test.com, limit: 5, offset: 0
INFO 🚫 Excluding 15 profiles (active interactions)
INFO 📊 After exclusions: 26 profiles
INFO    After age filter (20-40): 26 profiles
INFO    After gender filter (['female']): 15 profiles
INFO    After verified_only filter: 0 profiles  ← PROBLÈME ICI
INFO ✅ Final result: 0 profiles
```

---

## 🔍 Causes Probables du count=0

Basé sur le diagnostic, les causes probables sont :

1. **`verified_only: true`** avec peu/aucun profil vérifié
2. **`online_only: true`** avec peu d'utilisateurs connectés récemment
3. **Filtres de genre trop restrictifs**
4. **Filtres d'âge trop restrictifs**

Les logs détaillés permettront d'identifier précisément quel filtre élimine tous les profils.

---

## ✅ Solution Temporaire

Pour débloquer l'utilisateur immédiatement :

```sql
-- Désactiver verified_only pour Marie
UPDATE profiles_profile
SET verified_only = FALSE
WHERE user_id = '0e5ac2cb-07d8-4160-9f36-90393356f8c0';
```

Ou depuis l'admin Django : http://localhost:8000/admin/profiles/profile/

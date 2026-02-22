# Diagnostic : Écran Blanc au Lancement (29 Décembre 2025)

## 📊 Analyse des Logs

### ✅ Ce qui fonctionne correctement

1. **Authentification Firebase** : ✅ OK
   - Utilisateur authentifié : `marie.claire@test.com` (ID: `ayFjmQHalCYhmh8g6fOAPuf88ER2`)
   - Token Firebase valide

2. **Navigation** : ✅ OK
   - Navigation vers `/discovery` effectuée avec succès
   - Page Discovery initialisée correctement

3. **Communication Backend** : ✅ OK
   - Requête envoyée : `GET /discovery/` 
   - Réponse HTTP 200 reçue
   - Payload JSON valide : `{count: 0, next: null, previous: null, results: []}`

4. **UI** : ✅ OK
   - `EmptyStateWidget` s'affiche correctement
   - Titre : "Plus de profils"
   - Message : "Vous avez vu tous les profils disponibles dans votre région..."
   - Bouton "Ajuster les filtres" présent

### ❌ Le problème identifié

**Le backend renvoie 0 profils dans la liste de découverte.**

```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

## 🔍 Causes possibles

### 1. Base de données vide ou insuffisante
- Pas assez de profils dans la base de données de test
- Profils non complétés/validés
- Profils supprimés ou désactivés

### 2. Filtres trop restrictifs
Le log indique : `"Les filtres sauvegardés doivent être appliqués automatiquement par le backend"`

Les filtres peuvent être trop restrictifs :
- Distance maximale trop courte
- Tranche d'âge trop étroite
- Critères de séropositivité spécifiques
- Autres filtres personnalisés

### 3. Problème de localisation
- Utilisateur sans position géographique définie
- Position géographique invalide
- Aucun profil dans la zone géographique

### 4. Problème algorithmique backend
- Bug dans l'algorithme de matching
- Profils déjà vus/swipés exclus
- Profils cachés ou bloqués

## 🛠️ Solutions proposées

### Solution 1 : Vérifier et peupler la base de données (Backend)

**Priorité : HAUTE**

Créer un script pour ajouter des profils de test :

```python
# backend/scripts/populate_test_data.py
from django.contrib.auth import get_user_model
from apps.profiles.models import Profile

User = get_user_model()

# Créer 10 profils de test avec localisation Paris
test_users = [
    {
        'email': f'test{i}@hivmeet.com',
        'username': f'testuser{i}',
        'first_name': f'Test{i}',
        'age': 25 + i,
        'bio': f'Profil de test {i}',
        'latitude': 48.8566 + (i * 0.01),  # Paris avec variations
        'longitude': 2.3522 + (i * 0.01),
        'city': 'Paris',
        'country': 'France',
    }
    for i in range(1, 11)
]

for user_data in test_users:
    # Créer utilisateur et profil
    user, created = User.objects.get_or_create(
        email=user_data['email'],
        defaults={'username': user_data['username']}
    )
    if created:
        user.set_password('Test1234!')
        user.save()
        
        Profile.objects.create(
            user=user,
            first_name=user_data['first_name'],
            age=user_data['age'],
            bio=user_data['bio'],
            latitude=user_data['latitude'],
            longitude=user_data['longitude'],
            city=user_data['city'],
            country=user_data['country'],
            is_profile_complete=True,
        )
        print(f"✅ Profil créé : {user_data['email']}")
```

**Commande à exécuter :**
```bash
python manage.py shell < scripts/populate_test_data.py
```

### Solution 2 : Réinitialiser les filtres (Frontend)

**Priorité : MOYENNE**

Ajouter une option pour réinitialiser les filtres par défaut :

**Modification dans `discovery_page.dart` :**

```dart
Widget _buildNoMoreProfilesState() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      EmptyStateWidget(
        icon: Icons.people_outline,
        title: LocalizationService.translate('discovery.no_more_profiles_title'),
        message: LocalizationService.translate('discovery.no_more_profiles_message'),
        actionText: LocalizationService.translate('discovery.adjust_filters'),
        onAction: _showFiltersModal,
      ),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: _resetFiltersAndReload,
        icon: const Icon(Icons.refresh),
        label: const Text('Réinitialiser les filtres'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
        ),
      ),
    ],
  );
}

void _resetFiltersAndReload() async {
  // Réinitialiser les filtres
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('discovery_filters');
  
  // Recharger les profils
  _discoveryBloc.add(const LoadDiscoveryProfiles(limit: 5));
  
  // Afficher un message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Filtres réinitialisés')),
  );
}
```

### Solution 3 : Améliorer le feedback utilisateur (Frontend)

**Priorité : HAUTE**

Le widget d'état vide existe déjà, mais peut être amélioré pour mieux guider l'utilisateur :

**Modification dans `empty_state_widget.dart` :**

```dart
Widget build(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation ou illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.openSans(
              fontSize: 16,
              color: AppColors.slate,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.tune),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

### Solution 4 : Debug des filtres (Backend)

**Priorité : HAUTE**

Ajouter des logs pour comprendre pourquoi aucun profil n'est retourné :

**Dans le backend (views.py) :**

```python
@api_view(['GET'])
def discovery_profiles(request):
    user = request.user
    
    # Log des filtres appliqués
    filters = request.GET.dict()
    logger.info(f"🔍 Discovery pour {user.email} avec filtres: {filters}")
    
    # Compter tous les profils disponibles
    total_profiles = Profile.objects.exclude(user=user).count()
    logger.info(f"📊 Total profils en DB (excluant utilisateur): {total_profiles}")
    
    # Appliquer les filtres
    queryset = Profile.objects.exclude(user=user)
    
    # Log après chaque filtre
    if 'min_age' in filters:
        queryset = queryset.filter(age__gte=filters['min_age'])
        logger.info(f"📊 Après filtre âge min: {queryset.count()}")
    
    if 'max_distance' in filters and user.profile.latitude:
        # Filtre distance...
        logger.info(f"📊 Après filtre distance: {queryset.count()}")
    
    logger.info(f"✅ Profils retournés: {queryset.count()}")
    
    # ... reste du code
```

## 📋 Plan d'action immédiat

### Étape 1 : Vérifier la base de données (Backend) ⚡

```bash
# Lancer le shell Django
python manage.py shell

# Compter les profils
from apps.profiles.models import Profile
total = Profile.objects.count()
complete = Profile.objects.filter(is_profile_complete=True).count()
print(f"Total profils: {total}, Complétés: {complete}")

# Vérifier le profil de l'utilisateur connecté
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.get(email='marie.claire@test.com')
print(f"Profil: {user.profile}")
print(f"Localisation: {user.profile.latitude}, {user.profile.longitude}")
```

### Étape 2 : Peupler la base avec des données de test

Si le nombre de profils est < 5, exécuter le script de population.

### Étape 3 : Tester l'endpoint directement

```bash
# Tester avec curl
curl -H "Authorization: Bearer <TOKEN>" \
     http://10.0.2.2:8000/api/v1/discovery/
```

### Étape 4 : Améliorer l'UI frontend

Implémenter les améliorations du widget d'état vide pour un meilleur feedback.

## 🎯 Solution recommandée (rapide)

**Action immédiate : Peupler la base de données**

1. Créer 10-20 profils de test avec des localisations proches
2. S'assurer que les profils sont complétés (`is_profile_complete=True`)
3. Vérifier que l'utilisateur actuel a une localisation définie
4. Relancer l'application

**L'écran blanc disparaîtra car il y aura des profils à afficher !**

## 📝 Notes importantes

- **L'application fonctionne correctement** : ce n'est pas un bug du frontend
- **Le backend répond correctement** : status 200, JSON valide
- **L'UI s'affiche correctement** : `EmptyStateWidget` visible
- **Le problème est les données** : 0 profils dans la base de données de test

## ✅ Validation

Après avoir ajouté des profils, vous devriez voir dans les logs :

```
I/flutter: 🔄 DEBUG MatchRepositoryImpl: Liste extraite: 5 éléments
I/flutter: ✅ DEBUG MatchRepositoryImpl: Profils mappés: 5
I/flutter: ✅ DEBUG DiscoveryBloc: Profils récupérés: 5
I/flutter: 🔄 DEBUG DiscoveryPage: State change: DiscoveryLoaded(...)
```

Et l'affichage des cartes de profil au lieu de l'état vide.

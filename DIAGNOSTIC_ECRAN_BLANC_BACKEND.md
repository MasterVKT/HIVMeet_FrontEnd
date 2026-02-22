# Diagnostic - Écran Blanc: Aucun Profil Disponible

## ❌ Problème Actuel

L'application démarre correctement mais affiche un écran blanc avec le message "Plus de profils disponibles" car **le backend retourne 0 profils**.

## 🔍 Logs Observés

```
I/flutter (28276): 🔄 DEBUG MatchRepositoryImpl: Réponse reçue - status: 200
I/flutter (28276): 🔄 DEBUG MatchRepositoryImpl: Payload: {count: 0, next: null, previous: null, results: []}
I/flutter (28276): 🔄 DEBUG MatchRepositoryImpl: Liste extraite: 0 éléments
I/flutter (28276): ✅ DEBUG MatchRepositoryImpl: Profils mappés: 0
I/flutter (28276): ✅ DEBUG DiscoveryBloc: Profils récupérés: 0
I/flutter (28276): ℹ️ DEBUG DiscoveryBloc: NoMoreProfiles émis
```

## ✅ Ce Qui Fonctionne

- ✅ **Authentification Firebase** : L'utilisateur Marie est connecté
- ✅ **Navigation** : L'application navigue vers /discovery
- ✅ **Appel API** : GET /api/v1/discovery/profiles retourne 200 OK
- ✅ **Parsing** : La réponse JSON est correctement parsée

## ❌ Ce Qui Ne Fonctionne Pas

- ❌ **Aucun profil** : Le backend retourne `results: []`
- ❌ **NoMoreProfiles** : L'état affiché est "Plus de profils disponibles"
- ❌ **Écran blanc** : Aucune carte de profil à afficher

## 🎯 Cause Racine

Le backend Django **n'a pas de profils de découverte** dans la base de données pour l'utilisateur Marie (`0e5ac2cb-07d8-4160-9f36-90393356f8c0`).

### Raisons Possibles :

1. **Base de données vide** : Aucun profil utilisateur n'a été créé
2. **Filtres trop restrictifs** : Les préférences de Marie excluent tous les profils
3. **Algorithme de découverte** : Tous les profils ont déjà été likés/dislikés
4. **Géolocalisation** : Aucun profil dans la zone géographique
5. **Backend de test** : Utilisation du script Flask au lieu du backend Django

## 🔧 Solutions

### Solution 1 : Vérifier le Backend Actif

**Vérifiez quel backend est en cours d'exécution :**

```bash
# Vérifier si Django est actif sur le port 8000
curl http://localhost:8000/admin/
```

**Résultat attendu :**
- Si Django : Page d'administration Django
- Si Flask : `Backend de test opérationnel !`

### Solution 2 : Créer des Profils de Test (Backend Django)

Si vous utilisez le backend Django, créez des profils de test :

```bash
# Depuis le répertoire backend Django
python manage.py shell

# Dans le shell Django
from apps.users.models import User, UserProfile
from datetime import date

# Créer plusieurs profils de test
for i in range(5):
    user = User.objects.create_user(
        email=f'test{i}@example.com',
        password='testpass123'
    )
    UserProfile.objects.create(
        user=user,
        display_name=f'Test User {i}',
        birthdate=date(1990 + i, 1, 1),
        gender='male' if i % 2 == 0 else 'female',
        bio=f'Bio du profil test {i}',
        city='Paris',
        country='France'
    )
```

### Solution 3 : Utiliser le Backend de Test Amélioré

Si vous utilisez le script de test `test_backend_simulation.py`, il faut l'améliorer pour retourner des profils.

**Créer un nouveau backend de test complet :**

```python
# test_backend_complete.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import uuid
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# Compteur de likes pour simulation
likes_remaining = 10

# Profils de test
TEST_PROFILES = [
    {
        "id": str(uuid.uuid4()),
        "display_name": "Sophie",
        "age": 28,
        "bio": "Passionnée de voyages et de photographie 📸",
        "city": "Paris",
        "country": "France",
        "photos": [
            {"photo_url": "http://10.0.2.2:8000/media/default_female.jpg", "is_main": True}
        ],
        "interests": ["Voyages", "Photographie", "Cuisine"],
        "is_verified": True,
        "is_online": False,
        "last_active": (datetime.now() - timedelta(hours=2)).isoformat(),
        "distance_km": 5.2
    },
    {
        "id": str(uuid.uuid4()),
        "display_name": "Thomas",
        "age": 32,
        "bio": "Amateur de cuisine et de randonnée 🏔️",
        "city": "Lyon",
        "country": "France",
        "photos": [
            {"photo_url": "http://10.0.2.2:8000/media/default_male.jpg", "is_main": True}
        ],
        "interests": ["Cuisine", "Randonnée", "Musique"],
        "is_verified": False,
        "is_online": True,
        "last_active": datetime.now().isoformat(),
        "distance_km": 12.8
    },
    {
        "id": str(uuid.uuid4()),
        "display_name": "Emma",
        "age": 26,
        "bio": "Yoga, méditation et vie saine 🧘‍♀️",
        "city": "Paris",
        "country": "France",
        "photos": [
            {"photo_url": "http://10.0.2.2:8000/media/default_female.jpg", "is_main": True}
        ],
        "interests": ["Yoga", "Méditation", "Sport"],
        "is_verified": True,
        "is_online": False,
        "last_active": (datetime.now() - timedelta(days=1)).isoformat(),
        "distance_km": 3.5
    },
    {
        "id": str(uuid.uuid4()),
        "display_name": "Lucas",
        "age": 30,
        "bio": "Développeur et gamer passionné 🎮",
        "city": "Paris",
        "country": "France",
        "photos": [
            {"photo_url": "http://10.0.2.2:8000/media/default_male.jpg", "is_main": True}
        ],
        "interests": ["Gaming", "Tech", "Cinéma"],
        "is_verified": False,
        "is_online": True,
        "last_active": datetime.now().isoformat(),
        "distance_km": 8.2
    },
    {
        "id": str(uuid.uuid4()),
        "display_name": "Léa",
        "age": 27,
        "bio": "Artiste et musicienne 🎨🎵",
        "city": "Paris",
        "country": "France",
        "photos": [
            {"photo_url": "http://10.0.2.2:8000/media/default_female.jpg", "is_main": True}
        ],
        "interests": ["Art", "Musique", "Culture"],
        "is_verified": True,
        "is_online": False,
        "last_active": (datetime.now() - timedelta(hours=5)).isoformat(),
        "distance_km": 6.7
    }
]

@app.route('/api/v1/discovery/profiles', methods=['GET'])
def discovery_profiles():
    """Retourne les profils de découverte"""
    auth_header = request.headers.get('Authorization')
    
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Token manquant ou invalide'}), 401
    
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('page_size', 20))
    
    # Pagination
    start = (page - 1) * page_size
    end = start + page_size
    profiles_page = TEST_PROFILES[start:end]
    
    return jsonify({
        'count': len(TEST_PROFILES),
        'next': f'/api/v1/discovery/profiles?page={page+1}&page_size={page_size}' if end < len(TEST_PROFILES) else None,
        'previous': f'/api/v1/discovery/profiles?page={page-1}&page_size={page_size}' if page > 1 else None,
        'results': profiles_page
    })

@app.route('/api/v1/discovery/interactions/like', methods=['POST'])
def like_profile():
    """Like un profil"""
    global likes_remaining
    
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Token manquant ou invalide'}), 401
    
    data = request.get_json()
    target_user_id = data.get('target_user_id')
    
    if not target_user_id:
        return jsonify({'error': 'target_user_id requis'}), 400
    
    # Décrémenter les likes restants
    if likes_remaining > 0:
        likes_remaining -= 1
    
    # Simuler un match 20% du temps
    is_match = (likes_remaining % 5 == 0)
    
    return jsonify({
        'result': 'match' if is_match else 'like_sent',
        'match_id': str(uuid.uuid4()) if is_match else None,
        'daily_likes_remaining': likes_remaining,
        'super_likes_remaining': 3,
        'message': "It's a match!" if is_match else "Like envoyé"
    })

@app.route('/api/v1/discovery/interactions/dislike', methods=['POST'])
def dislike_profile():
    """Dislike un profil"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Token manquant ou invalide'}), 401
    
    data = request.get_json()
    target_user_id = data.get('target_user_id')
    
    if not target_user_id:
        return jsonify({'error': 'target_user_id requis'}), 400
    
    return jsonify({
        'result': 'dislike_sent',
        'message': 'Profil ignoré'
    })

@app.route('/api/v1/auth/firebase-exchange/', methods=['POST'])
def firebase_exchange():
    """Échange token Firebase"""
    data = request.get_json()
    firebase_token = data.get('firebase_token')
    
    if not firebase_token:
        return jsonify({'error': 'firebase_token requis'}), 400
    
    return jsonify({
        'access_token': 'test-access-token-123',
        'refresh_token': 'test-refresh-token-456',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'user': {
            'id': '0e5ac2cb-07d8-4160-9f36-90393356f8c0',
            'email': 'marie.claire@test.com',
            'display_name': 'Marie',
            'profile_complete': True
        }
    })

@app.route('/api/v1/health/')
def health():
    """Endpoint de santé"""
    return jsonify({
        'status': 'ok',
        'message': 'Backend de test avec profils',
        'profiles_count': len(TEST_PROFILES),
        'likes_remaining': likes_remaining
    })

if __name__ == '__main__':
    print("🚀 Démarrage backend de test HIVMeet")
    print(f"📊 {len(TEST_PROFILES)} profils de test disponibles")
    print("📍 URL: http://0.0.0.0:8000")
    print("📍 URL Émulateur: http://10.0.2.2:8000")
    print("\n✅ Endpoints disponibles:")
    print("   - GET  /api/v1/discovery/profiles")
    print("   - POST /api/v1/discovery/interactions/like")
    print("   - POST /api/v1/discovery/interactions/dislike")
    print("   - POST /api/v1/auth/firebase-exchange/")
    print("   - GET  /api/v1/health/")
    
    app.run(host='0.0.0.0', port=8000, debug=True, use_reloader=False)
```

**Lancer ce nouveau backend :**

```bash
python test_backend_complete.py
```

### Solution 4 : Ajuster les Préférences de Découverte

Si le backend est actif mais ne retourne pas de profils, vérifiez les préférences de recherche de Marie :

```bash
# Vérifier les préférences dans Django
python manage.py shell

from apps.users.models import UserProfile
marie = UserProfile.objects.get(user__email='marie.claire@test.com')
print(f"Age min: {marie.search_preferences.get('min_age', 18)}")
print(f"Age max: {marie.search_preferences.get('max_age', 99)}")
print(f"Distance max: {marie.search_preferences.get('max_distance_km', 50)}")
print(f"Genres recherchés: {marie.search_preferences.get('genders', [])}")
```

## 📋 Checklist de Dépannage

- [ ] Vérifier que le backend est en cours d'exécution sur le port 8000
- [ ] Tester l'endpoint : `curl http://localhost:8000/api/v1/health/`
- [ ] Vérifier qu'il y a des profils dans la base de données
- [ ] Vérifier les préférences de recherche de Marie
- [ ] Vérifier les logs backend pour des erreurs d'algorithme de découverte
- [ ] Tester avec le backend complet ci-dessus si nécessaire

## 🎯 Résultat Attendu

Après application d'une des solutions :

```
I/flutter: 🔄 DEBUG MatchRepositoryImpl: Payload: {count: 5, next: null, previous: null, results: [profil1, profil2, profil3, profil4, profil5]}
I/flutter: ✅ DEBUG MatchRepositoryImpl: Profils mappés: 5
I/flutter: ✅ DEBUG DiscoveryBloc: Profils récupérés: 5
I/flutter: 🔄 DEBUG DiscoveryBloc: _emitLoaded - _currentIndex: 0, _profiles.length: 5
```

L'application devrait maintenant afficher les cartes de profils au lieu de l'écran blanc.

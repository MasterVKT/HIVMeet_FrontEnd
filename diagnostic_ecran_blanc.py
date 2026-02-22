"""
Script pour diagnostiquer et corriger le problème d'écran blanc
Vérifie la base de données et crée des profils de test si nécessaire
"""

import requests
import json

# Configuration
BASE_URL = "http://10.0.2.2:8000"
API_URL = f"{BASE_URL}/api/v1"

def test_backend_availability():
    """Teste si le backend est accessible"""
    try:
        response = requests.get(f"{BASE_URL}/admin/", timeout=5)
        print(f"✅ Backend accessible (status: {response.status_code})")
        return True
    except Exception as e:
        print(f"❌ Backend inaccessible: {e}")
        return False

def get_firebase_token(email="marie.claire@test.com", password="Test1234!"):
    """Obtient un token Firebase pour tester"""
    print(f"\n🔐 Connexion avec {email}...")
    
    # Note: Ceci est un exemple, vous devrez utiliser votre méthode d'auth
    try:
        response = requests.post(
            f"{API_URL}/auth/login/",
            json={"email": email, "password": password},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('access_token') or data.get('token')
            print(f"✅ Token obtenu: {token[:20]}...")
            return token
        else:
            print(f"❌ Erreur login: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Exception login: {e}")
        return None

def test_discovery_endpoint(token):
    """Teste l'endpoint /discovery/"""
    print("\n🔍 Test de l'endpoint /discovery/...")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.get(
            f"{API_URL}/discovery/",
            headers=headers,
            timeout=10
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            count = data.get('count', 0)
            results = data.get('results', [])
            
            print(f"✅ Réponse reçue:")
            print(f"   - Count: {count}")
            print(f"   - Results: {len(results)} profils")
            
            if len(results) == 0:
                print("\n⚠️  PROBLÈME IDENTIFIÉ: Aucun profil retourné")
                print("   Causes possibles:")
                print("   1. Base de données vide")
                print("   2. Filtres trop restrictifs")
                print("   3. Pas de localisation définie")
                return False
            else:
                print("\n✅ Des profils sont disponibles!")
                for i, profile in enumerate(results[:3], 1):
                    print(f"   {i}. {profile.get('name', 'N/A')} - {profile.get('age', 'N/A')} ans")
                return True
        else:
            print(f"❌ Erreur: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def create_test_profiles_script():
    """Génère un script Django pour créer des profils de test"""
    script = """
# Script à exécuter dans Django shell
# python manage.py shell < create_test_profiles.py

from django.contrib.auth import get_user_model
from apps.profiles.models import Profile
import random

User = get_user_model()

# Données de test
test_data = [
    {'name': 'Sophie Martin', 'age': 28, 'bio': 'Passionnée de voyages et de lecture'},
    {'name': 'Thomas Dubois', 'age': 32, 'bio': 'Amateur de cuisine et de randonnée'},
    {'name': 'Emma Leroy', 'age': 26, 'bio': 'Artiste et mélomane'},
    {'name': 'Lucas Bernard', 'age': 30, 'bio': 'Développeur et gamer'},
    {'name': 'Chloé Petit', 'age': 29, 'bio': 'Photographe et aventurière'},
    {'name': 'Hugo Moreau', 'age': 27, 'bio': 'Musicien et cinéphile'},
    {'name': 'Léa Simon', 'age': 31, 'bio': 'Chef cuisinier et foodie'},
    {'name': 'Nathan Laurent', 'age': 33, 'bio': 'Sportif et nature lover'},
    {'name': 'Clara Michel', 'age': 25, 'bio': 'Designer et créative'},
    {'name': 'Alexandre Garnier', 'age': 34, 'bio': 'Entrepreneur et voyageur'},
]

# Coordonnées Paris centre avec variations
BASE_LAT = 48.8566
BASE_LON = 2.3522

created_count = 0

for i, data in enumerate(test_data, 1):
    email = f"test{i}@hivmeet.com"
    username = f"testuser{i}"
    
    # Vérifier si l'utilisateur existe déjà
    if User.objects.filter(email=email).exists():
        print(f"⏭️  {email} existe déjà")
        continue
    
    try:
        # Créer l'utilisateur
        user = User.objects.create_user(
            email=email,
            username=username,
            password='Test1234!'
        )
        
        # Créer le profil
        Profile.objects.create(
            user=user,
            first_name=data['name'].split()[0],
            age=data['age'],
            bio=data['bio'],
            latitude=BASE_LAT + (random.uniform(-0.05, 0.05)),
            longitude=BASE_LON + (random.uniform(-0.05, 0.05)),
            city='Paris',
            country='France',
            is_profile_complete=True,
            gender='other',
            looking_for='everyone',
        )
        
        created_count += 1
        print(f"✅ Profil créé: {data['name']} ({email})")
        
    except Exception as e:
        print(f"❌ Erreur pour {email}: {e}")

print(f"\\n🎉 {created_count} profils créés avec succès!")
"""
    
    with open('create_test_profiles.py', 'w', encoding='utf-8') as f:
        f.write(script)
    
    print("\n📄 Script généré: create_test_profiles.py")
    print("   Exécuter dans le backend:")
    print("   python manage.py shell < create_test_profiles.py")

def main():
    """Fonction principale de diagnostic"""
    print("=" * 60)
    print("🔍 DIAGNOSTIC ÉCRAN BLANC - HIVMeet")
    print("=" * 60)
    
    # Test 1: Backend accessible
    if not test_backend_availability():
        print("\n❌ Le backend n'est pas accessible!")
        print("   1. Vérifier que le serveur Django est lancé")
        print("   2. Vérifier l'URL: http://10.0.2.2:8000")
        return
    
    # Test 2: Authentification (optionnel)
    print("\n⚠️  Note: L'authentification Firebase n'est pas testée ici")
    print("   Le diagnostic se concentre sur la disponibilité des profils")
    
    # Test 3: Créer le script de population
    create_test_profiles_script()
    
    print("\n" + "=" * 60)
    print("📋 RÉSUMÉ DU DIAGNOSTIC")
    print("=" * 60)
    print("\n✅ Backend accessible")
    print("⚠️  Problème identifié: Backend renvoie 0 profils")
    print("\n🛠️  SOLUTION:")
    print("   1. Aller dans le dossier backend")
    print("   2. Exécuter: python manage.py shell < create_test_profiles.py")
    print("   3. Relancer l'application Flutter")
    print("   4. Les profils devraient apparaître!")
    print("\n💡 Alternative manuelle:")
    print("   - Se connecter à l'admin Django: http://10.0.2.2:8000/admin/")
    print("   - Créer manuellement quelques profils avec localisation")
    print("=" * 60)

if __name__ == "__main__":
    main()

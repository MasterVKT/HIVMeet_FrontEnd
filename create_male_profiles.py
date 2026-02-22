#!/usr/bin/env python3
"""
Script pour créer des profils masculins de test dans la base de données.
Marie (female, 39 ans) cherche des hommes de 30-50 ans dans un rayon de 25km.
"""

import os
import sys
import django
from datetime import date, timedelta
from decimal import Decimal

# Configuration Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'env', 'hivmeet_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hivmeet_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from profiles.models import Profile

User = get_user_model()

# Profils masculins à créer (30-50 ans, compatibles avec Marie)
MALE_PROFILES = [
    {
        'email': 'thomas.martin@test.com',
        'first_name': 'Thomas',
        'last_name': 'Martin',
        'age': 35,
        'bio': 'Passionné de voyage et de cuisine. À la recherche de moments authentiques.',
        'city': 'Paris',
        'latitude': 48.8566,
        'longitude': 2.3522,
    },
    {
        'email': 'julien.rousseau@test.com',
        'first_name': 'Julien',
        'last_name': 'Rousseau',
        'age': 42,
        'bio': 'Sportif et aventurier. J\'aime la nature et les défis.',
        'city': 'Paris',
        'latitude': 48.8606,
        'longitude': 2.3376,
    },
    {
        'email': 'alexandre.blanc@test.com',
        'first_name': 'Alexandre',
        'last_name': 'Blanc',
        'age': 38,
        'bio': 'Entrepreneur passionné. Amateur de bon vin et de bonnes conversations.',
        'city': 'Paris',
        'latitude': 48.8534,
        'longitude': 2.3488,
    },
    {
        'email': 'nicolas.petit@test.com',
        'first_name': 'Nicolas',
        'last_name': 'Petit',
        'age': 40,
        'bio': 'Musicien et créatif. À la recherche de complicité et de partage.',
        'city': 'Paris',
        'latitude': 48.8706,
        'longitude': 2.3522,
    },
    {
        'email': 'pierre.garcia@test.com',
        'first_name': 'Pierre',
        'last_name': 'Garcia',
        'age': 45,
        'bio': 'Chef cuisinier. Passionné de gastronomie et de moments conviviaux.',
        'city': 'Paris',
        'latitude': 48.8448,
        'longitude': 2.3733,
    },
    {
        'email': 'antoine.martinez@test.com',
        'first_name': 'Antoine',
        'last_name': 'Martinez',
        'age': 33,
        'bio': 'Architecte. J\'adore créer, voyager et découvrir de nouvelles cultures.',
        'city': 'Paris',
        'latitude': 48.8662,
        'longitude': 2.3422,
    },
    {
        'email': 'maxime.lopez@test.com',
        'first_name': 'Maxime',
        'last_name': 'Lopez',
        'age': 37,
        'bio': 'Développeur passionné de technologie. Cinéphile et amateur de jeux de société.',
        'city': 'Paris',
        'latitude': 48.8502,
        'longitude': 2.3654,
    },
    {
        'email': 'clement.fernandez@test.com',
        'first_name': 'Clément',
        'last_name': 'Fernandez',
        'age': 44,
        'bio': 'Médecin. Humain et attentionné. J\'aime les randonnées et la photographie.',
        'city': 'Paris',
        'latitude': 48.8588,
        'longitude': 2.3469,
    },
]


def create_male_profiles():
    print("=" * 80)
    print("CRÉATION DE PROFILS MASCULINS POUR TEST")
    print("=" * 80)
    
    created_count = 0
    
    for profile_data in MALE_PROFILES:
        email = profile_data['email']
        
        # Vérifier si l'utilisateur existe déjà
        if User.objects.filter(email=email).exists():
            print(f"\n⏭️  {email} existe déjà")
            continue
        
        # Calculer la date de naissance
        age = profile_data['age']
        today = date.today()
        date_of_birth = today - timedelta(days=age * 365 + age // 4)  # Approximation avec années bissextiles
        
        # Créer l'utilisateur
        user = User.objects.create_user(
            email=email,
            password='Test1234!',
            birth_date=date_of_birth,
        )
        user.is_active = True
        user.email_verified = True
        user.save()
        
        # Mettre à jour le profil (créé automatiquement par signal)
        profile = Profile.objects.get(user=user)
        profile.bio = profile_data['bio']
        profile.gender = 'male'
        profile.city = profile_data['city']
        profile.country = 'FR'
        profile.latitude = Decimal(str(profile_data['latitude']))
        profile.longitude = Decimal(str(profile_data['longitude']))
        profile.allow_profile_in_discovery = True
        profile.is_hidden = False
        # Préférences de recherche (cherche des femmes de 25-55 ans)
        profile.age_min_preference = 25
        profile.age_max_preference = 55
        profile.genders_sought = ['female']
        profile.distance_max_km = 50
        profile.relationship_types_sought = ['long_term', 'friendship', 'casual']
        profile.verified_only = False
        profile.online_only = False
        
        # ✅ FIX PRODUCTION: Définir gender_sought (requis pour Discovery filter)
        # Les profils masculins cherchent des femmes par défaut
        if hasattr(profile, 'gender_sought'):
            profile.gender_sought = 'female'
        
        profile.save()
        
        print(f"\n✅ Créé: {profile_data['first_name']} {profile_data['last_name']} ({age} ans)")
        print(f"   Email: {email}")
        print(f"   Localisation: {profile_data['city']} ({profile_data['latitude']}, {profile_data['longitude']})")
        print(f"   Cherche: femmes, 25-55 ans, dans 50km")
        
        created_count += 1
    
    print("\n" + "=" * 80)
    print(f"✅ TERMINÉ: {created_count} profils masculins créés")
    print("=" * 80)
    
    # Vérifier la compatibilité avec Marie
    print("\n🔍 VÉRIFICATION DE LA COMPATIBILITÉ AVEC MARIE")
    print("=" * 80)
    
    marie_email = "marie.claire@test.com"
    try:
        today = date.today()
        marie_user = User.objects.get(email=marie_email)
        marie_profile = Profile.objects.get(user=marie_user)
        
        print(f"\nMarie:")
        print(f"  - Genre: {marie_profile.gender}")
        print(f"  - Âge: {(today - marie_user.birth_date).days // 365} ans")
        print(f"  - Cherche: {marie_profile.genders_sought}")
        print(f"  - Âge recherché: {marie_profile.age_min_preference}-{marie_profile.age_max_preference} ans")
        print(f"  - Distance max: {marie_profile.distance_max_km}km")
        
        # Compter les profils compatibles
        compatible_count = 0
        for profile_data in MALE_PROFILES:
            age = profile_data['age']
            if marie_profile.age_min_preference <= age <= marie_profile.age_max_preference:
                compatible_count += 1
                print(f"\n✅ Compatible: {profile_data['first_name']} ({age} ans)")
        
        print(f"\n📊 Total profils compatibles: {compatible_count}/{len(MALE_PROFILES)}")
        
    except User.DoesNotExist:
        print(f"\n⚠️  Marie ({marie_email}) n'existe pas dans la base")


if __name__ == '__main__':
    create_male_profiles()

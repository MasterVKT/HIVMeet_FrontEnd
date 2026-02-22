# Script Django pour créer des profils de test
# À exécuter avec: python manage.py shell < create_test_profiles.py

from django.contrib.auth import get_user_model
import random

User = get_user_model()

# Vérifier si le modèle Profile existe
try:
    from apps.profiles.models import Profile
    print("✅ Modèle Profile importé")
except ImportError:
    try:
        from profiles.models import Profile
        print("✅ Modèle Profile importé")
    except ImportError:
        print("❌ Impossible d'importer le modèle Profile")
        print("   Veuillez vérifier la structure de votre projet Django")
        exit(1)

# Données de test avec diversité
test_data = [
    {'name': 'Sophie Martin', 'age': 28, 'bio': 'Passionnée de voyages et de lecture. J\'aime découvrir de nouvelles cultures.', 'gender': 'female'},
    {'name': 'Thomas Dubois', 'age': 32, 'bio': 'Amateur de cuisine et de randonnée. Toujours partant pour une aventure!', 'gender': 'male'},
    {'name': 'Emma Leroy', 'age': 26, 'bio': 'Artiste et mélomane. La musique est ma vie, l\'art ma passion.', 'gender': 'female'},
    {'name': 'Lucas Bernard', 'age': 30, 'bio': 'Développeur et gamer. Entre code et jeux vidéo, mon cœur balance.', 'gender': 'male'},
    {'name': 'Chloé Petit', 'age': 29, 'bio': 'Photographe et aventurière. Je capture les moments qui comptent.', 'gender': 'female'},
    {'name': 'Hugo Moreau', 'age': 27, 'bio': 'Musicien et cinéphile. La vie est un film, jouons-en la bande son!', 'gender': 'male'},
    {'name': 'Léa Simon', 'age': 31, 'bio': 'Chef cuisinier et foodie. La cuisine est un art que j\'aime partager.', 'gender': 'female'},
    {'name': 'Nathan Laurent', 'age': 33, 'bio': 'Sportif et nature lover. Le plein air, c\'est ma thérapie.', 'gender': 'male'},
    {'name': 'Clara Michel', 'age': 25, 'bio': 'Designer et créative. Je vois le monde en couleurs et en formes.', 'gender': 'female'},
    {'name': 'Alexandre Garnier', 'age': 34, 'bio': 'Entrepreneur et voyageur. Le monde est mon terrain de jeu!', 'gender': 'male'},
    {'name': 'Julie Rousseau', 'age': 27, 'bio': 'Professeure de yoga et zen attitude. Namaste! 🧘‍♀️', 'gender': 'female'},
    {'name': 'Maxime Blanc', 'age': 29, 'bio': 'Architecte et passionné d\'urbanisme. Je construis l\'avenir!', 'gender': 'male'},
    {'name': 'Sarah Vincent', 'age': 26, 'bio': 'Infirmière et bénévole. Aider les autres, c\'est ma vocation.', 'gender': 'female'},
    {'name': 'Antoine Girard', 'age': 35, 'bio': 'Écrivain et poète. Les mots sont mes compagnons de route.', 'gender': 'male'},
    {'name': 'Camille Fournier', 'age': 28, 'bio': 'Danseuse et chorégraphe. La danse est mon langage universel.', 'gender': 'female'},
]

# Coordonnées Paris centre avec variations (environ 5km de rayon)
BASE_LAT = 48.8566
BASE_LON = 2.3522

# Quartiers parisiens pour diversité
quartiers = [
    {'name': 'Marais', 'lat': 48.8566, 'lon': 2.3622},
    {'name': 'Montmartre', 'lat': 48.8867, 'lon': 2.3431},
    {'name': 'Latin Quarter', 'lat': 48.8499, 'lon': 2.3467},
    {'name': 'Saint-Germain', 'lat': 48.8534, 'lon': 2.3364},
    {'name': 'Bastille', 'lat': 48.8532, 'lon': 2.3692},
]

created_count = 0
skipped_count = 0
error_count = 0

print("\n" + "="*60)
print("🚀 CRÉATION DE PROFILS DE TEST POUR HIVMEET")
print("="*60 + "\n")

for i, data in enumerate(test_data, 1):
    email = f"test{i}@hivmeet.com"
    username = f"testuser{i}"
    
    # Vérifier si l'utilisateur existe déjà
    if User.objects.filter(email=email).exists():
        print(f"⏭️  [{i:2d}/{len(test_data)}] {email} existe déjà - ignoré")
        skipped_count += 1
        continue
    
    try:
        # Créer l'utilisateur
        user = User.objects.create_user(
            email=email,
            username=username,
            password='Test1234!',
            is_active=True,
        )
        
        # Choisir un quartier aléatoire
        quartier = random.choice(quartiers)
        
        # Ajouter une petite variation aléatoire (±500m environ)
        lat = quartier['lat'] + random.uniform(-0.005, 0.005)
        lon = quartier['lon'] + random.uniform(-0.005, 0.005)
        
        # Déterminer le looking_for de manière aléatoire
        looking_for_options = ['male', 'female', 'everyone']
        looking_for = random.choice(looking_for_options)
        
        # Créer le profil avec tous les champs nécessaires
        profile_data = {
            'user': user,
            'first_name': data['name'].split()[0],
            'age': data['age'],
            'bio': data['bio'],
            'latitude': lat,
            'longitude': lon,
            'city': 'Paris',
            'country': 'France',
            'is_profile_complete': True,
            'gender': data['gender'],
            'looking_for': looking_for,
        }
        
        # Ajouter d'autres champs si nécessaire
        profile = Profile.objects.create(**profile_data)
        
        created_count += 1
        print(f"✅ [{i:2d}/{len(test_data)}] {data['name']:20s} | {data['age']} ans | {quartier['name']:15s} | {email}")
        
    except Exception as e:
        error_count += 1
        print(f"❌ [{i:2d}/{len(test_data)}] Erreur pour {email}: {str(e)[:50]}")

# Résumé
print("\n" + "="*60)
print("📊 RÉSUMÉ DE LA CRÉATION")
print("="*60)
print(f"✅ Profils créés:  {created_count}")
print(f"⏭️  Profils ignorés: {skipped_count} (déjà existants)")
print(f"❌ Erreurs:        {error_count}")
print(f"📝 Total traité:   {len(test_data)}")

if created_count > 0:
    print(f"\n🎉 {created_count} nouveau(x) profil(s) créé(s) avec succès!")
    print("\n💡 Prochaines étapes:")
    print("   1. Vérifier dans l'admin Django: http://10.0.2.2:8000/admin/")
    print("   2. Relancer l'application Flutter")
    print("   3. Les profils devraient maintenant apparaître dans Discovery!")
else:
    print("\n⚠️  Aucun nouveau profil créé.")
    print("   Tous les profils de test existent déjà ou des erreurs sont survenues.")

# Afficher les statistiques globales
print("\n" + "="*60)
print("📊 STATISTIQUES DE LA BASE DE DONNÉES")
print("="*60)
total_users = User.objects.count()
total_profiles = Profile.objects.count()
complete_profiles = Profile.objects.filter(is_profile_complete=True).count()

print(f"Total utilisateurs:      {total_users}")
print(f"Total profils:           {total_profiles}")
print(f"Profils complétés:       {complete_profiles}")
print("="*60 + "\n")

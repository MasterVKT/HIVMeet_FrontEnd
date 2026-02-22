#!/usr/bin/env python3
"""
Script de migration de données: Ajouter gender_sought aux profils existants.

Ce script corrige les profils qui n'ont pas de valeur gender_sought définie,
ce qui bloque le filtre de compatibilité mutuelle dans Discovery.

Usage:
    python fix_gender_sought.py

Requis:
    - Django configuré correctement
    - Accès à la base de données
"""

import os
import sys
import django
from datetime import datetime

# Configuration Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'env', 'hivmeet_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hivmeet_backend.settings')
django.setup()

from profiles.models import Profile
from django.db.models import Q


def fix_gender_sought():
    """
    Ajoute gender_sought aux profils qui n'en ont pas.
    
    Logique par défaut:
    - Profils masculins -> cherchent 'female'
    - Profils féminins -> cherchent 'male'
    - Profils autres/non-binaires -> cherchent 'all'
    """
    print("=" * 80)
    print(f"FIX GENDER_SOUGHT - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    # Vérifier si le champ existe
    if not hasattr(Profile, 'gender_sought'):
        print("\n❌ ERREUR: Le modèle Profile n'a pas de champ 'gender_sought'")
        print("   Vérifiez que les migrations Django sont à jour.")
        return
    
    # 1. Profils masculins sans gender_sought
    print("\n📊 Analyse des profils masculins...")
    male_profiles = Profile.objects.filter(
        Q(gender='male') & (Q(gender_sought__isnull=True) | Q(gender_sought=''))
    )
    male_count = male_profiles.count()
    print(f"   Trouvés: {male_count} profils masculins sans gender_sought")
    
    if male_count > 0:
        print(f"   ✅ Mise à jour: gender_sought='female' pour {male_count} profils")
        male_profiles.update(gender_sought='female')
    
    # 2. Profils féminins sans gender_sought
    print("\n📊 Analyse des profils féminins...")
    female_profiles = Profile.objects.filter(
        Q(gender='female') & (Q(gender_sought__isnull=True) | Q(gender_sought=''))
    )
    female_count = female_profiles.count()
    print(f"   Trouvés: {female_count} profils féminins sans gender_sought")
    
    if female_count > 0:
        print(f"   ✅ Mise à jour: gender_sought='male' pour {female_count} profils")
        female_profiles.update(gender_sought='male')
    
    # 3. Profils non-binaires/autres sans gender_sought
    print("\n📊 Analyse des profils non-binaires/autres...")
    other_profiles = Profile.objects.filter(
        Q(gender__in=['non_binary', 'other']) & (Q(gender_sought__isnull=True) | Q(gender_sought=''))
    )
    other_count = other_profiles.count()
    print(f"   Trouvés: {other_count} profils non-binaires/autres sans gender_sought")
    
    if other_count > 0:
        print(f"   ✅ Mise à jour: gender_sought='all' pour {other_count} profils")
        other_profiles.update(gender_sought='all')
    
    # 4. Vérification finale
    print("\n" + "=" * 80)
    print("VÉRIFICATION FINALE")
    print("=" * 80)
    
    remaining = Profile.objects.filter(
        Q(gender_sought__isnull=True) | Q(gender_sought='')
    ).count()
    
    if remaining == 0:
        print("\n✅ SUCCÈS: Tous les profils ont maintenant un gender_sought défini")
    else:
        print(f"\n⚠️  ATTENTION: {remaining} profils n'ont toujours pas de gender_sought")
        print("   Vérifiez manuellement ces profils.")
    
    # Statistiques finales
    print("\n📊 STATISTIQUES FINALES:")
    print(f"   - Profils males mis à jour: {male_count}")
    print(f"   - Profils females mis à jour: {female_count}")
    print(f"   - Profils autres mis à jour: {other_count}")
    print(f"   - Total: {male_count + female_count + other_count} profils corrigés")
    
    # Afficher quelques exemples
    print("\n🔍 EXEMPLES DE PROFILS CORRIGÉS:")
    examples = Profile.objects.filter(gender='male').values('user__email', 'gender', 'gender_sought')[:5]
    for example in examples:
        print(f"   - {example['user__email']}: gender={example['gender']}, gender_sought={example['gender_sought']}")
    
    print("\n" + "=" * 80)
    print("✅ TERMINÉ")
    print("=" * 80)


if __name__ == '__main__':
    try:
        fix_gender_sought()
    except Exception as e:
        print(f"\n❌ ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

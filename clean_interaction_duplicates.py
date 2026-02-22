#!/usr/bin/env python3
"""
Script pour nettoyer les duplicatas d'interactions.
Garde seulement la plus récente interaction de chaque type pour chaque couple (user, target_user).
"""

import os
import sys
import django

# Configuration Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'env', 'hivmeet_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hivmeet_backend.settings')
django.setup()

from matching.models import InteractionHistory
from django.contrib.auth import get_user_model
from django.db.models import Count

User = get_user_model()


def main():
    print("=" * 80)
    print("NETTOYAGE DES DUPLICATAS D'INTERACTIONS")
    print("=" * 80)
    
    # 1. Trouver tous les duplicatas (même user, même target_user, is_revoked=False)
    duplicates = (
        InteractionHistory.objects
        .filter(is_revoked=False)
        .values('user_id', 'target_user_id')
        .annotate(count=Count('id'))
        .filter(count__gt=1)
    )
    
    print(f"\nDuplicatas trouvés: {duplicates.count()} couples")
    
    total_deleted = 0
    
    for dup in duplicates:
        user_id = dup['user_id']
        target_user_id = dup['target_user_id']
        
        # Récupérer toutes les interactions pour ce couple
        interactions = InteractionHistory.objects.filter(
            user_id=user_id,
            target_user_id=target_user_id,
            is_revoked=False
        ).order_by('-created_at')
        
        user = User.objects.get(id=user_id)
        target_user = User.objects.get(id=target_user_id)
        
        print(f"\n{user.email} -> {target_user.email}")
        print(f"   {interactions.count()} interactions actives")
        
        # Garder seulement la plus récente
        most_recent = interactions.first()
        to_delete = interactions.exclude(id=most_recent.id)
        
        print(f"   Garder: [{most_recent.interaction_type}] {most_recent.created_at}")
        for old_interaction in to_delete:
            print(f"   SUPPRIMER: [{old_interaction.interaction_type}] {old_interaction.created_at}")
            old_interaction.delete()
            total_deleted += 1
    
    print("\n" + "=" * 80)
    print(f"TERMINÉ: {total_deleted} interactions dupliquées supprimées")
    print("=" * 80)


if __name__ == '__main__':
    response = input("Voulez-vous vraiment supprimer les duplicatas? (oui/non): ")
    if response.lower() in ['oui', 'yes', 'y']:
        main()
    else:
        print("Annulé")

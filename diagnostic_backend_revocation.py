#!/usr/bin/env python3
"""
Script de diagnostic pour vérifier pourquoi le backend retourne 0 profils après révocation.

Ce script se connecte au backend Django pour :
1. Vérifier les interactions révoquées
2. Tester la logique de découverte
3. Identifier pourquoi count=0
4. Identifier le problème du profil "Chris" dans likes ET passes
"""

import os
import sys
import django

# Configuration Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'env', 'hivmeet_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hivmeet_backend.settings')
django.setup()

from profiles.models import Profile
from matching.models import InteractionHistory
from django.contrib.auth import get_user_model

User = get_user_model()


def main():
    print("=" * 80)
    print("🔍 DIAGNOSTIC BACKEND - RÉVOCATION ET DÉCOUVERTE")
    print("=" * 80)
    
    # Utilisateur Marie
    marie_email = "marie.claire@test.com"
    try:
        marie_user = User.objects.get(email=marie_email)
        marie_profile = Profile.objects.get(user=marie_user)
        print(f"\n✅ Utilisateur trouvé: {marie_email}")
        print(f"   ID: {marie_user.id}")
        print(f"   Profile ID: {marie_profile.id}")
    except User.DoesNotExist:
        print(f"\n❌ Utilisateur {marie_email} non trouvé")
        return
    
    # 1. Vérifier les interactions révoquées
    print("\n" + "=" * 80)
    print("📋 INTERACTIONS RÉVOQUÉES")
    print("=" * 80)
    
    revoked_interactions = InteractionHistory.objects.filter(
        user=marie_user,
        is_revoked=True
    ).select_related('target_user')
    
    print(f"\n🔄 Interactions révoquées: {revoked_interactions.count()}")
    for interaction in revoked_interactions:
        target_profile = Profile.objects.filter(user=interaction.target_user).first()
        print(f"   - ({interaction.target_user.email}) "
              f"[{interaction.interaction_type}] "
              f"révoqué le {interaction.revoked_at}")
    
    # 2. Vérifier les interactions actives (non révoquées)
    print("\n" + "=" * 80)
    print("📋 INTERACTIONS ACTIVES (is_revoked=False)")
    print("=" * 80)
    
    active_interactions = InteractionHistory.objects.filter(
        user=marie_user,
        is_revoked=False
    ).select_related('target_user')
    
    print(f"\n✅ Interactions actives: {active_interactions.count()}")
    for interaction in active_interactions:
        print(f"   - ({interaction.target_user.email}) "
              f"[{interaction.interaction_type}]")
    
    # 3. Vérifier la logique de découverte
    print("\n" + "=" * 80)
    print("🔍 LOGIQUE DE DÉCOUVERTE")
    print("=" * 80)
    
    # Profils exclus (interactions actives uniquement)
    excluded_user_ids = InteractionHistory.objects.filter(
        user=marie_user,
        is_revoked=False  # Devrait exclure SEULEMENT les non-révoqués
    ).values_list('target_user_id', flat=True)
    
    print(f"\n🚫 Profils exclus de la découverte: {len(excluded_user_ids)}")
    print(f"   IDs exclus: {list(excluded_user_ids)[:5]}..." if len(excluded_user_ids) > 5 else f"   IDs exclus: {list(excluded_user_ids)}")
    
    # Profils disponibles
    available_profiles = Profile.objects.exclude(
        user_id=marie_user.id  # Exclure Marie elle-même
    ).exclude(
        user_id__in=excluded_user_ids  # Exclure interactions actives
    )
    
    print(f"\n✅ Profils disponibles pour Marie: {available_profiles.count()}")
    for profile in available_profiles[:5]:
        print(f"   - ({profile.user.email})")
    
    # 4. Vérifier les profils révoqués qui DEVRAIENT réapparaître
    print("\n" + "=" * 80)
    print("🔄 PROFILS RÉVOQUÉS QUI DEVRAIENT RÉAPPARAÎTRE")
    print("=" * 80)
    
    revoked_user_ids = revoked_interactions.values_list('target_user_id', flat=True)
    revoked_profiles = Profile.objects.filter(
        user_id__in=revoked_user_ids
    )
    
    print(f"\n🎯 Profils révoqués actifs: {revoked_profiles.count()}")
    for profile in revoked_profiles:
        # Vérifier si ce profil est bien disponible
        is_excluded = profile.user_id in excluded_user_ids
        print(f"   - ({profile.user.email}) "
              f"{'❌ EXCLU' if is_excluded else '✅ DISPONIBLE'}")
    
    # 5. Problème du profil "Chris" dans les deux listes
    print("\n" + "=" * 80)
    print("DIAGNOSTIC: Profil 'Chris' dans likes ET passes")
    print("=" * 80)
    
    chris_profiles = Profile.objects.filter(user__email__icontains='chris')
    for chris in chris_profiles:
        print(f"\n** ({chris.user.email})")
        print(f"   ID: {chris.id}")
        
        # Vérifier toutes les interactions avec Chris
        interactions_with_chris = InteractionHistory.objects.filter(
            user=marie_user,
            target_user=chris.user
        ).order_by('-created_at')
        
        print(f"   Total interactions: {interactions_with_chris.count()}")
        for idx, interaction in enumerate(interactions_with_chris, 1):
            status = "RÉVOQUÉ" if interaction.is_revoked else "ACTIF"
            print(f"      {idx}. [{interaction.interaction_type}] - {status} - {interaction.created_at}")
            if interaction.is_revoked:
                print(f"         Révoqué le: {interaction.revoked_at}")
    
    # 6. Vérifier les likes de Marie
    print("\n" + "=" * 80)
    print("💖 LIKES DE MARIE")
    print("=" * 80)
    
    likes = InteractionHistory.objects.filter(
        user=marie_user,
        interaction_type='like',
        is_revoked=False
    ).select_related('target_user')
    
    print(f"\n✅ Likes actifs: {likes.count()}")
    for like in likes:
        print(f"   - ({like.target_user.email})")
    
    # 7. Vérifier les passes de Marie
    print("\n" + "=" * 80)
    print("👎 PASSES DE MARIE")
    print("=" * 80)
    
    passes = InteractionHistory.objects.filter(
        user=marie_user,
        interaction_type='dislike',
        is_revoked=False
    ).select_related('target_user')
    
    print(f"\n✅ Passes actifs: {passes.count()}")
    for pass_interaction in passes:
        print(f"   - ({pass_interaction.target_user.email})")
    
    # 8. Rechercher les duplicatas (même personne dans likes ET passes)
    print("\n" + "=" * 80)
    print("🔍 RECHERCHE DE DUPLICATAS")
    print("=" * 80)
    
    like_user_ids = set(likes.values_list('target_user_id', flat=True))
    pass_user_ids = set(passes.values_list('target_user_id', flat=True))
    
    duplicates = like_user_ids & pass_user_ids
    
    if duplicates:
        print(f"\n⚠️  DUPLICATAS TROUVÉS: {len(duplicates)} profil(s)")
        for user_id in duplicates:
            user = User.objects.get(id=user_id)
            print(f"\n   \u274c ({user.email})")
            
            # Afficher toutes les interactions
            all_interactions = InteractionHistory.objects.filter(
                user=marie_user,
                target_user=user
            ).order_by('-created_at')
            
            for interaction in all_interactions:
                status = "RÉVOQUÉ" if interaction.is_revoked else "ACTIF"
                print(f"      - [{interaction.interaction_type}] {status} - {interaction.created_at}")
    else:
        print("\n✅ Aucun duplicata trouvé")
    
    # 9. Vérifier la dernière interaction révoquée
    print("\n" + "=" * 80)
    print("🔄 DERNIÈRE INTERACTION RÉVOQUÉE")
    print("=" * 80)
    
    last_revoked = InteractionHistory.objects.filter(
        user=marie_user,
        is_revoked=True
    ).order_by('-revoked_at').first()
    
    if last_revoked:
        print(f"\n\ud83d\udccc Dernière révocation:")
        print(f"   Email: {last_revoked.target_user.email}")
        print(f"   Type: {last_revoked.interaction_type}")
        print(f"   Révoqué le: {last_revoked.revoked_at}")
        print(f"   ID interaction: {last_revoked.id}")
        
        # Vérifier si ce profil est disponible pour découverte
        is_in_excluded = last_revoked.target_user_id in excluded_user_ids
        print(f"   Exclu de découverte: {'❌ OUI (PROBLÈME!)' if is_in_excluded else '✅ NON (OK)'}")
    
    print("\n" + "=" * 80)
    print("✅ DIAGNOSTIC TERMINÉ")
    print("=" * 80)


if __name__ == '__main__':
    main()

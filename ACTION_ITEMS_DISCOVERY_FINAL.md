# 📌 ACTION ITEMS - Discovery Feature Completion

## 🚀 IMMÉDIAT (Frontend - Tester)

### ✅ Hot Reload et Test My Likes/Passes

**Commande :**
```bash
cd d:\Projets\HIVMeet\hivmeet
flutter run
# Puis taper 'r' pour hot reload
```

**Test 1 : My Likes**
```
1. Ouvrir app (déjà connecté)
2. Aller à "My Likes" onglet
3. Trouver un like existant
4. Cliquer sur "Révoquer" / "Annuler" / "X"
5. ❓ Profil disparaît immédiatement? ✅ OUI vs ❌ NON
6. Quitter onglet, revenir
7. ❓ Profil est revenu? ✅ NON vs ❌ OUI
```

**Test 2 : My Passes**
```
1. Aller à "My Passes" onglet
2. Trouver un pass existant
3. Cliquer sur "Révoquer" / "Annuler"
4. ❓ Profil disparaît immédiatement? ✅ OUI vs ❌ NON
5. Quitter onglet, revenir
6. ❓ Profil est revenu? ✅ NON vs ❌ OUI
```

**Résultat Attendu :**
```
✅ Profil disparaît immédiatement
✅ N'est jamais revenu après revocation
✅ Aucune erreur dans les logs
```

**Si test échoue :**
- Vérifier hot reload complètement appliqué
- Sinon faire `flutter clean && flutter pub get` puis re-run

---

## ⚠️ BLOQUANT (Backend - URGENT)

### ❌ Ajouter gender_sought aux Profils Males

**Problème :** Discovery page retourne 0 profils car les males n'ont pas `gender_sought`.

**Solution 1 : SQL Direct (Rapide)**
```sql
-- Sur la BD de production
UPDATE profiles_profile 
SET gender_sought = 'female'
WHERE gender = 'male' AND gender_sought IS NULL;

-- Vérifier
SELECT user_id, gender, gender_sought FROM profiles_profile WHERE gender='male' LIMIT 5;
-- Attendu: gender_sought = 'female' pour tous les males
```

**Solution 2 : Fix Script de Création**
```python
# Fichier: create_male_profiles.py ou équivalent

# ❌ AVANT
profile_data = {
    'gender': 'male',
    'relationship_types_sought': ['long_term', 'friendship', 'casual'],
}

# ✅ APRÈS
profile_data = {
    'gender': 'male',
    'gender_sought': 'female',  # ← AJOUTER CETTE LIGNE
    'relationship_types_sought': ['long_term', 'friendship', 'casual'],
}
```

**Solution 3 : Django Command**
```python
# Créer: backend/profiles/management/commands/fix_gender_sought.py

from django.core.management.base import BaseCommand
from profiles.models import Profile

class Command(BaseCommand):
    def handle(self, *args, **options):
        updated = Profile.objects.filter(
            gender='male',
            gender_sought__isnull=True
        ).update(gender_sought='female')
        
        self.stdout.write(f"✅ {updated} profils males mis à jour")
```

**Command :**
```bash
python manage.py fix_gender_sought
```

**Validation :**
```bash
# Logs du backend doivent montrer:
# After mutual gender compatibility (target seeks female): 6 profiles ✅
# Au lieu de: 0 profiles ❌
```

---

## 📝 TEST COMPLET (Après Backend Fix)

### Test de Bout en Bout

**Scénario :**
```
User: Marie (39F, cherche M 30-50, distance 25km)
Available: 8 profils males (33-45F, à Paris)
```

**Étapes :**
```
1. Ouvrir Discovery
   ❓ Voir 5 profils? ✅ OUI vs ❌ NON (0 profils)

2. Swiper 3 likes
   ❓ Profils disparaissent immédiatement? ✅ OUI vs ❌ NON

3. Aller à "My Likes"
   ❓ Voir 3 likes? ✅ OUI vs ❌ NON

4. Révoquer 1 like
   ❓ Profil disparaît immédiatement? ✅ OUI vs ❌ NON

5. Revenir Discovery
   ❓ Profil révoqué réapparaît? ✅ OUI vs ❌ NON

6. Swiper 5 dislike
   ❓ Pas d'erreur 400? ✅ CORRECT vs ❌ 400 Bad Request

7. Aller à "My Passes"
   ❓ Voir 5 passes? ✅ OUI vs ❌ NON

8. Révoquer 1 pass
   ❓ Profil disparaît immédiatement? ✅ OUI vs ❌ NON

9. Revenir Discovery
   ❓ Profil réapparaît? ✅ OUI vs ❌ NON
```

**Résultat Final Attendu :**
- ✅ Discovery : 3 profils restants (les 2 dislikés annnulés reprennent la place)
- ✅ My Likes : 2 likes (1 révoqué enlevé)
- ✅ My Passes : 4 passes (1 révoqué enlevé)
- ✅ Aucune erreur
- ✅ UI fluide et responsif

---

## 📋 CHECKLIST DÉPLOIEMENT

### Frontend
- [ ] Hot reload et test My Likes/Passes
- [ ] Vérifier aucune erreur de compilation
- [ ] Aucun log d'erreur dans la console
- [ ] Commit : "fix: InteractionHistoryBloc to LazySingleton for persistent state"

### Backend
- [ ] Ajouter `gender_sought = 'female'` aux profils males
- [ ] Tester API : GET /api/v1/discovery/profiles (doit retourner des profils)
- [ ] Vérifier logs : "After mutual gender compatibility: X profiles" (X > 0)
- [ ] Commit : "fix: add missing gender_sought to male profiles"

### QA / Testing
- [ ] Test complet bot-en-bout (cf. section précédente)
- [ ] Tester avec 2 comptes (Marie + autre user)
- [ ] Vérifier pas de regression

---

## 📞 COMMUNICATION

### À l'Utilisateur
```
Bonjour,

Voici le statut des corrections pour la page Découverte:

✅ CORRIGÉ (Frontend):
1. My Likes/Passes: Les profils disparaissent maintenant immédiatement après revocation
2. Discovery: Suppression immédiate après swipe + élimination des doublons

❌ EN ATTENTE (Backend):
1. Discovery page vide: Le backend doit ajouter l'attribut `gender_sought` aux profils males

Action requise de votre côté: Exécuter la correction SQL fournie pour que Discovery retrouve des profils.

Une fois cela fait, tout fonctionnera correctement ✅

Merci!
```

---

## 📊 METRICS / KPI

### Avant Corrections
```
❌ Suppression immédiate: NON
❌ Doublons: OUI (pierre.garcia 2x)
❌ Revocation persistent: NON
❌ Erreur 400: OUI (on 6e dislike)
❌ Discovery profiles: 0
```

### Après Corrections (Attendu)
```
✅ Suppression immédiate: OUI
✅ Doublons: NON
✅ Revocation persistent: OUI
✅ Erreur 400: NON
✅ Discovery profiles: 5-8
```

---

## 🎯 SUCCESS CRITERIA

**Frontend considéré COMPLET si :**
- ✅ All 3 discovery problems resolved (doublons, suppression, 400 error)
- ✅ My Likes/Passes: profils disparaissent immédiatement ET ne reviennent jamais
- ✅ 0 regression bugs
- ✅ Logs propres (aucun error)

**Backend considéré COMPLET si :**
- ✅ Tous les profils males ont `gender_sought = 'female'`
- ✅ API retourne 5-8 profils pour Marie
- ✅ Aucune error 400 ou filtrage incorrect

**Feature considérée DONE si :**
- ✅ Frontend ET Backend complet
- ✅ Test bot-en-bout réussi
- ✅ User confirmé "tout marche"

---

**Status Global :** 🟡 EN COURS  
**ETA Completion :** Dès que backend fix est appliqué (~1h)  
**Risk :** 🟢 LOW (changement minimal, bien isolé)

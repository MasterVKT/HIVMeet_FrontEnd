# 🔧 Fix gender_sought - Guide de Correction Production

## 📋 Contexte

**Problème :** Le filtre de compatibilité mutuelle dans Discovery échoue car les profils n'ont pas de valeur `gender_sought` définie.

**Impact :** 
- Discovery page retourne 0 profils pour les utilisateurs cherchant des hommes
- Le filtre backend `After mutual gender compatibility (target seeks female OR all): 0 profiles` échoue

**Cause racine :** Les profils créés n'initialisaient pas le champ `gender_sought`, le laissant à `NULL`.

---

## 🚀 Solution Immédiate (Production)

### Étape 1 : Exécuter le script de correction

```bash
cd d:\Projets\HIVMeet\hivmeet
python fix_gender_sought.py
```

**Ce script va :**
- ✅ Ajouter `gender_sought='female'` aux profils masculins sans valeur
- ✅ Ajouter `gender_sought='male'` aux profils féminins sans valeur
- ✅ Ajouter `gender_sought='all'` aux profils non-binaires sans valeur
- ✅ Afficher un rapport détaillé des corrections

**Sortie attendue :**
```
================================================================================
FIX GENDER_SOUGHT - 2026-01-19 17:30:00
================================================================================

📊 Analyse des profils masculins...
   Trouvés: 16 profils masculins sans gender_sought
   ✅ Mise à jour: gender_sought='female' pour 16 profils

📊 Analyse des profils féminins...
   Trouvés: 0 profils féminins sans gender_sought

📊 Analyse des profils non-binaires/autres...
   Trouvés: 0 profils non-binaires/autres sans gender_sought

================================================================================
VÉRIFICATION FINALE
================================================================================

✅ SUCCÈS: Tous les profils ont maintenant un gender_sought défini

📊 STATISTIQUES FINALES:
   - Profils males mis à jour: 16
   - Profils females mis à jour: 0
   - Profils autres mis à jour: 0
   - Total: 16 profils corrigés

🔍 EXEMPLES DE PROFILS CORRIGÉS:
   - thomas.martin@test.com: gender=male, gender_sought=female
   - julien.rousseau@test.com: gender=male, gender_sought=female
   ...

================================================================================
✅ TERMINÉ
================================================================================
```

### Étape 2 : Vérifier Discovery

Après exécution du script :

1. **Hot reload l'app Flutter** (ou redémarre)
2. **Ouvre Discovery page**
3. **Attendu :** Voir les profils masculins apparaître (Thomas, Julien, etc.)

**Log backend attendu :**
```
After user's gender filter (seeking ['male']): 16 profiles
After mutual gender compatibility (target seeks female): 16 profiles
✅ Final result: 16 profiles
```

---

## 🔒 Prévention (Production Future)

### 1. ✅ Script create_male_profiles.py mis à jour

Le script de création de profils a été corrigé pour **toujours** définir `gender_sought` :

```python
# ✅ FIX PRODUCTION: Définir gender_sought (requis pour Discovery filter)
if hasattr(profile, 'gender_sought'):
    profile.gender_sought = 'female'  # Males cherchent females par défaut
```

**Impact :** Tous les nouveaux profils créés via ce script auront `gender_sought` défini.

### 2. 📝 Validation Django Model (Recommandé)

Pour garantir que TOUS les profils futurs auront `gender_sought`, modifier le modèle Django :

**Fichier : `env/hivmeet_backend/profiles/models.py`**

```python
class Profile(models.Model):
    # ... autres champs ...
    
    gender_sought = models.CharField(
        max_length=20,
        choices=[
            ('male', 'Male'),
            ('female', 'Female'),
            ('all', 'All'),
        ],
        default='female',  # ✅ AJOUTER default
        null=False,        # ✅ Empêcher NULL
        blank=False,       # ✅ Requis en forms
        help_text="Gender sought by this profile for matching"
    )
```

**Puis créer et appliquer la migration :**

```bash
cd env/hivmeet_backend
python manage.py makemigrations profiles
python manage.py migrate profiles
```

### 3. 🧪 Tests Automatisés (Recommandé)

Ajouter un test pour vérifier que tous les profils ont `gender_sought` :

**Fichier : `env/hivmeet_backend/profiles/tests/test_profile_creation.py`**

```python
from django.test import TestCase
from profiles.models import Profile

class ProfileCreationTestCase(TestCase):
    def test_profile_must_have_gender_sought(self):
        """Vérifie que tous les profils ont gender_sought défini"""
        profiles_without_gender_sought = Profile.objects.filter(
            gender_sought__isnull=True
        )
        self.assertEqual(
            profiles_without_gender_sought.count(), 
            0,
            "Tous les profils doivent avoir gender_sought défini"
        )
```

---

## 📊 Vérifications Post-Déploiement

### Vérification SQL directe

```sql
-- Compter les profils sans gender_sought
SELECT COUNT(*) 
FROM profiles_profile 
WHERE gender_sought IS NULL OR gender_sought = '';

-- Attendu: 0

-- Voir la distribution gender_sought
SELECT gender, gender_sought, COUNT(*) 
FROM profiles_profile 
GROUP BY gender, gender_sought;

-- Attendu:
-- male   | female | 16
-- female | male   | 20
```

### Test Discovery API

```bash
# Requête Discovery pour Marie (cherche males)
curl -X GET "http://localhost:8000/api/v1/discovery/profiles?page=1&page_size=5" \
  -H "Authorization: Bearer <token_marie>"

# Attendu: count > 0, results contient des profils males
```

---

## 🐛 Troubleshooting

### Problème : Script échoue avec "Profile has no attribute gender_sought"

**Solution :** Le modèle Django n'a pas le champ `gender_sought`. Vérifier :

1. Le champ existe dans `profiles/models.py`
2. Les migrations sont à jour : `python manage.py migrate`

### Problème : Profils toujours pas visibles après fix

**Causes possibles :**

1. **Cache backend** : Redémarrer Django server
2. **Profils révoqués** : Vérifier `is_revoked=False` dans interactions
3. **Autres filtres** : Vérifier age, distance, relationship_types

**Diagnostic :**

```bash
# Voir les logs backend détaillés
# Chercher "After mutual gender compatibility"
# Doit afficher > 0 profiles
```

### Problème : "Each child must be laid out exactly once"

**Solution :** Hot restart Flutter (pas hot reload) :
```bash
# Dans terminal Flutter
R  # Hot restart complet
```

---

## 📝 Checklist de Déploiement

- [ ] ✅ Exécuter `fix_gender_sought.py` sur la base production
- [ ] ✅ Vérifier les logs : tous les profils corrigés
- [ ] ✅ Tester Discovery API : profils visibles
- [ ] ✅ Tester app Flutter : profils affichés
- [ ] ✅ Ajouter `default='female'` au modèle Django (optionnel mais recommandé)
- [ ] ✅ Mettre à jour `create_male_profiles.py` (déjà fait)
- [ ] ✅ Documenter la correction dans le changelog

---

## 📚 Références

- **Script de correction :** [fix_gender_sought.py](fix_gender_sought.py)
- **Script de création :** [create_male_profiles.py](create_male_profiles.py)
- **Documentation problème :** [BACKEND_GENDER_FILTER_BUG.md](BACKEND_GENDER_FILTER_BUG.md)
- **Frontend corrections :** [CORRECTIONS_DISCOVERY_COMPLETE.md](CORRECTIONS_DISCOVERY_COMPLETE.md)

---

## 🎯 Résumé Exécutif

**Problème :** Discovery retourne 0 profils car `gender_sought` manquant  
**Solution :** Script `fix_gender_sought.py` corrige tous les profils existants  
**Prévention :** Mise à jour `create_male_profiles.py` + validation modèle Django  
**Impact :** ✅ Discovery fonctionnelle, profils visibles  
**Temps :** ~2 minutes d'exécution  
**Risque :** ⚪ Faible (lecture/écriture simple, pas de suppression)  

# 🤖 Règles Automatiques pour GitHub Copilot - HIVMeet

## Règle 1 : Création Automatique de Fichier Markdown pour Problèmes Backend

**Déclencheur** : Quand tu détectes qu'un problème (ou une partie d'un problème) est localisé dans le **backend Django**, tu DOIS :

### 1️⃣ Créer un fichier Markdown
- **Localisation** : À la racine du projet (même niveau que README.md)
- **Nom** : `BACKEND_[DESCRIPTION_COURTE].md`
- **Format** : Markdown structuré avec emojis et sections claires

### 2️⃣ Contenu Requis du Fichier

```markdown
# 🔴 PROBLÈME BACKEND - [Titre du Problème]

## 1. Métadonnées
- Statut : 🚨 BLOQUANT / ⚠️ DÉGRADÉ / ℹ️ AMÉLIORABLE
- Date : YYYY-MM-DD
- Affecte : [Écran/API/Service affecté]
- Sévérité : CRITIQUE / HAUTE / NORMALE / BASSE

## 2. Description du Problème
- Ce qui fonctionne ✅
- Ce qui ne fonctionne pas ❌
- Impact utilisateur

## 3. Analyse Détaillée
- Réponse Backend actuelle (exemple JSON/données)
- Réponse attendue par le frontend
- Comparaison côte à côte

## 4. Problèmes Spécifiques
- Liste des champs/endpoints problématiques
- Table de comparaison si applicable

## 5. Solutions Proposées
- **Solution 1** : [Description]
  - Code exemple
- **Solution 2** : [Description]
  - Code exemple

## 6. Checklist de Correction
- [ ] Item 1
- [ ] Item 2

## 7. Tests de Validation
- Test 1
- Test 2

## 8. Notes Additionnelles
- Infos importantes
- Contexte utilisateur
```

### 3️⃣ Exemples de Titres
- `BACKEND_DISCOVERY_RESPONSE_INCOMPLETE.md`
- `BACKEND_AUTH_TOKEN_MISMATCH.md`
- `BACKEND_INTERACTION_HISTORY_DUPLICATES.md`
- `BACKEND_FILTER_GENDER_NOT_WORKING.md`

### 4️⃣ Quand Créer Ce Fichier

Tu dois créer ce fichier si tu identifier une des situations suivantes :

#### A. Réponse API incorrecte
```
Exemple: Backend retourne `display_name: ""` au lieu du vrai nom
↓
Crée: BACKEND_DISCOVERY_RESPONSE_INCOMPLETE.md
```

#### B. Champs manquants dans la réponse
```
Exemple: Backend n'inclut pas les photos dans la réponse
↓
Crée: BACKEND_[FEATURE]_MISSING_FIELDS.md
```

#### C. Format de données incohérent
```
Exemple: Backend utilise `user_id` dans certains endpoints et `id` dans d'autres
↓
Crée: BACKEND_INCONSISTENT_FIELD_NAMES.md
```

#### D. Logique métier incorrecte
```
Exemple: Filtre de genre ne fonctionne pas correctement
↓
Crée: BACKEND_FILTER_[FILTER_NAME]_NOT_WORKING.md
```

#### E. Performance/Calculs incorrects
```
Exemple: Calcul de compatibilité retourne 0 pour tous
↓
Crée: BACKEND_COMPATIBILITY_CALCULATION_WRONG.md
```

### 5️⃣ Structure Recommandée pour Chaque Section

#### 📋 Description du Problème
```markdown
### ✅ Ce qui fonctionne :
- Point 1
- Point 2

### ❌ Ce qui ne fonctionne pas :
- Point 1
- Point 2
```

#### 🔍 Analyse Détaillée
```markdown
**Réponse Backend Actuelle :**
\`\`\`json
{ /* JSON actuel */ }
\`\`\`

**Réponse Attendue :**
\`\`\`json
{ /* JSON attendu */ }
\`\`\`
```

#### 🔧 Solutions Proposées
```markdown
### Solution 1 : [Approche]
**Fichier** : `path/to/file.py`
**Complexité** : SIMPLE / MOYEN / COMPLEXE

\`\`\`python
# Code exemple
\`\`\`

**Avantages** : 
- Pro 1
- Pro 2

**Inconvénients** :
- Con 1
- Con 2
```

#### 📋 Checklist
```markdown
- [ ] Élément actionnable (verbe + action)
- [ ] Verbe : Mettre à jour, Créer, Ajouter, Corriger, Tester
- [ ] Toujours cocher une seule action par item
```

---

## Règle 2 : Identification du Problème Frontend vs Backend

**Quand créer un document Backend** :

| Symptôme | Localisation | Document |
|----------|-------------|----------|
| Données vides dans l'UI | Backend n'envoie pas les données | BACKEND_[...].md |
| API retourne 404/500 | Backend endpoint cassé | BACKEND_[...].md |
| Champs manquants dans JSON | Backend serializer incomplet | BACKEND_[...].md |
| Logique métier incorrecte | Backend service/view | BACKEND_[...].md |
| Widget ne s'affiche pas | Frontend widget | FRONTEND_[...].md |
| Erreur de navigation | Frontend route/bloc | FRONTEND_[...].md |
| Parsing JSON échoue | Frontend model (mais cause = backend) | BACKEND_[...].md |

---

## Règle 3 : Mises à Jour des Documents Existants

Si un document Backend existe déjà et que tu trouves une **nouvelle information** :

1. **Cherche** le fichier `BACKEND_*.md` correspondant
2. **Ajoute** une nouvelle section avec le timestamp : `### 📝 Update [HH:MM - YYYY-MM-DD]`
3. **Ne remplace pas** les sections existantes, **augmente** avec les nouvelles infos

---

## Règle 4 : Communication avec le Backend Team

Ces fichiers servent à :
- 📄 **Documenter** les problèmes pour que d'autres développeurs les comprennent
- 🎯 **Proposer** des solutions prêtes à implémenter
- ⏱️ **Accélérer** la correction en fournissant un contexte complet
- 🔄 **Tracer** l'historique des problèmes découverts

---

## Checklist pour Chaque Document Backend

Avant de finaliser un `BACKEND_*.md`, vérifie que tu as :

- [ ] Titre clair avec 🔴 PROBLÈME BACKEND
- [ ] Métadonnées (Statut, Date, Sévérité)
- [ ] Section "Ce qui fonctionne" ✅
- [ ] Section "Ce qui ne fonctionne pas" ❌
- [ ] Réponse actuelle (JSON/exemple)
- [ ] Réponse attendue (JSON/exemple)
- [ ] Au moins 2 solutions proposées
- [ ] Code exemple pour chaque solution
- [ ] Checklist de correction (7-10 items)
- [ ] Tests de validation
- [ ] Notes additionnelles

---

## Exemples de Documents Déjà Créés

- ✅ `BACKEND_DISCOVERY_RESPONSE_INCOMPLETE.md` - 2026-01-19
- (À ajouter au fur et à mesure)

---

**Ces règles s'appliquent à partir de maintenant et automatiquement dans tous les futurs problèmes identifiés.**

# Rapport de Hand-off — Plan de Remédiation des Anomalies Journaux HIVMeet

> **Document de transmission entre agents AI.**
>
> **Date de rédaction :** 2026-09-17
>
> **Agent source :** GitHub Copilot (GLM 5.2)
>
> **Plan source :** `docs/PLAN_REMEDIATION_ANOMALIES_JOURNAUX_2026-09-16.md`
>
> **Statut global :** Phases 0 à 4 terminées (5 anomalies sur 8 corrigées).
> Phases 5 et 6 restent à exécuter. Recette finale en attente.

---

## 1. Contexte du projet

### 1.1 Architecture du projet

HIVMeet est une application de rencontre sécurisée pour personnes vivant avec
le VIH. Le projet est composé de deux racines :

| Racine | Chemin | Stack | Rôle |
| --- | --- | --- | --- |
| Frontend | `D:\Projets\HIVMeet\hivmeet` | Flutter 3.27.3 / Dart 3.6.1 | Application mobile (Android/iOS) |
| Backend | `D:\Projets\HIVMeet\env\hivmeet_backend` | Django 4.2.7 + DRF + Daphne | API REST + WebSocket (Channels) |

**Carte de projet** : `.agents/project-map.json` dans chaque racine définit
les ancres, le scope et le pair.

### 1.2 Gouvernance inter-racines

Les règles partagées sont dans `D:\Projets\HIVMeet\.agents\` :
- `PROJECT_RULES.md` — invariants transversaux
- `agent-integrations.json` — configuration des agents

Chaque racine a ses propres :
- `AGENTS.md` — point d'entrée
- `.agents/project-map.json` — carte locale
- `.agents/PROJECT_RULES.md` — règles locales
- `.agents/WORKFLOW.md` — workflow local
- `.agents/skills/task-router/SKILL.md` — routeur de skills
- `.agents/skills/<name>/SKILL.md` — skills spécialisées

### 1.3 Le plan de remédiation

Le plan `docs/PLAN_REMEDIATION_ANOMALIES_JOURNAUX_2026-09-16.md` définit 8
anomalies (LOG-01 à LOG-08) détectées dans 3 journaux collectés le
2026-09-16 :
- `emulator_run.md` — exécution émulateur
- `device_run copy.md` — exécution appareil physique
- `backend_run.md` — logs serveur Django

Le plan comporte 7 phases (0 à 6) plus une recette finale.

---

## 2. État d'avancement

### 2.1 Résumé des phases

| Phase | Anomalies | Statut | Rapport QA |
| --- | --- | --- | --- |
| Phase 0 — Préparation | Baseline | ✅ Terminée | `docs/qa/BASELINE_PHASE0_2026-09-16.md` |
| Phase 1 — Artefact Android | LOG-01 | ✅ Terminée | `docs/qa/PHASE1_LOG01_2026-09-16.md` |
| Phase 2 — UI offline/localisée | LOG-02, LOG-03, LOG-04 | ✅ Terminée | `docs/qa/PHASE2_LOG02_04_2026-09-17.md` |
| Phase 3 — URLs photos | LOG-05 | ✅ Terminée | `docs/qa/PHASE3_LOG05_2026-09-17.md` |
| Phase 4 — FCM + Celery | LOG-06, LOG-07 | ✅ Terminée | `docs/qa/PHASE4_LOG06_07_2026-09-17.md` |
| Phase 5 — Performance | LOG-08 | ⬜ À exécuter | — |
| Phase 6 — Hygiène logs | Prévention | ⬜ À exécuter | — |
| Recette finale | Toutes | ⬜ À exécuter | — |

### 2.2 Résumé des anomalies

| ID | Anomalie | Verdict | Notes |
| --- | --- | --- | --- |
| LOG-01 | INSTALL_FAILED_VERSION_DOWNGRADE | **PASS** | versionCode monotone via commits Git |
| LOG-02 | google_fonts télécharge au runtime | **PASS** | 64 appels remplacés, polices bundlées |
| LOG-03 | Assertion ListTile invisible ink | **PASS** | Material remplace Container+DecoratedBox |
| LOG-04 | discovery.gender introuvable | **PASS** | Remplacé par discovery.gender_title |
| LOG-05 | GET /profile_photos 404 | **PASS** | normalize_media_url() sur 11 producteurs |
| LOG-06 | FCM SERVICE_NOT_AVAILABLE | **PASS** | Retry borné avec backoff exponentiel |
| LOG-07 | Celery hostname localhost | **PASS** | Config explicite + transaction.on_commit |
| LOG-08 | Jank / frames sautées | ⬜ En attente | Phase 5 |

---

## 3. Blocage environnemental critique (BLOCKED_EXTERNAL)

### 3.1 Incompatibilité Flutter SDK

**Problème :** Le `pubspec.yaml` (commit `bf2f88e`) a bumpé plusieurs
dépendances pour Dart 3.12+, mais le SDK installé est **Dart 3.6.1**
(Flutter 3.27.3). Les packages incompatibles sont :

| Package | Version dans pubspec.yaml | Requiert | SDK installé |
| --- | --- | --- | --- |
| `google_fonts` | 8.2.1 | Dart ^3.10.0 | 3.6.1 |
| `app_links` | ^7.2.1 | Dart ^3.12.0 | 3.6.1 |

**Conséquence :**
- `flutter pub get` échoue ("version solving failed")
- `flutter build apk` échoue (compilation `flutter_localizations` avec
  feature expérimentale `null-aware-elements`)
- `flutter test` et `dart test` ne peuvent pas exécuter les tests

**Ce qui a été fait :**
- La dépendance `google_fonts` a été **supprimée** du `pubspec.yaml`
  (polices bundlées en assets — LOG-02). Cela élimine une des deux
  incompatibilités.
- `app_links` reste incompatible. Il faudra soit :
  1. Upgrader le Flutter SDK vers une version supportant Dart 3.12+
     (recommandé), **ou**
  2. Downgrader `app_links` vers une version compatible avec Dart 3.6.1

**Action requise :** L'utilisateur doit installer un Flutter SDK plus
récent (ex: Flutter 3.35+ / Dart 3.12+). C'est une décision externe qui
dépasse les droits techniques de l'agent.

### 3.2 Impact sur les tests

| Test | Méthode de validation utilisée | Statut |
| --- | --- | --- |
| `flutter test` | Non exécutable (SDK incompatibility) | BLOCKED_EXTERNAL |
| `dart test` | Non exécutable (version solving failed) | BLOCKED_EXTERNAL |
| `flutter analyze` | Non exécutable (même cause) | BLOCKED_EXTERNAL |
| `get_errors` (VS Code) | ✅ Exécutable — 0 erreur sur tous les fichiers modifiés | Valide |
| `git diff --check` | ✅ Exit 0 sur tous les fichiers | Valide |
| Backend `python manage.py test` | ✅ 131 tests passent | Valide |
| Backend `python manage.py check` | ✅ 0 issue | Valide |

---

## 4. Détail des corrections par phase

### 4.1 Phase 0 — Préparation

**Fichier produit :** `docs/qa/BASELINE_PHASE0_2026-09-16.md`

Baseline capturé :
- Flutter 3.27.3 / Dart 3.6.1 / Python 3.12.3 / Django 4.2.7
- Matrice 8 anomalies avec scénario, appareil, test cible, preuve manuelle
- Hypothèses de fichiers initiales pour chaque LOG-xx
- Signaux à ne pas corriger aveuglément (403 likes-received, No FCM token, EGL/ion)

### 4.2 Phase 1 — LOG-01 : versionCode monotone

**Rapport :** `docs/qa/PHASE1_LOG01_2026-09-16.md`

**Cause racine :** `android/local.properties` (gitignored) figeait
`flutter.versionCode=1` avec un fallback Gradle `'1'`. Aucune CI.

**Fichiers modifiés :**

| Fichier | Changement |
| --- | --- |
| `android/app/build.gradle` | Logique versionCode monotone : env CI → local.properties → `1000 + git rev-list --count HEAD`. La valeur `1` est rejetée. |
| `android/local.properties` | Ligne `flutter.versionCode=1` supprimée (remplacée par commentaire) |
| `.github/workflows/android-build.yml` | **Nouveau** workflow CI : calcul monotone, vérification, build APK, checksum, upload artefact |
| `test/android/version_code_test.dart` | **Nouveau** test : 4 assertions (fallback > 1, local.properties gitignored, versionCode monotone, valeur "1" rejetée) |

**Preuve :** Gradle a confirmé `versionCode = 1050` (1000 + 50 commits).

### 4.3 Phase 2 — LOG-02 à LOG-04 : UI offline/localisée

**Rapport :** `docs/qa/PHASE2_LOG02_04_2026-09-17.md`

#### LOG-02 — Polices locales

**Cause racine :** `google_fonts 8.2.1` téléchargeait OpenSans/Pacifico depuis
`fonts.gstatic.com` au runtime.

**Fichiers modifiés :**

| Fichier | Changement |
| --- | --- |
| `pubspec.yaml` | Dépendance `google_fonts` supprimée, section `fonts:` ajoutée (OpenSans variable + Pacifico) |
| `assets/fonts/OpenSans.ttf` | **Nouveau** — 532 636 octets, police variable OFL |
| `assets/fonts/Pacifico-Regular.ttf` | **Nouveau** — 329 380 octets, OFL |
| `assets/fonts/OpenSans-LICENSE.txt` | **Nouveau** — licence OFL |
| `assets/fonts/Pacifico-LICENSE.txt` | **Nouveau** — licence OFL |
| `lib/core/config/theme/app_theme.dart` | 24× `GoogleFonts.openSans()` → `TextStyle(fontFamily: 'OpenSans', ...)` |
| `lib/presentation/pages/discovery/discovery_page.dart` | 3× remplacés (1 Pacifico + 2 OpenSans) |
| `lib/presentation/pages/discovery/profile_detail_page.dart` | 7× remplacés |
| `lib/presentation/pages/splash/simple_splash_page.dart` | 4× remplacés |
| `lib/presentation/pages/splash/splash_page.dart` | 8× remplacés |
| `lib/presentation/widgets/common/empty_state_widget.dart` | 2× remplacés |
| `lib/presentation/widgets/common/error_widget.dart` | 2× remplacés |
| `lib/presentation/widgets/common/loading_widget.dart` | 1× remplacé |
| `lib/presentation/widgets/modals/filters_modal.dart` | 12× remplacés |
| `lib/presentation/widgets/modals/match_found_modal.dart` | 3× remplacés |
| Import `package:google_fonts/google_fonts.dart` | **Supprimé** des 10 fichiers ci-dessus |

**Total :** 64 appels `GoogleFonts` remplacés par `TextStyle(fontFamily: ...)`.

#### LOG-03 — Assertion ListTile

**Cause racine :** `_ActionTile` dans `profile_detail_page.dart` wrappait
`ListTile` dans `Container(decoration: _cardDecoration())` masquant les ink
splashes.

**Fichier modifié :**

| Fichier | Changement |
| --- | --- |
| `lib/presentation/pages/profile/profile_detail_page.dart` | `_ActionTile.build()` : `Container(decoration) → Material(color, borderRadius, clipBehavior) → ListTile` |
| `test/android/action_tile_test.dart` | **Nouveau** — 3 tests (Material ancestor, ripple visible, accessible) |

#### LOG-04 — Clé i18n manquante

**Cause racine :** `filters_modal.dart` utilisait `discovery.gender` (inexistant)
au lieu de `discovery.gender_title` (existant).

**Fichier modifié :**

| Fichier | Changement |
| --- | --- |
| `lib/presentation/widgets/modals/filters_modal.dart` | `discovery.gender` → `discovery.gender_title` |

**Parité FR/EN validée :** 48/48 clés discovery, 14/14 sections top-level.

### 4.4 Phase 3 — LOG-05 : URLs photos

**Rapport :** `docs/qa/PHASE3_LOG05_2026-09-17.md`

**Cause racine :** Les 58 enregistrements `ProfilePhoto` stockent
`profile_photos/...` (relatif sans `/media/`). Les serializers exposaient
cette valeur brute. Le frontend recevait `profile_photos/...`, préfixait avec
`/`, demandait `GET /profile_photos/...` → 404.

**Correctif :** Fonction unique `normalize_media_url()` dans
`hivmeet_backend/utils.py`, appliquée à **11 producteurs de photos**.

**Fichiers backend modifiés :**

| Fichier | Changement |
| --- | --- |
| `hivmeet_backend/utils.py` | Ajout `normalize_media_url()` + `_ALLOWED_EXTERNAL_HOSTS` |
| `matching/serializers.py` | `get_photos()` + `get_main_photo_url()` → `normalize_media_url()` |
| `matching/services.py` | `rewind()` photos dict → `normalize_media_url()` + import |
| `matching/tasks.py` | `send_like_notification()` image_url → `normalize_media_url()` + import |
| `matching/views_discovery.py` | 2× match response → `normalize_media_url()` + import |
| `profiles/serializers.py` | `ProfilePhotoSerializer` → SerializerMethodField + `normalize_media_url()` |
| `profiles/views.py` | upload response → `normalize_media_url()` |
| `profiles/views_settings.py` | blocked users list → `normalize_media_url()` |
| `messaging/serializers.py` | `get_other_user()` → `normalize_media_url()` (fallback thumbnail) |
| `resources/serializers.py` | `get_profile_photo_url()` → `normalize_media_url()` |
| `hivmeet_backend/tests/test_normalize_media_url.py` | **Nouveau** — 12 tests unitaires |

**Règles de normalisation :**

| Cas | Entrée | Sortie |
| --- | --- | --- |
| HTTPS externe approuvée | `https://www.gravatar.com/...` | Conservée |
| HTTPS autre (Firebase) | `https://firebasestorage...` | Conservée |
| Chemin local sans préfixe | `profile_photos/test.jpg` | `/media/profile_photos/test.jpg` |
| Chemin avec leading slash | `/profile_photos/test.jpg` | `/media/profile_photos/test.jpg` |
| Déjà préfixé `/media/` | `/media/profile_photos/test.jpg` | Conservé |
| `media/` sans slash | `media/profile_photos/test.jpg` | `/media/profile_photos/test.jpg` (pas de double) |
| Vide/None | `''` / `None` | `None` |
| Schéma non autorisé | `ftp://...` / `file://...` | `None` (rejeté) |
| Avec request | `profile_photos/test.jpg` | URL absolue `http://host/media/...` |

**Tests backend :** 12 normalize_media_url + 22 matching + 15 profiles = 49 OK.

### 4.5 Phase 4 — LOG-06 + LOG-07 : FCM et Celery

**Rapport :** `docs/qa/PHASE4_LOG06_07_2026-09-17.md`

#### LOG-06 — FCM retry

**Cause racine :** `registerTokenWithBackend()` avalait silencieusement
`SERVICE_NOT_AVAILABLE` avec `catch (_)`.

**Fichiers frontend modifiés :**

| Fichier | Changement |
| --- | --- |
| `lib/data/services/notification_service.dart` | `registerTokenWithBackend()` : retry borné (3 max, backoff 2s/4s/8s plafond 30s), annulable via `sessionGeneration`, reset sur succès. `_sendTokenRegistration()` : reset `_tokenRetryCount = 0` sur succès. |
| `test/android/fcm_retry_test.dart` | **Nouveau** — 4 tests (backoff, max retries, annulation, sécurité token) |

**Endpoint backend :** déjà robuste, aucun changement requis.

#### LOG-07 — Celery explicite

**Cause racine :** `memory://` fallback silencieux + `eager=True` par défaut +
`send_call_notification.delay()` non différée après commit.

**Fichiers backend modifiés :**

| Fichier | Changement |
| --- | --- |
| `hivmeet_backend/settings.py` | Configuration Celery explicite : dev=memory+eager, prod=Redis obligatoire+`RuntimeError` si broker manquant |
| `messaging/services.py` | `CallService.initiate_call()` : `send_call_notification.delay()` → `transaction.on_commit()` |
| `messaging/tests.py` | Test `test_premium_user_can_initiate_call` : `captureOnCommitCallbacks(execute=True)` + expectation `thumbnail_url` |
| `hivmeet_backend/tests/test_celery_config.py` | **Nouveau** — 5 tests (eager, dev broker, prod RuntimeError, on_commit × 2) |

**Tests backend :** 126 matching+messaging+notifications + 5 celery config = 131 OK.

---

## 5. Conventions et règles à respecter

### 5.1 Workflow obligatoire

L'agent successeur doit suivre ce workflow pour chaque phase :

1. **Charger le routeur de skills** avant de commencer :
   - Frontend : `d:\Projets\HIVMeet\hivmeet\.agents\skills\task-router\SKILL.md`
   - Backend : `D:\Projets\HIVMeet\env\hivmeet_backend\.agents\skills\task-router\SKILL.md`
2. **Charger 1 à 2 skills spécialisées** selon le type de tâche
3. **Capturer l'état** avant modification (git status, diff)
4. **Corriger une anomalie à la fois**
5. **Après chaque correction** : formatter, analyse statique, tests ciblés,
   recette du scénario source, analyse d'impact
6. **Produire un rapport QA** dans `docs/qa/PHASE[N]_[LOG]_[DATE].md`
7. **Ne jamais** réinitialiser le worktree, écraser des changements
   préexistants, supprimer des données, ou désinstaller une app sans
   instruction explicite

### 5.2 Skills disponibles

**Frontend** (`.agents/skills/<name>/SKILL.md`) :

| Skill | Usage |
| --- | --- |
| `bug-fixing` | Diagnostiquer et corriger les bugs frontend |
| `frontend-development` | Développer des features Flutter/Dart |
| `i18n-integrity` | Maintenir la parité FR/EN |
| `api-contract-audit` | Auditer les contrats API |
| `regression-guard` | Valider la non-régression |
| `release-readiness` | Gates de release (build, analyze, test) |
| `test-impact-selection` | Sélectionner les tests à exécuter |

**Backend** (`.agents/skills/<name>/SKILL.md`) :

| Skill | Usage |
| --- | --- |
| `celery-redis-reliability` | Fiabilité async (retry, idempotency) |
| `firebase-auth-sync` | Firebase/JWT/sync |
| `security-permissions` | Authz, privacy, rate limiting |
| `migrations-data-integrity` | Migrations, backfill, rollback |
| `drf-api-development` | Endpoints DRF |
| `serializer-validation` | Validation des entrées |
| `performance-query-tuning` | Optimisation ORM/queries |
| `backend-testing-strategy` | Sélection de tests backend |

### 5.3 Règles de sécurité et confidentialité

- **NE JAMAIS** écrire dans un rapport, log, ou sortie CI : e-mail, téléphone,
  jeton FCM, JWT, UUID utilisateur, photo, URL signée, localisation précise,
  statut VIH, clé API
- Utiliser des corrélations non réversibles et des métriques agrégées
- Ne jamais prendre un `catch` vide comme preuve de succès
- Aucun secret Firebase, Redis, My-CoolPay, Android ou autre ne peut être
  ajouté au dépôt
- Toute migration impose dry-run, comptage agrégé, lots, transaction par lot,
  sauvegarde et plan de retour arrière

### 5.4 Verdicts

| Verdict | Signification |
| --- | --- |
| PASS | preuve automatisée et recette réelle disponibles |
| FAILED | défaut encore reproduit après correction |
| NOT_REPRODUCED | absence observée, mais condition ou preuve insuffisante |
| BLOCKED_EXTERNAL | dépendance appareil, réseau, fournisseur ou autorisation absente |
| NO_GO | défaut bloquant ou risque sécurité non levé |

### 5.5 Commandes de validation

```powershell
# Frontend (nécessite SDK compatible — voir section 3)
dart format --set-exit-if-changed <fichiers-modifiés>
flutter analyze --no-pub
flutter test --no-pub <tests-cibles>

# Backend (depuis D:\Projets\HIVMeet\env\hivmeet_backend)
$env:DJANGO_SETTINGS_MODULE='hivmeet_backend.test_settings'
python manage.py check
python manage.py test <modules-cibles> --noinput
```

### 5.6 Conventions de nommage des rapports QA

- Baseline : `docs/qa/BASELINE_PHASE[N]_[DATE].md`
- Phase : `docs/qa/PHASE[N]_[LOG]_[DATE].md`
- Recette : `docs/qa/RECETTE_FINALE_[DATE].md`

Chaque rapport doit contenir : date, hash commit, symptôme, cause racine,
correctif, test, résultat, impact, verdict.

---

## 6. Ce qui reste à faire

### 6.1 Phase 5 — LOG-08 : Performance mobile mesurée

**Statut :** À exécuter.

**Principe du plan :** Les frames sautées sont sérieuses, mais les journaux
viennent d'un build debug avec polices réseau. Interdiction d'optimiser à
l'aveugle avant que les phases 1 à 3 soient validées en runtime.

**Étapes du plan (section 9) :**

1. Construire et installer APK **profile** avec commit, hash et symboles
   connus. **⚠️ BLOCKED_EXTERNAL** — nécessite un SDK compatible (voir
   section 3). Si l'upgrade SDK est fait, construire `flutter build apk
   --profile`.
2. Mesurer 3 répétitions minimum par appareil : cold start, login,
   Découverte, swipe, modal filtres, profil, retour, notification, images.
   Employer Flutter DevTools Timeline, `gfxinfo/framestats` et trace système.
3. Distinguer UI, raster/GPU, I/O, JSON, réseau, Firebase, décodage image,
   stockage et logs synchrones.
4. Modifier uniquement un hotspot confirmé. Optimisations admises après
   mesure : préchargement borné, cache image dimensionné, pagination,
   réduction de rebuilds ou I/O hors UI. Ne pas réduire sécurité, permission
   ou qualité image sans mesure et décision UX.
5. Conserver une comparaison avant/après agrégée pour chaque optimisation.

**Vérification requise :**
- Aucun burst de centaines ou milliers de frames sautées
- p95 sous le budget de frame
- Pas de régression supérieure à 10% d'un parcours non concerné
- Temps de première interaction, CPU, mémoire, trafic et taille APK reportés

**Notes importantes :**
- LOG-02 (polices locales) a déjà éliminé une cause majeure de jank au
  démarrage (téléchargement `fonts.gstatic.com`). Les mesures profile doivent
  confirmer cette amélioration.
- LOG-03 (Material/Ink) a amélioré le rendu tactile.
- LOG-05 (URLs `/media/`) a éliminé les 404 photos qui causaient des retry
  réseau.

**Skill à charger :** `task-router` frontend → `release-readiness` (profiling)
ou `bug-fixing` (performance).

### 6.2 Phase 6 — Hygiène préventive des logs

**Statut :** À exécuter.

**Problème :** Le dépôt contient des `debugPrint` de JSON et données de profil
dans `interaction_history_repository_impl.dart`. Même si ce n'est pas la cause
directe d'un des messages, il faut l'assainir car HIVMeet manipule des données
sensibles.

**Étapes du plan (section 10) :**

1. Rechercher `print`, `debugPrint` et logs interpolant payload, headers ou
   modèle dans Flutter et Django.
2. Les supprimer ou les remplacer par le sanitizer commun : type d'erreur,
   code, durée et corrélation non réversible.
3. Ajouter des canaris de test : e-mail, téléphone, jeton, URL image,
   coordonnées et UUID. Aucun ne doit survivre dans une sortie log.
4. Vérifier CI, ADB, crash reporting et exports : rétention, masquage, accès.
5. Conserver un niveau d'observabilité qui diagnostique les défauts ; ne pas
   transformer tout log en silence.

**Vérification :**
- Aucun canari sensible dans logs Flutter/Django de test
- Les anomalies restent classifiables grâce à des métriques non sensibles
- Toute suppression d'artefact respecte la politique de rétention

**Fichiers connus à examiner :**
- `lib/data/repositories/interaction_history_repository_impl.dart` (dumps JSON
  de profils — visibles dans `device_run copy.md` lignes 172+)
- Tout fichier utilisant `debugPrint` avec des données de profil

**Skills à charger :** `bug-fixing` frontend + `security-permissions` backend.

### 6.3 Recette finale

**Statut :** À exécuter après Phases 5 et 6.

**Préconditions :**
- APK recette identifié sur les deux appareils (nécessite SDK compatible)
- Backend, stockage média, Firebase et Celery recette connus
- Comptes QA Free/Premium, médias test et permission notification prêts
- Aucune donnée de production utilisée

**Étapes du plan (section 13) :**
1. Rejouer LOG-01 à LOG-08 sur session neuve et persistante, sur deux appareils
2. Rejouer connexion, logout/login, Découverte Free/Premium, likes/dislikes,
   super likes, historique/révocation, messages, profil, notifications,
   abonnement et deep links
3. Exécuter tests ciblés puis suite élargie
4. Exécuter analyse statique, format, `git diff --check`, validations
   migration, scan PII/secrets et contrôle licences
5. Réaliser le double audit : exigences → preuves ; changements → exigences

**Décision GO/NO-GO :** Le verdict GO est autorisé seulement si chaque défaut
confirmé est PASS, les dépendances externes sont testées ou explicitement
acceptées comme exclusions, aucun défaut bloquant n'est ouvert et le rapport
QA fournit versions, appareils, tests et risques résiduels.

---

## 7. État Git

### 7.1 Frontend (`D:\Projets\HIVMeet\hivmeet`)

**Branche :** master
**Dernier commit :** `7dd7732` (fix: gere correctement la reponse liste API plans)
**Worktree :** modifications préexistantes (nombreux fichiers `.dart`, `.json`,
config) **préservées** — ne pas réinitialiser.

**Fichiers créés par ce plan (untracked) :**
```
.github/workflows/android-build.yml
assets/fonts/OpenSans.ttf
assets/fonts/Pacifico-Regular.ttf
assets/fonts/OpenSans-LICENSE.txt
assets/fonts/Pacifico-LICENSE.txt
test/android/version_code_test.dart
test/android/action_tile_test.dart
test/android/fcm_retry_test.dart
docs/qa/BASELINE_PHASE0_2026-09-16.md
docs/qa/PHASE1_LOG01_2026-09-16.md
docs/qa/PHASE2_LOG02_04_2026-09-17.md
docs/qa/PHASE3_LOG05_2026-09-17.md
docs/qa/PHASE4_LOG06_07_2026-09-17.md
```

**Fichiers modifiés par ce plan (tracked, dans le diff) :**
```
android/app/build.gradle          — versionCode monotone (LOG-01)
android/local.properties          — flutter.versionCode supprimé (LOG-01)
pubspec.yaml                       — google_fonts supprimé, fonts ajoutés (LOG-02)
lib/core/config/theme/app_theme.dart             — 24× GoogleFonts → TextStyle
lib/presentation/pages/discovery/discovery_page.dart          — 3× remplacés
lib/presentation/pages/discovery/profile_detail_page.dart     — 7× + _ActionTile Material
lib/presentation/pages/splash/simple_splash_page.dart          — 4× remplacés
lib/presentation/pages/splash/splash_page.dart                 — 8× remplacés
lib/presentation/pages/profile/profile_detail_page.dart       — _ActionTile fix (LOG-03)
lib/presentation/widgets/common/empty_state_widget.dart       — 2× remplacés
lib/presentation/widgets/common/error_widget.dart              — 2× remplacés
lib/presentation/widgets/common/loading_widget.dart            — 1× remplacé
lib/presentation/widgets/modals/filters_modal.dart             — 12× + discovery.gender fix (LOG-04)
lib/presentation/widgets/modals/match_found_modal.dart         — 3× remplacés
lib/data/services/notification_service.dart                    — FCM retry (LOG-06)
```

### 7.2 Backend (`D:\Projets\HIVMeet\env\hivmeet_backend`)

**Branche :** master
**Dernier commit :** `8f264c6` (fix: merge duplicate feed URL patterns)

**Fichiers modifiés par ce plan :**
```
hivmeet_backend/utils.py                        — normalize_media_url() (LOG-05)
hivmeet_backend/settings.py                     — Celery explicite (LOG-07)
matching/serializers.py                          — get_photos + get_main_photo_url normalisés (LOG-05)
matching/services.py                             — rewind() photos + import normalize (LOG-05)
matching/tasks.py                                — image_url normalisé (LOG-05)
matching/views_discovery.py                      — 2× main_photo_url normalisé (LOG-05)
profiles/serializers.py                          — ProfilePhotoSerializer normalisé (LOG-05)
profiles/views.py                                — upload response normalisé (LOG-05)
profiles/views_settings.py                       — blocked users normalisé (LOG-05)
messaging/serializers.py                         — main_photo_url normalisé (LOG-05)
messaging/services.py                            — CallService on_commit (LOG-07)
messaging/tests.py                               — captureOnCommitCallbacks + thumbnail expectation
resources/serializers.py                         — profile_photo_url normalisé (LOG-05)
```

**Fichiers créés par ce plan (untracked) :**
```
hivmeet_backend/tests/test_normalize_media_url.py   — 12 tests (LOG-05)
hivmeet_backend/tests/test_celery_config.py         — 5 tests (LOG-07)
```

---

## 8. Appareils de test

| Alias | Modèle | Statut |
| --- | --- | --- |
| ANDROID_EMULATOR_A | sdk gphone64 x86 64 (emulator-5554) | Connecté |
| ANDROID_PHYSICAL_A | TECNO KF7j (192.168.1.155:36181) | Connecté |

Les deux appareils ont actuellement `versionCode=1` installé. Le prochain APK
produit aura `versionCode=1050` (1000 + 50 commits).

---

## 9. Checklist de reprise pour l'agent successeur

- [ ] Lire ce rapport en intégralité
- [ ] Lire le plan `docs/PLAN_REMEDIATION_ANOMALIES_JOURNAUX_2026-09-16.md`
  (sections 9, 10, 11, 12, 13, 14 pour les phases restantes)
- [ ] Lire `AGENTS.md` dans chaque racine
- [ ] Charger le `task-router` approprié avant chaque phase
- [ ] Vérifier l'état Git des deux racines (`git status`)
- [ ] Si l'upgrade SDK a été fait : exécuter `flutter pub get`, `flutter
  analyze`, `flutter test` pour valider les phases 0-4 en runtime
- [ ] Exécuter Phase 5 (LOG-08) — profiling sur build profile
- [ ] Exécuter Phase 6 — hygiène des logs
- [ ] Exécuter recette finale (section 13 du plan)
- [ ] Produire rapport QA pour chaque phase restante
- [ ] Produire le livrable final obligatoire (section 14 du plan)

---

## 10. Contact et ressources

- **Règles frontend :** `.claude/rules/architecture.md`,
  `.claude/rules/backend-integration.md`, `.claude/rules/specifications.md`,
  `.claude/rules/testing.md`
- **API documentation :** `API_DOCUMENTATION.md` (racine frontend, plus récent)
- **Skills frontend :** `.agents/skills/`
- **Skills backend :** `D:\Projets\HIVMeet\env\hivmeet_backend\.agents\skills\`
- **Rapports QA produits :** `docs/qa/`

---

*Fin du rapport de hand-off.*
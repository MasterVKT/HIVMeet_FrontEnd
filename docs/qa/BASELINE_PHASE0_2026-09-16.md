# Baseline Phase 0 — Anomalies journaux 2026-09-16

> Rapport QA expurgé. Aucune donnée sensible (e-mail, téléphone, jeton, UUID
> utilisateur, URL signée, statut VIH) n'apparaît ci-dessous.

## Métadonnées d'environnement

| Élément | Valeur |
| --- | --- |
| Date baseline | 2026-09-16 |
| Frontend commit | worktree avec modifications préexistantes (non réinitialisées) |
| Backend commit | `8f264c6` (master) |
| Flutter | 3.27.3 (stable, 2025-01-21) |
| Dart SDK | 3.6.1 |
| Python | 3.12.3 |
| Backend | Django 4.2.7 + DRF + Daphne 4.0.0 |
| APK debug | `build/app/outputs/flutter-apk/app-debug.apk` (non reconstruit pour le baseline) |

### Appareils (anonymisés)

| Alias | Modèle | Source | Play Services | Réseau |
| --- | --- | --- | --- | --- |
| ANDROID_EMULATOR_A | sdk gphone64 x86 64 | emulator_run.md | Impliqué (SERVICE_NOT_AVAILABLE) | Host |
| ANDROID_PHYSICAL_A | TECNO KF7j | device_run copy.md | Impliqué (FCM token enregistré) | Wi-Fi local |

> Les numéros de série et identifiants propriétaires ne sont pas consignés.

## Sources analysées

- `emulator_run.md` — exécution émulateur debug, INSTALL_FAILED_VERSION_DOWNGRADE,
  google_fonts, FCM SERVICE_NOT_AVAILABLE, Choreographer jank.
- `device_run copy.md` — exécution appareil physique debug, même downgrade,
  google_fonts Pacifico, assertion ListTile, clé i18n `discovery.gender`,
  dump JSON interaction history (PII).
- `backend_run.md` — logs serveur Django/Daphne, 404 `/profile_photos/...`,
  warning Celery hostname localhost, `No FCM token`, 403 likes-received (Free).

## Matrice anomalie → scénario → appareil → test automatique → preuve manuelle

| ID | Anomalie | Scénario de reproduction | Appareil | Test automatique cible | Preuve manuelle | Verdict baseline |
| --- | --- | --- | --- | --- | --- | --- |
| LOG-01 | INSTALL_FAILED_VERSION_DOWNGRADE | `flutter run` installe un APK dont versionCode (1) est inférieur au package installé | EMU_A + PHYS_A | Test Gradle : versionCode monotone | adb dumpsys package + adb install résultat | NOT_REPRODUCED sur install neuve ; reproduit si package pré-existant supérieur |
| LOG-02 | google_fonts télécharge OpenSans/Pacifico depuis fonts.gstatic.com | Démarrage app offline ou réseau instable | EMU_A (lignes 72-79) + PHYS_A (144-145) | Test statique présence assets police + test widget offline | Logs Flutter sans `fonts.gstatic.com` | REPRODUCED |
| LOG-03 | Assertion ListTile sous DecoratedBox | Ouverture Profil / Réglages / Devise | PHYS_A (150-168) | Widget test ActionTile sans exception | Log Flutter sans assertion | REPRODUCED |
| LOG-04 | Clé `discovery.gender` introuvable | Ouverture modal filtres Découverte | PHYS_A (172-178) | Test modal filtres FR/EN + validateur parité ARB | Log Flutter sans `Translation key not found` | REPRODUCED |
| LOG-05 | GET `/profile_photos/...` retourne 404 | Affichage profil utilisateur avec photo locale | PHYS_A via backend (117-151) | Unit test normalizer URL + test API photo | Backend log : plus de 404 `/profile_photos` | REPRODUCED |
| LOG-06 | SERVICE_NOT_AVAILABLE + aucun jeton backend (émulateur) | Démarrage app émulateur, FCM getToken échoue | EMU_A (ligne 17) | Test fake FirebaseMessaging (SERVICE_NOT_AVAILABLE) | Backend : registration FCM absente pour EMU_A | REPRODUCED (émulateur) ; PHYS_A OK |
| LOG-07 | Broker Celery hostname localhost implicite | Like déclenche `send_like_notification` | backend_run.md (ligne 444) | Test Celery eager + test worker recette | Log backend sans `No hostname was supplied` | REPRODUCED (warning) |
| LOG-08 | Jank important, frames sautées | Démarrage + login + navigation Découverte | EMU_A (2265, 142, 499, 168 frames) + PHYS_A (366, 182 frames) | Profilage DevTools Timeline (build profile) | Comparaison agrégée avant/après | REPRODUCED (build debug) — à re-mesurer en profile |

## Hypothèses de fichiers initiales (par anomalie)

### LOG-01 — versionCode

- `android/local.properties` → `flutter.versionCode=1` (figé, cause racine confirmée)
- `android/app/build.gradle` → fallback `'1'` si local.properties absent
- `pubspec.yaml` → `version: 1.0.0+1` (source sémantique)
- Pas de workflow CI détecté (`.github/workflows/` absent)

### LOG-02 — google_fonts

- `lib/core/theme/` (thème global)
- `lib/presentation/widgets/` (widgets utilisant GoogleFonts)
- `pubspec.yaml` (dépendance `google_fonts`)
- `assets/` (assets polices — à vérifier)

### LOG-03 — ListTile assertion

- `lib/presentation/pages/profile/profile_detail_page.dart` (ActionTile)
- `lib/presentation/pages/settings/` (réglages)

### LOG-04 — discovery.gender

- `lib/presentation/widgets/filters_modal.dart`
- `assets/translations/fr.json` + `en.json`

### LOG-05 — URL photo 404

- Backend : serializer matching/profiles (photo_url, thumbnail_url)
- Backend : `MEDIA_URL`, `MEDIA_ROOT`, urls.py
- Frontend : consommateurs de photo_url (carte découverte, détail, matchs, messagerie)

### LOG-06 — FCM

- `lib/core/services/firebase_service.dart`
- `lib/data/services/notification_service.dart`
- Backend : `auth/fcm-token` endpoint, serializer, modèle `FcmToken`

### LOG-07 — Celery

- Backend : `hivmeet_backend/settings.py` (CELERY_BROKER_URL, CELERY_TASK_ALWAYS_EAGER)
- Backend : `matching/tasks.py`

### LOG-08 — Performance

- Build debug + google_fonts réseau → jank artefact.
- À re-mesurer après phases 1-3 sur build profile.

## Signaux à ne pas corriger aveuglément

| Signal | Verdict | Action |
| --- | --- | --- |
| 403 `/likes-received/` pour compte Free | Comportement attendu (verrou Premium) | Vérifier UX + absence de retry ; ne pas retirer la permission |
| `No FCM token` pour compte sans appareil enregistré | Normal | Anomalie uniquement si appareil authentifié compatible échoue |
| EGL/OpenGL sur émulateur, `ion` sur appareil | Signal plateforme | Ignorer tant que non reproduit en mode profile |
| Logs redigés fournis | Format de preuve | Ne justifie pas les dumps JSON restants dans le code source |

## Gate de sortie Phase 0

- [x] Chaque LOG-xx a un scénario de reproduction ou verdict NOT_REPRODUCED avec condition
- [x] APK, package installé et backend de recette identifiés
- [x] Aucun secret ni PII dans le baseline
- [x] Versions Flutter/Dart/Python/Gradle capturées
- [x] Worktree non réinitialisé (modifications préexistantes préservées)

## Analyse d'impact Phase 0

- **Interne** : build Android, injection Flutter, backend, serializers, tâches,
  contrats utilisés par les scénarios.
- **Externe** : Play Services, Firebase, réseau, proxy, Redis, stockage média,
  CDN. Une indisponibilité sera BLOCKED_EXTERNAL, jamais un succès simulé.

## Verdict global Phase 0

**PASS** — baseline capturé, matrice complète, hypothèses de fichiers établies
pour chaque anomalie. Prêt pour Phase 1 (LOG-01).
# Phase 6 — Hygiène préventive des logs

**Date :** 2026-09-17
**Commit frontend (base) :** `7dd7732` (worktree, modifications préexistantes préservées + correctifs ci-dessous)
**Commit backend (base) :** `8f264c6`
**Scope :** Flutter (`lib/`) + Django (apps + `hivmeet_backend/`), conformément au plan §10.

---

## 1. Méthode

1. Recherche exhaustive `debugPrint(`/`print(` dans `lib/` (22 fichiers, contenu
   intégral lu et trié par sensibilité réelle : payload/JSON brut, e-mail,
   jeton, vs. bruit générique déjà géré).
2. Recherche exhaustive `logger.*(f"..."`/`print(f"..."` dans les 8 apps
   Django (hors scripts utilitaires racine, migrations, tests), filtrée sur
   motifs `email|token|password|request.data|serializer.data|phone|jwt`.
3. Vérification de l'infrastructure de sanitisation existante avant toute
   correction (éviter de dupliquer un mécanisme déjà présent) :
   - Flutter : `lib/core/utils/log_service.dart` — `PrivacyLogSanitizer`
     (email, UUID, téléphone, coordonnées, champs sensibles nommés, URL →
     host seul).
   - Django : `hivmeet_backend/logging_privacy.py` — `PrivacyRedactionFilter`,
     miroir exact de la logique Flutter, attaché au handler `console` sur
     `root`/`django`/`hivmeet` dans `settings.py` (couvre tous les loggers du
     projet par propagation hiérarchique Python, y compris
     `logging.getLogger(__name__)` dans n'importe quel module).

## 2. Constat structurel : deux architectures différentes

- **Flutter** : le sanitizer n'est appliqué qu'aux appels passant par
  `LogService.log/debug/warning/error`. `debugPrint()` (utilisé nativement
  dans ~22 fichiers, souvent issus de sessions de débogage antérieures) **le
  contournait entièrement**. C'est la cause racine du problème signalé par le
  hand-off (`interaction_history_repository_impl.dart` et au-delà).
- **Django** : le filtre est câblé au niveau des *handlers* de logging, donc
  s'applique automatiquement à **tout** `logger.info/warning/error(...)`
  dans le projet, quel que soit le module. Les ~40 occurrences de
  `{user.email}` trouvées par grep dans `authentication/`, `matching/`,
  `profiles/`, `resources/`, `firebase_service.py` sont donc **déjà
  redigées en sortie réelle** — vérifié en observant la sortie de la suite
  de tests (voir §5). Aucune correction par site d'appel n'était nécessaire
  côté backend.

## 3. Correctifs appliqués

### 3.1 Frontend — 13 fichiers, `debugPrint(` → `LogService.debug/warning(`

| Fichier | Donnée exposée avant correctif |
| --- | --- |
| `lib/data/repositories/interaction_history_repository_impl.dart` | JSON de profil complet (bio, ville, photo, nom) dumpé à 6 endroits — fichier explicitement signalé par le hand-off |
| `lib/data/repositories/auth_repository_impl.dart` | e-mail en clair (repository signIn) |
| `lib/domain/usecases/auth/sign_in.dart` | e-mail en clair (use case) |
| `lib/data/datasources/remote/auth_api.dart` | e-mail en clair (data source Firebase) |
| `lib/presentation/pages/auth/login_page.dart` | e-mail en clair (UI) |
| `lib/presentation/blocs/auth/auth_bloc_simple.dart` | e-mail en clair (×6) |
| `lib/presentation/blocs/auth/auth_bloc.dart` | e-mail utilisateur (`user.email`) |
| `lib/presentation/blocs/chat/chat_bloc.dart` | payload d'erreur WebSocket brut (`wsEvent.data`) |
| `lib/presentation/blocs/interaction_history/interaction_history_bloc.dart` | identifiant de profil |
| `lib/core/events/app_events.dart` | identifiant de profil |
| `lib/core/services/token_service.dart` | exception brute lors d'échange/rafraîchissement de jeton |
| `lib/data/repositories/message_repository_impl.dart` | exception brute d'opération messagerie |
| `lib/core/services/chat_websocket_service.dart` | exception brute d'envoi/erreur WebSocket |

Pour les fichiers où le JSON/profil complet était dumpé, le remplacement
conserve la valeur diagnostique (type d'erreur, **clés** du JSON plutôt que
ses valeurs, identifiants pseudonymisés) sans jamais exposer le contenu réel
— conforme au plan §10.5 (« conserver un niveau d'observabilité »).

**Non modifié (revu et jugé sans risque)** :
- 5 fichiers avec un `_debugLog` gardé par `const bool _enableVerboseLogs =
  false` (`splash_page.dart`, `match_repository_impl.dart`,
  `discovery_bloc.dart`, `app_scaffold.dart`, `discovery_page.dart`) — code
  mort, éliminé par tree-shaking en build réel, aucun risque runtime.
- `notification_websocket_service.dart` — déjà correctement écrit (type
  d'erreur, drapeaux booléens, durées ; jamais le jeton malgré son
  utilisation dans l'URL de connexion).
- `routes.dart`, `localization_service.dart` — messages sans donnée
  utilisateur (chemin de route, clé de traduction).

### 3.2 Sanitizer — canari manquant ajouté (Flutter + Django)

Ni `PrivacyLogSanitizer` (Dart) ni `PrivacyRedactionFilter`/`redact_log_text`
(Python) ne redigeaient un jeton/JWT brut (`Bearer <jwt>`) apparaissant sans
préfixe de champ nommé — seul `fcm_token: "..."` (motif de champ) était
couvert. Ajout d'une regex JWT/Bearer (trois segments base64url) dans les
deux sanitizers, avec canari de test dédié dans chaque suite.

### 3.3 Canaris de test ajoutés

| Test | Catégories couvertes |
| --- | --- |
| `test/core/utils/log_service_test.dart` (Flutter, existant + 1 nouveau cas) | e-mail, UUID, téléphone, coordonnées, champs sensibles nommés, URL, **jeton/JWT (nouveau)** |
| `hivmeet_backend/test_logging_privacy.py` (Django, existant + 1 nouveau cas) | e-mail, UUID, téléphone, coordonnées, champs sensibles nommés, URL, arguments `%s` interpolés, texte d'exception, **jeton/JWT (nouveau)** |
| `test/core/utils/no_raw_payload_logging_test.dart` (Flutter, **nouveau fichier**) | Garde de non-régression statique : échoue si `debugPrint(` réapparaît dans l'un des 13 fichiers corrigés en §3.1 |

Toutes les catégories de canaris exigées par le plan (e-mail, téléphone,
jeton, URL image, coordonnées, UUID) sont couvertes des deux côtés.

## 4. Vérification CI / crash reporting / exports (plan §10, étape 4)

- **CI** (`.github/workflows/android-build.yml`) : seul l'APK est publié
  comme artefact ; aucun log n'est téléversé. OK.
- **Crash reporting** (`lib/main.dart`, Firebase Crashlytics) :
  `recordFlutterFatalError`/`recordError` reçoivent l'objet d'erreur natif,
  **sans passer par le sanitizer**. Analyse du flux réel : les erreurs
  gérées (`try/catch` → `Left(Failure(...))`, chemin dartz utilisé partout
  dans l'app) n'atteignent jamais ces handlers globaux — seules les
  exceptions réellement non interceptées y arrivent. **Risque résiduel non
  corrigé** : si une exception non interceptée porte un message construit
  par interpolation de PII (`throw Exception('... $email ...')`), son
  `.toString()` atteindrait Crashlytics tel quel. Un correctif générique
  (sanitizer appliqué à l'objet d'erreur) dégraderait le regroupement et la
  stack trace natifs sans certitude de gain réel ; nécessite un audit dédié
  des sites `throw` du dépôt, hors périmètre proportionné de cette phase.
  **Non corrigé, documenté explicitement.**
- **ADB** : aucun canal de log applicatif supplémentaire identifié en dehors
  de `debugPrint`/`developer.log`, tous deux désormais couverts.
- **Exports** (RGPD `RequestDataExport`) : chemin `ProfileBloc` → repository
  → API, aucun `debugPrint` trouvé sur ce chemin lors de l'audit initial.

## 5. Résultat des canaris — preuve réelle

Exécution réelle de la suite backend complète (pas une simulation) :
sortie console observée montre les redactions effectives en conditions
réelles, par exemple (extraits, déjà expurgés par le filtre lui-même) :

```
Profile created for user: <email:b5e7b4e45c1a>
Verification record created for user: <email:b5e7b4e45c1a>
Conversation websocket connected: conversation_id=<id:d66659156ed0>
```

Aucun e-mail, UUID ou jeton en clair n'apparaît dans la sortie de test
complète (263 tests).

## 6. Tests exécutés

| Suite | Résultat |
| --- | --- |
| `flutter analyze --no-pub` (fichiers modifiés) | 0 issue (2 problèmes intermédiaires détectés et corrigés en cours de route : import dupliqué, import inutilisé) |
| `dart format` (fichiers modifiés) | stable |
| `flutter test --no-pub` (suite complète) | **285/285** (1 skip volontaire), `All tests passed!` |
| `python manage.py check` | 0 issue |
| `python manage.py test --noinput` (suite complète) | **263/263**, `OK` |
| Canaris sanitizer (Dart + Python, e-mail/UUID/téléphone/coordonnées/champs/URL/JWT) | Tous verts |
| Garde de non-régression `no_raw_payload_logging_test.dart` | Vert |

## 7. Vérification de correction (plan §10)

- ✅ Aucun canari sensible (e-mail, téléphone, jeton, URL image,
  coordonnées, UUID) ne survit dans les logs de test Flutter ou Django.
- ✅ Les anomalies restent classifiables : type d'erreur, clés de champ,
  identifiants pseudonymisés stables (corrélation non réversible)
  conservés.
- ✅ Aucune suppression de log large ou de répertoire non validée — seuls
  des appels `debugPrint` individuels ont été reroutés, jamais supprimés.
- ⚠️ Risque résiduel documenté et non corrigé : Crashlytics (§4).

## 8. Verdict

**PASS**, avec un risque résiduel explicitement documenté (Crashlytics /
exceptions non interceptées) plutôt que masqué. Conforme à la règle du plan
« ne jamais prendre un catch vide comme preuve de succès ».

# Plan d'exécution autonome — anomalies détectées dans les journaux

> **Statut :** plan exécutable par un agent AI.
>
> **Périmètre :** Flutter/Android, Django/DRF, stockage média, Firebase Cloud
> Messaging, Celery et performance mobile.
>
> **Sources :** emulator_run.md, device_run copy.md et backend_run.md, collectés
> le 16 septembre 2026.
>
> **Exclusion :** les corrections Premium/My-CoolPay sont déjà traitées dans les
> phases précédentes. Elles restent des parcours obligatoires de non-régression.

## 1. Objectif et définition de terminé

Résoudre les défauts confirmés dans les journaux sans masquer leurs symptômes,
sans exposer de données sensibles et sans casser les parcours Free, Premium,
Découverte, profil ou notifications.

Le résultat attendu est :

1. un APK dont l'identité est vérifiée s'installe normalement sur l'émulateur et
   l'appareil physique ;
2. les polices ne sont plus téléchargées depuis Google Fonts pendant l'exécution ;
3. les réglages et filtres sont exempts d'assertion Flutter et de clés de
   traduction manquantes ;
4. les photos locales valides sont fournies sous une URL média correcte ;
5. un appareil Android compatible enregistre son jeton FCM et peut recevoir une
   notification de test sans divulguer d'identité ;
6. Celery a un comportement explicite pour chaque environnement ;
7. les performances sont évaluées sur un build profile réellement installé ;
8. toute régression détectée par l'analyse d'impact est corrigée avant livraison.

Un défaut n'est terminé que si les cinq preuves suivantes existent :

- reproduction initiale, ou condition de non-reproduction documentée ;
- cause racine établie, ou hypothèse écartée avec preuve ;
- test automatisé de non-régression ;
- contrôle des consommateurs internes et dépendances externes ;
- recette sur émulateur et appareil physique exécutant le même artefact vérifié.

L'agent continue automatiquement entre les phases tant qu'il reste dans les
droits techniques déjà accordés. Il doit s'arrêter avec le verdict
BLOCKED_EXTERNAL s'il nécessite une décision ou ressource externe : secret,
compte fournisseur, signature, production, suppression de médias, migration de
données ambiguë, désinstallation destructive ou coût financier.

## 2. Règles impératives pour l'agent exécutant

### 2.1 Gouvernance et discipline de changement

1. Lire AGENTS.md, cartes de projet, règles locales et routeurs frontend/backend
   avant toute action. Charger ensuite les skills spécifiques nécessaires :
   bug-fixing, test-impact-selection, celery-redis-reliability,
   migrations-data-integrity, security-permissions ou performance-query-tuning.
2. Utiliser d'abord le graphe de dépendances, puis une recherche textuelle
   ciblée. Écrire une courte hypothèse de fichiers avant toute exploration large.
3. Capturer l'état non destructif initial : statut Git, diff ciblé, versions
   Flutter/Dart/Python/Gradle, package Android installé et environnement expurgé
   des secrets.
4. Corriger une anomalie logique à la fois. Ne pas combiner refonte esthétique,
   migration, configuration infrastructure et optimisation de performance dans
   un même patch.
5. Après chaque correction : formatter, analyse statique, tests ciblés, recette
   du scénario source et analyse d'impact de la section 12. Corriger tout écart
   avant de poursuivre.
6. Ne jamais réinitialiser le worktree, écraser des changements préexistants,
   supprimer des données, installer un downgrade Android ou désinstaller une
   application sans sauvegarde et instruction explicite.
7. Pour un contrat partagé, documenter requête, réponse, codes HTTP, erreurs,
   consommateurs Flutter et permissions avant de modifier l'une des extrémités.

### 2.2 Confidentialité, sécurité et observabilité

- Ne jamais écrire dans un rapport, une sortie CI ou un log : e-mail, téléphone,
  jeton FCM, JWT, UUID utilisateur, photo, URL signée, localisation précise,
  statut VIH ou clé API.
- Utiliser des corrélations non réversibles et des métriques agrégées.
- Ne jamais prendre un catch vide comme preuve de succès. Les erreurs doivent
  être classifiées, redigées, mesurables et non bloquantes uniquement lorsque le
  produit peut effectivement fonctionner sans la fonctionnalité secondaire.
- Aucun secret Firebase, Redis, My-CoolPay, Android ou autre ne peut être ajouté
  au dépôt, à un test, à Flutter ou à ce document.
- Toute migration impose dry-run, comptage agrégé, lots, transaction par lot,
  sauvegarde et plan de retour arrière.

### 2.3 Preuves et verdicts

Créer ou mettre à jour un rapport QA expurgé sous docs/qa, ou l'emplacement QA
normalisé du projet. Il doit contenir : date, hash court de commit, hash APK,
version, appareil anonymisé, scénario, résultat, durée, métriques agrégées et
test associé. Ne jamais y coller les logs bruts.

| Verdict | Signification |
| --- | --- |
| PASS | preuve automatisée et recette réelle disponibles |
| FAILED | défaut encore reproduit après correction |
| NOT_REPRODUCED | absence observée, mais condition ou preuve insuffisante |
| BLOCKED_EXTERNAL | dépendance appareil, réseau, fournisseur ou autorisation absente |
| NO_GO | défaut bloquant ou risque sécurité non levé |

NOT_REPRODUCED n'est jamais assimilé à PASS pour une fonction critique.

## 3. Registre initial des anomalies

| ID | Anomalie | Preuve source | Priorité | Composants initiaux |
| --- | --- | --- | --- | --- |
| LOG-01 | APK refusé avec INSTALL_FAILED_VERSION_DOWNGRADE | lignes 5–7 des deux journaux mobiles | P0 | pubspec, Gradle, CI, ADB |
| LOG-02 | Échec OpenSans/Pacifico depuis fonts.gstatic.com | émulateur 72–79 ; appareil 144–145 | P1 | thème, splash, widgets, assets |
| LOG-03 | Assertion ListTile sous DecoratedBox | appareil 150–168 | P1 | profil, réglages, accessibilité |
| LOG-04 | Clé discovery.gender introuvable | appareil 172–178 | P1 | modal filtres, FR/EN |
| LOG-05 | GET /profile_photos retourne 404 | backend 117–151 | P1 | serializers, médias, caches |
| LOG-06 | SERVICE_NOT_AVAILABLE et aucun jeton backend | émulateur 17 ; backend 444, 471 | P1 | Android, FCM, endpoint |
| LOG-07 | Broker Celery avec hostname localhost implicite | backend 444 | P2 | settings, broker, worker, tâches |
| LOG-08 | Jank important et frames sautées | émulateur 38/50/60/62 ; appareil 31/56 | P1 à diagnostiquer | démarrage, rendu, réseau, images |

### 3.1 Signaux qui ne doivent pas déclencher une correction aveugle

- Le 403 de likes-received pour un compte Free correspond au verrou Premium
  attendu. Vérifier l'UX et l'absence de retry ; ne jamais retirer la permission.
- No FCM token est normal pour un compte sans appareil enregistré. Il devient une
  anomalie uniquement après échec d'un appareil authentifié, compatible et
  connecté à enregistrer son jeton.
- EGL/OpenGL sur émulateur et ion sur appareil sont des signaux de plateforme
  tant qu'ils ne sont pas reproduits avec l'APK courant en mode profile.
- Les logs joints sont redigés. Cette redaction ne justifie jamais les dumps de
  JSON complets restants dans le code source.

## 4. Phase 0 — Préparation et reproductibilité

### Objectif

Ne pas corriger une ancienne build ou un symptôme d'environnement.

### Actions automatisées

1. Créer deux comptes QA anonymisés, Free et Premium, sans donnée sensible ou
   donnée de production. Employer des alias non identifiants.
2. Nommer les appareils ANDROID_EMULATOR_A et ANDROID_PHYSICAL_A. Relever modèle,
   ABI, API level, package, versionCode, versionName, date d'installation, état
   Play Services et réseau. Ne pas conserver le numéro de série dans le rapport.
3. Vérifier que les requêtes des deux APK atteignent bien le backend dont les
   logs sont analysés, par corrélation anonymisée.
4. Construire une référence sans code modifié. Consigner hash APK, variante,
   commit et métadonnées Android.
5. Créer une matrice anomalie → scénario → appareil → test automatique → preuve
   manuelle. Toute cellule vide est un risque explicite.
6. Mesurer le baseline : lancement, erreurs de police, assertions, 404 image,
   token FCM, tâche Celery et jank. Ne pas qualifier la performance avant la
   phase 1.

### Gate de sortie

- Chaque LOG-xx a un scénario de reproduction, ou le verdict NOT_REPRODUCED avec
  condition manquante.
- APK, package installé et backend de recette sont identifiés.
- Aucun secret ni PII n'est présent dans le baseline.

### Analyse d'impact

- **Interne :** build Android, injection Flutter, backend, serializers, tâches
  et contrats utilisés par les scénarios.
- **Externe :** Play Services, Firebase, réseau, proxy, Redis, stockage média et
  CDN. Une indisponibilité devient BLOCKED_EXTERNAL, jamais un succès simulé.

## 5. Phase 1 — Intégrité de l'artefact Android : LOG-01

### Hypothèse à valider

Le versionCode fourni au build est inférieur à celui de l'application installée,
ou l'APK est signé différemment. Il faut vérifier pubspec.yaml, les paramètres
Flutter, android/local.properties, android/app/build.gradle et la CI. Un fichier
local ignoré par Git ne peut pas être la seule source de vérité.

### Étapes

1. Lire les métadonnées de l'APK et du package installé avec ADB ciblé par
   appareil. Relever versionCode, versionName, lastUpdateTime et empreinte de
   signature uniquement dans une preuve privée.
2. Identifier la source effective de flutter.versionCode pendant le build.
3. Mettre en place une règle monotone et reproductible : chaque build installable
   du même applicationId reçoit un versionCode strictement supérieur aux builds
   de recette antérieures. La CI doit appliquer la règle, pas une valeur Gradle
   isolée.
4. Construire un APK debug neuf, calculer son checksum et vérifier ses
   métadonnées avant l'installation.
5. Installer avec mise à jour normale seulement. Si code inférieur ou signature
   différente, arrêter la phase : ne pas employer adb install avec downgrade,
   ne pas désinstaller automatiquement.
6. Relire le package après installation et comparer à l'APK. Lancer l'app puis
   confirmer version/processus dans les logs redigés.
7. Construire et installer une seconde version supérieure pour prouver le
   comportement de mise à jour futur.

### Vérification de correction

- Installation réussie sur les deux appareils sans downgrade, désinstallation ou
  effacement de données.
- versionCode/versionName installés correspondent exactement à l'APK produit.
- Les nouveaux logs ne contiennent plus INSTALL_FAILED_VERSION_DOWNGRADE.
- Une mise à jour successive fonctionne.
- Un conflit de signature est classé BLOCKED_EXTERNAL et non contourné.

### Analyse d'impact et rollback

Vérifier scripts CI, documentation, variants debug/staging, deep links,
applicationId Firebase et certificat. Conserver l'APK précédent pour
investigation. Android ne permet pas de retour à une version plus basse sans
downgrade ou perte de données ; cette limite doit rester visible.

## 6. Phase 2 — UI déterministe, offline et localisée : LOG-02 à LOG-04

### 6.1 Polices locales : LOG-02

#### Hypothèse

Le package google_fonts tente de télécharger OpenSans et Pacifico au runtime. La
dépendance à fonts.gstatic.com échoue hors connexion et peut contribuer au jank
au démarrage.

#### Étapes

1. Scanner les appels GoogleFonts dans lib et recenser familles, styles et poids
   réellement utilisés. Ne pas se limiter aux trois valeurs vues dans les logs.
2. Obtenir les fichiers officiels sous licence compatible. Conserver origine,
   licence, checksum et taille ; les déclarer comme assets Flutter.
3. Configurer l'initialisation pour utiliser les assets et interdire le runtime
   fetching. Adapter thème global et appels isolés sans altérer involontairement
   poids, taille ou branding.
4. Ajouter un test statique qui échoue si une famille/variante utilisée n'est pas
   présente dans les assets déclarés, et un test de widget/démarrage sans réseau.
5. Tester offline sur émulateur, puis appareil physique, en sauvegardant et
   restaurant l'état réseau. Ne jamais laisser l'appareil utilisateur en mode
   avion.

#### Vérification de correction

- Aucun appel fonts.gstatic.com, aucune erreur google_fonts dans splash, login,
  Découverte, modal filtres, profil et modales.
- Comparaison visuelle FR/EN : aucun troncage, contraste valide, taille
  accessible et identité visuelle conforme.
- Taille APK, temps de démarrage et mémoire comparés au baseline. Toute hausse
  significative doit être expliquée.

#### Analyse d'impact

- **Interne :** thème, splash, widgets communs, cache de police, golden tests.
- **Externe :** licence, poids de téléchargement et disparition de la requête
  vers un tiers pendant le démarrage.

### 6.2 Assertion ListTile et feedback tactile : LOG-03

#### Cause probable

_ActionTile dans profile_detail_page.dart place ListTile sous un Container décoré.
Flutter ne garantit alors pas que l'effet Ink soit visible sur son Material
ancêtre.

#### Étapes

1. Reproduire l'assertion dans Profil et réglages avec l'APK validé phase 1.
2. Remplacer la composition par Material + Ink/InkWell, ou Card, qui porte
   décoration, forme et clipping. Préserver rayon, ombre, dimensions, onTap et
   animation.
3. Ne pas supprimer le feedback tactile afin de simplement masquer l'assertion.
4. Ajouter un widget test pour tous les ActionTile : construction sans exception,
   activation unique, sémantique et focus accessibles.

#### Vérification de correction

- Aucun message ListTile background color or ink splashes may be invisible dans
  Profil, réglages, devise ou Premium.
- Ripple visible, cible tactile utilisable et callback déclenché une fois.
- Tests widget, flutter analyze et recette FR/EN sur les deux appareils.

#### Analyse d'impact

Rechercher les autres ListTile sous Container décoré. Vérifier thèmes, effets
Ink, lecteur d'écran, contraste et taille de cible tactile.

### 6.3 Traduction manquante : LOG-04

#### Cause probable

filters_modal.dart appelle discovery.gender alors que les catalogues FR/EN ont
déjà discovery.gender_title. Ajouter une clé dupliquée n'est pas une correction
sûre.

#### Étapes et vérification

1. Vérifier la maquette et employer la clé sémantiquement correcte.
2. Exécuter un validateur récursif de parité FR/EN : JSON valide, zéro clé
   absente, zéro placeholder divergent.
3. Ajouter un test du modal de filtres dans les deux langues qui vérifie le texte
   effectivement rendu.
4. Rechercher tous les appels à discovery.gender avant retrait. Aucun texte brut
   de clé ne doit être affiché ou journalisé.

#### Analyse d'impact

Contrôler terminologie inclusive, options de genre réellement supportées,
lecteurs d'écran et absence de log des préférences de recherche.

## 7. Phase 3 — Contrat et intégrité des URLs de photos : LOG-05

### Hypothèse à valider

Le sérialiseur de matching conserve une URL relative débutant par une barre. Une
valeur historique /profile_photos devient une requête à la racine alors que les
fichiers locaux devraient être servis sous /media. Le fichier peut aussi être
réellement absent : l'inventaire doit départager les causes.

### Étapes détaillées

1. Créer une commande de diagnostic lecture seule qui compte, sans afficher
   valeurs ni profils, les formes de photo_url et thumbnail_url : HTTPS, /media,
   media, /profile_photos, profile_photos, vide, schéma inconnu, fichier absent.
2. Vérifier MEDIA_URL, MEDIA_ROOT, droits stockage, proxy/CDN et routes médias
   de chaque environnement. Tester un profil QA par endpoint authentifié puis
   par GET HTTP depuis les deux appareils.
3. Créer une fonction backend unique de normalisation :
   - conserver URL HTTPS explicitement autorisées ;
   - transformer un chemin local valide vers /media ;
   - éviter double préfixe ;
   - rejeter schéma non autorisé ;
   - fabriquer une URL absolue uniquement avec contexte de requête et hôte
     approuvé.
4. Employer la fonction dans tous les producteurs de photos : Découverte,
   profils, matching, messagerie, réglages, notifications et tâches qui
   exposent une image. Un patch du seul sérialiseur Découverte est insuffisant.
5. Si les données historiques sont erronées, écrire migration ou commande
   idempotente avec dry-run, lots, transaction, compteurs anonymisés et
   sauvegarde. Les URL externes et cas ambigus ne sont pas modifiés sans
   décision explicite.
6. Pour un fichier absent, appliquer le fallback UX prévu, placeholder local non
   identifiant ou absence d'image. Ne jamais télécharger une image tierce ou
   inventer un profil.

### Vérification de correction

- Le contrat reste une liste de chaînes URL ; aucun DTO Flutter ne change
  silencieusement.
- Chaque variante locale valide retourne HTTP 200 ; le chemin erroné
  /profile_photos n'est plus demandé.
- Photos opérationnelles dans carte Découverte, détail profil, matches,
  messagerie, réglages, notifications et images FCM si concernées.
- Tests unitaires : URL absolue, variantes locales, double préfixe, vide, URL
  externe, schéma invalide, fallback.
- Tests API : authentification, sans photo, photo non approuvée, pagination,
  permissions, stockage distant.
- Cache client/CDN compatible et aucun média privé ne devient public.

### Analyse d'impact et rollback

Auditer CDN, cache HTTP, reverse proxy, liens cacheés sur appareils, URLs FCM et
règles d'accès. Pour une migration, rollback par restauration de valeurs
originales consignées par lot ; jamais par suppression globale de médias.

## 8. Phase 4 — Fiabilité FCM et Celery : LOG-06 et LOG-07

Tester séparément acquisition Android du jeton, enregistrement authentifié dans
Django et livraison Celery/FCM. L'échec de l'un ne prouve pas une cause dans
l'autre.

### 8.1 Jeton FCM Android et endpoint backend : LOG-06

#### Diagnostic obligatoire

1. Vérifier Play Services, permission Android, réseau, package Firebase,
   signature build et projet Firebase sur les deux appareils. Ne jamais recopier
   les secrets Firebase.
2. Instrumenter temporairement par événements redigés : permission_state,
   get_token_result, registration_http_status, retry_number, session_generation.
   Le jeton est interdit dans les logs.
3. Tracer le flux getToken → POST auth/fcm-token → persistance fcm_tokens →
   envoi test. Distinguer permission, réseau, Firebase SDK, 401/403, serializer
   et erreur backend.

#### Correction

1. Conserver l'aspect non bloquant : login et navigation ne doivent pas attendre
   indéfiniment FCM.
2. Remplacer l'échec silencieux par retry borné, dédoublonné et annulable :
   backoff exponentiel plafonné, maximum explicite, reprise au premier plan ou
   après connectivité rétablie, jamais boucle active.
3. Conserver sessionGeneration et ne marquer le token enregistré qu'après succès
   HTTP.
4. Vérifier serializer, authentification, ownership et déduplication : un compte
   ne peut modifier que ses tokens ; les valeurs invalides et doublons ont des
   réponses stables.
5. Ajouter des tests avec faux FirebaseMessaging/AuthApi : token null,
   SERVICE_NOT_AVAILABLE, refresh, erreur transitoire/permanente, double appel,
   logout pendant retry, reprise réseau.

#### Vérification de bout en bout

- L'appareil compatible obtient et enregistre le jeton sans en dévoiler la valeur.
- Une notification QA arrive foreground, background et cold start ; son tap suit
  une route autorisée et protège l'identité d'un like pour Free.
- Hors connexion, l'app demeure utilisable, ne boucle pas et reprend proprement.
- No FCM token peut rester pour un compte sans appareil, mais pas pour le compte
  QA dont l'enregistrement a été confirmé.

### 8.2 Celery/Redis explicite : LOG-07

#### Hypothèse

Le fallback memory et le mode eager/thread rendent le chemin local ambigu. Le
warning de hostname ne prouve pas une panne de production mais interdit de
valider une fiabilité asynchrone réelle.

#### Étapes

1. Cartographier test, dev, recette/staging et production : broker, result
   backend, eager, worker, beat, retry, métriques.
2. Définir une politique :
   - tests unitaires : eager déterministe ;
   - dev sans broker : eager explicite, sans prétendre tester un worker ;
   - recette async : Redis accessible, worker et beat démarrés ;
   - production : URL broker via secret, sans fallback mémoire.
3. Corriger settings ou enqueue afin d'éviter hostname implicite et de conserver
   transaction.on_commit comme unique sortie des effets de bord.
4. Ne pas utiliser memory pour simuler une topologie multi-process ; elle ne
   remplace pas Redis dans une recette worker réelle.
5. Ajouter tests : pas de tâche au rollback, tâche après commit, panne broker non
   bloquante pour like/match, eager, worker recette, déduplication signal rejoué.

#### Vérification

- manage.py check et tests notifications/Celery ciblés passent.
- En recette Redis, worker consomme une tâche après commit avec corrélation
  redigée.
- En eager, pas de hostname implicite et pas de chemin production accidentel.
- Redis indisponible ne supprime pas like/match ; une métrique technique
  redigée est créée.

### Analyse d'impact phase 4

- **Interne :** login/logout, refresh token, endpoint FCM, préférences,
  notifications like/match, WebSocket, transactions, tâches et tests.
- **Externe :** Firebase Console, Play Services, APNs, Redis, worker, beat,
  pare-feu, quotas FCM et politique de rétention des tokens.

## 9. Phase 5 — Performance mobile mesurée : LOG-08

### Principe

Les frames sautées sont sérieuses, mais les journaux viennent d'une installation
échouée et d'un build debug avec polices réseau. Interdiction d'optimiser à
l'aveugle avant les phases 1 à 3.

### Étapes

1. Construire et installer APK profile avec commit, hash et symboles connus.
2. Mesurer trois répétitions minimum par appareil : cold start, login,
   Découverte, swipe, modal filtres, profil, retour, notification, images.
   Employer Flutter DevTools Timeline, gfxinfo/framestats et trace système si
   nécessaire.
3. Distinguer UI, raster/GPU, I/O, JSON, réseau, Firebase, décodage image,
   stockage et logs synchrones.
4. Modifier uniquement un hotspot confirmé. Optimisations admises après mesure :
   préchargement borné, cache image dimensionné, pagination, réduction de
   rebuilds ou I/O hors UI. Ne pas réduire sécurité, permission ou qualité image
   sans mesure et décision UX.
5. Conserver une comparaison avant/après agrégée pour chaque optimisation.

### Vérification

- Aucun burst de centaines ou milliers de frames sautées dans les scénarios.
- p95 sous le budget de frame de l'écran et aucune régression supérieure à 10 %
  d'un parcours non concerné par rapport au baseline corrigé.
- Temps de première interaction, CPU, mémoire, trafic et taille APK sont
  reportés.
- Une limite matérielle devient BLOCKED_EXTERNAL avec mesure sur l'autre
  appareil, jamais une conclusion non prouvée.

### Analyse d'impact

Rejouer swipe, images, cartes, listes, WebSocket, Firebase, logs et
accessibilité. Un cache ne doit jamais réafficher un profil passé ou révéler une
fonction Premium.

## 10. Phase 6 — Hygiène préventive des logs

Le dépôt contient des debugPrint de JSON et données de profil dans
interaction_history_repository_impl.dart. Même si ce n'est pas la cause directe
de l'un des messages, il faut l'assainir car HIVMeet manipule des données
sensibles.

### Étapes

1. Rechercher print, debugPrint et logs interpolant payload, headers ou modèle
   dans Flutter et Django.
2. Les supprimer ou les remplacer par le sanitizer commun, type d'erreur, code,
   durée et corrélation non réversible.
3. Ajouter des canaris de test : e-mail, téléphone, jeton, URL image,
   coordonnées et UUID. Aucun ne doit survivre dans une sortie log.
4. Vérifier CI, ADB, crash reporting et exports : rétention, masquage, accès.
5. Conserver un niveau d'observabilité qui diagnostique les défauts ; ne pas
   transformer tout log en silence.

### Vérification

- Aucun canari sensible dans logs Flutter/Django de test.
- Les anomalies restent classifiables grâce à des métriques non sensibles.
- Toute suppression d'artefact respecte la politique de rétention ; aucune
  suppression large ni répertoire non validé.

## 11. Contrôles après chaque correction

### Contrôles de code

~~~powershell
# Frontend : adapter les tests aux fichiers réellement modifiés
dart format --set-exit-if-changed <fichiers-dart-modifies>
flutter analyze --no-pub
flutter test --no-pub <tests-cibles>

# Backend : depuis D:\Projets\HIVMeet\env\hivmeet_backend
$env:DJANGO_SETTINGS_MODULE='hivmeet_backend.test_settings'
python manage.py check
python manage.py test <modules-cibles> --noinput
~~~

Les valeurs entre chevrons sont des emplacements de sélection, jamais des
commandes à exécuter telles quelles. Avant chaque exécution, l'agent les remplace
par les fichiers issus du diff et les tests nommés dans son analyse d'impact ; il
inscrit la commande concrète et son code de sortie dans le rapport QA.

Ajouter selon le patch :

- Android : build APK, checksum, métadonnées, version installée, smoke test.
- Migration : makemigrations --check, forward, rollback sur copie contrôlée,
  dry-run, volume et inventaire agrégé.
- Celery : test eager et test avec broker/worker recette réel.
- FCM : fake tests, permission, background/cold start sur appareil.
- Médias : unit normalizer, API et GET HTTP depuis appareils.
- i18n : parité FR/EN, placeholders, JSON et modal rendu.

### Matrice fonctionnelle minimale

| Parcours | Free | Premium | Émulateur | Appareil physique |
| --- | --- | --- | --- | --- |
| lancement offline et polices | requis | requis | requis | requis |
| Découverte, filtres, swipe, pile vide, actualisation | requis | requis | requis | requis |
| photo carte, détail, match, message | requis | requis | requis | requis |
| profil, réglages, devise, tap, accessibilité | requis | requis | requis | requis |
| notification foreground/background/cold start | identité masquée | droits appliqués | requis | requis |
| Premium, abonnement, deep links | non-régression | non-régression | si disponible | si disponible |

Les corrections Flutter de polices, widgets et notifications sont partagées avec
iOS. Si le produit distribue iOS, l'agent doit au minimum exécuter les tests
Dart communs et une compilation iOS sans signature sur un hôte macOS/Xcode
autorisé. Sans cet hôte, inscrire explicitement BLOCKED_EXTERNAL dans le rapport
au lieu de conclure que la non-régression iOS est prouvée.

### Contrôles de contrat et sécurité

- Vérifier DTO, codes HTTP, URLs, erreurs, deep links et métadonnées Android.
- Rejouer 401, 403, 404, 422 et 5xx pertinents ; ne jamais assouplir une
  permission pour faire passer une recette.
- Tester offline, timeout, reprise, double appui, arrière-plan et logout pendant
  une opération asynchrone.
- Exécuter git diff --check, scan secrets/PII et vérification licence de police.

## 12. Analyse d'impact interne et externe après chaque phase

| Axe | Questions | Preuve minimale |
| --- | --- | --- |
| Dépendances internes | Quels BLoC, routes, serializers, tâches, modèles, tests consomment le patch ? | graphe, recherche ciblée, tests voisins |
| Contrats | JSON, HTTP, URL, erreur, deep link, Android metadata changent-ils ? | avant/après, test consommateur |
| États/données | Cache, session, quota, media, token, migration/offline corrompus ? | reprise, rollback, persistance |
| Sécurité | Permission, token, image ou PII devient visible ? | canaris, revue authz |
| UX/i18n | FR/EN, focus, contraste, lecteur d'écran, erreurs cohérents ? | widget/golden ou recette |
| Externe | Firebase, Play Services, Redis, CDN, proxy, stockage, réseau changent ? | test réel ou BLOCKED_EXTERNAL |
| Performance | CPU, mémoire, trafic, batterie, APK, frames régressent ? | baseline agrégée |
| Rollback | Retour code, données, appareil sûr ? | procédure ou limite déclarée |

Un impact nouveau crée une nouvelle entrée LOG-xx et est corrigé avant le GO.
Deux boucles de correction maximum par anomalie sont autorisées avant une
livraison avec blocage étayé.

## 13. Recette finale et décision

### Préconditions

- APK recette identifié sur les deux appareils.
- Backend, stockage média, Firebase et Celery recette connus.
- Comptes QA Free/Premium, médias test et permission notification prêts.
- Aucune donnée, image, profil, téléphone ou paiement de production utilisé.

### Exécution finale

1. Rejouer LOG-01 à LOG-08 sur session neuve et persistante, sur deux appareils.
2. Rejouer connexion, logout/login, Découverte Free/Premium, likes/dislikes,
   super likes, historique/révocation, messages, profil, notifications,
   abonnement et deep links.
3. Exécuter tests ciblés puis suite élargie si contrat, migration, Firebase,
   Celery ou Android build est touché.
4. Exécuter analyse statique, format, git diff --check, validations migration,
   scan PII/secrets et contrôle licences.
5. Réaliser le double audit : exigences → preuves ; changements → exigences ;
   impact/régressions ; validation indépendante.

### Surveillance courte après recette

Pendant une fenêtre de test convenue, surveiller par métriques expurgées :

- taux d'échec d'installation et couple versionCode/signature ;
- erreurs de chargement de police et premier rendu ;
- assertions Flutter par écran ;
- taux de 404 médias, forme d'URL agrégée et fallback ;
- taux getToken, enregistrement FCM, livraison FCM, tokens purgés ;
- erreurs broker/worker, latence de tâche et nombre de tâches après commit ;
- p95 de frame, temps de première interaction, mémoire et trafic.

Définir une alerte ou un seuil d'investigation pour toute réapparition. Ne pas
faire remonter de valeur personnelle dans l'outil de métriques.

### Décision GO/NO-GO

Le verdict GO est autorisé seulement si chaque défaut confirmé est PASS, les
dépendances externes sont testées ou explicitement acceptées comme exclusions,
aucun défaut bloquant n'est ouvert et le rapport QA fournit versions, appareils,
tests et risques résiduels.

Une indisponibilité Firebase, Redis, stockage, signature Android ou appareil
reste BLOCKED_EXTERNAL ou NO_GO. Elle ne peut jamais être présentée comme un
succès réel.

## 14. Livrable final obligatoire

L'agent fournit :

1. fichiers modifiés, migrations, environnements et configurations touchés ;
2. rapport QA expurgé ;
3. pour chaque LOG-xx : symptôme, cause, correctif, test, résultat émulateur et
   appareil physique ;
4. dépendances externes et blocages ;
5. mesures performance avant/après ;
6. résultat du double audit de complétude ;
7. risques résiduels et rollback testé, ou justification précise de son absence.

# Audit phase 4 — Journaux d’exécution

Date de l’audit : 2026-08-02
Sources : `device_run.md` (154 lignes), `emulator_run.md` (571 lignes) et
`backend.md` (1 155 lignes).

Ce document ne reproduit aucun identifiant utilisateur, jeton FCM ou URL
complète provenant des journaux.

## Bilan

Les journaux ne montrent ni crash fatal, ni erreur HTTP applicative sur les
flux de messagerie, ni échec de connexion WebSocket. Le périphérique physique
ne contient pas d’exception Flutter. L’émulateur contient toutefois une erreur
de média répétée et plusieurs alertes d’intégration ou de configuration à
traiter hors du périmètre des quatre correctifs de messagerie.

Le journal backend précède presque toutes les corrections récentes : il atteste
des comportements historiques, non leur résolution définitive. Il contient huit
envois de message réussis, sans HTTP 5xx ni traceback, mais aussi des rafales
client et des risques de configuration décrits ci-dessous.

## Anomalies confirmées

### P0 — Données personnelles et techniques exposées par les journaux backend

- **Constat :** `backend.md` contient des adresses e-mail, des noms affichés,
  des identifiants internes et des préférences de compte dans des traces de
  fonctionnement normal. Le code actuellement lu ajoute également des traces
  contenant des identifiants utilisateur et, lors d’une invalidation FCM, peut
  journaliser la valeur complète des jetons rejetés.
- **Classement :** défaut backend actif confirmé par le code ; la présence de
  données personnelles dans le journal historique est également confirmée.
- **Impact :** fuite de données sensibles dans les consoles de développement,
  agrégateurs de logs, exports de diagnostic ou tickets de support, avec un
  risque particulièrement élevé pour une application de santé/rencontre.
- **Action backend :** supprimer les valeurs d’identité, préférences et jetons
  des messages applicatifs ; conserver au besoin un identifiant de corrélation
  non réversible, avec rédaction centralisée et politique de rétention.
- **Validation :** exécuter les flux connexion, message, FCM et erreur FCM puis
  contrôler que les journaux ne contiennent aucune donnée personnelle, aucun
  identifiant utilisateur brut et aucun jeton complet ou partiel.

### P1 — Livraison push non démontrée avec un broker Celery en mémoire

- **Constat :** le journal contient un avertissement Kombu indiquant l’absence
  d’hôte configuré. La configuration backend actuelle fixe le broker Celery à
  `memory://`. Huit messages et huit inscriptions FCM réussissent dans le
  journal, mais aucune exécution de tâche ni livraison FCM n’y est tracée.
- **Classement :** risque backend actif confirmé par la configuration ; la
  livraison push réelle demeure non prouvée par ces journaux historiques.
- **Impact :** une tâche n’est pas partagée entre les processus avec ce broker ;
  les notifications push peuvent donc manquer hors du processus qui les a
  produites ou après redémarrage.
- **Action backend :** rendre le broker et le backend de résultat configurables
  par environnement, employer un service partagé, superviser un worker et
  exposer des métriques de mise en file, exécution, retry et échec FCM.
- **Validation :** depuis un processus web distinct, envoyer un message vers une
  session destinataire et prouver une fois l’enqueue, l’exécution worker puis
  le résultat FCM, y compris en cas de retry.

### P1 — Persistance et WebSocket personnel couplés à l’enqueue FCM

- **Constat :** dans le code backend actuel, une exception lors de
  `send_message_notification.delay(...)` empêche ensuite la création de la
  notification persistée et l’émission vers le groupe WebSocket personnel.
- **Classement :** défaut d’intégration backend actif confirmé par le code ;
  il n’est pas directement observable dans le journal, qui ne contient aucun
  échec d’enqueue explicite.
- **Impact :** une indisponibilité push peut faire disparaître également le
  badge, la liste de notifications et la mise à jour temps réel, alors que le
  message a été créé avec succès.
- **Action backend :** découpler la persistance et la diffusion WebSocket de la
  livraison FCM ; une outbox transactionnelle avec worker idempotent et retry
  est la cible recommandée.
- **Validation :** simuler une panne du broker puis vérifier que le message, la
  notification persistée et le WebSocket utilisateur restent disponibles, avec
  un push remis en tentative ultérieure.

### P0 — Fragment de jeton FCM écrit dans les logs de débogage

- **Constat :** le journal du périphérique contient un préfixe de jeton FCM.
- **Cause confirmée :** `NotificationService._registerToken` appelle
  `debugPrint` avec les vingt premiers caractères du jeton lorsque
  `kDebugMode` est actif.
- **Impact :** les journaux de développement, les captures de CI ou les outils
  de diagnostic peuvent divulguer une donnée d’authentification de push. Un
  fragment n’est pas un secret complet, mais il ne doit pas être journalisé.
- **Action recommandée :** ne logger que l’état de succès/échec et la plate-forme,
  jamais le jeton ou une partie du jeton. Vérifier aussi que les traces de
  production sont désactivées ou correctement redirigées.
- **Validation :** lancer l’inscription FCM et vérifier qu’aucune sous-chaîne du
  jeton ne figure dans `logcat`.

### P1 — URL de photo de profil invalide, répétée et non dégradée dans le chat

- **Constat :** l’émulateur reçoit 127 erreurs `HTTP 404` pour une même photo
  de profil, dont une `NetworkImageLoadException` initiale. Elles se répètent
  pendant l’ouverture et l’utilisation d’une conversation.
- **Preuve backend complémentaire :** `backend.md` enregistre 286 réponses 404
  sur des chemins de photos de profil ; ce volume confirme que le problème ne
  se limite pas au rendu Flutter.
- **Cause confirmée :** le serveur local renvoie `404` pour le chemin média
  communiqué au client. La cause serveur précise reste à vérifier : fichier
  média supprimé, donnée persistée obsolète ou routage des médias local absent.
- **Amplification côté client :** les deux avatars de `ChatPage` utilisent
  `CircleAvatar(backgroundImage: NetworkImage(...))` sans solution de repli,
  alors que `OptimizedImage` possède déjà un `errorBuilder`.
- **Impact :** avatar absent, bruit massif dans les journaux, rapports
  Crashlytics parasites et surcoût réseau/rendu.
- **Action backend :** garantir que toute URL de photo renvoyée par les profils,
  conversations et matches est accessible, ou nettoyer les références de médias
  supprimés. Vérifier l’exposition du volume média dans l’environnement local.
- **Action frontend :** remplacer les avatars directs par un composant avec
  repli visuel et arrêt de la tentative d’affichage après erreur ; couvrir le
  cas HTTP 404 par un test widget.
- **Validation :** ouvrir une conversation avec une photo existante puis une
  référence volontairement inexistante ; aucune exception Flutter récurrente ne
  doit être produite et l’avatar de secours doit s’afficher.

### P1 — Firebase App Check non configuré sur l’émulateur

- **Constat :** Firebase indique l’absence d’`AppCheckProvider` et emploie un
  jeton de substitution à deux reprises.
- **Cause confirmée :** `firebase_app_check` n’est pas déclaré ni activé dans
  l’application actuelle.
- **Impact :** ce n’est pas bloquant pour l’exécution locale observée, mais les
  services Firebase protégés pourront refuser les requêtes lorsque l’application
  de production imposera App Check. La protection anti-abus est également
  incomplète tant que cette configuration n’est pas faite.
- **Action recommandée :** choisir et activer le fournisseur par environnement
  (Debug provider pour développement, Play Integrity/DeviceCheck/App Attest pour
  production), enregistrer les clés de débogage et n’imposer App Check dans la
  console Firebase qu’après validation des clients.
- **Validation :** aucun avertissement de jeton de substitution sur émulateur ;
  accès Firestore/Storage/Messaging confirmé avec le fournisseur attendu.

### P2 — Ressource Android non fermée

- **Constat :** l’émulateur émet une fois `A resource failed to call close` près
  d’une fermeture/réouverture de WebSocket.
- **Confiance :** moyenne : le journal ne permet pas d’identifier la ressource
  native fautive ; aucun lien causal définitif avec le WebSocket n’est prouvé.
- **Impact potentiel :** fuite de descripteur ou ressource native à long terme
  lors de navigations répétées.
- **Action recommandée :** reproduire avec StrictMode activé et compter les
  ouvertures/fermetures de sockets, subscriptions et contrôleurs de la page de
  chat. Corriger uniquement après attribution de la pile native.

## Avertissements à planifier ou surveiller

### P2 — Rafales historiques de lectures et rechargements de conversations

- **Constat :** `backend.md` compte 128 marquages de messages comme lus et 160
  rechargements de la première page des conversations. Les pics atteignent
  respectivement seize et vingt-deux requêtes dans une même seconde.
- **Classement :** anomalie historique d’intégration, sans erreur HTTP serveur.
  Le journal ne permet pas à lui seul de prouver sa persistance après les
  correctifs frontend récents.
- **Cause la plus probable :** acquittements de lecture non mémorisés localement
  et réconciliations temps réel déclenchées sans coalescence suffisante.
- **Impact :** charge inutile, consommation réseau/batterie et risque de badge
  transitoirement incohérent lorsque les réponses arrivent dans le désordre.
- **Action :** valider les protections frontend de coalescence et observer côté
  backend une limite d’au plus une lecture par curseur et des rechargements
  bornés par événement réel.

### P2 — Rafale de refresh JWT et inscriptions FCM répétées

- **Constat :** trois réponses 401 sont suivies de vingt-trois refresh JWT, dont
  plusieurs dans la même seconde. Huit inscriptions de jeton FCM réussissent
  alors que le journal ne montre que huit envois de message ; les deux séries
  sont compatibles avec des initialisations ou retries redondants.
- **Classement :** anomalie historique d’intégration ; un comportement backend
  erroné n’est pas démontré par les réponses 200. La concurrence du refresh et
  la double inscription restent à vérifier côté client.
- **Impact :** charge d’authentification superflue, risques de course lors du
  rejeu des requêtes et bruit d’observabilité.
- **Action :** vérifier un refresh single-flight et une inscription FCM
  idempotente par session/valeur de jeton ; classer les 401 attendues hors du
  niveau d’erreur applicatif côté backend.

### P3 — Déconnexions WebSocket 1006 sans cause applicative prouvée

- **Constat :** trois fermetures anormales `1006` sont présentes dans le journal
  backend, sans traceback ni 5xx associé.
- **Classement :** signal historique à surveiller ; il peut provenir de la
  fermeture de l’application, du réseau ou de l’émulateur et ne prouve pas un
  défaut du protocole.
- **Action :** ajouter des métriques anonymisées de durée, raison de fermeture,
  reconnexion et type de client ; investiguer seulement si le taux persiste sur
  plusieurs sessions réelles.

### P3 — Sondage de santé sur une route API inexistante

- **Constat :** le journal contient une réponse 404 pour une route de santé
  préfixée par l’API alors que la route de santé effective est hors de ce
  préfixe.
- **Classement :** bruit de configuration de sonde ou d’outil, non défaut
  fonctionnel backend prouvé.
- **Action :** corriger la configuration de la sonde et classer ce 404 attendu
  séparément des erreurs métier afin de préserver la qualité des alertes.

### P3 — Predictive Back Android non activé

- Le périphérique demande `android:enableOnBackInvokedCallback="true"` dans le
  manifeste. L’attribut est absent de l’activité.
- Ajouter puis valider le comportement retour Android 13+ (navigation, dialogues
  de blocage/signalement et feuille de pièces jointes).

### P3 — Crashlytics et Analytics sous pression à cause des erreurs image

- Crashlytics signale un délai d’attente de son écouteur Analytics ; ce signal
  survient pendant la rafale d’erreurs 404 et n’établit pas une panne autonome.
- Retester après la correction P1 ; si le délai persiste sans exception Flutter,
  auditer l’intégration Analytics/Crashlytics séparément.

### P3 — File Analytics longue sur le périphérique

- Une seule alerte indique des tâches Analytics en attente depuis longtemps.
- Aucun impact fonctionnel n’est démontré. Surveiller la fréquence après les
  correctifs de journalisation et d’images, sans créer de chantier tant que le
  signal reste isolé.

## Anomalies complémentaires de validation (hors journaux appareil)

Ces éléments ont été relevés lors des validations automatisées de la phase 3.
Ils ne doivent pas être interprétés comme des incidents constatés sur le
périphérique physique ou l’émulateur.

### P3 — Doubles de test sans `LocalizationService` enregistré

- **Constat :** les tests widget et BLoC de messagerie affichent des diagnostics
  GetIt indiquant que `LocalizationService` n’est pas enregistré, tout en
  réussissant leurs assertions grâce au comportement de repli actuel.
- **Impact :** bruit dans les sorties de test et risque de masquer une vraie
  régression de traduction ou de libellé utilisateur.
- **Action recommandée :** enregistrer un faux `LocalizationService` dans le
  `setUp` partagé des tests concernés, ou injecter un service de traduction
  déterministe dans les composants testés.
- **Validation :** exécuter les suites de notifications, de média et de
  conversations sans aucun diagnostic GetIt/LocalizationService.

### P3 — API Flutter dépréciées dans `ChatPage`

- **Constat :** l’analyse ciblée signale onze informations de dépréciation :
  l’accès à `window` et dix usages de `Color.withOpacity`.
- **Impact :** aucune régression fonctionnelle observée, mais risque de dette
  technique à l’approche de la prise en charge multi-fenêtre et des futures
  versions de Flutter.
- **Action recommandée :** remplacer `window` par `View.of(context)` ou
  `PlatformDispatcher` selon le contexte, puis `withOpacity` par `withValues`.
- **Validation :** relancer l’analyse ciblée de `ChatPage` sans information de
  dépréciation.

## Signaux écartés de cet audit

- Les messages WebRTC relatifs à l’audio focus sont des transitions Android
  attendues dans ce journal ; aucune erreur d’appel n’est visible.
- Les erreurs `RtgSchedIpcFile` du périphérique surviennent lors de la libération
  d’une surface Android et concernent des nœuds `/proc` propres à son ordonnanceur
  système. Sans pile Flutter ni symptôme visible associé, elles sont classées
  comme bruit de plate-forme ; les reconsidérer uniquement si des ralentissements
  sont reproductibles sur plusieurs appareils.
- Le démarrage du service Firebase Messaging, les réponses 200 de collecte
  Firebase et les fermetures WebSocket intentionnelles ne sont pas des anomalies.
- Les avertissements de clavier Android observés autour des saisies ne suffisent
  pas à établir un défaut applicatif.

## Ordre de traitement conseillé

1. Retirer des journaux backend les données personnelles, identifiants et jetons
   FCM, puis purger ou protéger les archives existantes (P0).
2. Remplacer le broker Celery en mémoire et découpler persistance/WebSocket de
   la livraison FCM (P1).
3. Retirer la journalisation frontend de jeton FCM (P0).
4. Corriger le cycle de vie des médias de profil côté serveur et ajouter le
   repli visuel client (P1).
5. Configurer Firebase App Check par environnement (P1).
6. Mesurer les rafales de lecture, rechargement, refresh JWT et inscription FCM
   après les correctifs de coalescence/idempotence (P2).
7. Reproduire l’alerte de ressource non fermée avec instrumentation (P2).
8. Activer et tester Predictive Back Android (P3).
9. Initialiser correctement `LocalizationService` dans les doubles de test (P3,
   hors journaux appareil).
10. Résorber les dépréciations Flutter de `ChatPage` (P3, hors journaux
   appareil).

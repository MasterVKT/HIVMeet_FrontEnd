# HIVMeet — rapport de passation de la session de remédiation

Date de rédaction : 27 septembre 2026.

Ce document prépare une nouvelle session de correction. Il résume les décisions,
les changements et les validations effectués durant la session précédente. Il ne
prétend pas qu'un comportement reste correct sur l'appareil après cette session :
toute anomalie observée maintenant doit être reproduite sur les binaires, données
et comptes actuellement utilisés avant toute nouvelle modification.

## 1. Contexte et règles de reprise

Deux demandes successives ont été traitées :

1. le plan de stabilisation en six phases couvrant les matches, la messagerie,
   l'accès Free mensuel, le profil/localisation/photos, les historiques/badges et
   une validation intégrée ;
2. le plan correctif complémentaire couvrant médias, téléchargement, actions de
   messages, alertes de lecture, masquage, présence, rewind et édition de profil.

Les décisions métier à conserver sont les suivantes :

| Sujet | Décision retenue |
| --- | --- |
| Accès Free | Un jeton mensuel UTC partagé entre révélation d'un like et déblocage Free-Free ; match Free-Free déverrouillé seulement si les deux jetons sont disponibles ; dix messages texte sortants par participant une fois déverrouillé. |
| Médias | Envoi réservé au Premium. Les aperçus ne doivent jamais sauvegarder automatiquement le fichier dans la galerie ; le téléchargement est explicite. |
| Messages | Copie gratuite des messages texte. Édition et suppression pour tous réservées au Premium, limitées à 15 minutes ; une suppression globale garde un marqueur « message supprimé ». |
| Reçus / alertes | Les coches existent pour tous (`sent → delivered → read`). Lorsqu’au moins un message passe réellement à `read`, l’auteur Premium éligible ayant activé sa préférence reçoit une alerte `message_read` persistante dans Notifications, regroupée par lot et dépourvue de contenu de message. |
| Présence | Même règle pour Free et Premium, mais uniquement si l'interlocuteur autorise la visibilité. Sous le nom, l'interface ne doit jamais afficher « Vu » ni une heure inventée. |
| Genre | Nouveaux comptes : `Homme` ou `Femme`, défini à l'inscription et immuable. Les anciens genres non conformes sont effacés sans déduction, excluent le profil de Découverte et demandent une confirmation explicite. |
| Préférences | Genres recherchés : `Tout le monde`, `Homme`, `Femme`. Relations : `Tous`, `Amitié`, `Relation sérieuse`, `Relation courte`, `Rencontre occasionnelle`. |
| Localisation | Lecture au premier plan après action utilisateur ; repli manuel obligatoire ; pas de coordonnées exposées à un tiers. Deux sélections manuelles de la même ville affichent « Même ville ». |

## 2. Ce qui a été livré par domaine

### Matches, interactions, historiques et badges

- Suppression d'un match, consultation du profil associé, archivage/fermeture de
  la conversation et comportement idempotent côté API.
- Interdiction de révoquer un like ayant déjà créé un match ; l'interface doit
  orienter vers la suppression du match.
- Rewind explicite et transactionnel par identifiant d'interaction, avec fenêtre,
  quota, idempotence et refus après création d'un match.
- Recherche et sélection multiple dans les historiques likes/passes, révocation
  groupée atomique et exclusion des likes liés à un match actif.
- État « vu » des matches séparé par participant et endpoints de compteur/lecture
  afin que le badge Matches désigne uniquement les matches non consultés.

Références : [phase 5 frontend](PHASE5_LOG08_2026-09-17.md), [contrat backend
historiques et badges](../../../env/hivmeet_backend/docs/PHASE_5_HISTORIES_AND_BADGES.md).

### Messagerie, médias et notifications

- Menu conversation avec masquage, restauration idempotente et réapparition
  uniquement après un message entrant de l'autre participant.
- Compositeur unifié : une à quatre lignes, défilement interne au-delà, commandes
  à taille fixe et alignement bas quelle que soit la taille d'écran ou le statut.
- Normalisation unique des URL médias, côté backend et client, pour les URL
  absolues, `/media/...`, `media/...` et chemins relatifs sans double barre.
- Métadonnées de média, rendu image/vidéo/audio, téléchargement authentifié et
  suppression du stockage lors d'une suppression globale.
- États optimistes de média, remplacement propre de l'aperçu local par l'URL
  serveur et mécanismes d'échec/réessai.
- Copie, édition Premium, suppression pour soi et suppression Premium pour tous
  depuis la sélection de messages ; la sélection est conservée sur erreur.
- Événements WebSocket de modification, reçus monotones, présence unifiée par
  heartbeat et déduplication des notifications de message.

Références : [phase 2 frontend](PHASE2_LOG02_04_2026-09-17.md),
[phase 3 URLs média](PHASE3_LOG05_2026-09-17.md), [matrice de validation](PHASE6_VALIDATION_MATRIX_2026-09-22.md).

### Profil, inscription, localisation et photos

- Inscription atomique incluant nom affiché, date de naissance, téléphone
  optionnel et genre requis ; protection de l'échange Firebase contre une
  création implicite de compte après la transition.
- Catalogue GeoNames versionné, pays puis villes paginées et recherchables,
  édition profil + localisation transactionnelle et confidentialité des
  coordonnées.
- Localisation automatique après action explicite, gestion des permissions et
  repli manuel ; calcul précis ou estimé côté serveur.
- Chargement initial de Photos, états vide/erreur/réessai, contraintes : une
  photo Free, six Premium, JPEG/PNG, 5 Mo, photo principale obligatoire et
  réordonnancement Premium.
- Catalogue Flutter partagé pour préférences de découverte, profil et
  inscription ; corrections de traductions françaises et mises en page étroites.

Références : [catalogue et inscription backend](../../../env/hivmeet_backend/docs/PHASE_4_ACCOUNT_PROFILE_CATALOG.md),
[localisation et photos backend](../../../env/hivmeet_backend/docs/PHASE_4_LOCATION_AND_PHOTOS.md),
[phase 4 frontend](PHASE4_LOG06_07_2026-09-17.md).

### Stabilisation transversale antérieure

- `versionCode` Android monotone pour éviter `INSTALL_FAILED_VERSION_DOWNGRADE`.
- Polices Open Sans et Pacifico embarquées localement : plus de téléchargement
  runtime vers `fonts.gstatic.com`.
- Corrections de localisations, widgets `ListTile`, URL de photos et erreurs de
  listes JSON dynamiques dans les repositories.
- FCM, Celery, authentification, abonnements et routes ont été revus dans les
  phases précédentes. Ces zones ont un fort impact transversal : ne pas les
  réécrire pour résoudre une anomalie locale sans suivre le contrat API.

Références : [baseline](BASELINE_PHASE0_2026-09-16.md), [version Android](PHASE1_LOG01_2026-09-16.md), [UI/offline/i18n](PHASE2_LOG02_04_2026-09-17.md).

## 3. Correctifs ajoutés pendant la validation finale

Les changements suivants ont été effectués en phase 6 à la suite d'échecs de
tests déterministes. Ils sont particulièrement pertinents pour toute nouvelle
régression de présence ou de messagerie.

| Racine | Fichiers | Raison et effet |
| --- | --- | --- |
| Backend | `notifications/consumers.py` | Un `ping` reçu avant authentification complète renvoie un instantané privé sans créer de présence ni provoquer d'exception. |
| Backend | `messaging/views.py`, `messaging/serializers.py` | La liste des conversations annote la présence des deux participants pour éviter une requête de présence par conversation, sans modifier le contrat REST/WebSocket. |
| Backend | `messaging/tests_phase2.py` | Le test de remise immédiate emploie désormais le service de présence effectif (`PresenceService.heartbeat`). |
| Backend | `tests/base.py`, `tests/test_integration.py` | Fixtures et inscription d'intégration rendues conformes au genre requis et aux préférences uniques. |
| Frontend + documentation | `docs/qa/PHASE6_VALIDATION_*` | Traçabilité des vérifications, limites de recette Android et audit de contrats. |

Les endpoints et clés JSON publics n'ont pas été modifiés par ces correctifs de
phase 6. Le détail et les commandes exactes figurent dans l'[addendum de
validation](PHASE6_VALIDATION_ADDENDUM_2026-09-26.md).

## 4. Migrations, flags et ordre de déploiement à respecter

Les migrations concernées comprennent notamment :

- `matching.0003_free_match_access`, `matching.0004_match_participant_seen_state`
  et `matching.0005_interaction_rewound_at` ;
- `messaging.0002` à `messaging.0007` : masquage, idempotence/unread, suppression
  globale, métadonnées média, édition et sessions de présence ;
- `profiles.0007_geo_catalog_and_location`, `profiles.0008_phase4_registration_gender_catalog`
  et `profiles.0009_normalize_sought_gender_single_choice`.

Avant d'activer le modèle Free-Free, déployer backend et migration, publier le
client compatible, puis seulement activer
`HIVMEET_FREE_MATCH_ACCESS_ENABLED=true`. Le flag est volontairement désactivé
par défaut afin que les anciens clients restent fonctionnels.

Avant de rendre le catalogue géographique obligatoire en production, importer et
vérifier l'archive GeoNames fournie localement via `sync_geonames_catalog`, puis
`verify_geonames_catalog`. Ne pas lancer ce chargement pendant une migration.

Les modalités précises de retour arrière sont documentées dans les deux documents
backend de phase 3 et 4 cités ci-dessus. Aucun rollback de schéma destructif ne
doit être lancé sans export et sauvegarde validés.

## 5. Validation réalisée et niveau de confiance

Les validations de l'état final documenté sont :

| Contrôle indépendant | Résultat documenté |
| --- | --- |
| `flutter analyze --no-pub` | Réussi, aucune anomalie. |
| `flutter test --no-pub` | 342 tests réussis ; un test d'intégration externe explicitement ignoré. |
| Tests Flutter ciblés de contrats | 33 tests réussis sur messagerie, matches et localisation. |
| `python manage.py check --settings=hivmeet_backend.test_settings` | Réussi. |
| `python manage.py test --settings=hivmeet_backend.test_settings` | 341 tests réussis en 116,448 s. |
| Tests backend ciblés présence/liste/notification/inscription | 4 tests réussis. |
| `makemigrations --check --dry-run` | Aucune migration manquante. |
| `git diff --check` dans les deux racines | Réussi ; avertissements CRLF connus seulement. |
| APK debug | Construit, SHA-256 consigné dans l'addendum. |

La [matrice Phase 6](PHASE6_VALIDATION_MATRIX_2026-09-22.md) contient une
recette à deux clients antérieure, caviardée, qui couvre messages, média,
lecture, masquage/restauration, profil de match et compositeur.

### Limites réelles à garder visibles

- Le nouvel APK n'a pas pu être réinstallé sur l'appareil physique car Android a
  refusé une signature différente (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Les
  données existantes n'ont pas été effacées pour contourner ce refus.
- Après installation, l'émulateur est devenu ADB `offline` et a perdu
  `system_server`. L'écran blanc observé pendant cet état n'est pas une preuve
  d'un défaut Flutter.
- La recette deux appareils doit donc être **rejouée** sur un émulateur sain et
  une build signée avec la même clé que l'application installée avant de conclure
  sur toute anomalie signalée maintenant.

## 6. État Git et précautions essentielles

Les deux dépôts étaient déjà très modifiés et contiennent de nombreux fichiers
non suivis. Aucun nettoyage, reset, checkout forcé ou suppression de données
utilisateur n'a été effectué pendant cette session. Une prochaine session doit :

1. inventorier `git status --short` dans les deux racines avant toute écriture ;
2. isoler les fichiers créés par la prochaine correction ;
3. ne pas interpréter chaque modification présente comme appartenant à cette
   session ;
4. ne pas inclure les captures temporaires non caviardées comme preuves produit.

Le fichier `docs/qa/phase6_current_emulator_start.png` est une capture
transitoire de l'émulateur défaillant. Elle n'est pas une preuve de produit.

## 7. Mode opératoire conseillé pour la prochaine session

1. Recueillir les nouvelles captures, logs et étapes exactes de reproduction,
   avec comptes de test anonymisés.
2. Reproduire chaque défaut sur le client actuellement installé et noter version,
   appareil, statut Free/Premium, état réseau et version backend.
3. Lire la matrice de phase 6 et cet handover, puis vérifier le contrat pair
   frontend/backend avant toute hypothèse de correction.
4. Pour une anomalie de chat, examiner en priorité :
   `message_input.dart`, `message_bubble.dart`, `chat_page.dart`, `chat_bloc.dart`,
   `messaging_api.dart`, `message_repository_impl.dart`, le WebSocket, puis
   `messaging/views.py`, `serializers.py`, `consumers.py`, `presence.py`.
5. Pour un défaut profil/localisation, examiner le contrat de catalogue, les
   réponses réelles pays/villes, les valeurs historiques et l'état de permission
   avant de modifier l'interface.
6. Ajouter un test déterministe reproduisant le défaut avant ou avec le correctif,
   puis exécuter le sous-ensemble Flutter/Django pertinent et une validation
   manuelle sur deux clients si l'anomalie concerne le temps réel.
7. À la fin, mettre à jour ce rapport ou ajouter un addendum daté qui distingue
   explicitement « corrigé et reproduit » de « couvert seulement par test ».

## 8. Sources de référence prioritaires

- [Matrice de validation finale](PHASE6_VALIDATION_MATRIX_2026-09-22.md)
- [Addendum de validation courant](PHASE6_VALIDATION_ADDENDUM_2026-09-26.md)
- [Recette finale initiale](RECETTE_FINALE_2026-09-17.md)
- [Baseline des logs](BASELINE_PHASE0_2026-09-16.md)
- [Contrat Free-Free backend](../../../env/hivmeet_backend/docs/PHASE_3_FREE_MATCH_ACCESS.md)
- [Contrat profil/inscription/catalogue backend](../../../env/hivmeet_backend/docs/PHASE_4_ACCOUNT_PROFILE_CATALOG.md)
- [Contrat localisation/photos backend](../../../env/hivmeet_backend/docs/PHASE_4_LOCATION_AND_PHOTOS.md)
- [Contrat historiques/badges backend](../../../env/hivmeet_backend/docs/PHASE_5_HISTORIES_AND_BADGES.md)

## Conclusion de passation

Ce rapport est utile et doit être conservé : il évite à la prochaine session de
réimplémenter des règles métier déjà décidées et lui donne les contrats, tests et
limites de validation connus. Il n'élimine pas le besoin d'un diagnostic neuf ;
les régressions observées après la livraison doivent être traitées comme des
faits nouveaux et confrontées au code, aux réponses API et à la recette actuelle.

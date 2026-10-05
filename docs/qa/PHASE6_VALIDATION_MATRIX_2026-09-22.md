# Phase 6 — matrice de validation finale

Date : 22 septembre 2026.

Les identifiants, jetons, UUID, coordonnées, noms de comptes et contenus issus
des conversations ont été retirés des preuves. Les deux captures conservées ne
montrent que des données de test non personnelles et des zones caviardées.

## Gates exécutés

| Contrôle | Résultat | Preuve |
|---|---|---|
| Migrations Django | `matching.0004` et `profiles.0007` appliquées ; aucune migration en attente | `migrate`, `showmigrations` et `makemigrations --check --dry-run` |
| Intégrité Django | `manage.py check` sans anomalie | sortie de commande Phase 6 |
| Régression backend | 266 tests réussis en 62,460 s | `env/hivmeet_backend/docs/qa/phase6_backend_suite_final.log` |
| Analyse Flutter | aucune anomalie | `phase6_flutter_analyze_final.log` |
| Widgets et BLoC Flutter ciblés | 18 tests réussis | `phase6_flutter_targeted_final.log` |
| APK Android debug | construit avec succès | `phase6_android_debug_build.log` |
| Installation Android | APK `versionCode 1050` installée sur appareil physique et émulateur | ADB `dumpsys package` |
| Vérification de confidentialité | exports XML caviardés, preuves visuelles caviardées, recherche de secrets négative | contrôle final Phase 6 |

## Recette Android à deux clients

- Deux sessions authentifiées ont été ouvertes simultanément : un compte Free
  sur l'appareil physique et un compte Premium sur l'émulateur.
- Un texte envoyé depuis le premier client a été affiché comme non lu sur le
  second, puis ouvert. La base a confirmé une unique transition finale
  `read`.
- Un média image envoyé depuis le compte Premium a été persisté avec une URL
  canonique, puis rendu par le client Free ; son état final était `read`.
  La preuve visuelle caviardée est [phase6_proof_messaging_redacted.png](phase6_proof_messaging_redacted.png).
- Le menu de conversation expose bien **Masquer** et sa confirmation explique
  qu'un message reçu fera réapparaître la conversation. L'endpoint exécuté
  dans la session de recette a renvoyé `204` et créé l'état de masquage ; un
  message entrant du second client l'a supprimé. Après rechargement, la
  conversation était de nouveau présente. La confirmation est visible dans
  [phase6_proof_hide_redacted.png](phase6_proof_hide_redacted.png).
- Un appui long sur un match a rendu disponibles **Voir le profil** et
  **Supprimer ce match**. L'ouverture du profil a abouti et l'emplacement a
  été affiché sous la forme `ville, pays` sans exposer de coordonnées.
- Sur l'appareil physique, le compositeur vide mesurait une seule ligne
  (42 pixels de hauteur utile), avec commandes fixes et bouton d'envoi
  visible. Les tests de widget vérifient aussi deux à quatre lignes, petit et
  grand écran, ainsi qu'un facteur de texte de 2x.

## Couverture des 17 demandes

| # | Comportement et preuve | Résultat |
|---:|---|---|
| 1 | Suppression idempotente, archivage et fermeture de conversation : `matching.tests_match_lifecycle` ; action disponible dans le menu de match Android. | Conforme |
| 2 | Masquage par participant, `DELETE /conversations/{id}`, restauration exclusivement à réception d'un message : `messaging.tests_phase2` et recette deux clients ci-dessus. | Conforme |
| 3 | Compositeur 1–4 lignes avec défilement interne, largeur indépendante du statut, alignement et facteur de texte : `message_input_test.dart` et mesure Android. | Conforme |
| 4 | Profil d'un match actif avec identifiant de compte canonique : `matching.tests_match_lifecycle` et ouverture réelle depuis le menu. | Conforme |
| 5 | Révélation Free mensuelle explicite et transactionnelle : `matching.tests_free_match_access` avec feature flag. | Conforme |
| 6 | Déblocage Free-Free atomique, limite indépendante de dix textes, REST et WebSocket : `matching.tests_free_match_access`. | Conforme |
| 7 | Catalogue unique genres et relations pour profil, inscription et découverte : tests profils/découverte de la suite backend. | Conforme |
| 8 | Pays, ville dépendante, permission de localisation, confidentialité et distance estimée : `profiles.tests.test_location_and_photos` ; affichage `ville, pays` constaté sur Android. | Conforme |
| 9 | Chargement initial, réessai, limites Free/Premium, ordre et suppression de photos : `profiles.tests.test_location_and_photos` et `profile_bloc_test.dart`. | Conforme |
| 10 | Recherche paginée insensible aux accents, sélection de page/tout et révocation atomique : `matching.tests_history_badges`. | Conforme |
| 11 | URL média absolue ou relative normalisée, validation du contenu et lecteur intégré : `messaging.tests` et transfert image Premium → Free rendu sur Android. | Conforme |
| 12 | Notification de message créée avant diffusion, UUID canonique et déduplication : `notifications.tests` ; le texte reçu a produit un seul événement non lu avant ouverture. | Conforme |
| 13 | États monotones `sent → delivered → read` : tests REST/WebSocket `messaging` et transition terminale `read` observée entre les deux clients. | Conforme |
| 14 | Révocation après match et rewind refusé avec erreur métier localisable, sans liste vide : `matching.tests_match_lifecycle`. | Conforme |
| 15 | Sélection multiple, masquage local et suppression globale Premium atomique sous 15 minutes : `messaging.tests_phase2`. | Conforme |
| 16 | Remise/réception après reconnexion, sans régression de lecture : tests temps réel `messaging` et recette de remise/lue. | Conforme |
| 17 | Badge de match inédit propre à chaque participant et réconciliation après lecture/suppression : `matching.tests_history_badges`, `GET /matches/unseen-count/`, `PUT /matches/seen/`. | Conforme |

## Contrats, migrations et compatibilité

- L'audit frontend/backend couvre : suppression de match, compteurs de matches
  vus, accès Free, masquage de conversation, suppression groupée de messages,
  médias, notifications, catalogues géographiques et localisation de profil.
- Les réponses REST et événements WebSocket conservent les formats de médias
  et notifications antérieurs pendant la transition ; les URL média sont
  normalisées au même endroit dans les deux flux.
- Les migrations sont additives. Les données de localisation historiques
  restent lisibles durant la migration, et les matches actifs existants restent
  accessibles.
- Les scénarios à données destructrices (suppression du match de recette,
  rewind après match et révocation en lot) ont été validés dans une base de
  test isolée par la suite Django afin de ne pas altérer les échanges de la
  recette Android.

## Décision de validation

Tous les contrôles automatisés sont verts. La recette Android a validé les
chemins partagés les plus sensibles : deux sessions, message, notification non
lue puis lecture, média, profil associé, compositeur et cycle de masquage /
restauration. Les combinaisons Free-Free, les limites, les permissions de
localisation, les historiques et les badges sont couvertes par les tests
backend déterministes exécutés dans la même validation.


## Addendum courant

La revalidation du 26 septembre 2026, incluant 342 tests Flutter et 341 tests Django, est consignée dans [PHASE6_VALIDATION_ADDENDUM_2026-09-26.md](PHASE6_VALIDATION_ADDENDUM_2026-09-26.md).

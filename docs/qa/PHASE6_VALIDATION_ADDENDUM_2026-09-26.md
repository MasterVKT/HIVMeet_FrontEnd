# Phase 6 — addendum de validation du 26 septembre 2026

Cet addendum complète la [matrice initiale de phase 6](PHASE6_VALIDATION_MATRIX_2026-09-22.md). Il ne remplace pas les preuves Android à deux clients qui y sont déjà référencées. Les commandes ci-dessous ont été relancées sur l'état courant des deux dépôts, sans réinitialiser leurs modifications préexistantes.

## Correctifs de régression découverts pendant la validation

| Fichier | Correctif | Exigence / risque traité | Preuve indépendante |
|---|---|---|---|
| `notifications/consumers.py` | Un `ping` reçu avant une authentification complète retourne un instantané privé inoffensif et ne crée aucune présence. | Le canal de notifications ne doit ni planter ni exposer une présence avant identification. | `notifications.tests.TestUserNotificationConsumerEvents.test_ping_receives_pong` passe. |
| `messaging/views.py` + `messaging/serializers.py` | La présence des deux participants est annotée dans la requête de liste ; le sérialiseur emploie ces annotations et garde le service comme repli sûr. | Éviter une requête de présence par conversation, tout en conservant confidentialité et même contrat REST/WebSocket. | Le test de coût constant de la liste passe pour une et deux conversations. |
| `messaging/tests_phase2.py` | Le test de remise immédiate emploie `PresenceService.heartbeat`, source de vérité actuelle, au lieu d'une ancienne clé de cache. | Vérifier `sent → delivered` pour un destinataire réellement connecté. | `test_online_recipient_is_delivered_without_waiting_for_reconnect` passe. |
| `tests/base.py` + `tests/test_integration.py` | Les fixtures et l'inscription d'intégration respectent le genre requis et la préférence de genre unique. | Les tests reproduisent le contrat de création de compte et ne fabriquent plus de données impossibles en production. | Parcours inscription → profil → photo passe. |

Ces cinq changements sont tous justifiés par des échecs déterministes de la première exécution complète Django. Aucun contrat mobile public n'a été modifié : les endpoints et formats existants restent les mêmes.

## Portes de validation relancées

| Contrôle | Commande | Résultat |
|---|---|---|
| Analyse Flutter | `flutter analyze --no-pub` | Réussi : `No issues found` (287,3 s). |
| Régression Flutter complète | `flutter test --no-pub` | Réussi : 342 tests, 1 scénario d'intégration externe explicitement ignoré. |
| Contrôle Django | `$env:DEBUG='True'; python manage.py check --settings=hivmeet_backend.test_settings` | Réussi, aucune anomalie. |
| Migrations | `python manage.py makemigrations --check --dry-run --settings=hivmeet_backend.settings` | Réussi : `No changes detected`. |
| Régression Django complète | `python manage.py test --settings=hivmeet_backend.test_settings --verbosity 1 --noinput` | Réussi : 341 tests en 116,448 s. |
| Régression ciblée après correction | 4 tests notifications / présence / liste / inscription | Réussi : 4 tests. |
| Audit de contrats Flutter ciblé | routes messagerie, mapping DTO, cycle de match et localisation | Réussi : 33 tests. |
| Intégrité des diffs | `git diff --check` dans chaque racine | Réussi ; seuls les avertissements CRLF connus apparaissent. |
| APK Android debug | `flutter build apk --debug --no-pub` | Réussi en 140,8 s. |

Empreinte de l'APK construit : `12F0CDF59FA49BDF539BF3753531131A900BBE3C56F88038191CFA751D29C5BD`.

Le contrôle `check --deploy` exécuté avec la configuration de **test** signale cinq paramètres de sécurité volontairement non activés (`HSTS`, redirection HTTPS, clé de test, cookies sécurisés). Il ne révèle aucune erreur de code. Ces réglages doivent être fournis par l'environnement de déploiement, et ne sont pas activables de façon sûre dans un fichier de test local.

## Audit des contrats communs

Les sources ont été contrôlées des deux côtés pour les routes ci-dessous, avec authentification JWT, corps de requête, formats de succès et erreurs 4xx.

| Surface | Contrat vérifié | Couverture |
|---|---|---|
| Actions de messages | `PATCH` et `DELETE /conversations/{id}/messages/{id}/`, `POST …/messages/delete/`, erreurs Premium / délai / propriétaire | Tests Flutter de data/repository et BLoC ; `messaging.tests` et `messaging.tests_phase2`. |
| Médias | multipart, métadonnées, URL normalisée, téléchargement authentifié, suppression globale | `messaging.tests`, `messaging.tests_media_download`, mapping Flutter `media_download_url`. |
| Masquage | `DELETE /conversations/{id}/`, `PUT /conversations/{id}/restore/`, réponse 204 idempotente | BLoC Chat, `messaging.tests`, `messaging.tests_phase2`. |
| Présence et reçus | `GET …/presence/`, WebSocket `presence_update`, transitions `sent → delivered → read` | `messaging.tests_phase3_presence`, tests WebSocket et régression de liste ci-dessus. |
| Matches / rewind / badges | suppression, `unseen-count`, `seen`, rewind explicite | tests Flutter de cycle de vie et `matching.tests_match_lifecycle`, `tests_phase3_rewind`, `tests_history_badges`. |
| Profil et localisation | pays, villes dépendantes, édition atomique, confidentialité | `profile_location_repository_test.dart` et `profiles.tests.test_location_and_photos`. |

Aucun écart de clé JSON, de méthode HTTP ou de permission n'a été trouvé dans ces surfaces. Les réponses non réussies sont mappées par les repositories vers des `Failure` localisables ; les écrans ne présentent pas de message Dio brut.

## Recette Android courante et limites visibles

- L'APK courant a été installé avec succès sur l'émulateur (`versionCode 1050`).
- L'installation sur l'appareil physique a été refusée par Android avec `INSTALL_FAILED_UPDATE_INCOMPATIBLE` : une application de même identifiant y est signée par une autre clé. La désinstaller supprimerait ses données ; cette action n'a pas été effectuée. L'application déjà installée s'est toutefois lancée normalement (`MainActivity` reprise, PID actif, aucune exception AndroidRuntime), ce qui vérifie uniquement l'environnement physique existant, pas le nouvel APK.
- Après l'installation, l'émulateur a perdu `system_server`, puis est resté ADB `offline` pendant sa relance. L'écran blanc observé a été corrélé à l'absence des services Android (`activity` et `window` indisponibles), sans pile Flutter ni exception `AndroidRuntime`. La capture transitoire n'est pas retenue comme preuve de produit.
- La recette à deux clients conservée dans la matrice initiale reste la preuve fonctionnelle Android disponible : message, média, lecture, profil de match, compositeur et masquage/restauration. La couverture déterministe actuelle a été relancée avec les binaires et sources actuels.

## Décision d'audit

Les validations statiques, les migrations, les contrats et les suites de régression sont conformes. La validation manuelle fraîche sur les deux appareils reste à rejouer dès que l'émulateur est de nouveau disponible et que l'appareil physique accepte une build signée compatible ; cette contrainte d'environnement est explicitement distincte des preuves automatisées et de la recette Android précédente.






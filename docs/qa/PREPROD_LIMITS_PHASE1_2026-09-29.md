# Vérification préproduction — phase 1 — 2026-09-29

## Périmètre et protection des données

Cette phase vérifie les préconditions, les contrats automatisés et deux scénarios backend isolés. Aucun message, média, interaction, paiement ou modification de forfait n'a été envoyé depuis les appareils de recette.

Les essais Django ont utilisé `hivmeet_backend.test_settings` et la base de test existante. Les objets créés par les `TestCase` sont annulés à la fin de chaque essai. Le scénario complémentaire d'échéance a été créé dans le répertoire temporaire du système et exécuté dans cette même base de test. Les comptes connectés et leurs données ne sont pas concernés.

## Préconditions observées

| Élément | Résultat |
| --- | --- |
| Émulateur Free | Joignable par ADB, application en cours d'exécution, version `1.0.0` (code 1050), cible Android 36. La permission de notification est en mode système par défaut `allow`. La sonde UI non intrusive ne permet pas de confirmer l'écran authentifié actuel ; l'état connecté est donc retenu d'après la précondition fournie, sans navigation ni lecture du stockage sécurisé. |
| Appareil Premium | Joignable par ADB, application en cours d'exécution, version `1.0.0` (code 1050), cible Android 36. La permission de notification est en mode système par défaut `allow`. La sonde UI confirme un écran authentifié. |
| Journaux allégés | Les trois journaux et le handover sont présents. Aucun motif `Bearer`, `access_token`, `refresh_token` ou affectation de mot de passe n'a été trouvé. `backend_run.md` contient trois mentions du libellé `fcm_token` ; aucune valeur n'est reproduite ici. Avant diffusion externe, ce journal doit recevoir une revue de caviardage humaine afin de confirmer que ce sont seulement des noms de champ. |

## Preuves automatisées

| Contrat | Commande ou scénario | Résultat |
| --- | --- | --- |
| FCM, alertes de lecture, photos et abonnements | `python manage.py test --keepdb notifications.tests messaging.tests_phase4_notifications messaging.tests_phase5_read_alerts profiles.tests.test_location_and_photos subscriptions.tests` avec `DJANGO_SETTINGS_MODULE=hivmeet_backend.test_settings` | 99 tests passés en 6,403 s. |
| Téléchargement média, notifications Flutter et abonnement Flutter | `flutter test` sur les 8 fichiers ciblés de médias, bulle de message, notifications et abonnement | 51 tests passés en 11 s. |
| Changement différé à échéance | Scénario Django isolé : programmer `proration=false`, faire expirer la période, appeler directement `check_subscription_expirations` | 1 test passé en 0,091 s en constatant le comportement erroné actuel : abonnement annulé, forfait initial conservé et Premium retiré. |
| Stockage local de photos | Les tests de photos couvrent l'écriture locale sous `MEDIA_ROOT`, le `503 photo_storage_unavailable`, le remplacement de la photo unique Free, la propriété et la suppression des deux objets d'une photo supprimable. | Couvert par les 99 tests backend passés. Aucun stockage objet réel n'a été contacté. |

## Bloqueurs et limites confirmés

| Référence | État | Preuve | Impact avant production | Correctif à prévoir |
| --- | --- | --- | --- | --- |
| `SCHEDULED_CHANGE_EXPIRATION` | Bloqueur backend confirmé | `SubscriptionService.modify_subscription(..., proration=False)` enregistre `plan_change:<plan>` dans `cancellation_reason` (`subscriptions/services.py:228-233`). À échéance, `check_subscription_expirations` annule toute souscription ayant `cancel_at_period_end` (`subscriptions/tasks.py:106+`). Le scénario isolé le reproduit. | Un changement différé peut retirer Premium au lieu d'activer le forfait cible. | Faire reconnaître `plan_change:` par la tâche d'échéance, appliquer le forfait cible de façon transactionnelle et ajouter le test de cycle à la suite backend permanente. |
| `MESSAGE_READ_TRANSIENT_FCM_RETRY` | Bloqueur backend confirmé | `new_message` examine `retryable` et appelle `self.retry` (`messaging/tasks.py:80-93`) ; son test dédié le confirme (`messaging/tests_phase4_notifications.py:73`). `send_read_notification` appelle le helper sans examiner son résultat (`messaging/tasks.py:146+`). Son test prouve que l'alerte persistante reste disponible si FCM échoue (`messaging/tests_phase5_read_alerts.py:138`). | Une panne FCM transitoire peut faire perdre l'alerte système de lecture, même si l'élément reste dans la liste interne. | Ajouter à la tâche `message_read` la même reprise bornée et testée que `new_message`, sans recréer la notification persistante. |
| `OBJECT_STORAGE_AUTHENTICATION` | Bloqueur de recette et risque de confidentialité confirmé dans le code | Le stockage de profils Firebase appelle `blob.make_public()` (`hivmeet_backend/storage/manager.py:67`), alors que le contrat attendu exige un accès authentifié. Le choix de stockage est local en développement et Firebase hors développement (`hivmeet_backend/settings.py:176-179`). | L'accès objet de production ne peut pas être déclaré conforme ni testé sans environnement isolé. | Remplacer l'ACL publique par un accès authentifié ou des URL signées, configurer un environnement de stockage dédié, puis y exécuter le healthcheck et les essais de remplacement/suppression. |
| `REDACTED_LOG_REVIEW` | Limite de preuve documentaire | Trois occurrences du libellé `fcm_token` subsistent dans le journal backend allégé ; la vérification automatique n'affiche pas leur contenu. | Le journal ne doit pas être partagé hors de l'équipe avant revue manuelle ciblée. | Vérifier puis caviarder toute valeur éventuelle, en conservant uniquement des identifiants hachés et les codes d'erreur. |

## Décisions pour la suite

- Les essais matériels de média sont réservés à la phase 2.
- Les essais matériels de notifications et de lecture sont réservés à la phase 3.
- Le parcours visuel de forfait sans confirmation est réservé à la phase 4.
- Aucun fournisseur objet réel n'a été contacté, conformément au périmètre retenu.
- Aucun résultat de cette phase ne constitue une validation de compatibilité avec l'APK historique.

# HIVMeet — validation intégrée de phase 6

Date : 29 septembre 2026.

## Décision de préparation

**Prêt sous conditions.** Les contrôles statiques, les suites Flutter et Django, les
migrations et les builds Android debug et Release sont concluants. Les contrats ajoutés
sont additifs. Une recette de notification FCM réellement émise entre les deux
appareils, un export média réel et la configuration du stockage objet de production
restent à confirmer avant une mise en production sans réserve.

Aucune donnée utilisateur n’a été modifiée pendant cette recette. Les captures
transitoires non caviardées, générées uniquement pour naviguer, ne constituent pas
des preuves produit et ne sont pas jointes.

## Portée contrôlée

| Domaine | Exigence des phases 1 à 5 | Preuve de correction et validation indépendante |
| --- | --- | --- |
| Profil | Traduire `common.all` et refléter immédiatement le profil sauvegardé. | Catalogue FR/EN et BLoC de profil couverts par les tests ciblés ; sur l’appareil Premium, l’édition affiche « Tous » dans les préférences de relation et jamais `common.all`. La sauvegarde de ville n’a pas été rejouée afin de ne pas modifier le compte de recette. |
| Photos | Free : une photo remplaçable ; Premium : jusqu’à six ; stockage et erreurs explicites. | Tests Django de photos et stockage réussis. L’émulateur Free affiche l’action « Remplacer » pour l’unique photo ; l’appareil Premium affiche « Ajouter » sous son plafond. Le vrai fournisseur objet de production n’a pas été sollicité. |
| Abonnement | Choix explicite de proratisation, changement différé visible et persistant. | Tests repository/BLoC/paiement Premium réussis. La page Profil Premium est accessible ; aucune modification de forfait n’a été soumise pendant la recette. Le rendu du choix après sélection d’un autre forfait reste à valider manuellement. |
| Médias de conversation | Fichier privé persistant, coche conservée, ouvrir et exporter. | Tests Flutter du téléchargement, repository de messages et bulle média réussis. Aucun média de conversation n’a été exporté vers le système pendant cette recette ; la vérification matérielle reste ouverte. |
| Rewind et historiques | Une seule interaction active par couple, révocation cohérente et Super Like distingué. | Tests Django transactionnels et Flutter des historiques réussis. La prévisualisation de réconciliation ne trouve aucune ligne à modifier dans la base de recette. Aucun pass/like réel n’a été créé pendant la phase 6 pour préserver les historiques des comptes connectés. |
| Notifications de message | Présence générale sans suppression abusive du push ; déduplication au premier plan. | Tests Django de présence/notifications et tests Flutter WebSocket/politique de premier plan réussis. Le canal n’est pas bloqué sur Android 11 ; un push FCM effectif entre les appareils reste à prouver. |
| Alertes de lecture Premium | Préférence par défaut pour Premium, notification `message_read` persistante par lot et sans contenu. | Tests Django des alertes/préférences et tests Flutter de mapping, lecture et libellés réussis. Le rapport de passation est corrigé : l’alerte est persistante dans Notifications, mais uniquement pour l’auteur Premium éligible. Un accusé de lecture réellement émis entre appareils reste à rejouer. |

## Contrôles automatisés

| Commande | Résultat |
| --- | --- |
| `flutter analyze` | Réussi, aucune anomalie. |
| `flutter test` | 363 tests réussis ; 1 test de contrat Discovery ignoré faute de variables d’accès au serveur externe. |
| Tests Flutter ciblés des profils, Premium, médias, historiques et notifications | 116 tests réussis. |
| `python manage.py test --keepdb` avec `hivmeet_backend.test_settings` | 371 tests réussis. |
| Tests Django ciblés profils, photos, abonnement, médias, rewind, présence et alertes | 81 tests réussis. |
| `python manage.py check` avec la configuration de développement contrôlée | Réussi, aucune anomalie. |
| `python manage.py makemigrations --check --dry-run` | Réussi, aucune migration manquante. |
| Prévisualisation `audit_message_read_preferences` | 0 préférence historique éligible. |
| Prévisualisation `reconcile_interaction_history --dry-run` | 0 ligne à modifier dans la base de recette. |
| `celery inspect ping --timeout=5` | Un worker répond. |
| `flutter build apk --debug` | Réussi ; APK installé sans effacer les données des deux appareils. |
| flutter build apk --release | Réussi après 356,2 s ; signature v2 vérifiée, SHA-256 36B90089111F380639CC998C4AB1AC749906E61A0B1511DC905B57A0B11F2083. |

Le test `test_e2e_profile.py` reste un script de diagnostic utilisant un service
externe et n’est pas inclus dans la suite Django par défaut. Son échec isolé de
codage console sous Windows n’est donc pas employé comme preuve de recette ni
comme régression produit.

## Recette sur appareils

| Compte / appareil | Conditions | Résultat observé |
| --- | --- | --- |
| Free / émulateur Android | Session reconnectée, APK debug 1.0.0 (code 1050). | Profil Free chargé ; compteur `1/1` et action « Remplacer » pour la photo unique. Aucun ajout de photo n’est proposé. |
| Premium / appareil Android 11 | Session reconnectée, APK debug 1.0.0 (code 1050). | Profil et Photos accessibles ; badge Premium et action « Ajouter » visibles ; édition des relations localisée avec « Tous » sans clé technique. La permission de notification n’est pas refusée par le système. |
| Messages interappareils | Deux comptes connectés. | Non exécuté : aucun nouveau message n’a été généré pendant cette phase. La notification système et l’alerte de lecture restent donc des validations matérielles à rejouer. |
| Médias interappareils | Deux comptes connectés. | Non exécuté : aucun export vers le système n’a été produit. |
| Découverte / rewind | Deux comptes connectés. | Non exécuté : les historiques n’ont pas été altérés. La cohérence est couverte par les tests transactionnels et UI. |

## Contrats, données et ordre de livraison

- Le remplacement de photo utilise `PUT /api/v1/user-profiles/me/photos/{photo_id}/` ; le DTO reste identique et l’erreur de stockage `503 photo_storage_unavailable` est identifiable.
- `scheduled_change` est un champ optionnel ajouté aux réponses d’abonnement ; il ne redéfinit pas `auto_renew`.
- `message_read` est un type ajouté aux flux REST, WebSocket et FCM ; son contenu ne comporte ni texte de message ni identifiant secret.
- Les interactions sont réconciliées par une procédure réversible avant toute contrainte d’unicité d’interaction active. Une application production exige une sauvegarde, une prévisualisation privée et l’autorisation de cette base.
- Les champs de réponse sont additifs. La compatibilité d’un client déjà déployé avec le nouveau type `message_read` doit être vérifiée avant déploiement progressif : cette phase n’a validé que le client courant.
- L’ordre requis est : déployer les contrats et migrations backend, prévisualiser puis appliquer la réparation de données si nécessaire, vérifier le stockage objet en production, puis distribuer le client Flutter consommant les champs ajoutés.

## Changements effectués pendant cette phase

- Le choix de proratisation utilise désormais `RadioGroup<bool>` dans l’écran Premium, ce qui conserve son comportement et retire quatre usages Flutter dépréciés détectés par l’analyseur.
- La configuration de test Django emploie `cache+memory://` comme backend de résultat Celery. `memory://` est un transport de broker et empêchait uniquement le test de l’export de données d’accéder à son backend de résultat en exécution eager.
- Le rapport de passation décrit désormais correctement l’alerte `message_read` comme persistante et Premium, plutôt que transitoire.

## Limites et actions avant production

1. Envoyer un message dans chaque sens avec l’autre appareil hors de la conversation, puis valider le push système en premier plan, arrière-plan et application fermée. Relever les codes FCM seulement en cas d’échec.
2. Ouvrir un média déjà téléchargé, l’exporter vers un emplacement choisi par le système, quitter puis rouvrir la conversation et vérifier la coche persistante.
3. Vérifier le fournisseur objet réel avec un compte de production de recette, sans URL ou secret dans les journaux, avant d’annoncer l’ajout de photos disponible en production.
4. Sur l’appareil Premium, sélectionner un autre forfait sans confirmer, puis confirmer un changement différé et vérifier son libellé à la réouverture. Ne pas utiliser un changement réel payant pour cette recette.
5. Vérifier le comportement d’une version cliente antérieure face au type `message_read` avant une diffusion progressive.
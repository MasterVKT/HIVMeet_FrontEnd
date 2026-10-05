# Vérification préproduction — Phase 4 : changement de forfait différé

**Date :** 29 septembre 2026  
**Statut :** terminée — bloqueur de production confirmé  
**Périmètre :** interface Premium de choix du moment du changement, contrat `POST /api/v1/subscriptions/current/modify/`, exposition de `scheduled_change` et comportement à l’échéance.

## Garde-fous respectés

- Le parcours a été ouvert sur l’appareil physique Premium, sans confirmer le changement, sans paiement et sans créer de planification sur le compte de recette.
- Tous les scénarios backend ont utilisé `hivmeet_backend.test_settings`, des données synthétiques et une transaction explicitement annulée. Aucun compte connecté, abonnement de recette ou donnée de production n’a été modifié.
- La chaîne backend prescrite a été exécutée avant les opérations Django : passerelle frontend, orchestrateur backend, orchestrateur partagé, routeur backend et skills de fiabilité Celery/Redis et de stratégie de test.

## Vérification matérielle de l’interface

| Point contrôlé sur l’appareil Premium | Résultat | Verdict |
| --- | --- | --- |
| Affichage étroit Android (720 × 1472) | Les cartes et textes du parcours restent lisibles, sans découpe observée. | Validé visuellement. |
| Choix du forfait différent | Le choix ouvre la question « Quand appliquer le changement ? ». | Validé. |
| Changement immédiat | Bouton radio réel, titre et explication du calcul au prorata ; le champ de téléphone est présent. | Validé pour le rendu et l’accessibilité. |
| Changement à la prochaine échéance | Bouton radio réel, libellé et explication indiquant que le forfait courant reste actif ; le champ de téléphone disparaît. | Validé pour le rendu et l’accessibilité. |
| Confirmation explicite | Le texte indique que le choix sera appliqué après confirmation ; le bouton « Changer de plan » est distinct. Il n’a pas été pressé. | Validé. |
| Retour sans confirmation | Retour à Profil sans demande réseau de modification ni changement d’abonnement. | Validé. |

Les deux choix sont donc compréhensibles et exploités avec des contrôles radio accessibles, plutôt qu’avec un interrupteur ambigu.

## Contrat et tests backend isolés

Le contrat conservé est `POST /api/v1/subscriptions/current/modify/` avec `new_plan_id` et `proration`. La branche `proration=false` programme le changement pour l’échéance et la réponse actuelle inclut `scheduled_change` avec `plan_id`, `plan_name` et `effective_at`.

| Vérification | Preuve | Résultat |
| --- | --- | --- |
| Programmation HTTP existante | `ModifySubscriptionAPITest.test_modify_with_proration_false_schedules_for_next_cycle` | Réussi. |
| Service de programmation | `ModifySubscriptionServiceTest.test_modify_without_proration_schedules_change` | Réussi. |
| Lecture de `scheduled_change` par le sérialiseur de la réponse | Création synthétique, programmation `proration=false`, lecture de `CurrentSubscriptionSerializer`, transaction annulée | `plan_id`, nom localisé et échéance correspondent au forfait cible. |
| Expiration d’un abonnement programmé | Abonnement synthétique arrivé à échéance, exécution isolée de `check_subscription_expirations`, transaction annulée | L’abonnement devient `canceled`, conserve le forfait courant et garde le marqueur de changement. |
| Renouvellement avec le même marqueur | Exécution isolée de `SubscriptionService.handle_subscription_renewal`, transaction annulée | Le forfait cible est appliqué, le statut redevient actif et le marqueur est effacé. |

Les deux tests ciblés ont été exécutés avec `--keepdb` et ont réussi : **2 tests, OK**. Les essais isolés ont confirmé leur annulation complète.

## Bloqueur confirmé à l’échéance

Le changement différé est encodé par `cancel_at_period_end=true` et le marqueur `cancellation_reason=plan_change:<plan_id>`.

La tâche `check_subscription_expirations` traite toutefois tout abonnement arrivé à échéance avec `cancel_at_period_end` comme une annulation : elle passe le statut à `canceled` et retire le statut Premium de l’utilisateur. Elle ne distingue pas le marqueur `plan_change:`. Le gestionnaire de renouvellement applique correctement le forfait cible, mais il ne protège pas contre l’exécution préalable de la tâche d’expiration.

Le comportement dépend donc de l’ordre d’arrivée entre la tâche d’expiration et le renouvellement. Il est impossible de déclarer le changement différé fiable à échéance dans cet état.

## Limite supplémentaire observée dans l’interface

Le compte Premium de recette affichait un abonnement courant générique tandis que les choix disponibles étaient les forfaits mensuel et annuel. Aucun de ces deux choix n’était présélectionné au chargement. Cela indique une divergence probable entre l’identifiant de forfait historique du compte et le catalogue actuel.

Ce point n’a pas été modifié ni confirmé par une action. Il faut auditer les identifiants de forfait actifs et le catalogue avant de considérer le parcours de changement comme entièrement fiable pour les abonnements existants.

## Correctifs requis avant livraison

1. Représenter le changement différé par une donnée dédiée, ou traiter explicitement `plan_change:` dans la tâche d’expiration, afin qu’il ne soit jamais assimilé à une annulation volontaire.
2. Rendre le traitement idempotent et protégé contre les ordres concurrents entre l’échéance, le renouvellement et les éventuelles relances Celery.
3. Ajouter des tests de régression pour les deux ordres d’exécution, les doublons d’événements et la réponse `GET`/`POST` contenant `scheduled_change`.
4. Auditer et réconcilier les forfaits historiques avec les identifiants du catalogue, puis vérifier la présélection et le libellé du forfait courant.

## Conclusion de phase

Le rendu et l’accessibilité des deux choix de proratisation sont validés sans modifier le compte Premium. Le contrat de programmation et la lecture de `scheduled_change` sont validés sur base de test isolée. La fiabilité à l’échéance est **bloquée** par une course confirmée : la tâche d’expiration annule le changement programmé si elle s’exécute avant le renouvellement. Aucun correctif n’a été appliqué dans cette phase de vérification.

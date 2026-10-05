# Vérification préproduction — Phase 3 : notifications et alertes de lecture

**Date :** 29 septembre 2026  
**Statut :** terminée avec limites de diagnostic consignées  
**Périmètre :** réception de nouveaux messages, déduplication de la conversation ouverte, préférences de notification et alertes de lecture Premium.

## Conditions de recette

| Élément | Free (émulateur) | Premium (appareil physique) |
| --- | --- | --- |
| Application | version 1.0.0 | version 1.0.0 |
| Système | Android API 34 | Android API 30 |
| Notifications système | permission `POST_NOTIFICATIONS` accordée | permission d’exécution non applicable à cette version Android |
| État initial | badge de notifications : 19 | badge de notifications : 34 ; alertes de lecture antérieures présentes |

Les badges et les listes ont été relevés avant les nouveaux envois. Aucun jeton FCM, identifiant de compte, contenu réel de conversation ni donnée personnelle n’est conservé dans ce rapport.

## Matrice de vérification

| Scénario | Résultat observé | Verdict |
| --- | --- | --- |
| Nouveau message vers Free, application ouverte sur un écran différent de la conversation | Entrée ajoutée dans Notifications et badge mis à jour. L’alerte système a été observée plus tard, une fois l’application mise en arrière-plan. | Partiel : persistance validée ; affichage système immédiat au premier plan non établi. |
| Nouveau message vers Free, application en arrière-plan | Alerte système HIVMeet visible dans le tiroir de notifications. | Validé. |
| Nouveau message vers Free, tâche retirée du sélecteur Android et processus absent | Aucune tâche HIVMeet avant l’envoi ; l’alerte système est apparue pendant la fenêtre d’observation. Aucune tâche n’a été recréée. | Validé. |
| Conversation exacte déjà ouverte chez Premium | Le message est arrivé dans la conversation et aucun doublon système immédiat n’a été observé. | Validé dans la fenêtre d’observation. |
| Préférence Free « Messages » désactivée, application en arrière-plan | Aucun avis système HIVMeet après une fenêtre d’observation de plus de 30 secondes. Le réglage était toujours désactivé à la réouverture, puis a été réactivé et sauvegardé. | Validé. |
| Premium envoie, puis Free lit | Une seule nouvelle entrée persistante « Lecture confirmée » est apparue chez Premium. L’alerte système Premium était visible et ne révélait pas le contenu du message. Les traces applicatives disponibles ont montré la diffusion de l’événement personnel. | Validé. |
| Free envoie, puis Premium lit | Pas de nouvelle alerte « Lecture confirmée » ni d’alerte système de lecture sur le compte Free. | Validé. |

## Cohérence fonctionnelle contrôlée

- Les notifications de nouveau message restent disponibles dans la liste de l’application, avec badge, indépendamment de l’alerte système.
- L’ouverture de la conversation exacte ne produit pas de doublon système immédiat.
- Les alertes de lecture sont persistantes dans la liste de notifications pour l’auteur Premium, sans contenu de message dans le push.
- Les coches de lecture restent visibles sans créer d’alerte Premium pour un auteur Free.
- La préférence de message est persistante et respectée. Elle a été rétablie à son état actif initial après l’essai.

## Messages de recette et nettoyage

Tous les envois utilisaient un préfixe de recette explicite.

| Catégorie | Traitement |
| --- | --- |
| Deux derniers messages de contrôle envoyés par Premium | Supprimés pour tous depuis l’interface. L’alerte système correspondante a aussi été retirée du tiroir Free. |
| Message de contrôle plus ancien lié à une tentative de fermeture non valide | Resté identifiable : la suppression globale n’est plus autorisée par le produit après quinze minutes. |
| Messages reçus par Premium depuis Free et anciens messages de contrôle | Restés identifiables : l’interface du destinataire ne propose pas la suppression globale ; les messages de l’expéditeur avaient dépassé la fenêtre de suppression. |

Aucun pass, like, Super Like, paiement, changement de forfait ou donnée de stockage objet n’a été déclenché.

## Limites et suivi avant production

1. Le cas application ouverte hors conversation établit la persistance, mais l’arrivée immédiate de l’alerte système au premier plan n’a pas été observée. Le mécanisme peut regrouper ou différer l’affichage jusqu’au passage en arrière-plan.
2. La déduplication testée couvre l’absence de doublon immédiat pendant l’ouverture de la conversation exacte. Elle ne couvre pas un éventuel push retardé après changement ultérieur d’état.
3. Les journaux fournis sont antérieurs aux essais du 29 septembre. La consultation de la base/backend locale est bloquée par la configuration de production locale (`DEBUG=False` et courtier Celery obligatoire). Aucun paramètre n’a été remplacé pour contourner ce garde-fou. Les codes FCM et identifiants de corrélation des essais ne sont donc pas disponibles.
4. En cas d’anomalie ultérieure, demander le journal backend original couvrant précisément les essais du 29 septembre, avec les seules colonnes horodatage, type d’événement, code FCM et identifiant de corrélation haché. Ne pas inclure de jeton, contenu, adresse ni identifiant personnel.
5. Cette phase ne qualifie pas une panne FCM transitoire. Le risque déjà identifié de reprise absente pour `message_read` reste à traiter par les vérifications backend isolées prévues.
6. Après retrait de la tâche puis nouveau lancement, le compte Free est revenu à l’écran de connexion. Le compte a été reconnecté et reste ouvert à la fin de la phase. Ce comportement de persistance de session est une anomalie distincte à diagnostiquer ; il n’invalide pas la réception du push, observée alors qu’aucune tâche n’avait été recréée.

## Conclusion de phase

La réception en arrière-plan et application fermée, la préférence utilisateur, la déduplication immédiate, la persistance des alertes de lecture Premium et l’exclusion des comptes Free ont été observées matériellement. La limite restante porte sur le délai d’alerte lorsque l’application est ouverte hors conversation et sur l’absence de journal FCM contemporain permettant d’en attribuer la cause.


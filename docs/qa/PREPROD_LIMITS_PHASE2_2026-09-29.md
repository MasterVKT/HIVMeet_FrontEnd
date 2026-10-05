# Vérification préproduction — phase 2 : médias de conversation

**Date :** 29 septembre 2026
**Statut :** achevée avec une limite de session documentée
**Portée :** téléchargement, ouverture, export et persistance des médias, sur l’émulateur Free et l’appareil Premium.

## Garde-fous appliqués

- Une image PNG synthétique non sensible a été utilisée.
- Un message de repérage `RECETTE_PHASE_2_MEDIA_TEST` a été envoyé afin que la recette reste identifiable.
- Aucun pass, Like, Super Like, paiement ou changement de forfait n’a été effectué.
- Aucun stockage objet ou environnement de production n’a été contacté.
- Aucun jeton, identifiant de compte, contenu personnel ou chemin privé d’utilisateur n’est repris dans ce document.

## Résultats matériels

| Vérification | Émulateur Free | Appareil Premium |
| --- | --- | --- |
| Média reçu et téléchargé | Réussi : confirmation d’enregistrement dans l’application. | Réussi : confirmation d’enregistrement dans l’application. |
| Ouverture par le système | Réussi dans le visualiseur système. | Réussi dans le visualiseur système. |
| Partage ou export explicite | Réussi : export système vers un PDF dans Téléchargements, faute de gestionnaire de fichiers installé. | Réussi : export système d’une copie PNG vers Téléchargements. |
| Sortie puis retour dans la conversation | Réussi : l’état terminé et les actions `Ouvrir` / `Partager ou exporter` sont restés disponibles. | Réussi : l’état terminé et les actions `Ouvrir` / `Partager ou exporter` sont restés disponibles. |
| Redémarrage de l’application | Réussi après reconnexion : les actions `Ouvrir` / `Partager ou exporter` sont de nouveau visibles. | Réussi après reconnexion : les actions `Ouvrir` / `Partager ou exporter` sont de nouveau visibles. |
| Fichier privé après redémarrage | 1 répertoire de compte, 1 fichier complet, aucun fichier partiel. | 1 répertoire de compte, 2 fichiers complets, aucun fichier partiel. |
| Enregistrement automatique dans la galerie | Non observé : le téléchargement reste privé ; l’export exige une action explicite. | Non observé pour le téléchargement. L’image source avait été injectée volontairement dans la galerie pour l’envoi, puis supprimée. |

Les copies externes créées pendant la recette (image source, export PNG et export PDF) ont été supprimées après contrôle. Les fichiers téléchargés dans l’espace privé de l’application ont été conservés car ils constituent l’état que cette phase vérifie.

## Persistance et isolation

Le service place le téléchargement dans l’espace privé de l’application selon la structure `message_media/<compte>/<conversation>/<message>/...`. Les contrôles sur les deux appareils ont confirmé un seul répertoire de compte par installation, des fichiers achevés et l’absence de fichier `.part`.

Cela confirme l’isolation structurelle par compte et le comportement réel sur les deux installations. Un changement de compte sur une même installation n’a pas été rejoué : le redémarrage forcé a demandé une reconnexion, ce qui aurait ajouté une manipulation de session hors du scénario média.

## Nettoyage du message de recette

La suppression globale est exposée par l’interface pour les messages propres de moins de quinze minutes. Au moment du nettoyage, cette action était désactivée pour les deux messages de recette ; seule la suppression pour l’émetteur était disponible. Elle a été annulée afin de ne pas laisser un média non identifié chez le destinataire.

Le message de repérage reste donc visible dans la conversation sur les deux comptes. Il ne contient aucune donnée sensible.

## Limite confirmée

Après arrêt forcé de l’application, les deux installations ont affiché l’écran de connexion. Les comptes ont été reconnectés pour achever la vérification. Ce comportement empêche de qualifier la reprise comme totalement transparente pour l’utilisateur ; il doit être traité comme une limite de session distincte, même si l’état du média persiste bien après reconnexion.

## Validation automatisée

La couverture ciblée `test/core/services/media_download_service_test.dart` avait réussi lors de la validation précédente de ce chantier. Une relance pendant cette phase a été interrompue par l’environnement Windows au chargement du runner avant tout résultat ; elle n’est donc pas comptée comme une exécution réussie ici. Aucune modification de code n’a été apportée par cette phase.

## Conclusion de phase

Le téléchargement privé, l’ouverture, l’export volontaire et la persistance de l’état sont validés matériellement sur Free et Premium. Le seul point restant pour cette phase est la continuité de session après arrêt forcé, documentée ci-dessus. La phase 3 n’a pas été commencée.


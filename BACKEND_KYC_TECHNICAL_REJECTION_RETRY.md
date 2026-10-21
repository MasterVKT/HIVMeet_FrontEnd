# KYC — reprise impossible après un refus technique

## Symptôme observable

Après `POST /api/v1/user-profiles/me/verification/upload-intents/` (`201`)
et `POST /api/v1/user-profiles/me/verification/upload-intents/{upload_id}/file/`
(`202`), le contrôle asynchrone peut placer la pièce dans l'état public
`rejected`. Une nouvelle tentative sur la même pièce appelle à nouveau
`POST /api/v1/user-profiles/me/verification/upload-intents/` et reçoit
`409 invalid_state`.

## Cause probable confirmée

Le serveur conserve une `KycDocument` techniquement rejetée en quarantaine
pendant `KYC_QUARANTINE_RETENTION_HOURS` (24 heures par défaut). Pendant cette
période, `issue_kyc_upload_intent()` interdit tout remplacement tant que la
suppression n'est pas vérifiée. Le statut public expose seulement `rejected`;
il ne communique ni l'instant de reprise ni l'état de purge. Le client Flutter
supprime sa copie locale et rend le bouton d'ajout à nouveau disponible : ces
deux comportements sont donc contradictoires.

## Impact utilisateur

Une personne ayant subi un refus technique ne peut pas poursuivre le KYC et
voit une erreur générique après avoir sélectionné une nouvelle pièce. Le
parcours reste bloqué jusqu'à l'exécution et la confirmation de la purge,
laquelle dépend en plus de Celery Beat.

## Demande backend actionnable

Conserver la politique de quarantaine approuvée, mais rendre l'état de reprise
observable et déterministe :

- `GET /api/v1/user-profiles/me/verification/` doit exposer, pour une pièce
  `rejected`, un état de reprise non sensible (par exemple
  `retry_available_at`, sans raison technique, chemin, URL ou contenu).
- `POST /api/v1/user-profiles/me/verification/upload-intents/` doit, tant que
  la purge n'est pas vérifiée, répondre avec un code métier stable distinct de
  `invalid_state` et une indication de temporisation non sensible. La requête
  reste inchangée : `attempt_id`, `document_type`, `mime_type`, `size_bytes`,
  `sha256`, `idempotency_key`.
- Après passage de la pièce à `purged`, le même endpoint doit accepter une
  nouvelle intention (`201`) pour ce `document_type`, sans réutiliser l'objet
  précédent.
- Vérifier que le worker et Celery Beat exécutent bien
  `purge_due_kyc_documents`; aucune relance client ne doit contourner ou
  supprimer une pièce avant la politique de rétention.

## Critères de validation

1. Une pièce techniquement rejetée reste dépourvue de détail sensible dans les
   réponses publiques.
2. Pendant la quarantaine, l'API fournit une information de reprise exploitable
   au client, sans `409` ambigu.
3. Après purge vérifiée, une nouvelle pièce du même type produit une intention
   `201`, peut être contrôlée puis soumise normalement.
4. Les tests couvrent le refus, la temporisation publique, la purge et la
   reprise; ils confirment qu'aucune donnée de pièce, URL, hash ou motif interne
   n'est exposé.

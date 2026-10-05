# Workflow local — frontend HIVMeet

1. Lire `project-map.json`, ces règles et le routeur `.agents/skills/task-router`.
2. Déterminer le scope : frontend seul, ou frontend + backend si contrat, DTO,
   erreur API, authentification, notification ou donnée partagée est concerné.
3. Charger une à deux skills spécialisées, appliquer le changement minimal et
   vérifier les chemins utilisateurs affectés.
4. Avant la réponse finale, appliquer l'audit de complétude : exigences vers
   preuves, changements vers exigences, impact et validation indépendante.

Pour une intervention multiscopes, consulter d'abord `../../.agents/project-map.json`
et désigner une seule correction coordonnée dans le scope qui possède le contrat.

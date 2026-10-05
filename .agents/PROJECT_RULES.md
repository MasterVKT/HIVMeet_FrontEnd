# Règles locales — frontend HIVMeet

Ce composant est l'application Flutter. Les règles produit détaillées demeurent
dans `AI_AGENT_SHARED_RULES.md`; les règles transversales sont dans
`../../.agents/PROJECT_RULES.md`.

- Conserver la Clean Architecture, BLoC/Cubit et les frontières data/domain/UI.
- Toute chaîne affichée doit être localisée FR/EN; ne jamais exposer de donnée de
  santé, d'identité ou de jeton dans les logs, messages d'erreur ou snapshots.
- Vérifier les contrats dans `docs/API_DOCUMENTATION.md` avant une intégration API;
  signaler un écart backend au lieu de le masquer côté client.
- Ne pas introduire de secret, clé, URL de production ou configuration figée dans
  le code. Respecter les constantes et la configuration existantes.
- Utiliser le graphe de revue avant une exploration textuelle quand il est
  disponible; préserver les modifications non liées déjà présentes dans le dépôt.

# HIVMeet — Frontend agent entry point

Lire dans cet ordre :

1. `.agents/project-map.json`
2. `.agents/PROJECT_RULES.md` et `AI_AGENT_SHARED_RULES.md`
3. `.agents/WORKFLOW.md`
4. `.agents/skills/task-router/SKILL.md` si la tâche n'est pas déjà clairement
   couverte par une skill.

Le frontend est une application Flutter. Consulter les règles approfondies sous
`.claude/rules/` uniquement lorsqu'elles sont nécessaires. Le graphe de revue est
la première source pour explorer l'impact; recourir à la recherche textuelle si
le graphe ne couvre pas la question.

Toute intervention qui touche un contrat API, une DTO, l'authentification, une
notification ou une donnée partagée est une intervention frontend + backend :
vérifier le pair indiqué par la carte avant de corriger. Ne jamais remplacer ou
réinitialiser les modifications non liées présentes dans le dépôt.

Avant la réponse finale, appliquer l'audit de complétude et donner : fichiers
modifiés, conformité, validation de non-régression et impact backend éventuel.

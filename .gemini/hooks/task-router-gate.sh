#!/usr/bin/env bash
# Gemini: task-router gate - MUST execute BEFORE every request
# Must output ONLY JSON on stdout. Logs go to stderr. Never blocks the session.
set -euo pipefail

cat > /dev/null || true

# Load and apply task-router decision tree
# This is a lightweight instruction - the actual skill loading is done by the agent
MSG="[ORCHESTRATOR GATE] Avant tout traitement : lire .agents/skills/task-router/SKILL.md, appliquer son arbre de decision, identifier les skills pertinentes, puis traiter la requete."

CRG_MSG="$MSG" python3 -c '
import json,os
m=os.environ.get("CRG_MSG","")
print(json.dumps({"systemMessage":m,"suppressOutput":True}))
' 2>/dev/null || echo '{"suppressOutput": true}'
exit 0

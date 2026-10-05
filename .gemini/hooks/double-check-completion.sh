#!/usr/bin/env bash
# Gemini: double-check completion gate - MUST execute AFTER every request completion
# Must output ONLY JSON on stdout. Logs go to stderr. Never blocks the session.
set -euo pipefail

cat > /dev/null || true

MSG="[DOUBLE CHECK GATE] OBLIGATOIRE avant envoi : 1- Relire la requete originale mot pour mot. 2- Verifier chaque exigence contre ce qui a ete fait. 3- Corriger tout ecart silencieusement. 4- Envoyer seulement apres verification complete."

CRG_MSG="$MSG" python3 -c '
import json,os
m=os.environ.get("CRG_MSG","")
print(json.dumps({"systemMessage":m,"suppressOutput":True}))
' 2>/dev/null || echo '{"suppressOutput": true}'
exit 0

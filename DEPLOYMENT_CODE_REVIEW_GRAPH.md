# Déploiement `code-review-graph` - HIVMeet

**Date** : 2026-07-18  
**Version CRG** : 2.3.3  
**Projet** : `D:\Projets\HIVMeet\hivmeet`

## Résumé

Mise en conformité avec le guide [CODE_REVIEW_GRAPH_MULTI_AGENT_SETUP.md](CODE_REVIEW_GRAPH_MULTI_AGENT_SETUP.md) : isolation du graphe de code par dépôt, suppression des appels ambigus via `python -m code_review_graph`, et application du contrat d'isolation sur tous les clients MCP présents dans le workspace.

## Prérequis validés

| Champ | Valeur |
|---|---|
| `project_root` | `D:\Projets\HIVMeet\hivmeet` |
| `operating_system` | windows |
| `vscode_distribution` | code |
| `python_version` | 3.12.3 |
| `python_executable` | `D:\Projets\HIVMeet\hivmeet\.venv\Scripts\python.exe` |
| `virtual_environment` | `D:\Projets\HIVMeet\hivmeet\.venv` |
| `crg_version_requested` | 2.3.3 |
| `crg_executable` | `D:\Projets\HIVMeet\hivmeet\.venv\Scripts\code-review-graph.exe` |
| `crg_data_dir` | `D:\Projets\HIVMeet\hivmeet\.code-review-graph` |

## Contrat d'isolation appliqué

```text
server name  = code-review-graph
transport    = stdio
command      = D:\Projets\HIVMeet\hivmeet\.venv\Scripts\code-review-graph.exe
args         = ["serve", "--repo", "D:\\Projets\\HIVMeet\\hivmeet"]
cwd          = D:\Projets\HIVMeet\hivmeet
PYTHONUTF8   = 1
CRG_REPO_ROOT= D:\Projets\HIVMeet\hivmeet
CRG_DATA_DIR = D:\Projets\HIVMeet\hivmeet\.code-review-graph
```

## Fichiers modifiés / créés

### Modifiés (déjà suivis par Git)

- [`.gitignore`](.gitignore) : ajout de `.code-review-graph/` (ligne déjà présente mais normalisée proprement).
- [`.vscode/cline_mcp_settings.json`](.vscode/cline_mcp_settings.json) : ajout du serveur `code-review-graph` avec le contrat d'isolation ; les serveurs globaux existants sont préservés.
- [`.vscode/settings.json`](.vscode/settings.json) : suppression d'une ligne vide avec espaces (trailing whitespace) détectée par `git diff --check`.
- [`.github/copilot.json`](.github/copilot.json) : remplacement des appels `code-review-graph` par le chemin absolu de l'exécutable et ajout de `--data-dir`.
- [`.gemini/hooks/crg-session-start.sh`](.gemini/hooks/crg-session-start.sh) : chemin absolu + `--data-dir`.
- [`.gemini/hooks/crg-update.sh`](.gemini/hooks/crg-update.sh) : chemin absolu + `--data-dir`.
- [`.claude/settings.json`](.claude/settings.json) : chemin absolu + `--data-dir`.
- [`.qoder/settings.json`](.qoder/settings.json) : chemin absolu + `--data-dir`.
- [`.opencode.json`](.opencode.json) : mise en conformité MCP (serveur unique, exécutable, args, env).

### Créés (non suivis par Git)

- [`.vscode/mcp.json`](.vscode/mcp.json)
- [`.cursor/mcp.json`](.cursor/mcp.json)
- [`.mcp.json`](.mcp.json)
- [`.codex/config.toml`](.codex/config.toml)
- [`.gemini/settings.json`](.gemini/settings.json)
- [`.kilo/kilo.json`](.kilo/kilo.json)
- [`.kiro/settings/mcp.json`](.kiro/settings/mcp.json)
- [`.qoder/mcp.json`](.qoder/mcp.json)

## Validation technique

### Version & statut

```text
code-review-graph 2.3.3
Nodes: 2673
Edges: 17931
Files: 310
Languages: kotlin, python, bash, swift, c, dart, powershell
```

### Handshake MCP

```text
server=code-review-graph tools=30 exit=0
```

### Isolation SQLite

```text
nodes=2673 files=310 outside=0
```

### Audit des configurations

Toutes les configurations projet pour `code-review-graph` respectent le contrat d'isolation (commande absolue, `--repo`, `cwd`, `PYTHONUTF8`, `CRG_REPO_ROOT`, `CRG_DATA_DIR`).

## Routeur Cline global (fail-closed)

La configuration globale Cline utilisait auparavant un serveur `code-review-graph` sans `--repo` (risque de pointer vers le mauvais graphe) et un second serveur `hivmeet-code-review-graph` utilisant `python -m code_review_graph`. La configuration a été normalisée en un seul serveur `code-review-graph` géré par un routeur fail-closed.

### Fichiers créés / modifiés pour Cline

- [`D:\\Projets\\HIVMeet\\hivmeet\\.cline\\code-review-graph-project-router.py`](.cline/code-review-graph-project-router.py) : routeur Python.
- `c:\\Users\\vekou\\AppData\\Roaming\\Code\\User\\globalStorage\\saoudrizwan.cline-nightly\\settings\\cline_mcp_settings.json` : configuration globale Cline mise à jour.
- Sauvegarde créée : `cline_mcp_settings.json.20260718T005649Z.bak`.

### Comportement du routeur

- **Depuis le dossier du projet HIVMeet** : le routeur démarre `code-review-graph.exe serve --repo D:\Projets\HIVMeet\hivmeet`.
- **Depuis un dossier non autorisé** : le routeur affiche `Routeur refuse : aucun workspace autorise unique n'a ete identifie.` et retourne le code d'erreur `2` sans démarrer de serveur.

## Points d'attention / restants

1. **Fichier `.gemini/settings.json.bak`** contient des références obsolètes ; il s'agit d'une sauvegarde, il peut être supprimé si non nécessaire.
2. **Secrets exposés** : `.kilo/kilo.json` et `.vscode/cline_mcp_settings.json` contiennent une clé API Tavily en clair. Ce n'est pas introduit par ce travail, mais il est signalé pour revue de sécurité future.

## Commandes de vérification

```powershell
# Version
D:\Projets\HIVMeet\hivmeet\.venv\Scripts\code-review-graph.exe --version

# Statut du graphe local
D:\Projets\HIVMeet\hivmeet\.venv\Scripts\code-review-graph.exe status `
  --repo D:\Projets\HIVMeet\hivmeet `
  --data-dir D:\Projets\HIVMeet\hivmeet\.code-review-graph

# Vérifier que le répertoire de données est ignoré par Git
git check-ignore -v .code-review-graph/graph.db
git status --short -- .code-review-graph

# Valider les syntaxes JSON
python -m json.tool .vscode\mcp.json
python -m json.tool .cursor\mcp.json
python -m json.tool .mcp.json
python -m json.tool .gemini\settings.json
python -m json.tool .kiro\settings\mcp.json
python -m json.tool .qoder\mcp.json
python -m json.tool .vscode\cline_mcp_settings.json
python -m json.tool .kilo\kilo.json
python -m json.tool .opencode.json
python -m json.tool .claude\settings.json
python -m json.tool .qoder\settings.json
python -m json.tool .github\copilot.json

# Valider le TOML Codex
python -c "import pathlib, tomllib; tomllib.loads(pathlib.Path('.codex/config.toml').read_text(encoding='utf-8'))"
```

## Impact sur l'application

Aucun impact sur le code fonctionnel de l'application HIVMeet. Seules les configurations d'outils d'analyse de code (MCP / hooks agents) ont été modifiées. Le graphe est local, ignoré par Git, et isolé au dépôt courant.

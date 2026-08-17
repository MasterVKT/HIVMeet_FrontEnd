# HIVMeet - Agent Entry Point

Version: 1.0  
Date: 2026-04-12

## Purpose

Single lightweight entry point for AI agents working in this repository.

## Quick Load Flow

Shared rules -> current agent wrapper (optional) -> one relevant skill -> deep rules only if required.

Read in this order:

1. [AI_AGENT_SHARED_RULES.md](AI_AGENT_SHARED_RULES.md)
2. Only the current agent wrapper if it adds native syntax or tool-specific behavior:
- Copilot: [.github/copilot-instructions.md](.github/copilot-instructions.md)
- Claude: [CLAUDE.md](CLAUDE.md)
- Cline: [.clinerules/cline-rules.md](.clinerules/cline-rules.md)
3. Deep rules only when the task needs them:
- [.claude/rules/architecture.md](.claude/rules/architecture.md)
- [.claude/rules/backend-integration.md](.claude/rules/backend-integration.md)
- [.claude/rules/specifications.md](.claude/rules/specifications.md)
- [.claude/rules/testing.md](.claude/rules/testing.md)
4. Skills — use task-router if the task type is unclear; otherwise load the matching skill directly:
- [.agents/skills/task-router/SKILL.md](.agents/skills/task-router/SKILL.md) ← orchestrateur, charger en premier si incertain
- [.agents/skills/frontend-development/SKILL.md](.agents/skills/frontend-development/SKILL.md)
- [.agents/skills/bug-fixing/SKILL.md](.agents/skills/bug-fixing/SKILL.md)
- [.agents/skills/api-contract-audit/SKILL.md](.agents/skills/api-contract-audit/SKILL.md)
- [.agents/skills/i18n-integrity/SKILL.md](.agents/skills/i18n-integrity/SKILL.md)
- [.agents/skills/regression-guard/SKILL.md](.agents/skills/regression-guard/SKILL.md)
- [.agents/skills/release-readiness/SKILL.md](.agents/skills/release-readiness/SKILL.md)
- [.agents/skills/test-impact-selection/SKILL.md](.agents/skills/test-impact-selection/SKILL.md)

## Loading Policy

- Do not load long detailed rule files by default.
- Prefer the shared rules file plus one relevant skill.
- Do not read multiple equivalent agent wrappers for the same task.
- Keep agent wrappers delta-only: no restating shared rules already covered elsewhere.
- Open deep rule files only when architecture, backend contract, specifications, or testing details are required.
- Prefer one relevant skill first; load a second skill only if the task genuinely spans both domains.
- Prefer scoped instructions over global instructions with broad apply patterns.

## Expected Output

- files changed
- spec compliance check
- non-regression validation
- backend impact when applicable
- concise summary

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.

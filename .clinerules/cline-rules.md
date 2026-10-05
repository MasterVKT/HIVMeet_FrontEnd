# Cline Rules (Factorise)

These rules are intentionally short to reduce token usage.

Read first:
- [AGENTS.md](AGENTS.md)
- `.agents/project-map.json`, `.agents/PROJECT_RULES.md` et `.agents/WORKFLOW.md`

Cline-specific:
- load only the skill relevant to the task; use task-router if uncertain
- do not reread equivalent wrappers already covered by AGENTS
- BEFORE every request: read .agents/skills/task-router/SKILL.md and apply decision tree
- AFTER every request completion: double-check that every requirement has been met before sending
- use `.claude/skills` adapters when Cline discovers Claude-compatible project skills

Skills (canonical location: `.agents/skills/<name>/SKILL.md`):
- [.agents/skills/task-router/SKILL.md](.agents/skills/task-router/SKILL.md) ← orchestrateur, charger en premier si incertain
- [.agents/skills/frontend-development/SKILL.md](.agents/skills/frontend-development/SKILL.md)
- [.agents/skills/bug-fixing/SKILL.md](.agents/skills/bug-fixing/SKILL.md)
- [.agents/skills/api-contract-audit/SKILL.md](.agents/skills/api-contract-audit/SKILL.md)
- [.agents/skills/i18n-integrity/SKILL.md](.agents/skills/i18n-integrity/SKILL.md)
- [.agents/skills/regression-guard/SKILL.md](.agents/skills/regression-guard/SKILL.md)
- [.agents/skills/release-readiness/SKILL.md](.agents/skills/release-readiness/SKILL.md)
- [.agents/skills/test-impact-selection/SKILL.md](.agents/skills/test-impact-selection/SKILL.md)

Note: `.clinerules/skill_frontend_development.md` and `.clinerules/skill_bug_fixing.md` are legacy extended sources.
Prefer `.agents/skills/` as the canonical single location for all agents.

Shared details and output structure are centralized in AGENTS.

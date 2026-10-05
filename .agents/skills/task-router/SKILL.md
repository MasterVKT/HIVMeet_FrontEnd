---
name: task-router
description: 'Meta-skill orchestrator for HIVMeet. Load this FIRST when uncertain which skill applies, or at session start. Routes development work and governance lifecycle maintenance to the correct project skill.'
argument-hint: 'Describe your task or request in one sentence.'
user-invocable: true
---

# Task Router — HIVMeet Skill Orchestrator

## Purpose
Single entry point to route any HIVMeet development request to the correct project skill without guessing.

Use this when:
- The task type is ambiguous or spans multiple domains
- Starting a new session without a clear category
- Multiple skills could plausibly apply

After selecting the right skill(s), immediately load the corresponding SKILL.md via read_file and follow its workflow from start to finish.

---

## Skill Registry

All skills are at .agents/skills/<name>/SKILL.md.

| Task type / trigger keywords | Skill to load | Priority |
|------------------------------|---------------|----------|
| Build page, widget, screen, navigation, BLoC, Cubit, state, feature, animation, module | frontend-development | High |
| Bug, error, crash, exception, blank screen, regression, unexpected behavior, anomaly, performance | bug-fixing | High |
| Debug issue, systematic debug, graph-powered trace, root cause analysis, call chain | debug-issue | High |
| API, endpoint, DTO, contract, payload, JSON mapping, 4xx/5xx, mismatch, integration, data source | api-contract-audit | High |
| Explore codebase, navigate, understand structure, architecture overview, semantic search | explore-codebase | Medium |
| Translation, i18n, hardcoded string, ARB, FR/EN, localization, missing key | i18n-integrity | Medium |
| Refactor, rename, dead code, dependency analysis, safe refactoring | refactor-safely | Medium |
| Before merge, validate changes, non-regression, risk assessment, impact analysis | regression-guard | Medium |
| Review changes, code review, change detection, merge recommendation | review-changes | Medium |
| Release, deploy, checklist, readiness, quality gate, production, build | release-readiness | Medium |
| Which tests to run, test scope, test selection, changed files, test impact | test-impact-selection | Medium |
| Agent governance, skills, adapters, hooks, lifecycle, activation, cross-root map | hivmeet-governance | High |

---

## Multi-Skill Scenarios

Load at most 2 skills. Secondary only when the task genuinely crosses two domains.

| Scenario | Primary skill | Secondary skill |
|----------|---------------|-----------------|
| New feature with user-facing text | frontend-development | i18n-integrity |
| Bug caused by API mismatch | bug-fixing | api-contract-audit |
| Feature ready for merge | frontend-development | regression-guard |
| New endpoint integration | api-contract-audit | frontend-development |
| Release branch preparation | release-readiness | regression-guard |
| Post-fix test selection | bug-fixing | test-impact-selection |
| Debug with graph tools | debug-issue | explore-codebase |
| Code review before merge | review-changes | regression-guard |
| Safe refactoring | refactor-safely | regression-guard |
| Agent governance installation or audit | hivmeet-governance | hivmeet-frontend-completion-audit |

---

## Decision Process

1. **Read the request** — identify the dominant action verb (build / fix / debug / audit / explore / translate / refactor / validate / review / release / test).
2. **Match the table above** — pick one primary skill; add a secondary only if the scenario clearly matches the multi-skill table.
3. **Load skill(s)** — call read_file on .agents/skills/<name>/SKILL.md immediately.
4. **Execute** — follow the loaded skill workflow from step 1 to completion.

---

## Hard Rules

- Never load more than 2 skills simultaneously.
- If a bug is confirmed as backend-only: stop, create BACKEND_[TYPE]_[DESCRIPTION].md at repo root — no skill needed.
- When uncertain between bug-fixing and api-contract-audit, default to bug-fixing as primary.
- Do not restate routing logic once the target skill is loaded — delegate fully to it.

---

## Quick Skill Summaries

| Skill | 10-word summary |
|-------|-----------------|
| frontend-development | Flutter/Dart features: Clean Architecture, BLoC, i18n, spec compliance |
| bug-fixing | Reproduce -> diagnose -> fix with root-cause and non-regression checks |
| debug-issue | Graph-powered systematic debug: trace, analyze, resolve |
| api-contract-audit | Validate endpoint contracts, DTO mapping, error paths before merge |
| explore-codebase | Navigate architecture, find modules, trace dependencies |
| i18n-integrity | Detect hardcoded strings, ensure FR/EN ARB parity, fix translation gaps |
| refactor-safely | Dependency-aware rename, dead-code analysis, safe restructure |
| regression-guard | Risk-scored validation of critical user journeys before merge |
| review-changes | Structured code review with change detection and impact analysis |
| release-readiness | Pre-release quality gate: build, analyze, test, privacy, contract safety |
| test-impact-selection | Select minimal high-value tests for the current set of file changes |
| hivmeet-governance | Maintain maps, adapters, hooks and deterministic lifecycle checks |
| hivmeet-frontend-orchestrator | Route frontend work and identify cross-root ownership |
| hivmeet-frontend-completion-audit | Audit frontend requirements, privacy, contracts and evidence |


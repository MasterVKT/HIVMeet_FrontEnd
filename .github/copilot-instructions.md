# GitHub Copilot - HIVMeet Instructions (Factorise)

Version: 3.1
Date: 2026-07-24

## Startup

Read [AGENTS.md](AGENTS.md) first.

## 🔁 Workflow Hooks (mirrored from Claude Code, mandatory)

Apply the same guardrails as the Claude Code hooks attached to this request:

1. **UserPromptSubmit equivalent — every request, no exception**
   - Before answering or editing anything, read `.agents/skills/task-router/SKILL.md` and apply its decision table, even if the task looks obvious.
   - Load the skill(s) it selects (max 2) via their `SKILL.md` file before doing the actual work.

2. **Maximum deliberation**
   - Reason through the request fully — edge cases, spec conformance, non-regression — before writing the final answer. Do not shortcut multi-step tasks regardless of which model is active or its native thinking-effort setting.

3. **Stop equivalent**
   - Before sending the final response, reread the original request word for word and verify every explicit requirement was addressed; fix gaps before replying.

4. **PostToolUse equivalent**
   - After any edit, verify with the smallest relevant check available: targeted test, `flutter analyze`, or file inspection.
   - Refresh the code-review-graph MCP index after changes if available.
   - Never claim success without fresh verification evidence.

5. **Visible workflow trace (MANDATORY — first block of every response)**
   - Every response starts with this block, before any other content:
     ```
     **Workflow: router consulted → skill(s) loaded → plan formed → implementation/checks performed.**
     Skills used: `frontend-development`, `i18n-integrity`

     - Router consulted
     - Skill(s) applied
     - Implementation performed
     - Verification performed
     ```
   - Adapt "Skills used" to whichever skill(s) the router actually selected.
   - This trace is the only visible evidence that routing ran, since the Chat UI does not expose internal skill-execution logs like Claude Code does.

## Copilot-Specific Notes

- Load deep rule files only when the task needs architecture, backend contract, specifications, or testing detail.
- Do not duplicate shared rules here; AGENTS and shared rules are the canonical source.

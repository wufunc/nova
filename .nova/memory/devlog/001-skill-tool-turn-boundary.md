---
tags: [skill, nesting, turn-boundary, claude-code, skill-tool, atomic]
modules: [skills/git-commit, skills/memory]
summary: "Skill tool creates turn boundaries that break atomic multi-step workflows"
tag: mem/001
---

# DevLog 001: Skill Tool Creates Turn Boundaries

## Date
2026-02-28 22:45

## Context

The git-commit skill executes an 8-step atomic workflow. Step 4 invoked
the memory skill using `Skill(skill="memory", args="update")`. After the
memory skill completed and returned its report, the workflow stopped —
the user had to type "continue" to resume Steps 5-8 (stage, commit, tag,
verify).

## Insight

The Skill tool in Claude Code injects a sub-skill's SKILL.md as a new
prompt, which creates a **conversation turn boundary**. The model treats
the sub-skill's output as the complete response for that turn and stops.

This is not a bug in the prompt or the skill logic — it's a structural
property of how the Skill tool works. No amount of "CRITICAL: do not
stop" instructions in the prompt can override the turn boundary behavior,
because the boundary is created by the tool dispatch mechanism, not by the
model's decision to stop.

The workaround is to avoid the Skill tool for nested/inline invocations.
Instead, use the Read tool to load the skill's SKILL.md file and execute
its instructions within the current turn. This preserves the skill's
logic while avoiding the turn boundary.

## Implications

- When building multi-step workflows that call other skills, **never use
  the Skill tool for nested calls** — use Read + inline execution instead
- The Skill tool is fine for top-level user-invoked skills (e.g., user
  types `/git-commit`), but not for skill-to-skill composition
- This pattern applies to any future skill that needs to orchestrate
  sub-skills as part of an atomic operation
- Prompt-level workarounds ("do not stop", "continue immediately") are
  ineffective against tool-level turn boundaries

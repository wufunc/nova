---
tags: [skill, nesting, turn-boundary, atomic-workflow, claude-code]
modules: [skills/git-commit, skills/memory]
summary: "Use Read+inline instead of Skill tool for nested skill invocation to avoid turn boundaries"
tag: mem/001
---

# ADR 001: Read-Inline for Nested Skill Invocation

## Date
2026-02-28 22:45

## Background

The git-commit skill orchestrates an atomic workflow (Steps 1-8) that includes invoking the memory skill at Step 4. The memory skill may in turn invoke adr-creator or devlog-creator sub-skills.

When using the Skill tool for these nested invocations, each call injects a new prompt into the conversation and creates a turn boundary. The model treats the sub-skill's output as the end of the current turn and stops, requiring the user to say "continue" before Steps 5-8 execute. This breaks the atomic execution guarantee.

Three approaches were considered:

- **A: Read + inline execution** — Load skill files with Read tool, execute their logic within the same turn
- **B: Flatten into git-commit** — Embed memory update decision logic directly in git-commit, eliminating nested calls
- **C: Two-phase user-triggered** — User runs `/memory update` separately before `/git-commit`

## Decision

Chosen approach: **A — Read + inline execution.**

Git-commit Step 4 uses the Read tool to load `~/.claude/skills/memory/SKILL.md`, then executes the update logic inline. If ADR or DevLog creation is needed, the same pattern applies: Read the creator's SKILL.md, execute inline.

This preserves the four-layer architecture (CLAUDE.md → git-commit → memory → writers) as a logical separation while avoiding the Skill tool's turn boundary mechanism.

## Consequences

### Advantages
- Atomic execution preserved — entire git-commit workflow runs in one turn
- Four-layer architecture maintained as logical separation
- Lazy loading preserved — creator skills only loaded when needed
- No user-facing workflow changes

### Disadvantages
- Read + inline is a convention, not enforced — future skill authors must know to avoid the Skill tool for nested calls
- Skill tool's built-in features (description matching, argument passing) are bypassed
- Slightly more verbose instructions in git-commit's Step 4

## Related Decisions
- None

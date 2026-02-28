---
tags: [multi-agent, installer, skill-resolution, codex, cursor, claude]
modules: [install.sh, uninstall.sh, skills/git-commit, templates]
summary: "Use agent-agnostic install targets and relative skill resolution"
tag: mem/002
---

# ADR 002: Agent-Agnostic Install and Skill Resolution

## Date
2026-02-28 23:43

## Background

The project originally targeted Claude-specific paths and instruction files.
That blocked first-class use in Codex and Cursor environments, and forced
agent-coupled maintenance across scripts and docs.

Three approaches were considered:

- **A: Keep Claude-only defaults with ad-hoc manual guides**
- **B: Introduce multi-agent install/uninstall adapters and agent templates**
- **C: Fully split repositories per agent implementation**

## Decision

Chosen approach: **B — multi-agent adapters in one repository.**

Key points:
- `install.sh` and `uninstall.sh` support `--agents` and auto-detection for
  `claude`, `codex`, and `cursor`
- Agent-specific instruction templates are provided under `templates/`
- `git-commit` resolves sibling skill paths relatively from its own location,
  avoiding absolute agent-home path coupling
- Documentation is synchronized bilingually to reflect the supported agents

This keeps one source of truth and preserves the four-layer architecture while
removing hard dependency on a single agent home layout.

## Consequences

### Advantages
- One codebase supports three agents with consistent memory workflow
- Install/uninstall remain idempotent while becoming agent-aware
- Skill composition is more portable because sub-skill lookup is relative
- User onboarding is simpler with explicit install targets and examples

### Disadvantages
- Installer/uninstaller complexity increases due to per-agent branching
- Documentation maintenance surface expands across more environments
- Cursor uses a rule-file workflow that differs from CLAUDE/AGENTS markers

### Risk Mitigation
- Keep agent mapping centralized in script helper functions
- Preserve marker-based updates for Claude/Codex to avoid duplicate inserts
- Keep templates minimal and enforce bilingual doc sync in contribution flow

## Related Decisions
- ADR 001: Read-Inline for Nested Skill Invocation

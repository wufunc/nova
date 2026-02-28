# Architecture Overview

Meta: updated 2026-02-28

## Repository Scope
- Open-source project providing a persistent memory system for Claude Code, Codex, and Cursor.
- Contains skill definitions, install/uninstall scripts, documentation, and examples.
- No application runtime code — this is a tool/configuration distribution project.

## Repository Structure
```
nova/
├── skills/                    # 4 core memory workflow skills
│   ├── memory/SKILL.md        # Memory recall + update (decision layer)
│   ├── git-commit/SKILL.md    # Commit orchestration (orchestration layer)
│   ├── adr-creator/           # ADR writer + format references (writer layer)
│   └── devlog-creator/        # DevLog writer + format references (writer layer)
├── templates/                 # Agent instruction templates (Claude/Codex/Cursor)
├── examples/                  # Example arch.md, ADR, DevLog files
├── install.sh                 # Multi-agent install: copies skills + injects agent rules
├── uninstall.sh               # Multi-agent uninstall: removes skills + cleans agent rules
├── DESIGN.md                  # System design document (English)
├── DESIGN.zh-CN.md            # System design document (Chinese)
├── README.md                  # Project README (English)
├── README.zh-CN.md            # Project README (Chinese)
├── CONTRIBUTING.md            # Contribution guide (bilingual)
├── LICENSE                    # MIT
├── CHANGELOG.md               # Version history
└── .nova/                 # Self-dogfooding memory
```

## Module Boundaries
- `skills/`: Skill source files. Installed to each supported agent's `skills/` directory.
- `templates/`: Agent-specific rule/instruction templates:
  - `claude-md-snippet.md` (for `~/.claude/CLAUDE.md`)
  - `codex-agents-snippet.md` (for `~/.codex/AGENTS.md`)
  - `cursor-rule-snippet.mdc` (for `~/.cursor/rules/nova.mdc`)
- `examples/`: Read-only reference files, not installed anywhere.
- `.nova/`: This project's own memory (dogfooding the system it distributes).

## Install Mechanism
- `install.sh` supports `--agents claude,codex,cursor` and auto-detects installed agents when omitted.
- For Claude/Codex, installer updates marked blocks with `<!-- nova:start -->` / `<!-- nova:end -->`.
- For Cursor, installer writes dedicated rule file `.cursor/rules/nova.mdc`.
- Supports both local clone install and remote curl-pipe-bash install.

## Key Conventions
- All documentation is bilingual (English + Chinese).
- Skill files must be generic — no project-specific or user-specific content.
- Four-layer skill architecture: agent instructions → git-commit → memory → writers.
- `git-commit` resolves sub-skills by relative sibling directories, not agent-specific absolute paths.

## Known Limitations
- No automated test suite (manual testing via agent sessions).
- Remote install depends on public GitHub repository URL.

# Architecture Overview

Meta: updated 2026-02-28

## Repository Scope
- Open-source project providing a persistent memory system for Claude Code (AI coding agent).
- Contains skill definitions, install/uninstall scripts, documentation, and examples.
- No application runtime code — this is a tool/configuration distribution project.

## Repository Structure
```
aicoding-memory/
├── skills/                    # 4 core Claude Code skills
│   ├── memory/SKILL.md        # Memory recall + update (decision layer)
│   ├── git-commit/SKILL.md    # Commit orchestration (orchestration layer)
│   ├── adr-creator/           # ADR writer + format references (writer layer)
│   └── devlog-creator/        # DevLog writer + format references (writer layer)
├── templates/                 # CLAUDE.md snippet with install markers
├── examples/                  # Example arch.md, ADR, DevLog files
├── install.sh                 # Copies skills to ~/.claude/skills/, updates CLAUDE.md
├── uninstall.sh               # Removes skills, cleans CLAUDE.md
├── DESIGN.md                  # System design document (English)
├── DESIGN.zh-CN.md            # System design document (Chinese)
├── README.md                  # Project README (English)
├── README.zh-CN.md            # Project README (Chinese)
├── CONTRIBUTING.md            # Contribution guide (bilingual)
├── LICENSE                    # MIT
├── CHANGELOG.md               # Version history
└── .aicoding/                 # Self-dogfooding memory
```

## Module Boundaries
- `skills/`: Skill source files. Installed to `~/.claude/skills/` by `install.sh`.
- `templates/`: Contains `claude-md-snippet.md` with marker comments for idempotent install/upgrade.
- `examples/`: Read-only reference files, not installed anywhere.
- `.aicoding/`: This project's own memory (dogfooding the system it distributes).

## Install Mechanism
- `install.sh` copies `skills/` to `~/.claude/skills/` and appends a marked block to `~/.claude/CLAUDE.md`.
- Uses `<!-- aicoding-memory:start -->` / `<!-- aicoding-memory:end -->` markers for idempotent upgrades.
- Supports both local clone install and remote curl-pipe-bash install.

## Key Conventions
- All documentation is bilingual (English + Chinese).
- Skill files must be generic — no project-specific or user-specific content.
- Four-layer skill architecture: CLAUDE.md → git-commit → memory → writers.

## Known Limitations
- No automated test suite (manual testing via Claude Code sessions).
- Remote install depends on public GitHub repository URL.

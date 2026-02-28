# Project Constitution

## Core Principles

1. **Skills must be generic**: No skill file may contain project-specific paths, configurations, or logic. Skills must work for any Claude Code user in any project.

2. **Bilingual documentation**: All user-facing documentation (README, DESIGN, CONTRIBUTING) must exist in both English and Chinese. Changes to one language must be reflected in the other.

3. **Minimal context overhead**: The four-layer skill architecture must be maintained. Decision logic stays in `memory`, writing logic stays in creators. Do not merge layers.

4. **Backward-compatible installs**: `install.sh` must be idempotent — running it multiple times must not duplicate content or break existing configurations.

5. **No external dependencies**: The memory system must work with only Claude Code, Git, and standard POSIX tools. No databases, no npm packages, no Python dependencies.

6. **Dogfooding**: This project must use its own memory system (`.nova/memory/`). Changes to the skill system should be validated by using this project as a test case.

# aicoding-memory

**Give your AI coding agent a persistent memory across sessions.**

[中文文档](README.zh-CN.md) | [Design Document](DESIGN.md) | [设计文档](DESIGN.zh-CN.md)

---

## The Problem

AI coding agents start every session as a blank slate. They don't remember why approach A was chosen over B, don't remember the undocumented API quirk that took hours to debug, and don't remember the architectural decisions that should constrain future work.

This leads to **repeated mistakes** and **decision drift** — carefully reasoned choices get unknowingly overturned because the agent has no memory of them.

## The Solution

aicoding-memory gives Claude Code a structured, persistent memory system with three complementary memory types:

| Memory Type | Purpose | Example |
|-------------|---------|---------|
| **arch.md** | Project architecture overview | "This is a Next.js monorepo with Supabase backend" |
| **ADR** | Architecture Decision Records | "We chose WebSocket over SSE because..." |
| **DevLog** | Development experience logs | "Sentinel API returns empty PoW config — check `required` field first" |

Memories are automatically written at commit time and recalled at session start. No manual maintenance required.

### How It Works

```
Session Start                          Code Commit
     │                                      │
     ▼                                      ▼
/memory recall                        /git-commit
     │                                      │
     ├─ Load arch.md                        ├─ Generate commit message
     ├─ Search relevant ADR/DevLog          ├─ /memory update
     └─ Present context to agent            │    ├─ Update arch.md?
                                            │    ├─ Create ADR?
                                            │    └─ Create DevLog?
                                            ├─ Stage + commit
                                            └─ Tag (mem/NNN)
```

### Four-Layer Skill Architecture

```
CLAUDE.md           → trigger rules (always in context)
  └─ git-commit     → orchestration (commit workflow)
       └─ memory    → decision (should we record?)
            ├─ adr-creator    → writer (format + write ADR)
            └─ devlog-creator → writer (format + write DevLog)
```

Only the layers needed are loaded — most commits only use the first two layers, keeping context overhead minimal.

## Quick Start

### Install

```bash
# Clone and install
git clone https://github.com/anthropic-lab/aicoding-memory.git
cd aicoding-memory && bash install.sh
```

This installs 4 skills into `~/.claude/skills/` and adds memory management rules to `~/.claude/CLAUDE.md`.

### First Use

1. Open any project with Claude Code
2. The agent automatically runs `/memory recall` at session start
3. If `.aicoding/memory/` doesn't exist, it initializes automatically
4. The agent generates `arch.md` from your repository structure
5. When you `/git-commit`, memories are evaluated and created as needed

### Uninstall

```bash
cd aicoding-memory && bash uninstall.sh
```

Project-level memory data (`.aicoding/memory/`) is preserved — delete manually if you no longer need it.

## Memory Types

### arch.md — The Map

A single-file architecture overview (~200 lines) loaded every session. Contains tech stack, directory structure, module responsibilities, data flow, and known limitations. Auto-generated on first use, auto-updated on code changes.

### ADR — The Signposts

Architecture Decision Records that capture **why** a technical choice was made. Created only when significant decisions are made (comparing 2+ approaches with trade-offs). See [ADR example](examples/adr-example.md).

### DevLog — The Traveler's Warnings

Development experience logs that capture **non-obvious discoveries**. Things like hidden API behaviors, debugging insights, environment gotchas, and approaches that don't work. See [DevLog example](examples/devlog-example.md).

## Retrieval: Grep-Driven, No Index

Each ADR and DevLog has YAML frontmatter optimized for Grep search:

```yaml
---
tags: [chatgpt, sentinel, pow, auth]
modules: [contents/providers/chatgpt/auth]
summary: "sentinel returns empty proofofwork, must skip PoW not error"
tag: mem/003
---
```

The agent searches by tags, modules, and summary using Grep — no vector database, no embeddings, no index file. This keeps context overhead at O(K) where K is the number of matches, not O(N) for all entries.

## Project Structure

```
aicoding-memory/
├── skills/                    # Skill source files
│   ├── memory/SKILL.md        # Core memory skill (recall + update)
│   ├── git-commit/SKILL.md    # Commit workflow orchestrator
│   ├── adr-creator/           # ADR writer + format references
│   └── devlog-creator/        # DevLog writer + format references
├── templates/                 # CLAUDE.md snippet for install
├── examples/                  # Real-world examples
├── install.sh                 # Install script
├── uninstall.sh               # Uninstall script
├── DESIGN.md                  # Design document (English)
├── DESIGN.zh-CN.md            # Design document (Chinese)
└── .aicoding/                 # This project's own memory (dogfooding)
```

## Configuration

### Constitution (Optional)

Create `.aicoding/constitution.md` in any project to define its highest-priority principles. The agent reads this before every session and ensures all actions (code and memory) respect these constraints.

```markdown
# Project Constitution

- All API responses must be typed with Zod schemas
- No direct DOM manipulation — use React state exclusively
- Test coverage must not drop below 80%
```

### Memory Directory

The `.aicoding/memory/` directory is auto-created. You can commit it to your repository so the memory persists across machines and team members.

## Design Philosophy

This system makes several deliberate design choices:

- **Grep over vector search** — zero dependencies, zero maintenance, O(K) context overhead
- **Git tags over commit hashes** — avoids the content-addressable cycle problem
- **Principle-driven over rule-driven** — flexible enough to capture diverse experience
- **Four-layer skills over monolith** — minimizes context overhead on the common path
- **Facts-only arch.md** — adapts to any project structure without empty template sections

Read the full design document: [DESIGN.md](DESIGN.md) | [设计文档](DESIGN.zh-CN.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues, pull requests, and skill modifications.

## License

[MIT](LICENSE)

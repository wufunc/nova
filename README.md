# nova

**Give your AI coding agent a persistent memory across sessions.**

[中文文档](README.zh-CN.md) | [Design Document](DESIGN.md) | [设计文档](DESIGN.zh-CN.md)

---

## The Problem

AI coding agents start every session as a blank slate. They don't remember why approach A was chosen over B, don't remember the undocumented API quirk that took hours to debug, and don't remember the architectural decisions that should constrain future work.

This leads to **repeated mistakes** and **decision drift** — carefully reasoned choices get unknowingly overturned because the agent has no memory of them.

## The Solution

nova gives Claude Code, Codex, and Cursor a structured, persistent memory system with three complementary memory types:

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
Agent instructions  → trigger rules (always in context)
                     (CLAUDE.md / AGENTS.md / Cursor rule)
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
git clone https://github.com/anthropic-lab/nova.git
cd nova && bash install.sh
```

By default, `install.sh` auto-detects installed agents and installs to all of them.
Use `--agents` to limit targets:

```bash
bash install.sh --agents codex,cursor
```

Installed locations:
- Claude: skills in `~/.claude/skills/`, rules in `~/.claude/CLAUDE.md`
- Codex: skills in `~/.codex/skills/`, rules in `~/.codex/AGENTS.md`
- Cursor: skills in `~/.cursor/skills/`, rules in `~/.cursor/rules/nova.mdc`

### How to Use

nova's memory system is self-maintained:
- At session start, the agent automatically runs `/memory recall`
- If `.nova/memory/` does not exist, the system initializes it automatically
- The system generates or updates `arch.md` from repository structure as needed
- During the commit workflow, the system evaluates and creates required memories (ADR/DevLog)

The only manual trigger is: run the `git-commit` skill once after each development unit is complete (`/git-commit` in Claude/Cursor, `$git-commit` in Codex).

Recommended granularity: one `git-commit` per independently verifiable and reversible unit of work (for example, one bug fix, one small feature, or one focused refactor).

If the granularity is too large (too many changes in one commit):
- Commit intent and memory records become mixed, making retrieval harder
- Rollback and cherry-pick become more costly and risky
- Key decision context can be buried by unrelated changes

If the granularity is too small (overly fragmented frequent commits):
- Commit history and memory noise increase
- More low-value records reduce recall signal quality
- Team review and issue tracing become more fragmented

### Uninstall

```bash
cd nova && bash uninstall.sh
```

Project-level memory data (`.nova/memory/`) is preserved — delete manually if you no longer need it.

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
nova/
├── skills/                    # Skill source files
│   ├── memory/SKILL.md        # Core memory skill (recall + update)
│   ├── git-commit/SKILL.md    # Commit workflow orchestrator
│   ├── adr-creator/           # ADR writer + format references
│   └── devlog-creator/        # DevLog writer + format references
├── templates/                 # Agent instruction snippets for install
├── examples/                  # Real-world examples
├── install.sh                 # Install script
├── uninstall.sh               # Uninstall script
├── DESIGN.md                  # Design document (English)
├── DESIGN.zh-CN.md            # Design document (Chinese)
└── .nova/                 # This project's own memory (dogfooding)
```

## Configuration

### Constitution (Optional)

Create `.nova/constitution.md` in any project to define its highest-priority principles. The agent reads this before every session and ensures all actions (code and memory) respect these constraints.

```markdown
# Project Constitution

- All API responses must be typed with Zod schemas
- No direct DOM manipulation — use React state exclusively
- Test coverage must not drop below 80%
```

### Memory Directory

The `.nova/memory/` directory is auto-created. You can commit it to your repository so the memory persists across machines and team members.

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

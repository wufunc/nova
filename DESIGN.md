# AI Coding Project Memory Management System Design

> This document describes a project memory management system designed for Claude Code, Codex, Cursor (or similar AI Coding Agents), covering design philosophy, architectural decisions, and implementation details.

---

## 1. The Problem: AI Agents Have Goldfish Memory

Every AI Coding Agent session starts as a blank slate. It doesn't remember why it chose approach A over approach B last time, doesn't remember that an API has an undocumented hidden limitation, and doesn't remember the root cause that took three hours to debug last week.

This leads to two consequences:

1. **Repeated mistakes**: The same pitfall, encountered twice across different sessions.
2. **Decision drift**: A carefully reasoned architectural decision from last time gets unknowingly overturned, because the Agent has no idea it exists.

The larger the project and the longer the development cycle, the worse this problem becomes. Code itself only records "what is," not "why it's this way" or "what pitfalls were encountered." Yet these are precisely the context an AI Agent needs most.

## 2. Design Philosophy

### 2.1 Memory Is the Shadow of Code

Code expresses the final state; memory expresses the path to reaching that state. A good memory system should cover three dimensions that code cannot express:

| Dimension | Corresponding Question | Memory Type |
|-----------|----------------------|-------------|
| **Global** | What is this project? How are modules organized? | Architecture Overview (arch.md) |
| **Decisions** | Why was approach A chosen over B? | Architecture Decision Records (ADR) |
| **Experience** | What non-obvious things were discovered during development? | Development Logs (DevLog) |

These three memory types are mutually exclusive:
- **arch.md** is the "map" — tells you where you are and what's around you
- **ADR** is the "signpost" — tells you why this path was taken
- **DevLog** is the "traveler's warning" — tells you there's a pitfall ahead

### 2.2 Writing Should Be Automatic, Recall Should Be Intelligent

The biggest enemy of a memory system is "forgetting to record." If it depends on the developer (or Agent) to actively record, the memory store will quickly become stale. Therefore:

- **Write timing is bound to git commit**: Every code commit automatically triggers session analysis to decide whether memory needs updating. This is the only reliable automation anchor — when code changes, memory should be evaluated in sync.
- **Recall timing is bound to session lifecycle**: Basic context is automatically loaded at session start; on-demand retrieval happens during development.

### 2.3 Context Window Is a Public Resource

An AI Agent's context window is finite. Every line loaded into it has an opportunity cost. Therefore, the memory system must follow the **minimum loading principle**:

- Only arch.md (~200 lines) is loaded every time
- ADR and DevLog are loaded only when relevant
- The overhead of the retrieval process itself should be as low as possible

This directly rules out the "load full index" approach — an index of 100 memories is 100 lines of context overhead, while perhaps only 2 of them are relevant.

### 2.4 Let the Agent Judge Relevance Itself

No vector database, no embeddings, no BM25 ranking. Our search engine is the AI Agent itself.

This seemingly "primitive" design is actually the most reasonable: the Agent understands natural language, understands code context, understands task intent — its ability to judge relevance far exceeds any keyword matching algorithm. All we need to do is **let it efficiently scan the candidate set**.

### 2.5 Separate Decision from Execution

In the memory system, "whether to write" and "how to write" are two independent concerns:

- **"Whether to write"** requires understanding the full session context and judging information value — this is high-level decision-making
- **"How to write"** requires following format specifications and generating structured content — this is execution detail

Putting both in a single skill means format specifications must be loaded every time (even though 90% of the time the conclusion is "no need to write"). After separation, the common path only needs to load decision logic, significantly saving context.

### 2.6 Constitution First

Each project can have a "constitution" (`.aicoding/constitution.md`) that defines the project's highest-priority principles and constraints. All operations of the memory system — whether the Agent's code modifications or memory writing — must not violate the constitution.

This solves a subtle problem: the Agent might make locally optimal but principle-violating decisions based on past experience. The constitution serves as a "check" on the memory system — experience can suggest, but principles must not be crossed.

### 2.7 Zero-Configuration Bootstrap

The memory system should have no manual initialization steps. When an Agent enters a new project, if the memory infrastructure doesn't exist, the system should automatically create directories, generate an initial arch.md based on repository facts, and then continue normal operation. This means any project works out of the box as long as it has a supported agent instruction entry (for example: Claude `CLAUDE.md`, Codex `AGENTS.md`, or Cursor rule file).

## 3. Architecture Design

### 3.1 Memory Structure

```
.aicoding/
├── constitution.md          # Project constitution: highest-priority principles (optional)
└── memory/
    ├── arch.md              # Architecture overview: project panorama, loaded every session
    ├── adr/                 # Architecture Decision Records: what was chosen and why
    │   ├── 001-xxx.md
    │   └── 002-xxx.md
    └── devlog/              # Development experience logs: pitfalls and lessons
        ├── 001-xxx.md
        └── 002-xxx.md
```

#### arch.md

The project's "one-page architecture brief." Content includes tech stack, directory structure, core data flow, module responsibilities, known limitations, and technical debt. After reading it, an AI Agent should understand the full project picture within 30 seconds.

**Characteristics**:
- Single file, always kept current (overwrite-style updates)
- Force-loaded every session
- Kept under 200 lines

**Auto-generation principles** (on first project entry):

arch.md does not use a fixed template; instead, it's generated on demand based on repository facts:

1. Include only verifiable facts from repository files
2. Prioritize architecture facts: module boundaries, data flow, build/deploy
3. Keep content minimal but sufficient for future recall and updates
4. Mark unknowable information explicitly as `Unknown` or `Not inferred`
5. Idempotent: in recall mode, if arch.md already exists, do not overwrite

Evidence sources (loaded as needed): directory structure, `package.json`, build configs (`vite.config.*`, `tsconfig*`, `vercel.json`, etc.).

#### ADR (Architecture Decision Record)

Records **architectural decisions that have been made**. Each ADR answers one question: "Why did we choose this approach?"

**Admission criteria**:
- Compared 2+ technical approaches and made a choice
- Introduced new architectural patterns or significantly changed existing ones
- Decisions that constrain future development

**Not in ADR scope**:
- Bug fixes, refactoring, feature implementation details
- Configuration changes, dependency updates

#### DevLog (Development Log)

Records **non-obvious discoveries during development**. Each DevLog answers one question: "If the next session encounters a similar scenario, what information would help it avoid a detour?"

**Admission criteria (principle-driven, not rule-driven)**:

> "If the next session encounters a similar scenario, would this information help it avoid a detour?"

If yes, record it. If not, don't. No further restrictions.

**ADR and DevLog deduplication rule**:

The system evaluates ADR first, then DevLog. If a topic has already produced an ADR, a DevLog is only created if there is a **completely unrelated, independent** debugging insight. This avoids redundancy from the same topic producing both an ADR and a DevLog.

**Essential difference between DevLog and ADR**:
- ADR records "choices" (decisions), DevLog records "discoveries" (experience)
- ADR is binding (subsequent development should follow), DevLog is advisory (for reference)
- ADR is "We decided to use WebSocket instead of SSE"; DevLog is "WebSocket heartbeat interval needs to be set to 30s on mobile weak networks to be stable"

### 3.2 Retrieval Mechanism: Grep-Driven Lazy Retrieval

Each ADR and DevLog file has YAML frontmatter in its header:

```yaml
---
tags: [chatgpt, sentinel, pow, auth]
modules: [contents/providers/chatgpt/auth]
summary: "sentinel returns empty proofofwork, must skip PoW not error"
tag: mem/003
---
```

Retrieval doesn't need to load any index file; it directly searches frontmatter with Grep:

```bash
# By technical tag
Grep "^tags:.*chatgpt"    → matches ChatGPT-related memories

# By code module
Grep "^modules:.*provider"  → matches provider-related memories

# By problem description
Grep "^summary:.*stream"  → matches stream processing-related memories
```

**Why not use an index table**:

| | Index Table | Grep Search |
|---|---|---|
| Context overhead | O(N) — all entry summaries must be loaded | O(K) — only matched entries consume context |
| Maintenance cost | Must sync-update index on every write | Zero maintenance |
| Scalability | Context pressure at 100+ entries | No pressure even at 1000+ entries (ripgrep is fast) |
| Search precision | Depends on Agent scanning full table for semantic matching | Grep exact match + Agent judgment |

The core insight of this design: **shift the "traversal" cost from the context window to tool calls**. Grep traversing the filesystem is free, but loading traversal results into context is expensive.

### 3.3 Commit Binding: Git Tag Approach

Each memory needs to be associated with the code change that produced it. A common approach is to record the commit hash in the file, but this faces a fundamental contradiction:

> File content affects the commit hash, but the commit hash also needs to be written into the file content. This is an inherent cycle of content-addressable storage.

**Solution: use git tags instead of commit hashes.**

```
1. Create memory file, write tag: mem/003
2. Commit code + memory files together
3. git tag mem/003
```

File references tag → tag points to commit → no cycle. `git show mem/003` is always valid.

Tag naming convention: `mem/NNN`, globally incrementing. ADR and DevLog share the numbering space. All memory files created in the same commit share the same tag.

### 3.4 Skill System: Four-Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│ Agent instruction entry (always in context)          │
│ (CLAUDE.md / AGENTS.md / Cursor rule)                │
│ Three rules:                                         │
│ 1. Session start → /memory recall                    │
│ 2. Encounter uncertainty → /memory recall             │
│ 3. Enter project → read .aicoding/constitution.md    │
└────────────────────┬──────────────────────────────────┘
                     │ triggers
┌────────────────────▼──────────────────────────────────┐
│ git-commit skill (orchestration layer)                │
│                                                       │
│ /git-commit                                           │
│   Analyze changes → generate Conventional Commits msg │
│                   → invoke /memory update             │
│                   → stage + commit + tag              │
│   Entire flow executes atomically, no user waits      │
└────────────────────┬──────────────────────────────────┘
                     │ invokes
┌────────────────────▼──────────────────────────────────┐
│ memory skill (decision layer)                         │
│                                                       │
│ /memory recall                                        │
│   Auto-init infrastructure (if missing)               │
│   Load arch.md + Grep search relevant ADR/DevLog      │
│                                                       │
│ /memory update                                        │
│   Analyze session → decide whether to update arch.md  │
│                   → evaluate ADR first → invoke sub-skill (if needed) │
│                   → then evaluate DevLog (after dedup) → invoke sub-skill │
│                   → coordinate tag numbering           │
└──────────┬──────────────────┬─────────────────────────┘
           │                  │ invoked on demand
┌──────────▼─────┐  ┌────────▼─────────┐
│ adr-creator    │  │ devlog-creator   │
│ (pure writer)  │  │ (pure writer)    │
│ w/ references/ │  │ w/ references/   │
│ and assets/    │  │                  │
└────────────────┘  └──────────────────┘
```

**Rationale for four layers**:

1. **Agent instruction entry** (always in context): Just a few rules, virtually zero overhead. Responsibility: "when to trigger" and "global constraints."
2. **git-commit skill** (loaded on user trigger): ~150 lines of orchestration. Responsibility: "how to commit." Orchestrates code commit and memory update as an atomic operation, ensuring memory and code stay in sync.
3. **memory skill** (invoked by git-commit or manually): ~200 lines of decision logic. Responsibility: "whether to do it." Most commits end here (conclusion: "no update needed"), without triggering the next layer.
4. **adr-creator / devlog-creator** (loaded on demand): ~80-130 lines each of writing specifications, plus independent format reference documents. Only loaded when memory actually needs to be written. Writers carry their own format specs and templates, ensuring output consistency.

**Context overhead comparison**:

| Scenario (frequency) | Skills loaded | Context overhead |
|----------------------|---------------|-----------------|
| Normal commit, no memory update (~70%) | git-commit + memory | ~350 lines |
| Commit with DevLog (~25%) | git-commit + memory + devlog-creator | ~480 lines |
| Commit with ADR (~5%) | git-commit + memory + adr-creator | ~530 lines |

Core benefit unchanged: format specifications and templates are only loaded when writing is needed.

## 4. Workflows

### 4.1 Session Start: Recall

```
User sends first message
  → Agent instruction rules trigger
  → Agent reads .aicoding/constitution.md first (if exists)
  → /memory recall executes
     ├─ Check if .aicoding/memory/ exists
     │    └─ Missing? → Auto-create directories + generate arch.md → report initialization complete
     ├─ Load arch.md → Agent understands project overview (present 3-5 line summary)
     ├─ Extract keywords from user message
     │    └─ No task context? → "Ready to search memories when your task is clear."
     ├─ Grep search devlog/ and adr/ frontmatter (multi-dimensional parallel search)
     └─ Load matched entries in full → present relevant memory summaries to user
  → Agent begins processing user task (with full context)
```

### 4.2 During Development: On-Demand Recall

```
Agent encounters uncertain problem during development
  → Proactively executes /memory recall
  → Grep search → load relevant memories
  → Continue development
```

### 4.3 Code Commit: Update

```
User says /git-commit
  → git-commit skill executes (entire flow is atomic)
     │
     ├─ Step 1: Analyze session context
     │    └─ Understand code changes, features, decisions
     │
     ├─ Step 2: Check git status
     │    └─ git status + git diff HEAD + git log (parallel)
     │
     ├─ Step 3: Generate Conventional Commits format message
     │    └─ <type>(<scope>): <subject> + detailed body
     │
     ├─ Step 4: Invoke /memory update
     │    ├─ Ensure memory infrastructure exists
     │    ├─ Analyze session, identify three signal types:
     │    │    ├─ Architecture changes? → update arch.md
     │    │    ├─ Architecture decisions? → evaluate first, if needed → invoke adr-creator
     │    │    └─ Development experience? → evaluate after dedup, if needed → invoke devlog-creator
     │    ├─ Coordinate tag numbering (ADR + DevLog share same tag)
     │    └─ Return: list of created files + tag name (or "no updates needed")
     │
     ├─ Step 5: git add -A (including memory files)
     ├─ Step 6: git commit (heredoc format, no hook skipping)
     ├─ Step 7: git tag mem/NNN (if memory files exist)
     └─ Step 8: git status + git log verification
```

**Atomic execution guarantee**: Steps 1-8 of git-commit are an uninterrupted flow. After the memory skill internally invokes sub-skills (adr-creator, devlog-creator) and they complete, control immediately returns to git-commit to continue subsequent steps — no pauses, no waiting for user input.

## 5. Implementation Details

### 5.1 Maintaining arch.md

arch.md is not a write-once artifact. It needs to be updated as code evolves. Updates are automatically judged by the memory skill during each `/memory update`.

**Judgment principle**:

> "Do this session's changes make any section of arch.md factually outdated, incomplete, or misleading?"

**Specific check method**: Compare section by section — does the structure, data flow, conventions, and known limitations described in arch.md still match the actual codebase state after this session's changes.

**Changes that trigger updates**:
- Directory structure or module boundary changes
- Communication protocol, data flow, or API contract changes
- New components/services/patterns introduced that arch.md doesn't mention
- Refactoring that makes existing descriptions inaccurate
- Technical debt resolved or newly discovered
- Development convention changes (toolchain, onboarding steps, debug workflows)

**Changes that don't trigger updates**:
- Bug fixes that don't change architecture or contracts
- Internal implementation changes within a module (arch.md describes structure, not implementation)
- Dependency version bumps without behavioral impact

### 5.2 DevLog Quality Control

DevLog uses principle-driven rather than rule-driven quality control. But several anti-patterns should be noted:

- **Too vague**: "Gemini streaming has some issues" → no actionable information
- **Too verbose**: "First tried approach A, then B, then C..." → this is an implementation log, not experience
- **Overlaps with ADR**: "We decided to use API-first strategy because..." → this is a decision, should be an ADR
- **Code already expresses it**: "The function takes two parameters: provider and message" → just read the code

Qualified DevLog entries focus on **non-obvious, actionable discoveries**:
- Non-obvious debugging discoveries (tried X, failed because Y, solution was Z)
- Hidden behaviors of third-party services or APIs
- Environment/configuration gotchas
- Performance observations with concrete data
- Approaches that don't work and why

### 5.3 Frontmatter Design

Frontmatter is the lifeline of retrieval. Writing good frontmatter matters more than writing good body content.

- **tags**: 3-8 keywords covering tech stack, concepts, problem types. Use lowercase.
- **modules**: Relevant source code paths (relative to src/), as specific as possible to the sub-module.
- **summary**: One line, under 80 characters. Imagine what keywords someone would use to search for this memory, and put those words in.
- **tag**: Git tag in `mem/NNN` format, linking to the commit that produced this memory.

### 5.4 Adapting to Other Projects

This system doesn't depend on any specific project structure, and has achieved **zero-configuration bootstrap**:

1. Global/always-applied agent instructions already contain trigger rules; new projects work automatically
2. First session's `/memory recall` automatically creates the `.aicoding/memory/` directory structure
3. arch.md is auto-generated by the Agent based on repository facts (not a fixed template)
4. First `/git-commit` triggers the memory update workflow automatically

The only optional manual step is writing `.aicoding/constitution.md` to define the project's constitutional principles.

### 5.5 Writer Resource Structure

adr-creator and devlog-creator, as pure writers, each carry independent format specifications:

```
adr-creator/
├── SKILL.md              # Writing logic and quality checklist
├── references/
│   └── adr-format.md     # Complete format specification
└── assets/
    └── template.md       # ADR template

devlog-creator/
├── SKILL.md              # Writing logic
└── references/
    └── devlog-format.md  # Format specification (with positive/negative examples)
```

These reference documents are only loaded when the writer is invoked, adding no context overhead to the normal path. Writers handle numbering, file naming, and YAML frontmatter generation according to their format specifications.

## 6. Design Trade-offs and Limitations

### Known Limitations

1. **Grep retrieval cannot do semantic matching**: If the user asks about "performance optimization" but the DevLog says "response latency," Grep won't match. Mitigation: proactively include synonyms in tags.
2. **Memories don't auto-expire**: If code changes but the corresponding DevLog isn't updated, it may be misleading. There is currently no automatic cleanup mechanism.
3. **Depends on Agent's judgment quality**: Whether "should I record this" or "what should I search for," both depend on the Agent's judgment. Different models/versions may perform differently.

### Intentional Trade-offs

| Choice | Given Up | Rationale |
|--------|----------|-----------|
| Grep retrieval | Vector search | Zero dependencies, zero maintenance, O(K) context overhead |
| Git tag binding | Commit hash binding | Avoids content-addressable cycle problem |
| Principle-driven DevLog | Rule-driven DevLog | Avoids overly rigid signals that miss valuable experience |
| Four-layer skill split | Single skill | Reduces context overhead on the common path |
| Agent instruction file as trigger | Agent instruction file with logic | Memory structure can evolve without changing the instruction entry |
| ADR-first evaluation + DevLog dedup | Parallel independent evaluation | Avoids same topic producing duplicate memories |
| Fact-driven arch.md generation | Fixed template | Adapts to any project structure, avoids empty section noise |
| Zero-config auto-initialization | Manual setup steps | Reduces friction for new project onboarding |

## 7. Future Evolution

1. **Memory expiration mechanism**: Periodically scan DevLogs, flag entries that may be outdated (corresponding code has changed significantly)
2. **Cross-project memory**: Some experiences are universal (e.g., "Chrome Extension MV3 Service Worker has a 5-minute timeout"), could be extracted to global memory
3. **Memory quality assessment**: Track which memories were actually recalled and used vs. never touched, to optimize writing decisions
4. **Semantic retrieval enhancement**: Add Agent-generated synonyms/related terms in frontmatter to improve Grep recall

---

*This document is itself a product of this memory system :)*

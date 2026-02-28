---
name: memory
description: "Project memory management: recall and update. Accepts an argument to select mode. (1) 'recall' mode — Load project architecture and search relevant development memories (ADR, DevLog) at session start or during development. MUST be invoked at the beginning of every session. (2) 'update' mode — Analyze session to update architecture doc, create DevLog and ADR entries before git commit. Invoked by git-commit skill or manually."
---

# Memory Skill


## Mode: recall

### Step 1: Ensure Memory Infrastructure (Auto-init)

If `.nova/memory/` is missing, initialize it automatically and continue:

```bash
# Create memory directories (idempotent)
mkdir -p .nova/memory/adr .nova/memory/devlog
```

If `.nova/memory/arch.md` is missing, generate it from repository facts
using principles (do NOT use a fixed project template):

1. Include only verifiable facts from repository files.
2. Prioritize architecture facts: module boundaries, data flow, build/deploy.
3. Keep content minimal but sufficient for future recall/update.
4. Mark unknowns explicitly as `Unknown` or `Not inferred`.
5. Be idempotent: if `arch.md` exists, do not overwrite in recall mode.

Suggested evidence sources (load only as needed):
- Directory structure (`client/`, `server/`, `shared/`, etc.)
- `package.json` scripts and key dependencies
- Build/deploy config (`vercel.json`, `vite.config.*`, `tsconfig*`)

When initialization happens, report once:
`Memory infrastructure initialized at .nova/memory/`

### Step 2: Load Architecture Overview

Always load the architecture file:

```bash
Read .nova/memory/arch.md
```

Present a brief summary (3-5 lines) of the project to the user.

### Step 3: Search Relevant Memories

Extract keywords from the conversation context (user's task description, mentioned technologies, file paths, problem descriptions).

If no task context is available yet (e.g., user just started the session), skip this step and note: "Ready to search memories when your task is clear."

If task context is available, search in parallel:

```bash
# Search DevLog by tags
Grep pattern: "^tags:.*KEYWORD" path: .nova/memory/devlog/

# Search DevLog by modules
Grep pattern: "^modules:.*MODULE_PATH" path: .nova/memory/devlog/

# Search DevLog by summary
Grep pattern: "^summary:.*KEYWORD" path: .nova/memory/devlog/

# Search ADR titles
Grep pattern: "^# ADR.*KEYWORD" path: .nova/memory/adr/
```

Use multiple keywords extracted from the task. Search is case-insensitive.

### Step 4: Load Relevant Entries

For each matching file from Step 3, Read the full content. Then present to the user:

```
Found relevant memories:

**DevLog 003: ChatGPT Sentinel Empty PoW Config**
- Relevance: Current task involves ChatGPT auth flow
- Key insight: sentinel token may return empty proofofwork, must check `required` field

**ADR 001: API-first Strategy with DOM Fallback**
- Relevance: Current task modifies provider integration
- Key decision: API-first with DOM fallback, error classification drives fallback
```

If no relevant memories found, briefly state so and proceed.

---

## Mode: update

Analyzes the current session and creates/updates memories as needed.

### Step 0: Ensure Memory Infrastructure (Fallback init)

Before analyzing the session, ensure memory directories exist:

```bash
mkdir -p .nova/memory/adr .nova/memory/devlog
```

If `.nova/memory/arch.md` is missing, generate an initial version using
the same facts-only principles defined in recall Step 1, then continue.

### Step 1: Analyze Session

Review the conversation to identify:

1. **Architecture changes** - Did code changes affect project structure, protocols, providers, data models, or other architectural aspects?
2. **Development experience** - Did the session produce insights that would help future sessions avoid mistakes or work more efficiently?
3. **Architectural decisions** - Were multiple technical approaches compared and a choice made?

### Step 2: Update arch.md

Apply this principle:

> "Does this session's changes make any section of arch.md factually outdated, incomplete, or misleading?"

Evaluation method:
1. If arch.md is not already in context (e.g., compressed away in a long session), Read `.nova/memory/arch.md` now; otherwise reuse the version already loaded during recall mode
2. Review the session's code changes (files modified, added, deleted)
3. For each section of arch.md, check if the described structure, data flow, conventions, or known limitations still accurately reflect the codebase after this session's changes

**What qualifies:**
- Directory structure or module boundaries changed
- Communication protocols, data flow, or API contracts changed
- New components/services/patterns introduced that arch.md doesn't mention
- Existing descriptions became inaccurate due to refactoring
- Technical debt resolved or newly discovered
- Development conventions changed (tooling, onboarding steps, debug workflows)

**What does NOT qualify:**
- Bug fixes that don't change architecture or contracts
- Internal implementation changes within an existing module (arch.md describes structure, not implementation details)
- Dependency version bumps without behavioral impact

If any section needs updating:
1. Update the relevant sections
2. Update the Meta line with the current date (commit hash will be filled by git-commit after commit)

If no section is outdated, skip this step.

### Step 3: Decide on ADR

**Evaluate this first** — ADR has stricter criteria, and its result gates the DevLog decision in Step 4.

Apply this principle:

> "Was a significant technical choice made between multiple viable approaches?"

If yes, invoke the `adr-creator` skill. The adr-creator will handle numbering, formatting, and file creation.

**What qualifies:**
- Chose technology/framework/pattern A over B with clear trade-offs
- Introduced new architectural patterns or significantly changed existing ones
- Made decisions that constrain future development

**What does NOT qualify:**
- Bug fixes, refactoring, feature implementation details
- Configuration changes, dependency updates

Record whether an ADR was created and what topic it covers — this is needed for Step 4.

### Step 4: Decide on DevLog

Apply this principle:

> "If the next session encounters a similar scenario, would this information help it avoid a detour?"

If yes, invoke the `devlog-creator` skill. The devlog-creator will handle numbering, formatting, and file creation.

**What qualifies:**
- Non-obvious debugging discoveries (tried X, failed because Y, solution was Z)
- Hidden behaviors of third-party services or APIs
- Environment/configuration gotchas
- Performance observations with concrete data
- Approaches that DON'T work and why
- Warnings or caveats for specific code areas

**What does NOT qualify (handled elsewhere):**
- Architectural decisions → ADR (if Step 3 already created an ADR covering the same topic, do NOT create a DevLog for that topic)
- What code was changed → commit message
- Information the code itself expresses → not needed

**De-duplication rule:** If an ADR was created in Step 3, only create a DevLog if there is a **genuinely separate** debugging insight not covered by the ADR. When in doubt, skip the DevLog.

### Step 5: Coordinate Tag

If Step 3 or Step 4 created any memory files:

1. Determine the tag name: check `git tag -l 'mem/*' --sort=-version:refname | head -1`, increment to get next `mem/NNN`
2. Communicate the tag name to sub-skills so all files created in this session share the same tag
3. Return to caller (git-commit): list of created files + tag name

If no memory files were created, return: "No memory updates needed for this session."

### Step 6: Report

Inform the user what was done:
- Which sections of arch.md were updated (if any)
- Which devlog entries were created (if any)
- Which ADR entries were created (if any)
- The tag name to be applied (if any)

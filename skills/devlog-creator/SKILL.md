---
name: devlog-creator
description: Create Development Log entries documenting coding experience and lessons learned. Use ONLY when invoked by the memory skill after it has decided a devlog entry is needed. This skill is a pure writer - it does NOT decide whether to create a devlog. It receives context about what to document and generates properly formatted devlog files in .aicoding/memory/devlog/ directory.
---

# DevLog Creator

## Overview

Pure writer skill that creates DevLog entries. Always invoked by the memory skill, never directly. Receives the session context and generates a structured devlog file capturing development experience that would help future sessions.

## Workflow

### Step 1: Determine DevLog Number

```bash
# Find existing devlogs to determine next number
Glob pattern: .aicoding/memory/devlog/[0-9]*.md

# Use next sequential three-digit number (001, 002, 003...)
```

### Step 2: Determine Memory Tag

```bash
# Find the latest mem tag to determine next number
git tag -l 'mem/*' --sort=-version:refname | head -1

# Next tag: mem/NNN (increment by 1)
# If no tags exist, use mem/001
```

If the memory skill has already provided a tag name (because an ADR is also being created in this session), use that same tag.

### Step 3: Generate DevLog Content

Analyze the conversation to extract development experience. Follow the format in `references/devlog-format.md`.

**Content Guidelines:**

1. **Title**: Concise description of the insight/lesson (not what was done, but what was learned)
2. **YAML Frontmatter**: Must include tags, modules, summary, tag
3. **Date**: Precise to the minute, format `YYYY-MM-DD HH:mm`
4. **Body sections**:
   - Context: Brief background on what triggered this insight
   - Insight/Lesson: The core knowledge to preserve
   - Implications: What future sessions should do differently because of this

**Quality Principles:**
- Focus on **non-obvious** information that code alone cannot express
- Be specific and actionable, not vague
- Keep entries concise (~50-150 lines)
- One clear insight per entry; create multiple entries if the session yielded multiple independent lessons

### Step 4: Create DevLog File

Write to `.aicoding/memory/devlog/` directory:

```bash
# Example:
Write .aicoding/memory/devlog/003-gemini-utf8-boundary.md
```

Filename format: `NNN-短横线分隔的关键词.md` (use English or pinyin for filenames).

### Step 5: Report Result

Return to the caller (memory skill):
- DevLog number and title
- File path
- Tag name used

## Critical Rules

- This skill is a **pure writer**. Never decide whether a devlog should be created.
- Never modify existing devlog files.
- Always include YAML frontmatter with all required fields.
- If multiple independent lessons exist, create multiple entries (each gets the same tag).

## Resources

- **references/devlog-format.md**: Complete format specification with examples

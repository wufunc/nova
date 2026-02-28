---
name: adr-creator
description: Create Architecture Decision Records (ADR) documenting key technical decisions. Use ONLY when invoked by the memory skill after it has decided an ADR is needed. This skill is a pure writer - it does NOT decide whether to create an ADR. It receives context about architectural decisions and generates properly formatted ADR files in .aicoding/memory/adr/ directory.
---

# ADR Creator

## Overview

Pure writer skill that creates Architecture Decision Records. Always invoked by the memory skill, never directly for decision-making. Receives the session context where architectural decisions were made and generates properly formatted ADR files.

## Workflow

### Step 1: Determine ADR Number

```bash
# List existing ADRs to find the highest number
Glob pattern: .aicoding/memory/adr/[0-9]*.md

# Use next sequential three-digit number (001, 002, 003...)
```

### Step 2: Determine Memory Tag

```bash
# Find the latest mem tag to determine next number
git tag -l 'mem/*' --sort=-version:refname | head -1

# Next tag: mem/NNN (increment by 1)
# If no tags exist, use mem/001
```

If the memory skill has already provided a tag name (because a DevLog is also being created in this session), use that same tag.

### Step 3: Generate ADR Content

Analyze the conversation to extract the architectural decision. Follow the format in `references/adr-format.md`.

**Structure**:
```markdown
---
tags: [tag1, tag2, tag3]
modules: [path/to/module1, path/to/module2]
summary: "One-line summary of the decision for Grep-based retrieval"
tag: mem/NNN
---

# ADR NNN: Concise Decision Title

## Date
YYYY-MM-DD HH:mm

## Background
- Problem description
- Why a decision was needed
- Technical constraints
- Alternative approaches considered

## Decision
- Chosen approach
- Key implementation points
- Design rationale (why this approach, why not others)

## Consequences
### Advantages
- Positive impacts

### Disadvantages
- Negative impacts and trade-offs

### Risk Mitigation (optional)
- How to reduce negative impacts

## Related Decisions
- ADR XXX: Reference to related decisions
```

**Content Guidelines**:

1. **Title** (max 10 words): Concise description of the decision
2. **YAML Frontmatter**: Must include tags, modules, summary, tag (for Grep-based retrieval)
3. **Background**: Explain the "why", list alternatives considered
4. **Decision**: State what was chosen and justify why
5. **Consequences**: Be honest about both advantages and disadvantages
6. **Related Decisions**: Reference other ADRs if applicable (use "None" if none)

**Quality Principles**:
- Explain **why** the decision was made, not just what
- List alternative approaches considered and why they were rejected
- Be honest about trade-offs and disadvantages
- Use code examples sparingly - only when they clarify key points
- Keep content concise and focused on decision logic
- Avoid implementation logs, validation details, or verification processes

### Step 4: Create ADR File

Write to `.aicoding/memory/adr/` directory:

```bash
# Example:
Write .aicoding/memory/adr/003-redis-caching-strategy.md
```

Filename format: `NNN-短横线分隔的关键词.md`

### Step 5: Report Result

Return to the caller (memory skill):
- ADR number and title
- File path
- Tag name used

## Critical Rules

- This skill is a **pure writer**. Never decide whether an ADR should be created.
- Never modify existing ADR files.
- Always include YAML frontmatter with all required fields (tags, modules, summary, tag).
- If multiple independent decisions exist, create multiple ADR entries (each gets the same tag).

## Quality Checklist

Before finalizing each ADR, verify:

- Title is concise (max 10 words) and descriptive
- Date is included
- YAML frontmatter has tags, modules, summary, tag fields
- Background explains the "why" behind the decision
- Alternative approaches are mentioned and compared
- Trade-offs are honestly presented
- Related decisions are referenced (if applicable)
- No implementation logs or validation details
- Code examples only when necessary

## Resources

- **references/adr-format.md**: Complete ADR format specification with detailed guidelines
- **assets/template.md**: ADR template structure for reference

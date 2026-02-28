# DevLog Format Specification

## File Structure

```markdown
---
tags: [tag1, tag2, tag3]
modules: [path/to/module1, path/to/module2]
summary: "One-line summary for Grep-based retrieval"
tag: mem/NNN
---

# DevLog NNN: Concise Insight Title

## Date
YYYY-MM-DD HH:mm

## Context

Brief background: what task was being worked on, what problem was encountered.
Keep to 2-5 sentences.

## Insight

The core lesson learned. This is the most important section.
Be specific, include concrete details (error messages, API behaviors, config values).
Code examples are welcome when they clarify the point.

## Implications

What should future sessions do differently:
- Specific warnings or caveats
- Recommended approaches
- Things to verify or check
```

## YAML Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| tags | Yes | Keywords for Grep retrieval. Use lowercase, include technology names, concepts, problem types. 3-8 tags. |
| modules | Yes | Relevant source code paths (relative to src/). Use the most specific path that applies. |
| summary | Yes | Single line, under 80 chars. Optimized for Grep matching. Should contain the key technical terms someone would search for. |
| tag | Yes | Git tag in format `mem/NNN`. Links this entry to its commit. |

## Naming Convention

Filename: `NNN-keywords-in-english.md`

- NNN: Three-digit sequential number
- Keywords: 2-4 English words separated by hyphens
- Examples:
  - `001-chatgpt-pow-timeout.md`
  - `002-claude-main-world-bridge.md`
  - `003-gemini-utf8-boundary.md`

## Example Entry

```markdown
---
tags: [chatgpt, sentinel, pow, auth, timeout]
modules: [contents/providers/chatgpt/auth, core/providers/chatgpt/api-client]
summary: "sentinel token returns empty proofofwork config, must skip PoW not error"
tag: mem/003
---

# DevLog 003: ChatGPT Sentinel Empty PoW Config

## Date
2026-01-15 14:32

## Context

While implementing ChatGPT API-first integration, the sentinel endpoint
`/backend-api/sentinel/chat-requirements` occasionally returns a response
where `proofofwork` is present but its `required` field is `false` and
`difficulty` is empty.

## Insight

The sentinel response has three possible states for PoW:
1. `proofofwork.required === true` with valid difficulty → compute PoW
2. `proofofwork.required === false` → skip PoW entirely
3. `proofofwork` field missing → skip PoW entirely

The original implementation only handled case 1 and 3, treating case 2
as an error (because difficulty was empty). The fix: check `required`
field before attempting PoW computation.

## Implications

- When modifying ChatGPT auth flow, always check `proofofwork.required` first
- Don't assume sentinel response fields are always present or always valid
- Similar defensive patterns may be needed for future API changes
```

## Anti-patterns

**Too vague:**
> "Gemini streaming has some issues with parsing"

**Too verbose (implementation log):**
> "First I tried approach A, then B, then C, and finally D worked..."

**Overlaps with ADR:**
> "We decided to use API-first strategy because..." (this is a decision, not an experience)

**Code can express it:**
> "The function takes two parameters: provider and message" (just read the code)

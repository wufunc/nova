# ADR Format Specification

## Standard Structure

```markdown
---
tags: [tag1, tag2, tag3]
modules: [path/to/module1, path/to/module2]
summary: "One-line summary for Grep-based retrieval"
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

## YAML Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| tags | Yes | Keywords for Grep retrieval. Use lowercase, include technology names, concepts, patterns. 3-8 tags. |
| modules | Yes | Relevant source code paths (relative to src/). Use the most specific path that applies. |
| summary | Yes | Single line, under 80 chars. Optimized for Grep matching. Should contain key technical terms. |
| tag | Yes | Git tag in format `mem/NNN`. Links this entry to its commit. |

## Format Notes

- **Title**: Concise, max 10 words, describes the decision
- **Date**: The date and time (to the minute) the decision was made, format `YYYY-MM-DD HH:mm`
- **Background**: Explain the "why" — problem, constraints, alternatives considered
- **Decision**: What was chosen, implementation key points, why this over alternatives
- **Consequences**: Honest listing of advantages and disadvantages. Optional risk mitigation.
- **Related Decisions**: Reference other ADRs. Use "None" if no related decisions.

## Key Principles

- ADR records **applied** decisions
- Focus on **decision logic**, not implementation logs or validation
- Must include **related decisions** references (if any)

## Writing Guidelines

### DO
- Explain "why" the decision was made
- List alternative approaches and why they were rejected
- Be honest about trade-offs
- Use code examples only when necessary to clarify key points
- Keep content concise

### DON'T
- Write vague reasoning ("because it's better")
- Hide negative impacts
- Include implementation logs or verification processes
- Create ADRs for minor changes (bug fixes, refactoring, config changes)

## Numbering Rules

- Use three-digit numbers: 001, 002, 003...
- Sequential by creation time
- Never reuse numbers even if an ADR is deleted

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
`difficulty` is empty string.

The original implementation only handled two states — PoW required (compute it)
and PoW field missing (skip it). When `required` was `false` but the field
existed, the code tried to compute PoW with an empty difficulty, causing a
cryptographic error that surfaced as a vague "auth failed" message.

## Insight

The sentinel response has three possible states for PoW:

1. `proofofwork.required === true` with valid `difficulty` → compute PoW
2. `proofofwork.required === false` (difficulty may be empty) → skip PoW entirely
3. `proofofwork` field missing entirely → skip PoW entirely

The fix was straightforward: check `proofofwork.required` before attempting
any PoW computation.

```typescript
// Before (buggy)
if (sentinel.proofofwork) {
  const pow = computePoW(sentinel.proofofwork.difficulty); // crashes on empty string
}

// After (fixed)
if (sentinel.proofofwork?.required) {
  const pow = computePoW(sentinel.proofofwork.difficulty);
}
```

This pattern (field present but "disabled" via a boolean sub-field) appears
in other sentinel response sections too (`turnstile`, `arkose`).

## Implications

- When modifying ChatGPT auth flow, always check the `required` sub-field
  before processing any sentinel section
- Don't assume that a field's presence means it's active — ChatGPT uses
  a `required: boolean` pattern to enable/disable features
- Similar defensive checks should be applied to `turnstile` and `arkose`
  sections in the sentinel response
- If "auth failed" errors appear intermittently (not every request), suspect
  conditional sentinel fields before investigating token issues

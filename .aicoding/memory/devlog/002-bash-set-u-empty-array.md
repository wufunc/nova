---
tags: [bash, set-u, array-expansion, installer, uninstaller, portability]
modules: [install.sh, uninstall.sh]
summary: "Under set -u, empty array iteration can fail without :- fallback"
tag: mem/003
---

# DevLog 002: Bash set -u Empty Array Expansion

## Date
2026-02-28 23:59

## Context

After adding multi-agent install/uninstall support, running
`bash install.sh --agents claude,codex,cursor` failed at runtime with:
`SELECTED_AGENTS[@]: unbound variable`.

The scripts use `set -euo pipefail`, and the failure happened before any
agent was appended when de-duplicating target lists.

## Insight

With `set -u` enabled, iterating an empty array via
`for x in "${ARRAY[@]}"` can raise an unbound-variable error in this shell
environment. Using the fallback expansion form
`"${ARRAY[@]:-}"` keeps the loop safe when the array has no elements yet.

This affected both `install.sh` and `uninstall.sh` in
`append_unique_agent()`.

## Implications

- For scripts that use `set -u`, prefer `"${ARRAY[@]:-}"` when empty arrays
  are possible at runtime
- Validate both install and uninstall flows after shell-safety refactors
- Keep the fix symmetric across paired scripts to avoid drift

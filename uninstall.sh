#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────
# aicoding-memory uninstaller
# Removes memory skills from Claude Code
# ──────────────────────────────────────────────────────

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARKER_START="<!-- aicoding-memory:start -->"
MARKER_END="<!-- aicoding-memory:end -->"

SKILL_NAMES=("memory" "git-commit" "adr-creator" "devlog-creator")

# Colors
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' NC=''
fi

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# ── Step 1: Remove skills ───────────────────────────
for skill in "${SKILL_NAMES[@]}"; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    rm -rf "$SKILLS_DIR/$skill"
    info "Removed skill: $skill"
  else
    warn "Skill not found: $skill (already removed)"
  fi
done

# ── Step 2: Remove CLAUDE.md snippet ────────────────
if [ -f "$CLAUDE_MD" ] && grep -q "$MARKER_START" "$CLAUDE_MD"; then
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"

  # Remove trailing blank lines
  sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$CLAUDE_MD.tmp" > "$CLAUDE_MD"
  rm -f "$CLAUDE_MD.tmp"

  # If CLAUDE.md is now empty, remove it
  if [ ! -s "$CLAUDE_MD" ]; then
    rm -f "$CLAUDE_MD"
    info "Removed empty CLAUDE.md"
  else
    info "Removed memory config from CLAUDE.md"
  fi
else
  warn "No memory config found in CLAUDE.md"
fi

# ── Done ─────────────────────────────────────────────
echo ""
info "Uninstall complete!"
echo ""
echo "Note: Project-level memory data (.aicoding/memory/) was NOT removed."
echo "Delete it manually in each project if you no longer need it."

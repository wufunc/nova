#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────
# aicoding-memory installer
# Installs memory skills for Claude Code
# ──────────────────────────────────────────────────────

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARKER_START="<!-- aicoding-memory:start -->"
MARKER_END="<!-- aicoding-memory:end -->"

SKILL_NAMES=("memory" "git-commit" "adr-creator" "devlog-creator")

# Colors (disabled if not a terminal)
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
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Determine source directory ──────────────────────
# If running from a cloned repo, use local files.
# If piped from curl, clone to a temp directory first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"

if [ -d "$SCRIPT_DIR/skills" ] && [ -f "$SCRIPT_DIR/templates/claude-md-snippet.md" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
  CLEANUP_DIR=""
else
  # Remote install mode: clone repo to temp dir
  REPO_URL="https://github.com/anthropic-lab/aicoding-memory.git"
  CLEANUP_DIR="$(mktemp -d)"
  echo "Cloning aicoding-memory..."
  git clone --depth 1 "$REPO_URL" "$CLEANUP_DIR" 2>/dev/null || error "Failed to clone repository. Check your network connection."
  SOURCE_DIR="$CLEANUP_DIR"
fi

cleanup() {
  if [ -n "$CLEANUP_DIR" ] && [ -d "$CLEANUP_DIR" ]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

# ── Step 1: Check Claude Code installation ──────────
if [ ! -d "$CLAUDE_DIR" ]; then
  error "Claude Code not found (~/.claude/ does not exist). Please install Claude Code first."
fi
info "Claude Code detected"

# ── Step 2: Create skills directory ──────────────────
mkdir -p "$SKILLS_DIR"

# ── Step 3: Copy skills ─────────────────────────────
for skill in "${SKILL_NAMES[@]}"; do
  if [ -d "$SOURCE_DIR/skills/$skill" ]; then
    rm -rf "$SKILLS_DIR/$skill"
    cp -r "$SOURCE_DIR/skills/$skill" "$SKILLS_DIR/$skill"
    info "Installed skill: $skill"
  else
    warn "Skill not found in source: $skill (skipped)"
  fi
done

# ── Step 4: Update CLAUDE.md ────────────────────────
SNIPPET_FILE="$SOURCE_DIR/templates/claude-md-snippet.md"

if [ ! -f "$SNIPPET_FILE" ]; then
  error "Template file not found: templates/claude-md-snippet.md"
fi

SNIPPET_CONTENT="$(cat "$SNIPPET_FILE")"

if [ -f "$CLAUDE_MD" ]; then
  if grep -q "$MARKER_START" "$CLAUDE_MD"; then
    # Replace existing block (upgrade)
    # Use awk to replace content between markers
    awk -v start="$MARKER_START" -v end="$MARKER_END" -v content="$SNIPPET_CONTENT" '
      $0 == start { print content; skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"
    mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
    info "Updated existing memory config in CLAUDE.md"
  else
    # Append
    echo "" >> "$CLAUDE_MD"
    echo "$SNIPPET_CONTENT" >> "$CLAUDE_MD"
    info "Appended memory config to CLAUDE.md"
  fi
else
  # Create new file
  echo "$SNIPPET_CONTENT" > "$CLAUDE_MD"
  info "Created CLAUDE.md with memory config"
fi

# ── Done ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Installed skills:"
for skill in "${SKILL_NAMES[@]}"; do
  echo "  - $skill"
done
echo ""
echo "Usage:"
echo "  Start a Claude Code session — memory recall runs automatically"
echo "  Use /git-commit to commit with automatic memory updates"
echo ""
echo "Optional: create .aicoding/constitution.md in your projects"
echo "to define project-level principles."

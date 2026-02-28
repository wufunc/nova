#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────
# aicoding-memory installer
# Installs memory skills for Claude Code, Codex, and Cursor
# ──────────────────────────────────────────────────────

MARKER_START="<!-- aicoding-memory:start -->"
MARKER_END="<!-- aicoding-memory:end -->"

SKILL_NAMES=("memory" "git-commit" "adr-creator" "devlog-creator")
SUPPORTED_AGENTS=("claude" "codex" "cursor")
SELECTED_AGENTS=()
INSTALLED_AGENTS=()

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

usage() {
  cat <<'EOF'
Usage: bash install.sh [--agents claude,codex,cursor]

Options:
  --agents   Comma-separated list of target agents.
             Default: auto-detect installed agents.
  -h, --help Show this help.
EOF
}

normalize_agent() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

agent_dir() {
  case "$1" in
    claude) echo "$HOME/.claude" ;;
    codex) echo "$HOME/.codex" ;;
    cursor) echo "$HOME/.cursor" ;;
    *) return 1 ;;
  esac
}

agent_instruction_file() {
  case "$1" in
    claude) echo "$(agent_dir "$1")/CLAUDE.md" ;;
    codex) echo "$(agent_dir "$1")/AGENTS.md" ;;
    cursor) echo "$(agent_dir "$1")/rules/aicoding-memory.mdc" ;;
    *) return 1 ;;
  esac
}

agent_template_file() {
  case "$1" in
    claude) echo "$SOURCE_DIR/templates/claude-md-snippet.md" ;;
    codex) echo "$SOURCE_DIR/templates/codex-agents-snippet.md" ;;
    cursor) echo "$SOURCE_DIR/templates/cursor-rule-snippet.mdc" ;;
    *) return 1 ;;
  esac
}

append_unique_agent() {
  local candidate="$1"
  local existing=""
  for existing in "${SELECTED_AGENTS[@]:-}"; do
    if [ "$existing" = "$candidate" ]; then
      return
    fi
  done
  SELECTED_AGENTS+=("$candidate")
}

validate_agent() {
  local candidate="$1"
  local allowed=""
  for allowed in "${SUPPORTED_AGENTS[@]}"; do
    if [ "$allowed" = "$candidate" ]; then
      return 0
    fi
  done
  return 1
}

select_agents() {
  local agents_arg="$1"
  local token=""
  local candidate=""

  if [ -n "$agents_arg" ]; then
    local old_ifs="$IFS"
    IFS=','
    for token in $agents_arg; do
      candidate="$(normalize_agent "$token")"
      if [ -z "$candidate" ]; then
        continue
      fi
      if ! validate_agent "$candidate"; then
        error "Unsupported agent: $candidate (supported: claude,codex,cursor)"
      fi
      append_unique_agent "$candidate"
    done
    IFS="$old_ifs"
  else
    for candidate in "${SUPPORTED_AGENTS[@]}"; do
      if [ -d "$(agent_dir "$candidate")" ]; then
        append_unique_agent "$candidate"
      fi
    done
  fi

  if [ "${#SELECTED_AGENTS[@]}" -eq 0 ]; then
    error "No target agents selected. Install at least one of ~/.claude, ~/.codex, ~/.cursor or pass --agents."
  fi
}

upsert_marked_block() {
  local target_file="$1"
  local snippet_file="$2"
  local snippet_content=""

  if [ ! -f "$snippet_file" ]; then
    error "Template file not found: $snippet_file"
  fi

  snippet_content="$(cat "$snippet_file")"
  mkdir -p "$(dirname "$target_file")"

  if [ -f "$target_file" ]; then
    if grep -q "$MARKER_START" "$target_file"; then
      awk -v start="$MARKER_START" -v end="$MARKER_END" -v content="$snippet_content" '
        $0 == start { print content; skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
      ' "$target_file" > "$target_file.tmp"
      mv "$target_file.tmp" "$target_file"
    else
      if [ -s "$target_file" ]; then
        echo "" >> "$target_file"
      fi
      echo "$snippet_content" >> "$target_file"
    fi
  else
    echo "$snippet_content" > "$target_file"
  fi
}

install_skills_for_agent() {
  local agent="$1"
  local root_dir=""
  local skills_dir=""
  local instruction_file=""
  local template_file=""
  local skill=""

  root_dir="$(agent_dir "$agent")"
  if [ ! -d "$root_dir" ]; then
    warn "$agent not found (${root_dir} does not exist), skipped"
    return
  fi

  skills_dir="$root_dir/skills"
  mkdir -p "$skills_dir"

  for skill in "${SKILL_NAMES[@]}"; do
    if [ -d "$SOURCE_DIR/skills/$skill" ]; then
      rm -rf "$skills_dir/$skill"
      cp -r "$SOURCE_DIR/skills/$skill" "$skills_dir/$skill"
      info "[$agent] Installed skill: $skill"
    else
      warn "[$agent] Skill not found in source: $skill (skipped)"
    fi
  done

  instruction_file="$(agent_instruction_file "$agent")"
  template_file="$(agent_template_file "$agent")"

  if [ "$agent" = "cursor" ]; then
    mkdir -p "$(dirname "$instruction_file")"
    cp "$template_file" "$instruction_file"
    info "[$agent] Installed rule: $instruction_file"
  else
    upsert_marked_block "$instruction_file" "$template_file"
    info "[$agent] Updated instructions: $instruction_file"
  fi

  INSTALLED_AGENTS+=("$agent")
}

# ── Parse arguments ─────────────────────────────────
AGENTS_ARG=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --agents)
      shift
      [ "$#" -gt 0 ] || error "--agents requires a comma-separated value"
      AGENTS_ARG="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1 (use --help for usage)"
      ;;
  esac
  shift
done

# ── Determine source directory ──────────────────────
# If running from a cloned repo, use local files.
# If piped from curl, clone to a temp directory first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"

if [ -d "$SCRIPT_DIR/skills" ] \
  && [ -f "$SCRIPT_DIR/templates/claude-md-snippet.md" ] \
  && [ -f "$SCRIPT_DIR/templates/codex-agents-snippet.md" ] \
  && [ -f "$SCRIPT_DIR/templates/cursor-rule-snippet.mdc" ]; then
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

# ── Step 1: Select agents ───────────────────────────
select_agents "$AGENTS_ARG"

# ── Step 2: Install per agent ───────────────────────
for agent in "${SELECTED_AGENTS[@]}"; do
  install_skills_for_agent "$agent"
done

if [ "${#INSTALLED_AGENTS[@]}" -eq 0 ]; then
  error "No agents were installed. Check your local agent directories."
fi

# ── Done ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Installed agents:"
for agent in "${INSTALLED_AGENTS[@]}"; do
  echo "  - $agent"
done
echo ""
echo "Usage:"
echo "  Start a supported agent session — memory recall runs automatically"
echo "  Use /git-commit to commit with automatic memory updates"
echo ""
echo "Tip:"
echo "  Use --agents to limit targets, e.g. bash install.sh --agents codex,cursor"
echo ""
echo "Optional: create .aicoding/constitution.md in your projects"
echo "to define project-level principles."

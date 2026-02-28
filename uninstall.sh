#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────
# aicoding-memory uninstaller
# Removes memory skills from Claude Code, Codex, and Cursor
# ──────────────────────────────────────────────────────

MARKER_START="<!-- aicoding-memory:start -->"
MARKER_END="<!-- aicoding-memory:end -->"

SKILL_NAMES=("memory" "git-commit" "adr-creator" "devlog-creator")
SUPPORTED_AGENTS=("claude" "codex" "cursor")
SELECTED_AGENTS=()
PROCESSED_AGENTS=()

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

usage() {
  cat <<'EOF'
Usage: bash uninstall.sh [--agents claude,codex,cursor]

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
        echo "[✗] Unsupported agent: $candidate (supported: claude,codex,cursor)" >&2
        exit 1
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
}

remove_marked_block() {
  local target_file="$1"
  local label="$2"

  if [ -f "$target_file" ] && grep -q "$MARKER_START" "$target_file"; then
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$target_file" > "$target_file.tmp"

    # Remove trailing blank lines
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$target_file.tmp" > "$target_file"
    rm -f "$target_file.tmp"

    if [ ! -s "$target_file" ]; then
      rm -f "$target_file"
      info "Removed empty $label"
    else
      info "Removed memory config from $label"
    fi
  else
    warn "No memory config found in $label"
  fi
}

uninstall_for_agent() {
  local agent="$1"
  local root_dir=""
  local skills_dir=""
  local instruction_file=""
  local skill=""

  root_dir="$(agent_dir "$agent")"
  if [ ! -d "$root_dir" ]; then
    warn "$agent not found (${root_dir} does not exist), skipped"
    return
  fi

  skills_dir="$root_dir/skills"
  for skill in "${SKILL_NAMES[@]}"; do
    if [ -d "$skills_dir/$skill" ]; then
      rm -rf "$skills_dir/$skill"
      info "[$agent] Removed skill: $skill"
    else
      warn "[$agent] Skill not found: $skill (already removed)"
    fi
  done

  instruction_file="$(agent_instruction_file "$agent")"
  if [ "$agent" = "cursor" ]; then
    if [ -f "$instruction_file" ]; then
      rm -f "$instruction_file"
      info "[$agent] Removed rule file: $instruction_file"
    else
      warn "[$agent] Rule file not found: $instruction_file"
    fi
  elif [ "$agent" = "claude" ]; then
    remove_marked_block "$instruction_file" "CLAUDE.md"
  else
    remove_marked_block "$instruction_file" "AGENTS.md"
  fi

  PROCESSED_AGENTS+=("$agent")
}

# ── Parse arguments ─────────────────────────────────
AGENTS_ARG=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --agents)
      shift
      [ "$#" -gt 0 ] || { echo "[✗] --agents requires a comma-separated value" >&2; exit 1; }
      AGENTS_ARG="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[✗] Unknown option: $1 (use --help for usage)" >&2
      exit 1
      ;;
  esac
  shift
done

# ── Step 1: Select agents ───────────────────────────
select_agents "$AGENTS_ARG"
if [ "${#SELECTED_AGENTS[@]}" -eq 0 ]; then
  warn "No installed agents found. Nothing to uninstall."
  exit 0
fi

# ── Step 2: Uninstall per agent ─────────────────────
for agent in "${SELECTED_AGENTS[@]}"; do
  uninstall_for_agent "$agent"
done

# ── Done ─────────────────────────────────────────────
echo ""
info "Uninstall complete!"
echo ""
if [ "${#PROCESSED_AGENTS[@]}" -gt 0 ]; then
  echo "Processed agents:"
  for agent in "${PROCESSED_AGENTS[@]}"; do
    echo "  - $agent"
  done
  echo ""
fi
echo "Note: Project-level memory data (.aicoding/memory/) was NOT removed."
echo "Delete it manually in each project if you no longer need it."

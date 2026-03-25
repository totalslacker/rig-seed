#!/usr/bin/env bash
# recap.sh — Summarize the latest journal entry.
#
# Extracts the most recent session from JOURNAL.md and displays it.
# Useful for quick status checks: what was the last session about?
#
# Usage: ./scripts/recap.sh [options] [directory]
#
# Options:
#   -s, --short    Only show Goal and Next Steps lines
#   -d, --diff     Show the git diff from the latest session's commits
#   --json         Output as JSON object
#   --color        Force colored output
#   --no-color     Disable colored output
#   -h, --help     Show this help message
#
# Exit codes:
#   0 — recap displayed successfully
#   1 — no journal found or no entries

set -euo pipefail

# --- Parse arguments ---
short=false
diff_mode=false
json=false
use_color=auto
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: $(basename "$0") [options] [directory]"
      echo ""
      echo "Summarize the latest journal entry."
      echo ""
      echo "Options:"
      echo "  -s, --short    Only show Goal and Next Steps lines"
      echo "  -d, --diff     Show the git diff from the latest session's commits"
      echo "  --json         Output as JSON object"
      echo "  --color        Force colored output"
      echo "  --no-color     Disable colored output"
      echo "  -h, --help     Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory      Path to the rig-seed project root (default: current directory)"
      exit 0
      ;;
    -s|--short) short=true ;;
    -d|--diff) diff_mode=true ;;
    --json) json=true ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    *) dir="$arg" ;;
  esac
done

dir="${dir:-.}"

# --- Color setup ---
setup_colors() {
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    # shellcheck disable=SC2034  # Color vars used in output sections
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    RED='\033[31m' GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' BOLD='\033[1m' RESET='\033[0m'
  else
    # shellcheck disable=SC2034  # Color vars used in output sections
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
setup_colors

# --- Validation ---
journal="$dir/JOURNAL.md"
if [ ! -f "$journal" ]; then
  echo "Error: $journal not found" >&2
  exit 1
fi

# --- Extract latest entry ---
# The latest entry starts at the first "## Day" or "## Session" header
# and ends at the next "---" separator or another "## Day/Session" header.

entry=""
in_entry=false
header=""
while IFS= read -r line; do
  if [[ "$line" =~ ^##\ (Day|Session)\  ]]; then
    if [ "$in_entry" = true ]; then
      # Hit the next entry — stop
      break
    fi
    in_entry=true
    header="$line"
    entry="$line"
    continue
  fi

  if [ "$in_entry" = true ]; then
    # Stop at --- separator (but not the one immediately after the header area)
    if [[ "$line" == "---" ]]; then
      break
    fi
    entry="$entry
$line"
  fi
done < "$journal"

if [ -z "$entry" ]; then
  echo "Error: no journal entries found in $journal" >&2
  exit 1
fi

# --- Extract components ---
# Goal line: **Goal**: ...
goal=$(echo "$entry" | grep -oP '^\*\*Goal\*\*:\s*\K.*' | head -1)

# Next Steps: everything after **Next Steps**: until end
next_steps=$(echo "$entry" | sed -n '/^\*\*Next Steps\*\*/,$ p' | tail -n +1 | head -1 | sed 's/^\*\*Next Steps\*\*:\s*//')

# Session info from header
session_info="$header"

# --- Diff mode ---
if [ "$diff_mode" = true ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for --diff mode" >&2
    exit 1
  fi

  # Extract session number from header (e.g., "## Day 9 — Session 27 (2026-03-24)")
  session_num=$(echo "$header" | grep -oP 'Session \K[0-9]+' || true)
  if [ -z "$session_num" ]; then
    echo "Error: could not extract session number from journal header" >&2
    exit 1
  fi

  # Find commits from this session by matching commit messages
  # Session commits typically contain "Session N" in the message
  session_commits=$(cd "$dir" && git log --oneline --all --grep="Session $session_num" 2>/dev/null) || true

  if [ -z "$session_commits" ]; then
    # Fallback: use the date from the header to find commits
    session_date=$(echo "$header" | grep -oP '\d{4}-\d{2}-\d{2}' || true)
    if [ -n "$session_date" ]; then
      session_commits=$(cd "$dir" && git log --oneline --after="${session_date}T00:00:00" --before="${session_date}T23:59:59" 2>/dev/null) || true
    fi
  fi

  if [ -z "$session_commits" ]; then
    printf '%b\n' "${YELLOW}No commits found for Session $session_num${RESET}"
    exit 0
  fi

  printf '%b\n' "${BOLD}${session_info##\#\# }${RESET}"
  echo ""
  printf '%b\n' "${CYAN}Commits:${RESET}"
  echo "$session_commits"
  echo ""

  # Show the combined diff: from the parent of the oldest commit to the newest
  oldest_sha=$(echo "$session_commits" | tail -1 | cut -d' ' -f1)
  newest_sha=$(echo "$session_commits" | head -1 | cut -d' ' -f1)
  parent_sha=$(cd "$dir" && git rev-parse "${oldest_sha}^" 2>/dev/null || echo "$oldest_sha")

  printf '%b\n' "${CYAN}Diff (${oldest_sha}..${newest_sha}):${RESET}"
  echo ""
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    (cd "$dir" && git diff --stat "$parent_sha".."$newest_sha" 2>/dev/null) || true
    echo ""
    (cd "$dir" && git diff "$parent_sha".."$newest_sha" 2>/dev/null) || true
  else
    (cd "$dir" && git diff --stat --color=always "$parent_sha".."$newest_sha" 2>/dev/null) || true
    echo ""
    (cd "$dir" && git diff --color=always "$parent_sha".."$newest_sha" 2>/dev/null) || true
  fi
  exit 0
fi

# --- Output ---
if [ "$json" = true ]; then
  # Escape strings for JSON
  json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
  }

  printf '{"header":"%s","goal":"%s","next_steps":"%s","full_entry":"%s"}\n' \
    "$(json_escape "$header")" \
    "$(json_escape "${goal:-}")" \
    "$(json_escape "${next_steps:-}")" \
    "$(json_escape "$entry")"
  exit 0
fi

if [ "$short" = true ]; then
  printf '%b\n' "${BOLD}${session_info##\#\# }${RESET}"
  echo ""
  if [ -n "$goal" ]; then
    printf '%b\n' "${CYAN}Goal:${RESET} $goal"
  fi
  if [ -n "$next_steps" ]; then
    printf '%b\n' "${CYAN}Next:${RESET} $next_steps"
  fi
  exit 0
fi

# Full entry display
printf '%b\n' "${CYAN}=== Latest Session ===${RESET}"
echo ""

# Print the entry with colored header
first=true
while IFS= read -r line; do
  if [ "$first" = true ] && [[ "$line" =~ ^##\  ]]; then
    printf '%b\n' "${BOLD}${line}${RESET}"
    first=false
  elif [[ "$line" =~ ^\*\*Goal\*\*: ]]; then
    printf '%b\n' "${CYAN}${line}${RESET}"
  elif [[ "$line" =~ ^\*\*Next\ Steps\*\*: ]]; then
    printf '%b\n' "${CYAN}${line}${RESET}"
  else
    echo "$line"
  fi
done <<< "$entry"

echo ""
printf '%b\n' "${CYAN}========================${RESET}"

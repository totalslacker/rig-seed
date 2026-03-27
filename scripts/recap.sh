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
#   --since N      Show the last N sessions (default: 1)
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
since=1
dir=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "Usage: $(basename "$0") [options] [directory]"
      echo ""
      echo "Summarize the latest journal entry (or last N entries with --since)."
      echo ""
      echo "Options:"
      echo "  -s, --short    Only show Goal and Next Steps lines"
      echo "  -d, --diff     Show the git diff from the latest session's commits"
      echo "  --since N      Show the last N sessions (default: 1)"
      echo "  --json         Output as JSON object"
      echo "  --color        Force colored output"
      echo "  --no-color     Disable colored output"
      echo "  -h, --help     Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory      Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Examples:"
      echo "  ./scripts/recap.sh                # Latest session"
      echo "  ./scripts/recap.sh --since 3      # Last 3 sessions"
      echo "  ./scripts/recap.sh --since 5 -s   # Last 5 sessions, goals only"
      exit 0
      ;;
    -s|--short) short=true ;;
    -d|--diff) diff_mode=true ;;
    --since)
      shift
      if [ $# -eq 0 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: --since requires a numeric argument" >&2
        exit 1
      fi
      since="$1"
      ;;
    --since=*)
      since="${1#*=}"
      if ! [[ "$since" =~ ^[0-9]+$ ]]; then
        echo "Error: --since requires a numeric argument" >&2
        exit 1
      fi
      ;;
    --json) json=true ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    *) dir="$1" ;;
  esac
  shift
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

# --- Extract entries ---
# Each entry starts at a "## Day" or "## Session" header
# and ends at the next "---" separator or another "## Day/Session" header.

entries=()
current_entry=""
in_entry=false
entries_found=0

while IFS= read -r line; do
  if [[ "$line" =~ ^##\ (Day|Session)\  ]]; then
    if [ "$in_entry" = true ]; then
      entries+=("$current_entry")
      entries_found=$((entries_found + 1))
      if [ "$entries_found" -ge "$since" ]; then
        break
      fi
    fi
    in_entry=true
    current_entry="$line"
    continue
  fi

  if [ "$in_entry" = true ]; then
    if [[ "$line" == "---" ]]; then
      entries+=("$current_entry")
      entries_found=$((entries_found + 1))
      in_entry=false
      if [ "$entries_found" -ge "$since" ]; then
        break
      fi
      continue
    fi
    current_entry="$current_entry
$line"
  fi
done < "$journal"

# Capture final entry if still in progress
if [ "$in_entry" = true ] && [ "$entries_found" -lt "$since" ]; then
  entries+=("$current_entry")
  entries_found=$((entries_found + 1))
fi

if [ "${#entries[@]}" -eq 0 ]; then
  echo "Error: no journal entries found in $journal" >&2
  exit 1
fi

# For single-entry compatibility, set entry/header/goal/next_steps from first entry
entry="${entries[0]}"
header=$(echo "$entry" | head -1)

# --- Extract components from first entry ---
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

# --- Helper: extract goal from entry ---
extract_goal() {
  echo "$1" | grep -oP '^\*\*Goal\*\*:\s*\K.*' | head -1
}

# --- Helper: extract next_steps from entry ---
extract_next_steps() {
  echo "$1" | sed -n '/^\*\*Next Steps\*\*/,$ p' | tail -n +1 | head -1 | sed 's/^\*\*Next Steps\*\*:\s*//'
}

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

  if [ "${#entries[@]}" -eq 1 ]; then
    printf '{"header":"%s","goal":"%s","next_steps":"%s","full_entry":"%s"}\n' \
      "$(json_escape "$header")" \
      "$(json_escape "${goal:-}")" \
      "$(json_escape "${next_steps:-}")" \
      "$(json_escape "$entry")"
  else
    printf '['
    first_json=true
    for e in "${entries[@]}"; do
      if [ "$first_json" = true ]; then
        first_json=false
      else
        printf ','
      fi
      e_header=$(echo "$e" | head -1)
      e_goal=$(extract_goal "$e")
      e_next=$(extract_next_steps "$e")
      printf '{"header":"%s","goal":"%s","next_steps":"%s","full_entry":"%s"}' \
        "$(json_escape "$e_header")" \
        "$(json_escape "${e_goal:-}")" \
        "$(json_escape "${e_next:-}")" \
        "$(json_escape "$e")"
    done
    printf ']\n'
  fi
  exit 0
fi

if [ "$short" = true ]; then
  for e in "${entries[@]}"; do
    e_header=$(echo "$e" | head -1)
    e_goal=$(extract_goal "$e")
    e_next=$(extract_next_steps "$e")
    printf '%b\n' "${BOLD}${e_header##\#\# }${RESET}"
    if [ -n "$e_goal" ]; then
      printf '%b\n' "  ${CYAN}Goal:${RESET} $e_goal"
    fi
    if [ -n "$e_next" ]; then
      printf '%b\n' "  ${CYAN}Next:${RESET} $e_next"
    fi
    echo ""
  done
  exit 0
fi

# Full entry display
if [ "${#entries[@]}" -eq 1 ]; then
  printf '%b\n' "${CYAN}=== Latest Session ===${RESET}"
else
  printf '%b\n' "${CYAN}=== Last ${#entries[@]} Sessions ===${RESET}"
fi
echo ""

for e in "${entries[@]}"; do
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
  done <<< "$e"
  echo ""
  printf '%b\n' "${CYAN}---${RESET}"
  echo ""
done

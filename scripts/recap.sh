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
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    RED='\033[31m' GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' BOLD='\033[1m' RESET='\033[0m'
  else
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

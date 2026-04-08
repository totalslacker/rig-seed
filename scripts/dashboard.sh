#!/usr/bin/env bash
# dashboard.sh — Aggregate evolution metrics across multiple rig-seed projects.
#
# Usage: dashboard.sh [-q|--quiet] [-h|--help] [--json] [--summary] [--format=FORMAT] [--projects DIR] [--depth N] <dir1> [dir2] ...
#
# Outputs a table comparing evolution metrics across projects. Each argument
# should be a path to a rig-seed project root (containing SESSION_COUNT,
# JOURNAL.md, etc.).
#
# Options:
#   -q, --quiet       Machine-readable key=value output (alias for --format=kv)
#   --json            JSON output (alias for --format=json)
#   --summary         One-line-per-project compact output
#   --format=FORMAT   Output format: table (default), csv, json, kv
#   --projects DIR    Auto-discover rig-seed projects under DIR (recursive)
#   --depth N         Limit --projects search depth (default: unlimited)
#   --color           Force colored output
#   --no-color        Disable colored output
#   -h, --help        Show this help message
#
# Exit codes:
#   0 — metrics computed successfully
#   1 — no valid projects found

set -euo pipefail

# --- Options ---

format=table
summary=false
use_color=auto
projects_dir=""
max_depth=""
dirs=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      cat <<'HELP'
Usage: dashboard.sh [options] [dir1] [dir2] ...

Aggregate evolution metrics across multiple rig-seed projects.

Options:
  -q, --quiet       Machine-readable key=value output (alias for --format=kv)
  --json            JSON array output (alias for --format=json)
  --summary         One-line-per-project compact output
  --format=FORMAT   Output format: table (default), csv, json, kv
  --projects DIR    Auto-discover rig-seed projects under DIR (recursive)
  --depth N         Limit --projects search depth (default: unlimited)
  --color           Force colored output
  --no-color        Disable colored output
  -h, --help        Show this help message

Arguments:
  dir1, dir2    Paths to rig-seed project roots

Examples:
  # Compare two projects
  ./dashboard.sh ~/projects/my-cli ~/projects/my-api

  # Auto-discover all rig-seed projects under a directory
  ./dashboard.sh --projects ~/projects

  # Limit auto-discovery to 3 directory levels deep
  ./dashboard.sh --projects ~/projects --depth 3

  # JSON output for all rigs in a Gas Town workspace
  ./dashboard.sh --format=json ~/gt/*/repo

  # CSV output for spreadsheets
  ./dashboard.sh --format=csv ~/gt/*/repo

  # Machine-readable for scripting
  ./dashboard.sh --format=kv ~/projects/*/

  # Quick one-line-per-project overview
  ./dashboard.sh --summary ~/gt/*/repo
HELP
      exit 0
      ;;
    -q|--quiet)
      format=kv
      shift
      ;;
    --json)
      format=json
      shift
      ;;
    --format=*)
      format="${1#*=}"
      case "$format" in
        table|csv|json|kv) ;;
        *)
          echo "Error: unknown format '$format' (expected: table, csv, json, kv)" >&2
          exit 1
          ;;
      esac
      shift
      ;;
    --summary|-s)
      summary=true
      shift
      ;;
    --projects)
      shift
      if [ $# -eq 0 ]; then
        echo "Error: --projects requires a directory argument." >&2
        exit 1
      fi
      projects_dir="$1"
      shift
      ;;
    --depth)
      shift
      if [ $# -eq 0 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: --depth requires a numeric argument." >&2
        exit 1
      fi
      max_depth="$1"
      shift
      ;;
    --depth=*)
      max_depth="${1#*=}"
      if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Error: --depth requires a numeric argument." >&2
        exit 1
      fi
      shift
      ;;
    --color)
      use_color=always
      shift
      ;;
    --no-color)
      use_color=never
      shift
      ;;
    *)
      dirs+=("$1")
      shift
      ;;
  esac
done

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

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# --- Auto-discover rig-seed projects ---
if [ -n "$projects_dir" ]; then
  if [ ! -d "$projects_dir" ]; then
    echo "Error: --projects directory does not exist: $projects_dir" >&2
    exit 1
  fi
  # Find directories containing SESSION_COUNT (rig-seed marker)
  depth_args=()
  if [ -n "$max_depth" ]; then
    depth_args=(-maxdepth "$max_depth")
  fi
  while IFS= read -r session_file; do
    dirs+=("$(dirname "$session_file")")
  done < <(find "$projects_dir" "${depth_args[@]}" -name SESSION_COUNT -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sort)
  if [ ${#dirs[@]} -eq 0 ]; then
    echo "Error: No rig-seed projects found under $projects_dir" >&2
    exit 1
  fi
fi

if [ ${#dirs[@]} -eq 0 ]; then
  echo "Error: No project directories specified." >&2
  echo "Usage: dashboard.sh [options] <dir1> [dir2] ..." >&2
  echo "  Use --projects DIR to auto-discover rig-seed projects." >&2
  exit 1
fi

# --- Helpers ---

gather_metrics() {
  local dir="$1"
  local name
  name=$(basename "$dir")

  # SESSION_COUNT
  local session_counter=0
  if [ -f "$dir/SESSION_COUNT" ]; then
    session_counter=$(tr -d '[:space:]' < "$dir/SESSION_COUNT")
    [[ "$session_counter" =~ ^[0-9]+$ ]] || session_counter=0
  fi

  # DAY_COUNT
  local day_count=0
  if [ -f "$dir/DAY_COUNT" ]; then
    day_count=$(tr -d '[:space:]' < "$dir/DAY_COUNT")
    [[ "$day_count" =~ ^[0-9]+$ ]] || day_count=0
  fi

  # Journal entry count
  local journal_entries=0
  if [ -f "$dir/JOURNAL.md" ]; then
    journal_entries=$(grep -c '^## \(Day\|Session\) ' "$dir/JOURNAL.md" 2>/dev/null) || journal_entries=0
  fi

  # Roadmap progress
  local roadmap_done=0
  local roadmap_todo=0
  if [ -f "$dir/ROADMAP.md" ]; then
    roadmap_done=$(grep -c '^\- \[x\]' "$dir/ROADMAP.md" 2>/dev/null) || roadmap_done=0
    roadmap_todo=$(grep -c '^\- \[ \]' "$dir/ROADMAP.md" 2>/dev/null) || roadmap_todo=0
  fi
  local roadmap_total=$((roadmap_done + roadmap_todo))
  local roadmap_pct=0
  if [ "$roadmap_total" -gt 0 ]; then
    roadmap_pct=$((roadmap_done * 100 / roadmap_total))
  fi

  # Learnings
  local learnings=0
  if [ -f "$dir/LEARNINGS.md" ]; then
    learnings=$(grep -c '^### ' "$dir/LEARNINGS.md" 2>/dev/null) || learnings=0
  fi

  # Git metrics
  local total_commits=0
  local last_commit="n/a"
  local age_days=0
  local sessions_per_week="n/a"

  if git -C "$dir" rev-parse --git-dir &>/dev/null; then
    total_commits=$(git -C "$dir" rev-list --count HEAD 2>/dev/null || echo "0")
    if [ "$total_commits" -gt 0 ]; then
      last_commit=$(git -C "$dir" log -1 --format='%ci' 2>/dev/null | cut -d' ' -f1)
      local first_epoch last_epoch
      first_epoch=$(git -C "$dir" log --reverse --format='%ct' 2>/dev/null | head -1 || true)
      last_epoch=$(git -C "$dir" log -1 --format='%ct' 2>/dev/null)
      if [ -n "$first_epoch" ] && [ -n "$last_epoch" ]; then
        age_days=$(( (last_epoch - first_epoch) / 86400 ))
        [ "$age_days" -eq 0 ] && age_days=1
        local weeks=$(( age_days / 7 ))
        [ "$weeks" -eq 0 ] && weeks=1
        if [ "$journal_entries" -gt 0 ]; then
          sessions_per_week=$(echo "scale=1; $journal_entries / $weeks" | bc 2>/dev/null || echo "n/a")
        fi
      fi
    fi
  fi

  # Output based on format
  if [ "$summary" = true ]; then
    local status_icon="${GREEN}●${RESET}"
    if [ "$session_counter" -eq 0 ]; then
      status_icon="${YELLOW}○${RESET}"
    fi
    printf '%b %s  %dd/%ds  %d/%d roadmap (%d%%)  last: %s\n' \
      "$status_icon" "$name" "$day_count" "$session_counter" \
      "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$last_commit"
    return
  fi
  case "$format" in
    json)
      printf '{"name":"%s","day_count":%d,"sessions":%d,"commits":%d,"roadmap_done":%d,"roadmap_total":%d,"roadmap_pct":%d,"learnings":%d,"last_commit":"%s","velocity":"%s"}' \
        "$(json_escape "$name")" "$day_count" "$session_counter" "$total_commits" \
        "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$learnings" \
        "$(json_escape "$last_commit")" "$(json_escape "$sessions_per_week")"
      ;;
    csv)
      printf '%s,%d,%d,%d,%d,%d,%d,%d,%s,%s\n' \
        "$(csv_escape "$name")" "$day_count" "$session_counter" "$total_commits" \
        "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$learnings" \
        "$(csv_escape "$last_commit")" "$(csv_escape "$sessions_per_week")"
      ;;
    kv)
      echo "project=$name"
      echo "day_count=$day_count"
      echo "sessions=$session_counter"
      echo "commits=$total_commits"
      echo "roadmap_done=$roadmap_done"
      echo "roadmap_total=$roadmap_total"
      echo "roadmap_pct=$roadmap_pct"
      echo "learnings=$learnings"
      echo "last_commit=$last_commit"
      echo "velocity=$sessions_per_week"
      echo "---"
      ;;
    *)
      printf "  %-20s %4d %8d %7d %6d/%-4d %4d%% %8d   %-10s %s\n" \
        "$name" "$day_count" "$session_counter" "$total_commits" \
        "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$learnings" \
        "$last_commit" "$sessions_per_week"
      ;;
  esac
}

# --- Main ---

valid_count=0

if [ "$format" = "json" ]; then
  echo "["
fi

if [ "$format" = "csv" ]; then
  echo "name,day_count,sessions,commits,roadmap_done,roadmap_total,roadmap_pct,learnings,last_commit,velocity"
fi

first=true
for dir in "${dirs[@]}"; do
  if [ ! -f "$dir/SESSION_COUNT" ] && [ ! -f "$dir/JOURNAL.md" ]; then
    if [ "$format" = "table" ] && [ "$summary" = false ]; then
      echo "  Skipping $dir (not a rig-seed project)" >&2
    fi
    continue
  fi
  valid_count=$((valid_count + 1))

  if [ "$format" = "json" ]; then
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    gather_metrics "$dir"
  elif [ "$summary" = true ]; then
    gather_metrics "$dir"
    first=false
  elif [ "$format" = "csv" ] || [ "$format" = "kv" ]; then
    gather_metrics "$dir"
    first=false
  else
    if [ "$first" = true ]; then
      printf '%b\n' "${CYAN}=== Multi-Project Evolution Dashboard ===${RESET}"
      echo ""
      printf "  ${BOLD}%-20s %4s %8s %7s %11s %5s %8s   %-10s %s${RESET}\n" \
        "PROJECT" "DAYS" "SESSIONS" "COMMITS" "ROADMAP" "PCT" "LEARNS" "LAST" "VEL/WK"
      printf "  %-20s %4s %8s %7s %11s %5s %8s   %-10s %s\n" \
        "-------" "----" "--------" "-------" "-------" "---" "------" "----" "------"
      first=false
    fi
    gather_metrics "$dir"
  fi
done

if [ "$format" = "json" ]; then
  echo ""
  echo "]"
fi

if [ "$valid_count" -eq 0 ]; then
  echo "Error: No valid rig-seed projects found in the specified directories." >&2
  exit 1
fi

# Summary (human-readable only)
if [ "$format" = "table" ] && [ "$summary" = false ] && [ "$valid_count" -gt 1 ]; then
  echo ""
  echo "  $valid_count projects tracked"
  echo ""
  printf '%b\n' "${CYAN}================================${RESET}"
fi

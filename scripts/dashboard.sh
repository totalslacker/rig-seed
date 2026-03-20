#!/usr/bin/env bash
# dashboard.sh — Aggregate evolution metrics across multiple rig-seed projects.
#
# Usage: dashboard.sh [-q|--quiet] [-h|--help] [--json] <dir1> [dir2] ...
#
# Outputs a table comparing evolution metrics across projects. Each argument
# should be a path to a rig-seed project root (containing SESSION_COUNT,
# JOURNAL.md, etc.).
#
# Options:
#   -q, --quiet   Machine-readable key=value output
#   --json        JSON output (one object per project)
#   -h, --help    Show this help message
#
# Exit codes:
#   0 — metrics computed successfully
#   1 — no valid projects found

set -euo pipefail

# --- Options ---

quiet=false
json=false
dirs=()

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<'HELP'
Usage: dashboard.sh [options] <dir1> [dir2] ...

Aggregate evolution metrics across multiple rig-seed projects.

Options:
  -q, --quiet   Machine-readable key=value output (one block per project)
  --json        JSON array output (for dashboards and APIs)
  -h, --help    Show this help message

Arguments:
  dir1, dir2    Paths to rig-seed project roots

Examples:
  # Compare two projects
  ./dashboard.sh ~/projects/my-cli ~/projects/my-api

  # JSON output for all rigs in a Gas Town workspace
  ./dashboard.sh --json ~/gt/*/repo

  # Machine-readable for scripting
  ./dashboard.sh -q ~/projects/*/
HELP
      exit 0
      ;;
    -q|--quiet)
      quiet=true
      ;;
    --json)
      json=true
      ;;
    *)
      dirs+=("$arg")
      ;;
  esac
done

if [ ${#dirs[@]} -eq 0 ]; then
  echo "Error: No project directories specified." >&2
  echo "Usage: dashboard.sh [options] <dir1> [dir2] ..." >&2
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
    journal_entries=$(grep -c '^## \(Day\|Session\) ' "$dir/JOURNAL.md" 2>/dev/null || echo "0")
  fi

  # Roadmap progress
  local roadmap_done=0
  local roadmap_todo=0
  if [ -f "$dir/ROADMAP.md" ]; then
    roadmap_done=$(grep -c '^\- \[x\]' "$dir/ROADMAP.md" 2>/dev/null || echo "0")
    roadmap_todo=$(grep -c '^\- \[ \]' "$dir/ROADMAP.md" 2>/dev/null || echo "0")
  fi
  local roadmap_total=$((roadmap_done + roadmap_todo))
  local roadmap_pct=0
  if [ "$roadmap_total" -gt 0 ]; then
    roadmap_pct=$((roadmap_done * 100 / roadmap_total))
  fi

  # Learnings
  local learnings=0
  if [ -f "$dir/LEARNINGS.md" ]; then
    learnings=$(grep -c '^### ' "$dir/LEARNINGS.md" 2>/dev/null || echo "0")
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
      first_epoch=$(git -C "$dir" log --reverse --format='%ct' 2>/dev/null | head -1)
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
  if [ "$json" = true ]; then
    printf '{"name":"%s","day_count":%d,"sessions":%d,"commits":%d,"roadmap_done":%d,"roadmap_total":%d,"roadmap_pct":%d,"learnings":%d,"last_commit":"%s","velocity":"%s"}' \
      "$name" "$day_count" "$session_counter" "$total_commits" \
      "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$learnings" \
      "$last_commit" "$sessions_per_week"
  elif [ "$quiet" = true ]; then
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
  else
    printf "  %-20s %4d %8d %7d %6d/%-4d %4d%% %8d   %-10s %s\n" \
      "$name" "$day_count" "$session_counter" "$total_commits" \
      "$roadmap_done" "$roadmap_total" "$roadmap_pct" "$learnings" \
      "$last_commit" "$sessions_per_week"
  fi
}

# --- Main ---

valid_count=0

if [ "$json" = true ]; then
  echo "["
fi

first=true
for dir in "${dirs[@]}"; do
  if [ ! -f "$dir/SESSION_COUNT" ] && [ ! -f "$dir/JOURNAL.md" ]; then
    if [ "$quiet" = false ] && [ "$json" = false ]; then
      echo "  Skipping $dir (not a rig-seed project)" >&2
    fi
    continue
  fi
  valid_count=$((valid_count + 1))

  if [ "$json" = true ]; then
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    gather_metrics "$dir"
  else
    if [ "$first" = true ] && [ "$quiet" = false ]; then
      echo "=== Multi-Project Evolution Dashboard ==="
      echo ""
      printf "  %-20s %4s %8s %7s %11s %5s %8s   %-10s %s\n" \
        "PROJECT" "DAYS" "SESSIONS" "COMMITS" "ROADMAP" "PCT" "LEARNS" "LAST" "VEL/WK"
      printf "  %-20s %4s %8s %7s %11s %5s %8s   %-10s %s\n" \
        "-------" "----" "--------" "-------" "-------" "---" "------" "----" "------"
      first=false
    fi
    gather_metrics "$dir"
  fi
done

if [ "$json" = true ]; then
  echo ""
  echo "]"
fi

if [ "$valid_count" -eq 0 ]; then
  echo "Error: No valid rig-seed projects found in the specified directories." >&2
  exit 1
fi

# Summary (human-readable only)
if [ "$quiet" = false ] && [ "$json" = false ] && [ "$valid_count" -gt 1 ]; then
  echo ""
  echo "  $valid_count projects tracked"
  echo ""
  echo "================================"
fi

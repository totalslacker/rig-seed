#!/usr/bin/env bash
# metrics.sh — Summarize evolution history for a rig-seed project.
#
# Usage: ./metrics.sh [-q|--quiet] [-h|--help] [directory]
#
# Outputs:
#   - Total sessions and current day count
#   - Average commits per session
#   - Files added/changed over time
#   - Roadmap progress (checked vs unchecked items)
#   - Learnings count
#   - Session velocity (sessions per week)
#
# Exit codes:
#   0 — metrics computed successfully
#   1 — not a valid rig-seed project

set -euo pipefail

# --- Options ---

quiet=false
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: metrics.sh [options] [directory]"
      echo ""
      echo "Summarize evolution history for a rig-seed project."
      echo ""
      echo "Options:"
      echo "  -q, --quiet   Machine-readable output (key=value pairs)"
      echo "  -h, --help    Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory     Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Examples:"
      echo "  ./metrics.sh              # Human-readable summary"
      echo "  ./metrics.sh -q           # key=value output for scripting"
      echo "  ./metrics.sh ~/my-project # Check a different project"
      exit 0
      ;;
    -q|--quiet)
      quiet=true
      ;;
    *)
      dir="$arg"
      ;;
  esac
done

dir="${dir:-.}"

# --- Validation ---

if [ ! -f "$dir/DAY_COUNT" ] || [ ! -f "$dir/JOURNAL.md" ]; then
  echo "Error: $dir does not appear to be a rig-seed project (missing DAY_COUNT or JOURNAL.md)" >&2
  exit 1
fi

# --- Helpers ---

print_metric() {
  local label="$1"
  local key="$2"
  local value="$3"
  if [ "$quiet" = true ]; then
    echo "${key}=${value}"
  else
    printf "  %-30s %s\n" "$label" "$value"
  fi
}

# --- Gather metrics ---

# DAY_COUNT
day_count=$(tr -d '[:space:]' < "$dir/DAY_COUNT")
if [[ ! "$day_count" =~ ^[0-9]+$ ]]; then
  day_count=0
fi

# Session count from journal
session_count=$(grep -c '^## \(Day\|Session\) ' "$dir/JOURNAL.md" 2>/dev/null || echo "0")

# Git metrics (only if in a git repo)
total_commits=0
first_commit_date=""
last_commit_date=""
age_days=0
commits_per_session="n/a"
sessions_per_week="n/a"
files_in_repo=0
total_lines=0

if git -C "$dir" rev-parse --git-dir &>/dev/null; then
  total_commits=$(git -C "$dir" rev-list --count HEAD 2>/dev/null || echo "0")

  if [ "$total_commits" -gt 0 ]; then
    first_commit_date=$(git -C "$dir" log --reverse --format='%ci' | head -1 | cut -d' ' -f1)
    last_commit_date=$(git -C "$dir" log -1 --format='%ci' | cut -d' ' -f1)

    first_epoch=$(git -C "$dir" log --reverse --format='%ct' | head -1)
    last_epoch=$(git -C "$dir" log -1 --format='%ct')
    age_days=$(( (last_epoch - first_epoch) / 86400 ))
    if [ "$age_days" -eq 0 ]; then
      age_days=1
    fi

    if [ "$session_count" -gt 0 ]; then
      commits_per_session=$(( total_commits / session_count ))
      weeks=$(( age_days / 7 ))
      if [ "$weeks" -eq 0 ]; then
        weeks=1
      fi
      sessions_per_week=$(echo "scale=1; $session_count / $weeks" | bc 2>/dev/null || echo "n/a")
    fi
  fi

  files_in_repo=$(git -C "$dir" ls-files | wc -l | tr -d ' ')
  total_lines=$(git -C "$dir" ls-files -z | xargs -0 cat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
fi

# Roadmap progress
roadmap_checked=0
roadmap_unchecked=0
if [ -f "$dir/ROADMAP.md" ]; then
  roadmap_checked=$(grep -c '^\- \[x\]' "$dir/ROADMAP.md" 2>/dev/null || echo "0")
  roadmap_unchecked=$(grep -c '^\- \[ \]' "$dir/ROADMAP.md" 2>/dev/null || echo "0")
fi
roadmap_total=$((roadmap_checked + roadmap_unchecked))

# Learnings count
learnings_count=0
if [ -f "$dir/LEARNINGS.md" ]; then
  learnings_count=$(grep -c '^### ' "$dir/LEARNINGS.md" 2>/dev/null || echo "0")
fi

# --- Output ---

if [ "$quiet" = false ]; then
  echo "=== Evolution Metrics ==="
  echo ""
  echo "Progress:"
fi

print_metric "Day count:" "day_count" "$day_count"
print_metric "Total sessions:" "session_count" "$session_count"
print_metric "Total commits:" "total_commits" "$total_commits"
print_metric "Commits per session:" "commits_per_session" "$commits_per_session"

if [ "$quiet" = false ]; then
  echo ""
  echo "Velocity:"
fi

print_metric "Project age (days):" "age_days" "$age_days"
print_metric "Sessions per week:" "sessions_per_week" "$sessions_per_week"
print_metric "First commit:" "first_commit_date" "${first_commit_date:-n/a}"
print_metric "Last commit:" "last_commit_date" "${last_commit_date:-n/a}"

if [ "$quiet" = false ]; then
  echo ""
  echo "Codebase:"
fi

print_metric "Files in repo:" "files_in_repo" "$files_in_repo"
print_metric "Total lines:" "total_lines" "$total_lines"

if [ "$quiet" = false ]; then
  echo ""
  echo "Roadmap:"
fi

print_metric "Items completed:" "roadmap_checked" "$roadmap_checked"
print_metric "Items remaining:" "roadmap_unchecked" "$roadmap_unchecked"
if [ "$roadmap_total" -gt 0 ]; then
  pct=$(( roadmap_checked * 100 / roadmap_total ))
  print_metric "Completion:" "roadmap_pct" "${pct}%"
fi

if [ "$quiet" = false ]; then
  echo ""
  echo "Knowledge:"
fi

print_metric "Learnings recorded:" "learnings_count" "$learnings_count"

if [ "$quiet" = false ]; then
  echo ""
  echo "================================"
fi

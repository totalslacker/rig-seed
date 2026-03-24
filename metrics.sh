#!/usr/bin/env bash
# metrics.sh — Summarize evolution history for a rig-seed project.
#
# Usage: ./metrics.sh [-q|--quiet] [-p|--plan] [--format=FORMAT] [-h|--help] [directory]
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

format=table
plan=false
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: metrics.sh [options] [directory]"
      echo ""
      echo "Summarize evolution history for a rig-seed project."
      echo ""
      echo "Options:"
      echo "  -q, --quiet           Machine-readable output (alias for --format=kv)"
      echo "  --format=FORMAT       Output format: table (default), kv, csv, json"
      echo "  -p, --plan            Show planning-relevant info (unchecked roadmap, next steps)"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Formats:"
      echo "  table   Human-readable aligned output (default)"
      echo "  kv      Key=value pairs, one per line (same as -q)"
      echo "  csv     Comma-separated with header row"
      echo "  json    JSON object with all metrics"
      echo ""
      echo "Arguments:"
      echo "  directory     Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Examples:"
      echo "  ./metrics.sh                   # Human-readable summary"
      echo "  ./metrics.sh -q                # key=value output for scripting"
      echo "  ./metrics.sh --format=json     # JSON output"
      echo "  ./metrics.sh --format=csv      # CSV for spreadsheets"
      echo "  ./metrics.sh -p                # Planning-focused output"
      echo "  ./metrics.sh ~/my-project      # Check a different project"
      exit 0
      ;;
    -q|--quiet)
      format=kv
      ;;
    --format=*)
      format="${arg#*=}"
      case "$format" in
        table|kv|csv|json) ;;
        *)
          echo "Error: unknown format '$format' (expected: table, kv, csv, json)" >&2
          exit 1
          ;;
      esac
      ;;
    -p|--plan)
      plan=true
      ;;
    *)
      dir="$arg"
      ;;
  esac
done

dir="${dir:-.}"

# --- Validation ---

if [ ! -f "$dir/SESSION_COUNT" ] || [ ! -f "$dir/JOURNAL.md" ]; then
  echo "Error: $dir does not appear to be a rig-seed project (missing SESSION_COUNT or JOURNAL.md)" >&2
  exit 1
fi

# --- Helpers ---

# Accumulate metrics for csv/json output
metric_keys=()
metric_values=()

print_metric() {
  local label="$1"
  local key="$2"
  local value="$3"
  # Accumulate for csv/json
  metric_keys+=("$key")
  metric_values+=("$value")
  # Print immediately for table/kv formats
  if [ "$format" = "kv" ]; then
    echo "${key}=${value}"
  elif [ "$format" = "table" ]; then
    printf "  %-30s %s\n" "$label" "$value"
  fi
  # csv and json are emitted at the end
}

# --- Gather metrics ---

# SESSION_COUNT
session_counter=$(tr -d '[:space:]' < "$dir/SESSION_COUNT")
if [[ ! "$session_counter" =~ ^[0-9]+$ ]]; then
  session_counter=0
fi

# DAY_COUNT
day_count=0
if [ -f "$dir/DAY_COUNT" ]; then
  day_count=$(tr -d '[:space:]' < "$dir/DAY_COUNT")
  if [[ ! "$day_count" =~ ^[0-9]+$ ]]; then
    day_count=0
  fi
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
    first_commit_date=$(git -C "$dir" log --reverse --format='%ci' | head -1 | cut -d' ' -f1 || true)
    last_commit_date=$(git -C "$dir" log -1 --format='%ci' | cut -d' ' -f1)

    first_epoch=$(git -C "$dir" log --reverse --format='%ct' | head -1 || true)
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
  total_lines=$(git -C "$dir" ls-files -z | xargs -0 wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
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

section() {
  if [ "$format" = "table" ]; then
    echo "$@"
  fi
}

section "=== Evolution Metrics ==="
section ""
section "Progress:"

print_metric "Day count:" "day_count" "$day_count"
print_metric "Session count:" "session_counter" "$session_counter"
print_metric "Total journal entries:" "session_count" "$session_count"
print_metric "Total commits:" "total_commits" "$total_commits"
print_metric "Commits per session:" "commits_per_session" "$commits_per_session"

section ""
section "Velocity:"

print_metric "Project age (days):" "age_days" "$age_days"
print_metric "Sessions per week:" "sessions_per_week" "$sessions_per_week"
print_metric "First commit:" "first_commit_date" "${first_commit_date:-n/a}"
print_metric "Last commit:" "last_commit_date" "${last_commit_date:-n/a}"

section ""
section "Codebase:"

print_metric "Files in repo:" "files_in_repo" "$files_in_repo"
print_metric "Total lines:" "total_lines" "$total_lines"

section ""
section "Roadmap:"

print_metric "Items completed:" "roadmap_checked" "$roadmap_checked"
print_metric "Items remaining:" "roadmap_unchecked" "$roadmap_unchecked"
if [ "$roadmap_total" -gt 0 ]; then
  pct=$(( roadmap_checked * 100 / roadmap_total ))
  print_metric "Completion:" "roadmap_pct" "${pct}%"
fi

section ""
section "Knowledge:"

print_metric "Learnings recorded:" "learnings_count" "$learnings_count"

section ""
section "================================"

# --- CSV output ---
if [ "$format" = "csv" ]; then
  # Header row
  csv_header=""
  for key in "${metric_keys[@]}"; do
    if [ -n "$csv_header" ]; then
      csv_header="$csv_header,$key"
    else
      csv_header="$key"
    fi
  done
  echo "$csv_header"
  # Data row
  csv_row=""
  for value in "${metric_values[@]}"; do
    # Quote values containing commas or percent signs
    if [ -n "$csv_row" ]; then
      csv_row="$csv_row,$value"
    else
      csv_row="$value"
    fi
  done
  echo "$csv_row"
fi

# --- JSON output ---
if [ "$format" = "json" ]; then
  printf '{'
  first=true
  for i in "${!metric_keys[@]}"; do
    key="${metric_keys[$i]}"
    value="${metric_values[$i]}"
    if [ "$first" = true ]; then
      first=false
    else
      printf ','
    fi
    # Emit numbers as bare values, strings as quoted
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf '"%s":%s' "$key" "$value"
    elif [[ "$value" =~ ^[0-9]+%$ ]]; then
      # Strip % for JSON, store as number
      printf '"%s":%s' "$key" "${value%\%}"
    else
      printf '"%s":"%s"' "$key" "$value"
    fi
  done
  printf '}\n'
fi

# --- Planning output (--plan) ---

if [ "$plan" = true ]; then
  section ""
  section "=== Planning Context ==="

  # Unchecked roadmap items by phase
  if [ -f "$dir/ROADMAP.md" ]; then
    section ""
    section "Unchecked roadmap items:"
    current_phase=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^##\  ]]; then
        current_phase="${line## }"
        current_phase="${current_phase#\#\# }"
      elif [[ "$line" =~ ^-\ \[\ \] ]]; then
        item="${line#- \[ \] }"
        if [ "$format" = "kv" ]; then
          echo "roadmap_unchecked_item=${item}"
        elif [ "$format" = "table" ]; then
          echo "  [$current_phase] $item"
        fi
      fi
    done < "$dir/ROADMAP.md"
  fi

  # NEXT_STEPS.md content
  if [ -f "$dir/NEXT_STEPS.md" ]; then
    # Count items by category
    priority_count=$(grep -c '^\- \[ \]' "$dir/NEXT_STEPS.md" 2>/dev/null || echo "0")
    section ""
    section "Next steps ($priority_count items):"
    print_metric "Next steps items:" "next_steps_count" "$priority_count"

    current_section=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^##\  ]]; then
        current_section="${line#\#\# }"
      elif [[ "$line" =~ ^-\ \[.\] ]]; then
        item="${line#- \[?\] }"
        # Extract checked status
        if [[ "$line" =~ ^-\ \[x\] ]]; then
          status="done"
        else
          status="open"
          item="${line#- \[ \] }"
        fi
        if [ "$format" = "kv" ]; then
          echo "next_step_${status}=${item}"
        elif [ "$format" = "table" ]; then
          if [ "$status" = "done" ]; then
            echo "  [x] ($current_section) $item"
          else
            echo "  [ ] ($current_section) $item"
          fi
        fi
      fi
    done < "$dir/NEXT_STEPS.md"
  else
    if [ "$format" = "kv" ]; then
      echo "next_steps_count=0"
    elif [ "$format" = "table" ]; then
      echo ""
      echo "NEXT_STEPS.md: not found"
    fi
  fi

  # Open GitHub issues count (if gh is available)
  if command -v gh &>/dev/null && git -C "$dir" rev-parse --git-dir &>/dev/null; then
    open_issues=$(gh issue list --state open --limit 100 --json number 2>/dev/null | grep -c '"number"' || echo "0")
    print_metric "Open GitHub issues:" "open_issues" "$open_issues"
  fi

  section ""
  section "================================"
fi

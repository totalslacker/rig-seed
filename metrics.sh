#!/usr/bin/env bash
# metrics.sh — Summarize evolution history for a rig-seed project.
#
# Usage: ./metrics.sh [-q|--quiet] [-s|--summary] [-p|--plan [--since N]] [-w|--watch [secs]] [--format=FORMAT] [--color|--no-color] [-h|--help] [directory]
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
plan_since=0
summary=false
watch=false
watch_interval=60
use_color=auto
dir=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "Usage: metrics.sh [options] [directory]"
      echo ""
      echo "Summarize evolution history for a rig-seed project."
      echo ""
      echo "Options:"
      echo "  -q, --quiet           Machine-readable output (alias for --format=kv)"
      echo "  -s, --summary         One-line summary output"
      echo "  --format=FORMAT       Output format: table (default), kv, csv, json"
      echo "  -p, --plan            Show planning-relevant info (unchecked roadmap, next steps)"
      echo "  --since N             With --plan: show journal goals from last N sessions"
      echo "  -w, --watch [seconds] Re-run continuously (default: 60s)"
      echo "  --color               Force colored output"
      echo "  --no-color            Disable colored output"
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
      echo "  ./metrics.sh -s                # One-line quick summary"
      echo "  ./metrics.sh -q                # key=value output for scripting"
      echo "  ./metrics.sh --format=json     # JSON output"
      echo "  ./metrics.sh --format=csv      # CSV for spreadsheets"
      echo "  ./metrics.sh -p                # Planning-focused output"
      echo "  ./metrics.sh -p --since 3      # Planning context with last 3 session goals"
      echo "  ./metrics.sh -w 30             # Refresh every 30 seconds"
      echo "  ./metrics.sh ~/my-project      # Check a different project"
      exit 0
      ;;
    -q|--quiet)
      format=kv
      shift
      ;;
    -s|--summary)
      summary=true
      shift
      ;;
    --format=*)
      format="${1#*=}"
      case "$format" in
        table|kv|csv|json) ;;
        *)
          echo "Error: unknown format '$format' (expected: table, kv, csv, json)" >&2
          exit 1
          ;;
      esac
      shift
      ;;
    -p|--plan)
      plan=true
      shift
      ;;
    --since)
      shift
      if [ $# -eq 0 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: --since requires a numeric argument" >&2
        exit 1
      fi
      plan_since="$1"
      shift
      ;;
    -w|--watch)
      watch=true
      shift
      # If next arg is a number, use it as the interval
      if [ $# -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        watch_interval="$1"
        shift
      fi
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
      dir="$1"
      shift
      ;;
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
    # shellcheck disable=SC2034
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
setup_colors

# --- Validation ---

if [ ! -f "$dir/SESSION_COUNT" ] || [ ! -f "$dir/JOURNAL.md" ]; then
  echo "Error: $dir does not appear to be a rig-seed project (missing SESSION_COUNT or JOURNAL.md)" >&2
  exit 1
fi

# --- Metrics function (for --watch support) ---

run_metrics() {

# --- Helpers ---

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  # Strip other control characters
  printf '%s' "$s" | tr -d '\000-\010\013\014\016-\037'
}

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
    printf "  %-30s ${BOLD}%s${RESET}\n" "$label" "$value"
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

# --- Summary output (--summary) ---

if [ "$summary" = true ]; then
  # One-line output: Day D | Session S | Roadmap X/Y (Z%) | N commits | last: DATE
  if [ "$roadmap_total" -gt 0 ]; then
    pct=$(( roadmap_checked * 100 / roadmap_total ))
    roadmap_info="roadmap ${roadmap_checked}/${roadmap_total} (${pct}%)"
  else
    roadmap_info="roadmap n/a"
  fi
  printf '%b\n' "Day ${BOLD}${day_count}${RESET} | Session ${BOLD}${session_counter}${RESET} | ${roadmap_info} | ${total_commits} commits | last: ${last_commit_date:-n/a}"
  return 0 2>/dev/null || exit 0
fi

# --- Output ---

section() {
  if [ "$format" = "table" ]; then
    printf '%b\n' "$@"
  fi
}

section "${CYAN}=== Evolution Metrics ===${RESET}"
if [ "$watch" = true ]; then
  section "  ($(date '+%Y-%m-%d %H:%M:%S'))"
fi
section ""
section "${BOLD}Progress:${RESET}"

print_metric "Day count:" "day_count" "$day_count"
print_metric "Session count:" "session_counter" "$session_counter"
print_metric "Total journal entries:" "session_count" "$session_count"
print_metric "Total commits:" "total_commits" "$total_commits"
print_metric "Commits per session:" "commits_per_session" "$commits_per_session"

section ""
section "${BOLD}Velocity:${RESET}"

print_metric "Project age (days):" "age_days" "$age_days"
print_metric "Sessions per week:" "sessions_per_week" "$sessions_per_week"
print_metric "First commit:" "first_commit_date" "${first_commit_date:-n/a}"
print_metric "Last commit:" "last_commit_date" "${last_commit_date:-n/a}"

section ""
section "${BOLD}Codebase:${RESET}"

print_metric "Files in repo:" "files_in_repo" "$files_in_repo"
print_metric "Total lines:" "total_lines" "$total_lines"

section ""
section "${BOLD}Roadmap:${RESET}"

print_metric "Items completed:" "roadmap_checked" "$roadmap_checked"
print_metric "Items remaining:" "roadmap_unchecked" "$roadmap_unchecked"
if [ "$roadmap_total" -gt 0 ]; then
  pct=$(( roadmap_checked * 100 / roadmap_total ))
  print_metric "Completion:" "roadmap_pct" "${pct}%"
fi

section ""
section "${BOLD}Knowledge:${RESET}"

print_metric "Learnings recorded:" "learnings_count" "$learnings_count"

section ""
section "${CYAN}================================${RESET}"

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
    # Emit numbers as bare values, strings as quoted (with escaping)
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf '"%s":%s' "$key" "$value"
    elif [[ "$value" =~ ^[0-9]+%$ ]]; then
      # Strip % for JSON, store as number
      printf '"%s":%s' "$key" "${value%\%}"
    else
      printf '"%s":"%s"' "$key" "$(json_escape "$value")"
    fi
  done
  # Don't close JSON yet if --plan will append more data
  if [ "$plan" != true ]; then
    printf '}\n'
  fi
fi

# --- Planning output (--plan) ---

if [ "$plan" = true ]; then
  section ""
  section "${CYAN}=== Planning Context ===${RESET}"

  # Collect plan items for JSON/CSV output
  plan_roadmap_items=()
  plan_next_steps=()
  plan_recent_goals=()

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
        plan_roadmap_items+=("[$current_phase] $item")
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
        plan_next_steps+=("${status}:($current_section) $item")
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

  # Recent session goals (--since N)
  if [ "$plan_since" -gt 0 ] && [ -f "$dir/JOURNAL.md" ]; then
    section ""
    section "Recent session goals (last $plan_since):"
    count=0
    while IFS= read -r line; do
      if [[ "$line" =~ ^##\ (Day|Session)\  ]]; then
        count=$((count + 1))
        if [ "$count" -gt "$plan_since" ]; then
          break
        fi
        current_header="$line"
        goal_line=""
      elif [ "$count" -gt 0 ] && [ "$count" -le "$plan_since" ]; then
        if [[ "$line" =~ ^\*\*Goal\*\*: ]]; then
          goal_line="${line#\*\*Goal\*\*: }"
          header_short="${current_header#\#\# }"
          plan_recent_goals+=("${header_short}: ${goal_line}")
          if [ "$format" = "kv" ]; then
            echo "recent_goal_${count}=${header_short}: ${goal_line}"
          elif [ "$format" = "table" ]; then
            echo "  ${header_short}"
            echo "    Goal: ${goal_line}"
          fi
        fi
      fi
    done < "$dir/JOURNAL.md"
  fi

  # Open GitHub issues count (if gh is available)
  if command -v gh &>/dev/null && git -C "$dir" rev-parse --git-dir &>/dev/null; then
    open_issues=$(gh issue list --state open --limit 100 --json number 2>/dev/null | grep -c '"number"' || echo "0")
    print_metric "Open GitHub issues:" "open_issues" "$open_issues"
  fi

  section ""
  section "${CYAN}================================${RESET}"

  # --- Plan CSV output ---
  if [ "$format" = "csv" ]; then
    if [ ${#plan_roadmap_items[@]} -gt 0 ]; then
      echo ""
      echo "roadmap_unchecked_phase,roadmap_unchecked_item"
      for entry in "${plan_roadmap_items[@]}"; do
        # Extract phase from "[Phase] item" format
        phase="${entry%%] *}"
        phase="${phase#[}"
        item="${entry#*] }"
        printf '%s,%s\n' "\"$phase\"" "\"$item\""
      done
    fi
    if [ ${#plan_next_steps[@]} -gt 0 ]; then
      echo ""
      echo "next_step_status,next_step_section,next_step_item"
      for entry in "${plan_next_steps[@]}"; do
        status="${entry%%:*}"
        rest="${entry#*:}"
        # Section is between first ( and last ) before the item text
        section_name="${rest#(}"
        section_name="${section_name%%) *}"
        item="${rest#*) }"
        printf '%s,%s,%s\n' "\"$status\"" "\"$section_name\"" "\"$item\""
      done
    fi
    if [ ${#plan_recent_goals[@]} -gt 0 ]; then
      echo ""
      echo "recent_goal_session,recent_goal_text"
      for entry in "${plan_recent_goals[@]}"; do
        session_label="${entry%%: *}"
        goal_text="${entry#*: }"
        printf '%s,%s\n' "\"$session_label\"" "\"$goal_text\""
      done
    fi
  fi

  # --- Plan JSON output ---
  if [ "$format" = "json" ]; then
    printf ',\"plan\":{'

    # Roadmap unchecked items
    printf '\"roadmap_unchecked\":['
    first=true
    for entry in "${plan_roadmap_items[@]}"; do
      if [ "$first" = true ]; then first=false; else printf ','; fi
      printf '"%s"' "$(json_escape "$entry")"
    done
    printf ']'

    # Next steps
    printf ',\"next_steps\":['
    first=true
    for entry in "${plan_next_steps[@]}"; do
      if [ "$first" = true ]; then first=false; else printf ','; fi
      status="${entry%%:*}"
      rest="${entry#*:}"
      printf '{"status":"%s","item":"%s"}' "$status" "$(json_escape "$rest")"
    done
    printf ']'

    # Recent goals
    if [ ${#plan_recent_goals[@]} -gt 0 ]; then
      printf ',\"recent_goals\":['
      first=true
      for entry in "${plan_recent_goals[@]}"; do
        if [ "$first" = true ]; then first=false; else printf ','; fi
        printf '"%s"' "$(json_escape "$entry")"
      done
      printf ']'
    fi

    printf '}'  # close plan object
    printf '}\n'  # close outer JSON object
  fi
fi

# Close JSON if --plan was set but format isn't json (no-op for other formats)
# Also handle edge case: --plan with json format already closed above
if [ "$plan" != true ] && [ "$format" = "json" ]; then
  : # already closed
fi

} # end run_metrics

# --- Main ---

if [ "$watch" = true ]; then
  echo "Watching $dir every ${watch_interval}s (Ctrl+C to stop)"
  echo ""
  while true; do
    run_metrics
    echo ""
    sleep "$watch_interval"
  done
else
  run_metrics
fi

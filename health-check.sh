#!/usr/bin/env bash
# health-check.sh — Check if a forked rig-seed project is actively evolving.
#
# Usage: ./health-check.sh [options] [directory]
#   directory: path to the rig-seed project root (default: current directory)
#
# Options:
#   -q, --quiet              Only print problems and the final result
#   -w, --watch [interval]   Re-run continuously (default: 60s)
#   --format=FORMAT          Output format: table (default), csv, json, kv
#   --json                   Alias for --format=json
#   -h, --help               Show help
#
# Checks:
#   - SESSION_COUNT is advancing (compared to git history)
#   - Journal has recent entries
#   - Last commit is recent (within configured threshold)
#   - Build/validation passes
#
# Exit codes:
#   0 — project appears healthy
#   1 — one or more concerns detected

set -euo pipefail

# --- Options ---

quiet=false
watch=false
watch_interval=60
use_color=auto
format=table
dir=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "Usage: health-check.sh [options] [directory]"
      echo ""
      echo "Check if a forked rig-seed project is actively evolving."
      echo ""
      echo "Options:"
      echo "  -q, --quiet              Only print problems and the final result"
      echo "  -w, --watch [seconds]    Re-run continuously (default: 60s)"
      echo "  --format=FORMAT          Output format: table (default), csv, json, kv"
      echo "  --json                   Alias for --format=json"
      echo "  --color                  Force colored output"
      echo "  --no-color               Disable colored output"
      echo "  -h, --help               Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory     Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Environment variables:"
      echo "  MAX_COMMIT_AGE_DAYS    Days before stale commit warning (default: 7)"
      echo "  MAX_JOURNAL_AGE_DAYS   Days before stale journal warning (default: 7)"
      echo "  NO_COLOR               Disable colored output (see https://no-color.org/)"
      echo ""
      echo "Exit codes:"
      echo "  0  Project appears healthy (warnings are non-fatal)"
      echo "  1  One or more errors detected"
      exit 0
      ;;
    -q|--quiet)
      quiet=true
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
    --json) format=json; shift ;;
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
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
setup_colors

# --- Helpers ---

# Structured result collection for multi-format output
# Each result: "category|status|message" where status is ok/warn/fail
results=()

add_result() {
  local category="$1" status="$2" message="$3"
  results+=("${category}|${status}|${message}")
}

info() {
  if [ "$quiet" = false ] && [ "$format" = "table" ]; then
    printf '%b\n' "$1"
  fi
}

warn() {
  if [ "$format" = "table" ]; then
    printf "  ${YELLOW}⚠${RESET} %s\n" "$1"
  fi
  warnings=$((warnings + 1))
}

fail() {
  if [ "$format" = "table" ]; then
    printf "  ${RED}✗${RESET} %s\n" "$1"
  fi
  errors=$((errors + 1))
}

ok() {
  if [ "$format" = "table" ]; then
    info "  ${GREEN}✓${RESET} $1"
  fi
}

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/scripts/lib.sh"

# --- Configuration ---

# Max days since last commit before we flag it
MAX_COMMIT_AGE_DAYS="${MAX_COMMIT_AGE_DAYS:-7}"

# Max days since last journal entry (heuristic: checks for "## Session" headers)
MAX_JOURNAL_AGE_DAYS="${MAX_JOURNAL_AGE_DAYS:-7}"

# --- Health check function ---

run_health_check() {
  warnings=0
  errors=0
  results=()

  info "Health check for rig-seed project: $dir"
  if [ "$watch" = true ]; then
    info "  ($(date '+%Y-%m-%d %H:%M:%S'))"
  fi
  info ""

  # --- 1. SESSION_COUNT is present and non-zero ---

  info "${CYAN}=== Evolution Progress ===${RESET}"
  day_file="$dir/SESSION_COUNT"
  if [ ! -f "$day_file" ]; then
    fail "SESSION_COUNT file missing"
    add_result "evolution" "fail" "SESSION_COUNT file missing"
  else
    day_val=$(tr -d '[:space:]' < "$day_file")
    if [[ ! "$day_val" =~ ^[0-9]+$ ]]; then
      fail "SESSION_COUNT is not a valid integer: '$day_val'"
      add_result "evolution" "fail" "SESSION_COUNT is not a valid integer: $day_val"
    elif [ "$day_val" -eq 0 ]; then
      warn "SESSION_COUNT is 0 — evolution hasn't started yet"
      add_result "evolution" "warn" "SESSION_COUNT is 0"
    else
      ok "SESSION_COUNT = $day_val"
      add_result "evolution" "ok" "SESSION_COUNT = $day_val"
    fi
  fi

  # --- 2. Journal has entries ---

  info ""
  info "${CYAN}=== Journal Activity ===${RESET}"
  journal_file="$dir/JOURNAL.md"
  if [ ! -f "$journal_file" ]; then
    fail "JOURNAL.md missing"
    add_result "journal" "fail" "JOURNAL.md missing"
  else
    # Match all journal header formats: "## Day N — Session M", "## Session N", "## Day N"
    entry_count=$(grep -c '^## \(Day [0-9].* — Session\|Session\|Day\) ' "$journal_file" 2>/dev/null) || entry_count=0
    if [ "$entry_count" -eq 0 ]; then
      warn "JOURNAL.md has no session entries (no '## Day' or '## Session' headers found)"
      add_result "journal" "warn" "No session entries found"
    else
      ok "JOURNAL.md has $entry_count session entries"
      add_result "journal" "ok" "JOURNAL.md has $entry_count session entries"

      # Check if the latest entry mentions a recent day/session number
      # Extract session number from any format: "Day N — Session M", "Session N", "Day N"
      latest_header=$(grep '^## \(Day [0-9].* — Session\|Session\|Day\) ' "$journal_file" | head -1)
      if echo "$latest_header" | grep -q 'Session [0-9]'; then
        latest_day=$(echo "$latest_header" | sed 's/.*Session \([0-9]*\).*/\1/')
      else
        latest_day=$(echo "$latest_header" | sed 's/## Day \([0-9]*\).*/\1/')
      fi
      if [ -n "$latest_day" ] && [ -f "$day_file" ]; then
        current_day=$(tr -d '[:space:]' < "$day_file")
        if [[ "$current_day" =~ ^[0-9]+$ ]] && [[ "$latest_day" =~ ^[0-9]+$ ]]; then
          gap=$((current_day - latest_day))
          if [ "$gap" -gt 1 ]; then
            warn "Journal's latest session is $latest_day but SESSION_COUNT is $current_day (gap of $gap)"
            add_result "journal" "warn" "Journal gap: latest=$latest_day, SESSION_COUNT=$current_day"
          else
            ok "Journal is up to date with SESSION_COUNT"
            add_result "journal" "ok" "Journal is up to date with SESSION_COUNT"
          fi
        fi
      fi
    fi
  fi

  # --- 3. Recent git activity ---

  info ""
  info "${CYAN}=== Git Activity ===${RESET}"
  if [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir &>/dev/null; then
    last_commit_epoch=$(git -C "$dir" log -1 --format='%ct' 2>/dev/null || echo "0")
    if [ "$last_commit_epoch" -eq 0 ]; then
      warn "Could not read git log (no commits?)"
      add_result "git" "warn" "Could not read git log"
    else
      now_epoch=$(date +%s)
      age_days=$(( (now_epoch - last_commit_epoch) / 86400 ))
      last_commit_date=$(git -C "$dir" log -1 --format='%ci' 2>/dev/null)
      if [ "$age_days" -gt "$MAX_COMMIT_AGE_DAYS" ]; then
        warn "Last commit was $age_days days ago ($last_commit_date) — threshold is $MAX_COMMIT_AGE_DAYS days"
        add_result "git" "warn" "Last commit $age_days days ago (threshold: $MAX_COMMIT_AGE_DAYS)"
      else
        ok "Last commit: $age_days day(s) ago ($last_commit_date)"
        add_result "git" "ok" "Last commit: $age_days day(s) ago"
      fi
    fi

    # Check if there are uncommitted changes
    if git -C "$dir" diff --quiet 2>/dev/null && git -C "$dir" diff --cached --quiet 2>/dev/null; then
      ok "Working tree is clean"
      add_result "git" "ok" "Working tree is clean"
    else
      warn "Uncommitted changes detected"
      add_result "git" "warn" "Uncommitted changes detected"
    fi
  else
    warn "Not a git repository — can't check commit history"
    add_result "git" "warn" "Not a git repository"
  fi

  # --- 4. SPECS.md has content ---

  info ""
  info "${CYAN}=== Project Configuration ===${RESET}"
  specs_file="$dir/SPECS.md"
  if [ ! -f "$specs_file" ]; then
    fail "SPECS.md missing"
    add_result "config" "fail" "SPECS.md missing"
  elif [ ! -s "$specs_file" ]; then
    warn "SPECS.md is empty — the agent needs specs to guide its work"
    add_result "config" "warn" "SPECS.md is empty"
  else
    # Check if it still has placeholder text
    if grep -q '\[PLACEHOLDER\]\|\[YOUR\]\|\[TODO\]' "$specs_file" 2>/dev/null; then
      warn "SPECS.md appears to still have placeholder text"
      add_result "config" "warn" "SPECS.md has placeholder text"
    else
      ok "SPECS.md has content"
      add_result "config" "ok" "SPECS.md has content"
    fi
  fi

  # Check ROADMAP.md has unchecked items (work remaining)
  roadmap_file="$dir/ROADMAP.md"
  if [ -f "$roadmap_file" ]; then
    unchecked=$(grep -c '^\- \[ \]' "$roadmap_file" 2>/dev/null) || unchecked=0
    checked=$(grep -c '^\- \[x\]' "$roadmap_file" 2>/dev/null) || checked=0
    if [ "$unchecked" -eq 0 ] && [ "$checked" -gt 0 ]; then
      warn "ROADMAP.md has no unchecked items — the agent may not know what to work on next"
      add_result "config" "warn" "ROADMAP.md: $checked done, 0 remaining"
    else
      ok "ROADMAP.md: $checked done, $unchecked remaining"
      add_result "config" "ok" "ROADMAP.md: $checked done, $unchecked remaining"
    fi
  fi

  # --- 5. Validate template structure ---

  info ""
  info "${CYAN}=== Template Validation ===${RESET}"
  if [ -x "$dir/validate.sh" ]; then
    if "$dir/validate.sh" "$dir" > /dev/null 2>&1; then
      ok "validate.sh passes"
      add_result "validation" "ok" "validate.sh passes"
    else
      fail "validate.sh reports errors (run it directly for details)"
      add_result "validation" "fail" "validate.sh reports errors"
    fi
  else
    warn "validate.sh not found or not executable — can't verify template structure"
    add_result "validation" "warn" "validate.sh not found or not executable"
  fi

  # --- Summary / Structured Output ---

  local result_status="healthy"
  local exit_code=0
  if [ "$errors" -gt 0 ]; then
    result_status="errors"
    exit_code=1
  elif [ "$warnings" -gt 0 ]; then
    result_status="warnings"
  fi

  if [ "$format" = "json" ]; then
    printf '{"project":"%s","status":"%s","errors":%d,"warnings":%d,"checks":[' \
      "$(json_escape "$dir")" "$result_status" "$errors" "$warnings"
    local first=true
    for r in "${results[@]}"; do
      IFS='|' read -r cat stat msg <<< "$r"
      if [ "$first" = true ]; then first=false; else printf ','; fi
      printf '{"category":"%s","status":"%s","message":"%s"}' \
        "$(json_escape "$cat")" "$stat" "$(json_escape "$msg")"
    done
    printf ']}\n'
    return "$exit_code"
  fi

  if [ "$format" = "csv" ]; then
    printf 'category,status,message\n'
    for r in "${results[@]}"; do
      IFS='|' read -r cat stat msg <<< "$r"
      printf '%s,%s,"%s"\n' "$cat" "$stat" "$msg"
    done
    return "$exit_code"
  fi

  if [ "$format" = "kv" ]; then
    printf 'project=%s\n' "$dir"
    printf 'status=%s\n' "$result_status"
    printf 'errors=%d\n' "$errors"
    printf 'warnings=%d\n' "$warnings"
    for r in "${results[@]}"; do
      IFS='|' read -r cat stat msg <<< "$r"
      printf '%s_%s=%s\n' "$cat" "$stat" "$msg"
    done
    return "$exit_code"
  fi

  # Default: table format
  info ""
  printf '%b\n' "${CYAN}================================${RESET}"
  if [ "$errors" -gt 0 ]; then
    printf "${BOLD}${RED}RESULT: %d error(s), %d warning(s) — project needs attention${RESET}\n" "$errors" "$warnings"
    return 1
  elif [ "$warnings" -gt 0 ]; then
    printf "${BOLD}${YELLOW}RESULT: %d warning(s) — project is evolving but has concerns${RESET}\n" "$warnings"
    return 0
  else
    printf "${BOLD}${GREEN}RESULT: all checks passed — project is healthy${RESET}\n"
    return 0
  fi
}

# --- Main ---

if [ "$watch" = true ]; then
  info "Watching $dir every ${watch_interval}s (Ctrl+C to stop)"
  info ""
  while true; do
    run_health_check || true
    echo ""
    sleep "$watch_interval"
  done
else
  run_health_check
  exit $?
fi

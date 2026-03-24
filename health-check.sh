#!/usr/bin/env bash
# health-check.sh — Check if a forked rig-seed project is actively evolving.
#
# Usage: ./health-check.sh [options] [directory]
#   directory: path to the rig-seed project root (default: current directory)
#
# Options:
#   -q, --quiet              Only print problems and the final result
#   -w, --watch [interval]   Re-run continuously (default: 60s)
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

info() {
  if [ "$quiet" = false ]; then
    printf '%b\n' "$1"
  fi
}

warn() {
  printf "  ${YELLOW}⚠${RESET} %s\n" "$1"
  warnings=$((warnings + 1))
}

fail() {
  printf "  ${RED}✗${RESET} %s\n" "$1"
  errors=$((errors + 1))
}

ok() {
  info "  ${GREEN}✓${RESET} $1"
}

# --- Configuration ---

# Max days since last commit before we flag it
MAX_COMMIT_AGE_DAYS="${MAX_COMMIT_AGE_DAYS:-7}"

# Max days since last journal entry (heuristic: checks for "## Session" headers)
MAX_JOURNAL_AGE_DAYS="${MAX_JOURNAL_AGE_DAYS:-7}"

# --- Health check function ---

run_health_check() {
  warnings=0
  errors=0

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
  else
    day_val=$(tr -d '[:space:]' < "$day_file")
    if [[ ! "$day_val" =~ ^[0-9]+$ ]]; then
      fail "SESSION_COUNT is not a valid integer: '$day_val'"
    elif [ "$day_val" -eq 0 ]; then
      warn "SESSION_COUNT is 0 — evolution hasn't started yet"
    else
      ok "SESSION_COUNT = $day_val"
    fi
  fi

  # --- 2. Journal has entries ---

  info ""
  info "${CYAN}=== Journal Activity ===${RESET}"
  journal_file="$dir/JOURNAL.md"
  if [ ! -f "$journal_file" ]; then
    fail "JOURNAL.md missing"
  else
    # Match all journal header formats: "## Day N — Session M", "## Session N", "## Day N"
    entry_count=$(grep -c '^## \(Day [0-9].* — Session\|Session\|Day\) ' "$journal_file" 2>/dev/null || echo "0")
    if [ "$entry_count" -eq 0 ]; then
      warn "JOURNAL.md has no session entries (no '## Day' or '## Session' headers found)"
    else
      ok "JOURNAL.md has $entry_count session entries"

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
          else
            ok "Journal is up to date with SESSION_COUNT"
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
    else
      now_epoch=$(date +%s)
      age_days=$(( (now_epoch - last_commit_epoch) / 86400 ))
      last_commit_date=$(git -C "$dir" log -1 --format='%ci' 2>/dev/null)
      if [ "$age_days" -gt "$MAX_COMMIT_AGE_DAYS" ]; then
        warn "Last commit was $age_days days ago ($last_commit_date) — threshold is $MAX_COMMIT_AGE_DAYS days"
      else
        ok "Last commit: $age_days day(s) ago ($last_commit_date)"
      fi
    fi

    # Check if there are uncommitted changes
    if git -C "$dir" diff --quiet 2>/dev/null && git -C "$dir" diff --cached --quiet 2>/dev/null; then
      ok "Working tree is clean"
    else
      warn "Uncommitted changes detected"
    fi
  else
    warn "Not a git repository — can't check commit history"
  fi

  # --- 4. SPECS.md has content ---

  info ""
  info "${CYAN}=== Project Configuration ===${RESET}"
  specs_file="$dir/SPECS.md"
  if [ ! -f "$specs_file" ]; then
    fail "SPECS.md missing"
  elif [ ! -s "$specs_file" ]; then
    warn "SPECS.md is empty — the agent needs specs to guide its work"
  else
    # Check if it still has placeholder text
    if grep -q '\[PLACEHOLDER\]\|\[YOUR\]\|\[TODO\]' "$specs_file" 2>/dev/null; then
      warn "SPECS.md appears to still have placeholder text"
    else
      ok "SPECS.md has content"
    fi
  fi

  # Check ROADMAP.md has unchecked items (work remaining)
  roadmap_file="$dir/ROADMAP.md"
  if [ -f "$roadmap_file" ]; then
    unchecked=$(grep -c '^\- \[ \]' "$roadmap_file" 2>/dev/null || echo "0")
    checked=$(grep -c '^\- \[x\]' "$roadmap_file" 2>/dev/null || echo "0")
    if [ "$unchecked" -eq 0 ] && [ "$checked" -gt 0 ]; then
      warn "ROADMAP.md has no unchecked items — the agent may not know what to work on next"
    else
      ok "ROADMAP.md: $checked done, $unchecked remaining"
    fi
  fi

  # --- 5. Validate template structure ---

  info ""
  info "${CYAN}=== Template Validation ===${RESET}"
  if [ -x "$dir/validate.sh" ]; then
    if "$dir/validate.sh" "$dir" > /dev/null 2>&1; then
      ok "validate.sh passes"
    else
      fail "validate.sh reports errors (run it directly for details)"
    fi
  else
    warn "validate.sh not found or not executable — can't verify template structure"
  fi

  # --- Summary ---

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

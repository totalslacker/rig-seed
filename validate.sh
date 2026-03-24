#!/usr/bin/env bash
# validate.sh — Verify a rig-seed template has all required files and structure.
#
# Usage: ./validate.sh [directory]
#   directory: path to the rig-seed project root (default: current directory)
#
# Exit codes:
#   0 — all checks pass
#   1 — one or more checks failed

set -euo pipefail

# --- Options ---

quiet=false
use_color=auto
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: validate.sh [options] [directory]"
      echo ""
      echo "Verify a rig-seed template has all required files and structure."
      echo ""
      echo "Options:"
      echo "  -q, --quiet    Only print failures and the final result"
      echo "  --color        Force colored output"
      echo "  --no-color     Disable colored output"
      echo "  -h, --help     Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory      Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Exit codes:"
      echo "  0  All checks pass"
      echo "  1  One or more checks failed"
      exit 0
      ;;
    -q|--quiet)
      quiet=true
      ;;
    --color)
      use_color=always
      ;;
    --no-color)
      use_color=never
      ;;
    *)
      dir="$arg"
      ;;
  esac
done

dir="${dir:-.}"
errors=0

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

check_file() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    printf "  ${RED}✗${RESET} missing %s (%s)\n" "$label" "$1"
    ((errors++))
  else
    info "  ${GREEN}✓${RESET} $label"
  fi
}

check_dir() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -d "$path" ]; then
    printf "  ${RED}✗${RESET} missing directory %s (%s)\n" "$label" "$1"
    ((errors++))
  else
    info "  ${GREEN}✓${RESET} $label"
  fi
}

check_nonempty() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    printf "  ${RED}✗${RESET} missing %s (%s)\n" "$label" "$1"
    ((errors++))
  elif [ ! -s "$path" ]; then
    printf "  ${YELLOW}⚠${RESET} %s exists but is empty (%s)\n" "$label" "$1"
  else
    info "  ${GREEN}✓${RESET} $label"
  fi
}

# --- Checks ---

info "Validating rig-seed template in: $dir"
info ""

info "${CYAN}=== Required State Files ===${RESET}"
check_nonempty "IDENTITY.md"    "Project identity"
check_file     "SPECS.md"       "Project specification"
check_file     "ROADMAP.md"     "Roadmap"
check_file     "JOURNAL.md"     "Evolution journal"
check_file     "LEARNINGS.md"   "Technical learnings"
check_file     "SESSION_COUNT"  "Session counter"
check_file     "DAY_COUNT"      "Day counter"
check_file     "DAY_DATE"       "Last session date"
check_file     "NEXT_STEPS.md"  "Planning handoff"
check_file     "PERSONALITY.md" "Agent personality"

info ""
info "${CYAN}=== Evolution Config ===${RESET}"
check_dir      ".evolve"              "Evolution config directory"
check_nonempty ".evolve/config.toml"  "Evolution settings"
check_nonempty ".evolve/IMMUTABLE.txt" "Immutable file list"

info ""
info "${CYAN}=== Project Infrastructure ===${RESET}"
check_file     "README.md"       "README"
check_file     "LICENSE"         "License file"
check_file     "CONTRIBUTING.md" "Contributing guide"
check_dir      ".claude"         "Claude config directory"
check_nonempty ".claude/CLAUDE.md" "Claude instructions"

info ""
info "${CYAN}=== SESSION_COUNT Format ===${RESET}"
session_count_file="$dir/SESSION_COUNT"
if [ -f "$session_count_file" ]; then
  day_val=$(tr -d '[:space:]' < "$session_count_file")
  if [[ "$day_val" =~ ^[0-9]+$ ]]; then
    info "  ${GREEN}✓${RESET} SESSION_COUNT is a valid integer ($day_val)"
  else
    printf "  ${RED}✗${RESET} SESSION_COUNT must contain a single integer, got: '%s'\n" "$day_val"
    ((errors++))
  fi
fi

info ""
info "${CYAN}=== DAY_COUNT Format ===${RESET}"
day_count_file="$dir/DAY_COUNT"
if [ -f "$day_count_file" ]; then
  dc_val=$(tr -d '[:space:]' < "$day_count_file")
  if [[ "$dc_val" =~ ^[0-9]+$ ]]; then
    info "  ${GREEN}✓${RESET} DAY_COUNT is a valid integer ($dc_val)"
  else
    printf "  ${RED}✗${RESET} DAY_COUNT must contain a single integer, got: '%s'\n" "$dc_val"
    ((errors++))
  fi
fi

info ""
info "${CYAN}=== DAY_DATE Format ===${RESET}"
day_date_file="$dir/DAY_DATE"
if [ -f "$day_date_file" ]; then
  dd_val=$(tr -d '[:space:]' < "$day_date_file")
  if [[ "$dd_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    info "  ${GREEN}✓${RESET} DAY_DATE is a valid date ($dd_val)"
  else
    printf "  ${RED}✗${RESET} DAY_DATE must contain a YYYY-MM-DD date, got: '%s'\n" "$dd_val"
    ((errors++))
  fi
fi

info ""
info "${CYAN}=== Integration Config ===${RESET}"
beads_map="$dir/.beads-external-map.json"
if [ -f "$beads_map" ]; then
  # File exists — check it's valid JSON
  if command -v python3 &>/dev/null; then
    if python3 -c "import json; json.load(open('$beads_map'))" 2>/dev/null; then
      info "  ${GREEN}✓${RESET} .beads-external-map.json is valid JSON"
    else
      printf "  ${YELLOW}⚠${RESET} .beads-external-map.json exists but is not valid JSON\n"
    fi
  elif command -v jq &>/dev/null; then
    if jq empty "$beads_map" 2>/dev/null; then
      info "  ${GREEN}✓${RESET} .beads-external-map.json is valid JSON"
    else
      printf "  ${YELLOW}⚠${RESET} .beads-external-map.json exists but is not valid JSON\n"
    fi
  else
    info "  ${CYAN}ℹ${RESET} .beads-external-map.json present (install jq or python3 to validate)"
  fi
else
  info "  ${CYAN}ℹ${RESET} no .beads-external-map.json (ok — only needed for external integrations)"
fi

info ""
info "${CYAN}=== Immutable File Protection ===${RESET}"
immutable_file="$dir/.evolve/IMMUTABLE.txt"
if [ -f "$immutable_file" ]; then
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue
    path="$dir/$line"
    if [[ "$line" == */ ]]; then
      # Directory entry
      if [ -d "$path" ]; then
        info "  ${GREEN}✓${RESET} immutable directory $line exists"
      else
        info "  ${CYAN}ℹ${RESET} immutable directory $line not yet created (ok for fresh template)"
      fi
    else
      if [ -f "$path" ]; then
        info "  ${GREEN}✓${RESET} immutable file $line exists"
      else
        printf "  ${RED}✗${RESET} immutable file %s is listed but missing\n" "$line"
        ((errors++))
      fi
    fi
  done < "$immutable_file"
fi

info ""
if [ "$errors" -gt 0 ]; then
  printf "${BOLD}${RED}RESULT: %d check(s) failed${RESET}\n" "$errors"
  exit 1
else
  printf "${BOLD}${GREEN}RESULT: all checks passed${RESET}\n"
  exit 0
fi

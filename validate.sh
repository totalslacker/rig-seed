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
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: validate.sh [options] [directory]"
      echo ""
      echo "Verify a rig-seed template has all required files and structure."
      echo ""
      echo "Options:"
      echo "  -q, --quiet   Only print failures and the final result"
      echo "  -h, --help    Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory     Path to the rig-seed project root (default: current directory)"
      echo ""
      echo "Exit codes:"
      echo "  0  All checks pass"
      echo "  1  One or more checks failed"
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
errors=0

# --- Helpers ---

info() {
  if [ "$quiet" = false ]; then
    echo "$1"
  fi
}

check_file() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    echo "FAIL: missing $label ($1)"
    ((errors++))
  else
    info "  ok: $label"
  fi
}

check_dir() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -d "$path" ]; then
    echo "FAIL: missing directory $label ($1)"
    ((errors++))
  else
    info "  ok: $label"
  fi
}

check_nonempty() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    echo "FAIL: missing $label ($1)"
    ((errors++))
  elif [ ! -s "$path" ]; then
    echo "WARN: $label exists but is empty ($1)"
  else
    info "  ok: $label"
  fi
}

# --- Checks ---

info "Validating rig-seed template in: $dir"
info ""

info "=== Required State Files ==="
check_nonempty "IDENTITY.md"    "Project identity"
check_file     "SPECS.md"       "Project specification"
check_file     "ROADMAP.md"     "Roadmap"
check_file     "JOURNAL.md"     "Evolution journal"
check_file     "LEARNINGS.md"   "Technical learnings"
check_file     "SESSION_COUNT"  "Session counter"
check_file     "DAY_COUNT"      "Day counter"
check_file     "DAY_DATE"       "Last session date"
check_file     "PERSONALITY.md" "Agent personality"

info ""
info "=== Evolution Config ==="
check_dir      ".evolve"              "Evolution config directory"
check_nonempty ".evolve/config.toml"  "Evolution settings"
check_nonempty ".evolve/IMMUTABLE.txt" "Immutable file list"

info ""
info "=== Project Infrastructure ==="
check_file     "README.md"       "README"
check_file     "LICENSE"         "License file"
check_file     "CONTRIBUTING.md" "Contributing guide"
check_dir      ".claude"         "Claude config directory"
check_nonempty ".claude/CLAUDE.md" "Claude instructions"

info ""
info "=== SESSION_COUNT Format ==="
session_count_file="$dir/SESSION_COUNT"
if [ -f "$session_count_file" ]; then
  day_val=$(tr -d '[:space:]' < "$session_count_file")
  if [[ "$day_val" =~ ^[0-9]+$ ]]; then
    info "  ok: SESSION_COUNT is a valid integer ($day_val)"
  else
    echo "FAIL: SESSION_COUNT must contain a single integer, got: '$day_val'"
    ((errors++))
  fi
fi

info ""
info "=== DAY_COUNT Format ==="
day_count_file="$dir/DAY_COUNT"
if [ -f "$day_count_file" ]; then
  dc_val=$(tr -d '[:space:]' < "$day_count_file")
  if [[ "$dc_val" =~ ^[0-9]+$ ]]; then
    info "  ok: DAY_COUNT is a valid integer ($dc_val)"
  else
    echo "FAIL: DAY_COUNT must contain a single integer, got: '$dc_val'"
    ((errors++))
  fi
fi

info ""
info "=== DAY_DATE Format ==="
day_date_file="$dir/DAY_DATE"
if [ -f "$day_date_file" ]; then
  dd_val=$(tr -d '[:space:]' < "$day_date_file")
  if [[ "$dd_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    info "  ok: DAY_DATE is a valid date ($dd_val)"
  else
    echo "FAIL: DAY_DATE must contain a YYYY-MM-DD date, got: '$dd_val'"
    ((errors++))
  fi
fi

info ""
info "=== Immutable File Protection ==="
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
        info "  ok: immutable directory $line exists"
      else
        info " info: immutable directory $line not yet created (ok for fresh template)"
      fi
    else
      if [ -f "$path" ]; then
        info "  ok: immutable file $line exists"
      else
        echo "FAIL: immutable file $line is listed but missing"
        ((errors++))
      fi
    fi
  done < "$immutable_file"
fi

info ""
if [ "$errors" -gt 0 ]; then
  echo "RESULT: $errors check(s) failed"
  exit 1
else
  echo "RESULT: all checks passed"
  exit 0
fi

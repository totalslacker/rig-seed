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

dir="${1:-.}"
errors=0

# --- Helpers ---

check_file() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    echo "FAIL: missing $label ($1)"
    ((errors++))
  else
    echo "  ok: $label"
  fi
}

check_dir() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -d "$path" ]; then
    echo "FAIL: missing directory $label ($1)"
    ((errors++))
  else
    echo "  ok: $label"
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
    echo "  ok: $label"
  fi
}

# --- Checks ---

echo "Validating rig-seed template in: $dir"
echo ""

echo "=== Required State Files ==="
check_nonempty "IDENTITY.md"    "Project identity"
check_file     "SPECS.md"       "Project specification"
check_file     "ROADMAP.md"     "Roadmap"
check_file     "JOURNAL.md"     "Evolution journal"
check_file     "LEARNINGS.md"   "Technical learnings"
check_file     "DAY_COUNT"      "Day counter"
check_file     "PERSONALITY.md" "Agent personality"

echo ""
echo "=== Evolution Config ==="
check_dir      ".evolve"              "Evolution config directory"
check_nonempty ".evolve/config.toml"  "Evolution settings"
check_nonempty ".evolve/IMMUTABLE.txt" "Immutable file list"

echo ""
echo "=== Project Infrastructure ==="
check_file     "README.md"       "README"
check_file     "LICENSE"         "License file"
check_file     "CONTRIBUTING.md" "Contributing guide"
check_dir      ".claude"         "Claude config directory"
check_nonempty ".claude/CLAUDE.md" "Claude instructions"

echo ""
echo "=== DAY_COUNT Format ==="
day_count_file="$dir/DAY_COUNT"
if [ -f "$day_count_file" ]; then
  day_val=$(tr -d '[:space:]' < "$day_count_file")
  if [[ "$day_val" =~ ^[0-9]+$ ]]; then
    echo "  ok: DAY_COUNT is a valid integer ($day_val)"
  else
    echo "FAIL: DAY_COUNT must contain a single integer, got: '$day_val'"
    ((errors++))
  fi
fi

echo ""
echo "=== Immutable File Protection ==="
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
        echo "  ok: immutable directory $line exists"
      else
        echo " info: immutable directory $line not yet created (ok for fresh template)"
      fi
    else
      if [ -f "$path" ]; then
        echo "  ok: immutable file $line exists"
      else
        echo "FAIL: immutable file $line is listed but missing"
        ((errors++))
      fi
    fi
  done < "$immutable_file"
fi

echo ""
if [ "$errors" -gt 0 ]; then
  echo "RESULT: $errors check(s) failed"
  exit 1
else
  echo "RESULT: all checks passed"
  exit 0
fi

#!/usr/bin/env bash
# check-evolve-state.sh — Verify mol-evolve sessions update required state files.
#
# Compares the current branch against the base branch and checks that required
# state files were modified. Run this before `gt done` to catch missing updates.
#
# Usage: ./scripts/check-evolve-state.sh [--color|--no-color] [-q|--quiet] [base-branch]
#   --color        Force colored output
#   --no-color     Disable colored output
#   -q, --quiet    Only show failures and the result line
#   base-branch    Branch to compare against (default: main)
#
# Exit codes:
#   0 — all required state files updated
#   1 — one or more required files missing from diff

set -euo pipefail

# --- Help ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $(basename "$0") [--color|--no-color] [-q|--quiet] [base-branch]"
    echo ""
    echo "Verify that a mol-evolve session updated all required state files."
    echo "Compares changed files on the current branch against the base branch."
    echo ""
    echo "Options:"
    echo "  --color        Force colored output"
    echo "  --no-color     Disable colored output"
    echo "  -q, --quiet    Only show failures and the result line"
    echo "  base-branch    Branch to compare against (default: main)"
    echo ""
    echo "Required files (must be modified):"
    echo "  JOURNAL.md, NEXT_STEPS.md, SESSION_COUNT"
    echo ""
    echo "Expected files (warn if missing):"
    echo "  ROADMAP.md, DAY_COUNT, DAY_DATE"
    echo ""
    echo "Exit codes:"
    echo "  0   All required state files updated"
    echo "  1   One or more required files missing"
    exit 0
fi

# --- Parse arguments ---
quiet=false
use_color=auto
base_branch="main"
for arg in "$@"; do
  case "$arg" in
    -q|--quiet) quiet=true ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    *) base_branch="$arg" ;;
  esac
done

# --- Color setup ---
setup_colors() {
  if [[ "$use_color" == "never" ]]; then
    RED="" GREEN="" YELLOW="" CYAN="" RESET=""
  elif [[ "$use_color" == "always" ]] || [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    CYAN=$'\033[0;36m'
    RESET=$'\033[0m'
  else
    RED="" GREEN="" YELLOW="" CYAN="" RESET=""
  fi
}
# shellcheck disable=SC2034  # Color vars used conditionally
setup_colors

info() {
  if ! $quiet; then
    echo "$@"
  fi
}

# --- Get changed files ---
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "${RED}Error: not inside a git repository${RESET}"
  exit 1
fi

# Fetch base branch ref if available
git fetch origin "$base_branch" --quiet 2>/dev/null || true

changed_files=$(git diff --name-only "origin/${base_branch}...HEAD" 2>/dev/null || \
                git diff --name-only "${base_branch}...HEAD" 2>/dev/null || echo "")

if [ -z "$changed_files" ]; then
  echo "${YELLOW}  ⚠ No commits ahead of ${base_branch} — nothing to check${RESET}"
  exit 0
fi

# --- Check required files ---
errors=0
warnings=0

info "${CYAN}=== Required State Files ===${RESET}"

check_required() {
  local file="$1"
  local label="$2"
  if echo "$changed_files" | grep -q "^${file}$"; then
    info "  ${GREEN}✓${RESET} ${label} (${file})"
  else
    echo "  ${RED}✗${RESET} ${label} not updated (${file})"
    errors=$((errors + 1))
  fi
}

check_expected() {
  local file="$1"
  local label="$2"
  if echo "$changed_files" | grep -q "^${file}$"; then
    info "  ${GREEN}✓${RESET} ${label} (${file})"
  else
    if ! $quiet; then
      echo "  ${YELLOW}⚠${RESET} ${label} not updated (${file})"
    fi
    warnings=$((warnings + 1))
  fi
}

check_required "JOURNAL.md"    "Journal entry"
check_required "NEXT_STEPS.md" "Planning handoff"
check_required "SESSION_COUNT" "Session counter"

info ""
info "${CYAN}=== Expected State Files ===${RESET}"

check_expected "ROADMAP.md"    "Roadmap"
check_expected "DAY_COUNT"     "Day counter"
check_expected "DAY_DATE"      "Day date"
check_expected "LEARNINGS.md"  "Learnings"

# --- Result ---
echo ""
if [ "$errors" -gt 0 ]; then
  echo "RESULT: FAIL (${errors} required file(s) not updated, ${warnings} warning(s))"
  exit 1
else
  echo "RESULT: PASS (${warnings} warning(s))"
  exit 0
fi

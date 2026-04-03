#!/usr/bin/env bash
# check-evolve-state.sh — Verify mol-evolve sessions update required state files.
#
# Compares the current branch against the base branch and checks that required
# state files were modified. Run this before `gt done` to catch missing updates.
#
# Usage: ./scripts/check-evolve-state.sh [options] [base-branch]
#   --format=FORMAT  Output format: table (default), csv, json, kv
#   --json           Alias for --format=json
#   --color          Force colored output
#   --no-color       Disable colored output
#   -q, --quiet      Only show failures and the result line
#   base-branch      Branch to compare against (default: main)
#
# Exit codes:
#   0 — all required state files updated
#   1 — one or more required files missing from diff

set -euo pipefail

# --- Help ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $(basename "$0") [options] [base-branch]"
    echo ""
    echo "Verify that a mol-evolve session updated all required state files."
    echo "Compares changed files on the current branch against the base branch."
    echo ""
    echo "Options:"
    echo "  --format=FORMAT  Output format: table (default), csv, json, kv"
    echo "  --json           Alias for --format=json"
    echo "  --color          Force colored output"
    echo "  --no-color       Disable colored output"
    echo "  -q, --quiet      Only show failures and the result line"
    echo "  base-branch      Branch to compare against (default: main)"
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
format=table
base_branch="main"
for arg in "$@"; do
  case "$arg" in
    -q|--quiet) quiet=true ;;
    --format=*)
      format="${arg#*=}"
      case "$format" in
        table|csv|json|kv) ;;
        *)
          echo "Error: unknown format '$format' (expected: table, csv, json, kv)" >&2
          exit 1
          ;;
      esac
      ;;
    --json) format=json ;;
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

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Structured result collection: "file|type|status|message"
check_results=()

add_result() {
  local file="$1" type="$2" status="$3" message="$4"
  check_results+=("${file}|${type}|${status}|${message}")
}

info() {
  if ! $quiet && [ "$format" = "table" ]; then
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
  if [ "$format" != "table" ]; then
    case "$format" in
      json) printf '{"base_branch":"%s","errors":0,"warnings":0,"result":"no_changes","checks":[]}\n' \
              "$(json_escape "$base_branch")" ;;
      csv)  printf 'file,type,status,message\n' ;;
      kv)   printf 'result=no_changes\nbase_branch=%s\nerrors=0\nwarnings=0\n' "$base_branch" ;;
    esac
  else
    echo "${YELLOW}  ⚠ No commits ahead of ${base_branch} — nothing to check${RESET}"
  fi
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
    add_result "$file" "required" "pass" "$label updated"
  else
    [ "$format" = "table" ] && echo "  ${RED}✗${RESET} ${label} not updated (${file})"
    errors=$((errors + 1))
    add_result "$file" "required" "fail" "$label not updated"
  fi
}

check_expected() {
  local file="$1"
  local label="$2"
  if echo "$changed_files" | grep -q "^${file}$"; then
    info "  ${GREEN}✓${RESET} ${label} (${file})"
    add_result "$file" "expected" "pass" "$label updated"
  else
    [ "$format" = "table" ] && ! $quiet && echo "  ${YELLOW}⚠${RESET} ${label} not updated (${file})"
    warnings=$((warnings + 1))
    add_result "$file" "expected" "warn" "$label not updated"
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

result_status="pass"
exit_code=0
if [ "$errors" -gt 0 ]; then
  result_status="fail"
  exit_code=1
fi

if [ "$format" = "json" ]; then
  printf '{"base_branch":"%s","errors":%d,"warnings":%d,"result":"%s","checks":[' \
    "$(json_escape "$base_branch")" "$errors" "$warnings" "$result_status"
  first=true
  for r in "${check_results[@]}"; do
    IFS='|' read -r file type status msg <<< "$r"
    if [ "$first" = true ]; then first=false; else printf ','; fi
    printf '{"file":"%s","type":"%s","status":"%s","message":"%s"}' \
      "$(json_escape "$file")" "$type" "$status" "$(json_escape "$msg")"
  done
  printf ']}\n'
  exit "$exit_code"
fi

if [ "$format" = "csv" ]; then
  printf 'file,type,status,message\n'
  for r in "${check_results[@]}"; do
    IFS='|' read -r file type status msg <<< "$r"
    printf '%s,%s,%s,%s\n' "$file" "$type" "$status" "$(csv_escape "$msg")"
  done
  exit "$exit_code"
fi

if [ "$format" = "kv" ]; then
  printf 'base_branch=%s\n' "$base_branch"
  printf 'errors=%d\n' "$errors"
  printf 'warnings=%d\n' "$warnings"
  printf 'result=%s\n' "$result_status"
  for r in "${check_results[@]}"; do
    IFS='|' read -r file _type status _msg <<< "$r"
    printf '%s=%s\n' "$file" "$status"
  done
  exit "$exit_code"
fi

# Default: table format
echo ""
if [ "$errors" -gt 0 ]; then
  echo "RESULT: FAIL (${errors} required file(s) not updated, ${warnings} warning(s))"
  exit 1
else
  echo "RESULT: PASS (${warnings} warning(s))"
  exit 0
fi

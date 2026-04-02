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
lint=false
fix=false
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
      echo "  -l, --lint     Check script conventions compliance"
      echo "  --fix          With --lint: auto-apply shellcheck fixes"
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
    -l|--lint)
      lint=true
      ;;
    --fix)
      fix=true
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
    errors=$((errors + 1))
  else
    info "  ${GREEN}✓${RESET} $label"
  fi
}

check_dir() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -d "$path" ]; then
    printf "  ${RED}✗${RESET} missing directory %s (%s)\n" "$label" "$1"
    errors=$((errors + 1))
  else
    info "  ${GREEN}✓${RESET} $label"
  fi
}

check_nonempty() {
  local path="$dir/$1"
  local label="${2:-$1}"
  if [ ! -f "$path" ]; then
    printf "  ${RED}✗${RESET} missing %s (%s)\n" "$label" "$1"
    errors=$((errors + 1))
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
info "${CYAN}=== Formula ===${RESET}"
check_nonempty "formulas/mol-evolve.formula.toml" "Evolution formula"

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
    errors=$((errors + 1))
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
    errors=$((errors + 1))
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
    errors=$((errors + 1))
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
        errors=$((errors + 1))
      fi
    fi
  done < "$immutable_file"
fi

# --- Script Conventions Lint (--lint) ---

if [ "$lint" = true ]; then
  info ""
  info "${CYAN}=== Script Conventions Lint ===${RESET}"

  # Find all .sh files in project root and scripts/
  lint_files=()
  while IFS= read -r -d '' f; do
    lint_files+=("$f")
  done < <(find "$dir" -maxdepth 1 -name '*.sh' -print0 2>/dev/null)
  while IFS= read -r -d '' f; do
    lint_files+=("$f")
  done < <(find "$dir/scripts" -maxdepth 1 -name '*.sh' -print0 2>/dev/null)

  if [ ${#lint_files[@]} -eq 0 ]; then
    info "  ${CYAN}ℹ${RESET} no .sh files found to lint"
  else
    for script in "${lint_files[@]}"; do
      rel="${script#"$dir"/}"
      script_errors=0

      # Check shebang
      if ! head -1 "$script" | grep -q '^#!/usr/bin/env bash\|^#!/bin/bash'; then
        printf "  ${RED}✗${RESET} %s: missing bash shebang\n" "$rel"
        script_errors=1
      fi

      # Check --help / -h
      if ! grep -q '\-\-help\|\-h)' "$script" 2>/dev/null; then
        printf "  ${RED}✗${RESET} %s: missing --help flag\n" "$rel"
        script_errors=1
      fi

      # Check set -euo pipefail
      if ! grep -q 'set -euo pipefail' "$script" 2>/dev/null; then
        printf "  ${YELLOW}⚠${RESET} %s: missing 'set -euo pipefail'\n" "$rel"
      fi

      # Check --color/--no-color
      if ! grep -q '\-\-no-color' "$script" 2>/dev/null; then
        printf "  ${YELLOW}⚠${RESET} %s: missing --color/--no-color flags\n" "$rel"
      fi

      # Check RESULT line (only for validation/check scripts, not all scripts)
      # Look for scripts that do checks (have error counters or check functions)
      if grep -q 'errors=' "$script" 2>/dev/null || grep -q 'check_' "$script" 2>/dev/null; then
        if ! grep -q 'RESULT:' "$script" 2>/dev/null; then
          printf "  ${YELLOW}⚠${RESET} %s: check-style script missing RESULT line\n" "$rel"
        fi
      fi

      if [ "$script_errors" -gt 0 ]; then
        errors=$((errors + 1))
      else
        info "  ${GREEN}✓${RESET} $rel"
      fi
    done
  fi

  # --- Shellcheck pass ---
  info ""
  info "${CYAN}=== Shellcheck ===${RESET}"
  if command -v shellcheck &>/dev/null; then
    if [ ${#lint_files[@]} -eq 0 ]; then
      info "  ${CYAN}ℹ${RESET} no .sh files found to check"
    else
      fixed_count=0
      for script in "${lint_files[@]}"; do
        rel="${script#"$dir"/}"
        if shellcheck -S warning "$script" >/dev/null 2>&1; then
          info "  ${GREEN}✓${RESET} $rel"
        elif [ "$fix" = true ]; then
          # Try to auto-fix using shellcheck's diff format
          diff_output=$(shellcheck -S warning -f diff "$script" 2>/dev/null || true)
          if [ -n "$diff_output" ]; then
            if echo "$diff_output" | patch -p1 --no-backup-if-mismatch -d / >/dev/null 2>&1; then
              fixed_count=$((fixed_count + 1))
              # Re-check after fix — some issues can't be auto-fixed
              if shellcheck -S warning "$script" >/dev/null 2>&1; then
                printf "  ${GREEN}✓${RESET} %s: auto-fixed\n" "$rel"
              else
                printf "  ${YELLOW}⚠${RESET} %s: partially fixed (remaining issues need manual review)\n" "$rel"
                if [ "$quiet" = false ]; then
                  shellcheck -S warning -f gcc "$script" 2>&1 | head -10 | sed 's/^/      /'
                fi
                errors=$((errors + 1))
              fi
            else
              printf "  ${RED}✗${RESET} %s: auto-fix failed (patch could not apply)\n" "$rel"
              if [ "$quiet" = false ]; then
                shellcheck -S warning -f gcc "$script" 2>&1 | head -10 | sed 's/^/      /'
              fi
              errors=$((errors + 1))
            fi
          else
            printf "  ${RED}✗${RESET} %s: shellcheck warnings/errors (no auto-fix available)\n" "$rel"
            if [ "$quiet" = false ]; then
              shellcheck -S warning -f gcc "$script" 2>&1 | head -10 | sed 's/^/      /'
            fi
            errors=$((errors + 1))
          fi
        else
          printf "  ${RED}✗${RESET} %s: shellcheck warnings/errors\n" "$rel"
          if [ "$quiet" = false ]; then
            shellcheck -S warning -f gcc "$script" 2>&1 | head -10 | sed 's/^/      /'
          fi
          errors=$((errors + 1))
        fi
      done
      if [ "$fix" = true ] && [ "$fixed_count" -gt 0 ]; then
        info "  ${GREEN}ℹ${RESET} Auto-fixed $fixed_count file(s). Review changes before committing."
      fi
    fi
  else
    info "  ${CYAN}ℹ${RESET} shellcheck not installed (install it for shell syntax linting)"
  fi
fi

info ""
if [ "$errors" -gt 0 ]; then
  printf "${BOLD}${RED}RESULT: %d check(s) failed${RESET}\n" "$errors"
  exit 1
else
  printf "${BOLD}${GREEN}RESULT: all checks passed${RESET}\n"
  exit 0
fi

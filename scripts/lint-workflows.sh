#!/usr/bin/env bash
# lint-workflows.sh — Validate GitHub Actions workflow files.
#
# Checks beyond basic YAML syntax: deprecated actions, missing required
# fields, best-practice violations, and security anti-patterns.
#
# Usage: ./scripts/lint-workflows.sh [directory]
#   directory: project root (default: current directory)
#
# Flags:
#   -h, --help     Show this help
#   -q, --quiet    Only show errors and the result line
#   --color        Force colored output
#   --no-color     Disable colored output
#
# Exit codes:
#   0 — all checks passed (or no workflow files found)
#   1 — one or more checks failed

set -euo pipefail

quiet=false
use_color=auto

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,/^$/s/^# //p' "$0"
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
  esac
done

# Strip flags from positional args
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help|-q|--quiet|--color|--no-color) ;;
    *) args+=("$arg") ;;
  esac
done

dir="${args[0]:-.}"
cd "$dir"

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

info() {
  [ "$quiet" = true ] || printf '%b\n' "$*"
}

errors=0
warnings=0
checked=0

workflow_dir=".github/workflows"

if [ ! -d "$workflow_dir" ]; then
  info "No $workflow_dir directory found — nothing to lint."
  echo "RESULT: no workflows to lint"
  exit 0
fi

# Collect workflow files
files=()
for ext in yml yaml; do
  for f in "$workflow_dir"/*."$ext"; do
    [ -f "$f" ] && files+=("$f")
  done
done

if [ ${#files[@]} -eq 0 ]; then
  info "No workflow files found in $workflow_dir."
  echo "RESULT: no workflows to lint"
  exit 0
fi

info "${CYAN}=== Workflow Lint ===${RESET}"
info ""

for wf in "${files[@]}"; do
  ((checked++))
  wf_name=$(basename "$wf")
  info "${CYAN}--- $wf_name ---${RESET}"

  # 1. YAML syntax check
  if command -v python3 &>/dev/null; then
    if ! python3 -c "import yaml; yaml.safe_load(open('$wf'))" 2>/dev/null; then
      printf '%b\n' "  ${RED}✗${RESET} Invalid YAML syntax: $wf"
      ((errors++))
      continue  # Can't check further if YAML is broken
    else
      info "  ${GREEN}✓${RESET} YAML syntax valid"
    fi
  fi

  # 2. Required top-level keys
  # Every workflow needs 'name', 'on', and 'jobs'
  for key in name on jobs; do
    if ! grep -qE "^${key}:" "$wf"; then
      printf '%b\n' "  ${RED}✗${RESET} Missing required top-level key: '$key'"
      ((errors++))
    fi
  done

  # 3. Deprecated actions (pinned to old major versions)
  # Check for actions/checkout@v1, v2, v3 (v4 is current)
  if grep -qE 'actions/checkout@v[123](\s|$)' "$wf"; then
    version=$(grep -oE 'actions/checkout@v[0-9]+' "$wf" | head -1)
    printf '%b\n' "  ${YELLOW}⚠${RESET} Deprecated action: $version (current: v4)"
    ((warnings++))
  fi

  # actions/setup-node, setup-python, setup-go — v3+ is current for most
  for action in setup-node setup-python setup-go; do
    if grep -qE "actions/${action}@v[12](\s|$)" "$wf"; then
      version=$(grep -oE "actions/${action}@v[0-9]+" "$wf" | head -1)
      printf '%b\n' "  ${YELLOW}⚠${RESET} Deprecated action: $version (check for newer major version)"
      ((warnings++))
    fi
  done

  # 4. Security: using pull_request_target without explicit permissions
  if grep -qE 'pull_request_target' "$wf"; then
    if ! grep -qE '^permissions:' "$wf"; then
      printf '%b\n' "  ${RED}✗${RESET} Uses pull_request_target without explicit permissions (security risk)"
      ((errors++))
    else
      info "  ${GREEN}✓${RESET} pull_request_target has explicit permissions"
    fi
  fi

  # 5. Security: workflow_dispatch without input validation
  # Just a warning — it's common and not always needed
  if grep -qE 'workflow_dispatch:' "$wf" && ! grep -qE 'inputs:' "$wf"; then
    info "  ${CYAN}ℹ${RESET} workflow_dispatch has no inputs defined (ok if intentional)"
  fi

  # 6. Best practice: runs-on should use a specific runner
  if grep -qE 'runs-on:.*\$\{' "$wf"; then
    info "  ${CYAN}ℹ${RESET} Dynamic runs-on detected — ensure the expression resolves to a valid runner"
  fi

  # 7. Check for hardcoded secrets in env blocks (obvious patterns)
  if grep -qiE '(password|token|secret|api_key)\s*[:=]\s*["\x27][^$]' "$wf"; then
    printf '%b\n' "  ${RED}✗${RESET} Possible hardcoded secret detected (use GitHub secrets instead)"
    ((errors++))
  fi

  # 8. Check for 'continue-on-error: true' at job level (can hide failures)
  if grep -qE '^\s+continue-on-error:\s*true' "$wf"; then
    printf '%b\n' "  ${YELLOW}⚠${RESET} continue-on-error: true detected — may hide build failures"
    ((warnings++))
  fi

  info ""
done

# --- Summary ---
info "${CYAN}=== Lint Summary ===${RESET}"
info "  Files checked: $checked"
info "  Errors:        $errors"
info "  Warnings:      $warnings"

if [ $errors -gt 0 ]; then
  printf '\n%b\n' "${BOLD}RESULT: $errors error(s) found — fix before submitting${RESET}"
  exit 1
else
  printf '\n%b\n' "${BOLD}RESULT: all workflow checks passed ($warnings warning(s))${RESET}"
  exit 0
fi

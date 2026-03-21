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
#
# Exit codes:
#   0 — all checks passed (or no workflow files found)
#   1 — one or more checks failed

set -euo pipefail

quiet=false

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,/^$/s/^# //p' "$0"
      exit 0
      ;;
    -q|--quiet)
      quiet=true
      ;;
  esac
done

# Strip flags from positional args
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help|-q|--quiet) ;;
    *) args+=("$arg") ;;
  esac
done

dir="${args[0]:-.}"
cd "$dir"

info() {
  [ "$quiet" = true ] || echo "$@"
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

info "=== Workflow Lint ==="
info ""

for wf in "${files[@]}"; do
  ((checked++))
  wf_name=$(basename "$wf")
  info "--- $wf_name ---"

  # 1. YAML syntax check
  if command -v python3 &>/dev/null; then
    if ! python3 -c "import yaml; yaml.safe_load(open('$wf'))" 2>/dev/null; then
      echo "  ✗ Invalid YAML syntax: $wf"
      ((errors++))
      continue  # Can't check further if YAML is broken
    else
      info "  ✓ YAML syntax valid"
    fi
  fi

  # 2. Required top-level keys
  # Every workflow needs 'name', 'on', and 'jobs'
  for key in name on jobs; do
    if ! grep -qE "^${key}:" "$wf"; then
      echo "  ✗ Missing required top-level key: '$key'"
      ((errors++))
    fi
  done

  # 3. Deprecated actions (pinned to old major versions)
  # Check for actions/checkout@v1, v2, v3 (v4 is current)
  if grep -qE 'actions/checkout@v[123](\s|$)' "$wf"; then
    version=$(grep -oE 'actions/checkout@v[0-9]+' "$wf" | head -1)
    echo "  ⚠ Deprecated action: $version (current: v4)"
    ((warnings++))
  fi

  # actions/setup-node, setup-python, setup-go — v3+ is current for most
  for action in setup-node setup-python setup-go; do
    if grep -qE "actions/${action}@v[12](\s|$)" "$wf"; then
      version=$(grep -oE "actions/${action}@v[0-9]+" "$wf" | head -1)
      echo "  ⚠ Deprecated action: $version (check for newer major version)"
      ((warnings++))
    fi
  done

  # 4. Security: using pull_request_target without explicit permissions
  if grep -qE 'pull_request_target' "$wf"; then
    if ! grep -qE '^permissions:' "$wf"; then
      echo "  ✗ Uses pull_request_target without explicit permissions (security risk)"
      ((errors++))
    else
      info "  ✓ pull_request_target has explicit permissions"
    fi
  fi

  # 5. Security: workflow_dispatch without input validation
  # Just a warning — it's common and not always needed
  if grep -qE 'workflow_dispatch:' "$wf" && ! grep -qE 'inputs:' "$wf"; then
    info "  ℹ workflow_dispatch has no inputs defined (ok if intentional)"
  fi

  # 6. Best practice: runs-on should use a specific runner
  if grep -qE 'runs-on:.*\$\{' "$wf"; then
    info "  ℹ Dynamic runs-on detected — ensure the expression resolves to a valid runner"
  fi

  # 7. Check for hardcoded secrets in env blocks (obvious patterns)
  if grep -qiE '(password|token|secret|api_key)\s*[:=]\s*["\x27][^$]' "$wf"; then
    echo "  ✗ Possible hardcoded secret detected (use GitHub secrets instead)"
    ((errors++))
  fi

  # 8. Check for 'continue-on-error: true' at job level (can hide failures)
  if grep -qE '^\s+continue-on-error:\s*true' "$wf"; then
    echo "  ⚠ continue-on-error: true detected — may hide build failures"
    ((warnings++))
  fi

  info ""
done

# --- Summary ---
info "=== Lint Summary ==="
info "  Files checked: $checked"
info "  Errors:        $errors"
info "  Warnings:      $warnings"

if [ $errors -gt 0 ]; then
  echo ""
  echo "RESULT: $errors error(s) found — fix before submitting"
  exit 1
else
  echo ""
  echo "RESULT: all workflow checks passed ($warnings warning(s))"
  exit 0
fi

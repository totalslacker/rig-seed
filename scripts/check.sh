#!/usr/bin/env bash
# check.sh — Run ALL build/test/lint checks for this project.
#
# This is the canonical build gate for rig-seed projects. The evolution agent
# runs this script during Step 7 (Build Check). If it exits non-zero, the
# agent must fix the issue or revert.
#
# How it works:
#   1. If [build] commands are configured in .evolve/config.toml, run those
#   2. Auto-detect secondary build systems (package.json, Cargo.toml, etc.)
#   3. Run all detected checks — ALL must pass
#
# Usage: ./scripts/check.sh [options] [directory]
#   -q, --quiet            Suppress passing checks (alias for --format=kv)
#   --format=FORMAT        Output format: table (default), kv, csv, json
#   --json                 Alias for --format=json
#   --color                Force colored output
#   --no-color             Disable colored output
#   -h, --help             Show this help message
#   directory              Project root (default: current directory)
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

set -euo pipefail

# --- Help ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $(basename "$0") [options] [directory]"
    echo ""
    echo "Run ALL build/test/lint checks for a rig-seed project."
    echo ""
    echo "Options:"
    echo "  -q, --quiet            Suppress passing checks (alias for --format=kv)"
    echo "  --format=FORMAT        Output format: table (default), kv, csv, json"
    echo "  --json                 Alias for --format=json"
    echo "  --color                Force colored output"
    echo "  --no-color             Disable colored output"
    echo "  directory              Project root (default: current directory)"
    echo ""
    echo "Formats:"
    echo "  table   Human-readable output with section headers (default)"
    echo "  kv      Key=value pairs, one per line (same as -q)"
    echo "  csv     Comma-separated with header row"
    echo "  json    JSON object with all check results"
    echo ""
    echo "Detects Go, Node.js, Rust, Python, and Makefile projects."
    echo "Also runs commands from [build] in .evolve/config.toml."
    echo ""
    echo "Exit codes:"
    echo "  0   All checks passed"
    echo "  1   One or more checks failed"
    exit 0
fi

# --- Parse arguments ---
quiet=false
format=table
use_color=auto
dir="."
for arg in "$@"; do
  case "$arg" in
    -q|--quiet) quiet=true ;;
    --json) format=json ;;
    --format=*) format="${arg#--format=}" ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    *) dir="$arg" ;;
  esac
done
cd "$dir"

# Quiet mode is an alias for --format=kv (backward compat)
if [ "$quiet" = true ] && [ "$format" = "table" ]; then
  format=kv
fi

# Non-table formats suppress verbose output
if [ "$format" != "table" ]; then
  quiet=true
  use_color=never
fi

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

passed=0
failed=0
skipped=0

# Collect results for structured output
check_names=()
check_statuses=()

add_check() {
  local name="$1" status="$2"
  check_names+=("$name")
  check_statuses+=("$status")
}

# --- Helpers ---

info() {
  [ "$quiet" = true ] || printf '%b\n' "$*"
}

run_check() {
  local label="$1"
  shift
  info "  ${CYAN}▶${RESET} $label"
  if "$@" 2>&1 | { if [ "$quiet" = true ]; then cat >/dev/null; else sed 's/^/    /'; fi; }; then
    info "  ${GREEN}✓${RESET} $label passed"
    passed=$((passed + 1))
    add_check "$label" "passed"
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${RED}✗${RESET} $label FAILED"
    failed=$((failed + 1))
    add_check "$label" "failed"
  fi
}

run_check_cmd() {
  local label="$1"
  local cmd="$2"
  info "  ${CYAN}▶${RESET} $label"
  if eval "$cmd" 2>&1 | { if [ "$quiet" = true ]; then cat >/dev/null; else sed 's/^/    /'; fi; }; then
    info "  ${GREEN}✓${RESET} $label passed"
    passed=$((passed + 1))
    add_check "$label" "passed"
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${RED}✗${RESET} $label FAILED"
    failed=$((failed + 1))
    add_check "$label" "failed"
  fi
}

detect_info() {
  info "  ${CYAN}ℹ${RESET} $1"
}

skip_check() {
  local label="$1"
  skipped=$((skipped + 1))
  add_check "$label" "skipped"
}

# --- Parse config.toml for [build] commands ---

config_file=".evolve/config.toml"
config_commands=()

if [ -f "$config_file" ]; then
  # Extract [build] commands array from config.toml
  # Simple TOML parsing: find lines between [build] and next section
  in_build=false
  in_commands=false
  while IFS= read -r line; do
    # Detect section headers
    if [[ "$line" =~ ^\[build\]$ ]]; then
      in_build=true
      continue
    elif [[ "$line" =~ ^\[.*\]$ ]]; then
      in_build=false
      in_commands=false
      continue
    fi

    if [ "$in_build" = true ]; then
      # Detect commands array start
      if [[ "$line" =~ ^commands[[:space:]]*= ]]; then
        in_commands=true
        # Check for single-line array
        if [[ "$line" =~ \[.*\] ]]; then
          # Extract commands from single-line array
          cmds="${line#*[}"
          cmds="${cmds%]*}"
          while IFS=',' read -ra parts; do
            for part in "${parts[@]}"; do
              cmd=$(echo "$part" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//')
              [ -n "$cmd" ] && config_commands+=("$cmd")
            done
          done <<< "$cmds"
          in_commands=false
        fi
        continue
      fi

      # Inside multi-line commands array
      if [ "$in_commands" = true ]; then
        if [[ "$line" =~ \] ]]; then
          in_commands=false
          continue
        fi
        cmd=$(echo "$line" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*,\?[[:space:]]*$//')
        [ -n "$cmd" ] && [[ ! "$cmd" =~ ^# ]] && config_commands+=("$cmd")
      fi
    fi
  done < "$config_file"
fi

# --- Run configured commands ---

info "${CYAN}=== Build Check ===${RESET}"
info ""

if [ ${#config_commands[@]} -gt 0 ]; then
  info "${CYAN}--- Configured Commands (from config.toml) ---${RESET}"
  for cmd in "${config_commands[@]}"; do
    run_check_cmd "config: $cmd" "$cmd"
  done
  info ""
fi

# --- Auto-detect build systems ---

info "${CYAN}--- Auto-Detected Build Systems ---${RESET}"

# Go
if [ -f "go.mod" ]; then
  detect_info "Go project detected (go.mod)"
  if command -v go &>/dev/null; then
    run_check "go build" go build ./...
    run_check "go test" go test ./...
    run_check "go vet" go vet ./...
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${YELLOW}⚠${RESET} go not found in PATH — skipping Go checks"
    skip_check "go"
  fi
fi

# Node.js (root)
if [ -f "package.json" ]; then
  detect_info "Node.js project detected (package.json)"
  if command -v npm &>/dev/null; then
    # Check what scripts are available
    if npm run --silent 2>/dev/null | grep -q "^build$" || grep -q '"build"' package.json 2>/dev/null; then
      run_check "npm build" npm run build
    fi
    if npm run --silent 2>/dev/null | grep -q "^test$" || grep -q '"test"' package.json 2>/dev/null; then
      run_check "npm test" npm test
    fi
    if npm run --silent 2>/dev/null | grep -q "^lint$" || grep -q '"lint"' package.json 2>/dev/null; then
      run_check "npm lint" npm run lint
    fi
    if npm run --silent 2>/dev/null | grep -q "^typecheck$" || grep -q '"typecheck"' package.json 2>/dev/null; then
      run_check "npm typecheck" npm run typecheck
    fi
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${YELLOW}⚠${RESET} npm not found in PATH — skipping Node.js checks"
    skip_check "npm"
  fi
fi

# Frontend subdirectory (common in Go+TS projects)
for subdir in frontend client web ui app; do
  if [ -f "$subdir/package.json" ]; then
    detect_info "Node.js sub-project detected ($subdir/package.json)"
    if command -v npm &>/dev/null; then
      if grep -q '"build"' "$subdir/package.json" 2>/dev/null; then
        run_check_cmd "$subdir: npm build" "cd $subdir && npm run build"
      fi
      if grep -q '"test"' "$subdir/package.json" 2>/dev/null; then
        run_check_cmd "$subdir: npm test" "cd $subdir && npm test"
      fi
      if grep -q '"typecheck"' "$subdir/package.json" 2>/dev/null; then
        run_check_cmd "$subdir: npm typecheck" "cd $subdir && npm run typecheck"
      fi
      # TypeScript without a typecheck script — try tsc directly
      if [ -f "$subdir/tsconfig.json" ] && ! grep -q '"typecheck"' "$subdir/package.json" 2>/dev/null; then
        if command -v npx &>/dev/null; then
          run_check_cmd "$subdir: tsc --noEmit" "cd $subdir && npx tsc --noEmit"
        fi
      fi
    else
      [ "$format" = "table" ] && printf '%b\n' "  ${YELLOW}⚠${RESET} npm not found in PATH — skipping $subdir checks"
      skip_check "$subdir"
    fi
  fi
done

# Rust
if [ -f "Cargo.toml" ]; then
  detect_info "Rust project detected (Cargo.toml)"
  if command -v cargo &>/dev/null; then
    run_check "cargo build" cargo build
    run_check "cargo test" cargo test
    run_check "cargo clippy" cargo clippy -- -D warnings 2>/dev/null || true
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${YELLOW}⚠${RESET} cargo not found in PATH — skipping Rust checks"
    skip_check "cargo"
  fi
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
  detect_info "Python project detected"
  if command -v python3 &>/dev/null; then
    if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
      run_check "pytest" python3 -m pytest
    elif [ -d "tests" ]; then
      run_check "pytest" python3 -m pytest
    fi
    if command -v mypy &>/dev/null && [ -f "pyproject.toml" ] && grep -q "mypy" pyproject.toml 2>/dev/null; then
      run_check "mypy" mypy .
    fi
    if command -v ruff &>/dev/null; then
      run_check "ruff check" ruff check .
    fi
  else
    [ "$format" = "table" ] && printf '%b\n' "  ${YELLOW}⚠${RESET} python3 not found in PATH — skipping Python checks"
    skip_check "python3"
  fi
fi

# Makefile (fallback — if no other system detected and Makefile has standard targets)
if [ -f "Makefile" ] && [ $passed -eq 0 ] && [ ${#config_commands[@]} -eq 0 ]; then
  detect_info "Makefile detected (fallback)"
  if grep -q "^build:" Makefile 2>/dev/null; then
    run_check "make build" make build
  fi
  if grep -q "^test:" Makefile 2>/dev/null; then
    run_check "make test" make test
  fi
  if grep -q "^lint:" Makefile 2>/dev/null; then
    run_check "make lint" make lint
  fi
fi

# --- CI workflow lint (if workflows were modified) ---

if [ -d ".github/workflows" ]; then
  detect_info "GitHub Actions workflows detected"
  # Check YAML syntax of workflow files
  if command -v python3 &>/dev/null; then
    workflow_errors=0
    for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
      [ -f "$wf" ] || continue
      if ! python3 -c "import yaml; yaml.safe_load(open('$wf'))" 2>/dev/null; then
        [ "$format" = "table" ] && printf '%b\n' "  ${RED}✗${RESET} Invalid YAML: $wf"
        workflow_errors=$((workflow_errors + 1))
      fi
    done
    if [ $workflow_errors -gt 0 ]; then
      [ "$format" = "table" ] && printf '%b\n' "  ${RED}✗${RESET} workflow YAML lint FAILED ($workflow_errors files)"
      failed=$((failed + 1))
      add_check "workflow YAML lint" "failed"
    else
      info "  ${GREEN}✓${RESET} workflow YAML lint passed"
      passed=$((passed + 1))
      add_check "workflow YAML lint" "passed"
    fi
  fi
fi

# --- Structured output ---

local_result="passed"
if [ $failed -gt 0 ]; then
  local_result="failed"
elif [ $passed -eq 0 ] && [ ${#config_commands[@]} -eq 0 ]; then
  local_result="no_checks"
fi

if [ "$format" = "json" ]; then
  # Build checks array
  checks_json=""
  for i in "${!check_names[@]}"; do
    entry="{\"name\":\"${check_names[$i]}\",\"status\":\"${check_statuses[$i]}\"}"
    if [ -n "$checks_json" ]; then
      checks_json="$checks_json,$entry"
    else
      checks_json="$entry"
    fi
  done

  printf '{"result":"%s","passed":%d,"failed":%d,"skipped":%d,"checks":[%s]}\n' \
    "$local_result" "$passed" "$failed" "$skipped" "$checks_json"

elif [ "$format" = "csv" ]; then
  echo "name,status"
  for i in "${!check_names[@]}"; do
    printf '%s,%s\n' "${check_names[$i]}" "${check_statuses[$i]}"
  done
  echo ""
  echo "result,$local_result"
  echo "passed,$passed"
  echo "failed,$failed"
  echo "skipped,$skipped"

elif [ "$format" = "kv" ]; then
  for i in "${!check_names[@]}"; do
    printf 'check_%s=%s\n' "$(echo "${check_names[$i]}" | tr ' :' '__')" "${check_statuses[$i]}"
  done
  echo "result=$local_result"
  echo "passed=$passed"
  echo "failed=$failed"
  echo "skipped=$skipped"

else
  # Table format
  info ""
  info "${CYAN}=== Check Summary ===${RESET}"
  info "  Passed:  $passed"
  info "  Failed:  $failed"
  info "  Skipped: $skipped"

  if [ $failed -gt 0 ]; then
    printf '\n%b\n' "${BOLD}RESULT: $failed check(s) FAILED — fix before submitting${RESET}"
  elif [ $passed -eq 0 ] && [ ${#config_commands[@]} -eq 0 ]; then
    printf '\n%b\n' "${BOLD}RESULT: no build systems detected — add [build] commands to .evolve/config.toml${RESET}"
    info "  See docs/FORMULA-CUSTOMIZATION.md for examples."
  else
    printf '\n%b\n' "${BOLD}RESULT: all checks passed${RESET}"
  fi
fi

[ $failed -eq 0 ]

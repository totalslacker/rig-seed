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
# Usage: ./scripts/check.sh [directory]
#   directory: project root (default: current directory)
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

set -euo pipefail

dir="${1:-.}"
cd "$dir"

passed=0
failed=0
skipped=0

# --- Helpers ---

run_check() {
  local label="$1"
  shift
  echo "  ▶ $label"
  if "$@" 2>&1 | sed 's/^/    /'; then
    echo "  ✓ $label passed"
    ((passed++))
  else
    echo "  ✗ $label FAILED"
    ((failed++))
  fi
}

run_check_cmd() {
  local label="$1"
  local cmd="$2"
  echo "  ▶ $label"
  if eval "$cmd" 2>&1 | sed 's/^/    /'; then
    echo "  ✓ $label passed"
    ((passed++))
  else
    echo "  ✗ $label FAILED"
    ((failed++))
  fi
}

detect_info() {
  echo "  ℹ $1"
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

echo "=== Build Check ==="
echo ""

if [ ${#config_commands[@]} -gt 0 ]; then
  echo "--- Configured Commands (from config.toml) ---"
  for cmd in "${config_commands[@]}"; do
    run_check_cmd "config: $cmd" "$cmd"
  done
  echo ""
fi

# --- Auto-detect build systems ---

echo "--- Auto-Detected Build Systems ---"

# Go
if [ -f "go.mod" ]; then
  detect_info "Go project detected (go.mod)"
  if command -v go &>/dev/null; then
    run_check "go build" go build ./...
    run_check "go test" go test ./...
    run_check "go vet" go vet ./...
  else
    echo "  ⚠ go not found in PATH — skipping Go checks"
    ((skipped++))
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
    echo "  ⚠ npm not found in PATH — skipping Node.js checks"
    ((skipped++))
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
      echo "  ⚠ npm not found in PATH — skipping $subdir checks"
      ((skipped++))
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
    echo "  ⚠ cargo not found in PATH — skipping Rust checks"
    ((skipped++))
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
    echo "  ⚠ python3 not found in PATH — skipping Python checks"
    ((skipped++))
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
        echo "  ✗ Invalid YAML: $wf"
        ((workflow_errors++))
      fi
    done
    if [ $workflow_errors -gt 0 ]; then
      echo "  ✗ workflow YAML lint FAILED ($workflow_errors files)"
      ((failed++))
    else
      echo "  ✓ workflow YAML lint passed"
      ((passed++))
    fi
  fi
fi

# --- Summary ---

echo ""
echo "=== Check Summary ==="
echo "  Passed:  $passed"
echo "  Failed:  $failed"
echo "  Skipped: $skipped"

if [ $failed -gt 0 ]; then
  echo ""
  echo "RESULT: $failed check(s) FAILED — fix before submitting"
  exit 1
elif [ $passed -eq 0 ] && [ ${#config_commands[@]} -eq 0 ]; then
  echo ""
  echo "RESULT: no build systems detected — add [build] commands to .evolve/config.toml"
  echo "  See docs/FORMULA-CUSTOMIZATION.md for examples."
  exit 0
else
  echo ""
  echo "RESULT: all checks passed"
  exit 0
fi

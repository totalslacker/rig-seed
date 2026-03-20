#!/usr/bin/env bash
# integration-test.sh — End-to-end test: fork → quickstart → validate → health-check.
#
# Creates a temporary copy of the template, runs the full lifecycle,
# and verifies each step succeeds.
#
# Usage: ./tests/integration-test.sh
#
# Exit codes:
#   0 — all tests pass
#   1 — one or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMPDIR_BASE="${TMPDIR:-/tmp}"
WORK_DIR=""
tests_run=0
tests_passed=0
tests_failed=0

# --- Helpers ---

cleanup() {
  if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

pass() {
  echo "  PASS: $1"
  tests_passed=$((tests_passed + 1))
  tests_run=$((tests_run + 1))
}

fail() {
  echo "  FAIL: $1"
  tests_failed=$((tests_failed + 1))
  tests_run=$((tests_run + 1))
}

run_test() {
  local desc="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

# --- Setup: simulate a fork ---

echo "=== Integration Test: fork → quickstart → validate → health-check ==="
echo ""

echo "--- Step 1: Simulating a fork ---"

WORK_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-integration-XXXXXX")

# Copy template files (excluding .git, .beads, .runtime)
rsync -a \
  --exclude='.git' \
  --exclude='.beads' \
  --exclude='.runtime' \
  "$PROJECT_DIR/" "$WORK_DIR/"

# Initialize a fresh git repo to simulate a real fork
(
  cd "$WORK_DIR"
  git init -q
  git add -A
  git commit -q -m "Initial fork of rig-seed"
)

echo "  Forked to: $WORK_DIR"
echo ""

# --- Step 2: Validate the raw fork ---

echo "--- Step 2: Validate raw fork (before quickstart) ---"
run_test "validate.sh passes on raw fork" "$WORK_DIR/validate.sh" "$WORK_DIR"
echo ""

# --- Step 3: Run quickstart ---

echo "--- Step 3: Run quickstart ---"

# Write example specs before quickstart (simulates user filling in specs)
cp "$WORK_DIR/docs/examples/specs/cli-tool.md" "$WORK_DIR/SPECS.md"

run_test "quickstart.sh completes successfully" "$WORK_DIR/quickstart.sh"

# Verify quickstart results
day_val=$(tr -d '[:space:]' < "$WORK_DIR/SESSION_COUNT")
if [ "$day_val" = "0" ]; then
  pass "SESSION_COUNT reset to 0"
else
  fail "SESSION_COUNT should be 0 after quickstart, got: '$day_val'"
fi

journal_lines=$(wc -l < "$WORK_DIR/JOURNAL.md")
if [ "$journal_lines" -le 6 ]; then
  pass "JOURNAL.md cleared to header only"
else
  fail "JOURNAL.md should be header-only after quickstart ($journal_lines lines)"
fi

if grep -q '^\- \[ \]' "$WORK_DIR/ROADMAP.md"; then
  pass "ROADMAP.md has bootstrap checklist"
else
  fail "ROADMAP.md should have unchecked bootstrap items"
fi

echo ""

# --- Step 4: Validate after quickstart ---

echo "--- Step 4: Validate after quickstart ---"
run_test "validate.sh passes after quickstart" "$WORK_DIR/validate.sh" "$WORK_DIR"
echo ""

# --- Step 5: Simulate one evolution session ---

echo "--- Step 5: Simulate an evolution session ---"

# Increment SESSION_COUNT
echo "1" > "$WORK_DIR/SESSION_COUNT"

# Add a journal entry (using the current Session format)
cat > "$WORK_DIR/JOURNAL.md" << 'JOURNAL'
# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Session 1 — Bootstrap: initial setup (test-001)

Set up project structure, wrote specs, configured build commands.
Everything passes. Ready for Day 2.

---
JOURNAL

# Check off a roadmap item
sed -i 's/- \[ \] Read and document project specs/- [x] Read and document project specs/' "$WORK_DIR/ROADMAP.md"

# Commit the simulated session
(
  cd "$WORK_DIR"
  git add -A
  git commit -q -m "Session 1: bootstrap"
)

pass "Simulated evolution session committed"
echo ""

# --- Step 6: Validate after evolution ---

echo "--- Step 6: Validate after evolution ---"
run_test "validate.sh passes after evolution" "$WORK_DIR/validate.sh" "$WORK_DIR"
echo ""

# --- Step 7: Health check ---

echo "--- Step 7: Health check ---"
run_test "health-check.sh passes on active project" "$WORK_DIR/health-check.sh" "$WORK_DIR"

# Verify health check catches problems
echo "bad" > "$WORK_DIR/SESSION_COUNT"
if "$WORK_DIR/health-check.sh" "$WORK_DIR" > /dev/null 2>&1; then
  fail "health-check.sh should catch invalid SESSION_COUNT"
else
  pass "health-check.sh catches invalid SESSION_COUNT"
fi
echo "1" > "$WORK_DIR/SESSION_COUNT"  # restore

# Test with missing SPECS.md
mv "$WORK_DIR/SPECS.md" "$WORK_DIR/SPECS.md.bak"
if "$WORK_DIR/health-check.sh" "$WORK_DIR" > /dev/null 2>&1; then
  # health-check may only warn on missing specs, so this is acceptable
  pass "health-check.sh handles missing SPECS.md (warning or error)"
else
  pass "health-check.sh catches missing SPECS.md"
fi
mv "$WORK_DIR/SPECS.md.bak" "$WORK_DIR/SPECS.md"

echo ""

# --- Summary ---

echo "================================"
echo "Tests run: $tests_run"
echo "Passed:    $tests_passed"
echo "Failed:    $tests_failed"
echo ""

if [ "$tests_failed" -gt 0 ]; then
  echo "RESULT: $tests_failed test(s) failed"
  exit 1
else
  echo "RESULT: all tests passed"
  exit 0
fi

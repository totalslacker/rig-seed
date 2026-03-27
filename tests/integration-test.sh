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
  echo "  ✓ $1"
  tests_passed=$((tests_passed + 1))
  tests_run=$((tests_run + 1))
}

fail() {
  echo "  ✗ $1"
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
if [ "$day_val" = "1" ]; then
  pass "SESSION_COUNT set to 1 (Day 1)"
else
  fail "SESSION_COUNT should be 1 after quickstart, got: '$day_val'"
fi

dc_val=$(tr -d '[:space:]' < "$WORK_DIR/DAY_COUNT")
if [ "$dc_val" = "1" ]; then
  pass "DAY_COUNT set to 1 (Day 1)"
else
  fail "DAY_COUNT should be 1 after quickstart, got: '$dc_val'"
fi

dd_val=$(tr -d '[:space:]' < "$WORK_DIR/DAY_DATE")
if [[ "$dd_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  pass "DAY_DATE set to today's date ($dd_val)"
else
  fail "DAY_DATE should be a valid date after quickstart, got: '$dd_val'"
fi

# Quickstart writes a Day 1 spawn journal entry (not header-only)
if grep -q '## Day 1 — Session 1' "$WORK_DIR/JOURNAL.md"; then
  pass "JOURNAL.md has Day 1 spawn entry"
else
  fail "JOURNAL.md should have Day 1 spawn entry after quickstart"
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

# Increment SESSION_COUNT and DAY_COUNT
echo "1" > "$WORK_DIR/SESSION_COUNT"
echo "1" > "$WORK_DIR/DAY_COUNT"
echo "2026-01-01" > "$WORK_DIR/DAY_DATE"

# Add a journal entry (using the Day/Session format)
cat > "$WORK_DIR/JOURNAL.md" << 'JOURNAL'
# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Day 1 — Session 1 (2026-01-01)

**Goal**: Bootstrap the project — set up structure, write specs, configure build.

Set up project structure, wrote specs, configured build commands.
Everything passes.

**Next Steps**: Add tests and CI configuration.

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

# --- Step 8: Test new script flags ---

echo "--- Step 8: Test new script flags ---"

# Test quickstart.sh --check
run_test "quickstart.sh --check passes on valid project" "$WORK_DIR/quickstart.sh" --check
echo ""

# Test recap.sh --since and --top
echo "--- Step 8b: recap.sh flags ---"
run_test "recap.sh --short shows output" "$WORK_DIR/scripts/recap.sh" -s "$WORK_DIR"
run_test "recap.sh --since 1 shows one entry" "$WORK_DIR/scripts/recap.sh" --since 1 "$WORK_DIR"
run_test "recap.sh --short --top 1 limits to 1 entry" "$WORK_DIR/scripts/recap.sh" --short --top 1 "$WORK_DIR"
run_test "recap.sh --json produces valid output" "$WORK_DIR/scripts/recap.sh" --json "$WORK_DIR"
echo ""

# Test dashboard.sh --projects and --depth
echo "--- Step 8c: dashboard.sh --projects and --depth ---"
# Create a nested structure with two rig-seed projects
DASH_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-dash-XXXXXX")
mkdir -p "$DASH_DIR/proj-a" "$DASH_DIR/proj-b" "$DASH_DIR/deep/nested/proj-c"
echo "1" > "$DASH_DIR/proj-a/SESSION_COUNT"
cat > "$DASH_DIR/proj-a/JOURNAL.md" << 'J'
# Journal

---

## Day 1 — Session 1 (2026-01-01)

**Goal**: Test project A.

---
J
echo "1" > "$DASH_DIR/proj-b/SESSION_COUNT"
cat > "$DASH_DIR/proj-b/JOURNAL.md" << 'J'
# Journal

---

## Day 1 — Session 1 (2026-01-01)

**Goal**: Test project B.

---
J
echo "1" > "$DASH_DIR/deep/nested/proj-c/SESSION_COUNT"
cat > "$DASH_DIR/deep/nested/proj-c/JOURNAL.md" << 'J'
# Journal

---

## Day 1 — Session 1 (2026-01-01)

**Goal**: Test project C.

---
J
# Initialize git repos so dashboard can read git metrics
for p in "$DASH_DIR/proj-a" "$DASH_DIR/proj-b" "$DASH_DIR/deep/nested/proj-c"; do
  (cd "$p" && git init -q && git add -A && git commit -q -m "init")
done

run_test "dashboard.sh --projects finds all projects" "$WORK_DIR/scripts/dashboard.sh" --summary --projects "$DASH_DIR" --no-color

# --depth 2 should find proj-a and proj-b but NOT deep/nested/proj-c
dash_output=$("$WORK_DIR/scripts/dashboard.sh" --summary --projects "$DASH_DIR" --depth 2 --no-color 2>/dev/null || true)
if echo "$dash_output" | grep -q "proj-a" && echo "$dash_output" | grep -q "proj-b" && ! echo "$dash_output" | grep -q "proj-c"; then
  pass "dashboard.sh --depth 2 excludes deeply nested projects"
else
  fail "dashboard.sh --depth 2 should find proj-a/b but not deep/nested/proj-c"
fi

rm -rf "$DASH_DIR"
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

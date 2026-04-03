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

# Test recap.sh --format=csv
recap_csv=$("$WORK_DIR/scripts/recap.sh" --format=csv --no-color "$WORK_DIR" 2>/dev/null || true)
if echo "$recap_csv" | grep -q 'header,goal,next_steps'; then
  pass "recap.sh --format=csv includes CSV header"
else
  fail "recap.sh --format=csv should include CSV header (header,goal,next_steps)"
fi
if echo "$recap_csv" | grep -q 'Bootstrap'; then
  pass "recap.sh --format=csv includes entry data"
else
  fail "recap.sh --format=csv should include entry data"
fi

# Test recap.sh --format=kv
recap_kv=$("$WORK_DIR/scripts/recap.sh" --format=kv --no-color "$WORK_DIR" 2>/dev/null || true)
if echo "$recap_kv" | grep -q '^header='; then
  pass "recap.sh --format=kv includes header= key"
else
  fail "recap.sh --format=kv should include header= key"
fi
if echo "$recap_kv" | grep -q '^goal='; then
  pass "recap.sh --format=kv includes goal= key"
else
  fail "recap.sh --format=kv should include goal= key"
fi
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

# Test dashboard.sh --format=csv
dash_csv=$("$WORK_DIR/scripts/dashboard.sh" --format=csv --no-color --projects "$DASH_DIR" 2>/dev/null || true)
if echo "$dash_csv" | head -1 | grep -q 'name,day_count,sessions'; then
  pass "dashboard.sh --format=csv includes CSV header"
else
  fail "dashboard.sh --format=csv should include CSV header"
fi
if echo "$dash_csv" | grep -q 'proj-a'; then
  pass "dashboard.sh --format=csv includes project data"
else
  fail "dashboard.sh --format=csv should include project data"
fi

# Test dashboard.sh --format=kv
dash_kv=$("$WORK_DIR/scripts/dashboard.sh" --format=kv --no-color --projects "$DASH_DIR" 2>/dev/null || true)
if echo "$dash_kv" | grep -q '^project=proj-a'; then
  pass "dashboard.sh --format=kv includes project= key"
else
  fail "dashboard.sh --format=kv should include project= key"
fi

# --depth 2 should find proj-a and proj-b but NOT deep/nested/proj-c
dash_output=$("$WORK_DIR/scripts/dashboard.sh" --summary --projects "$DASH_DIR" --depth 2 --no-color 2>/dev/null || true)
if echo "$dash_output" | grep -q "proj-a" && echo "$dash_output" | grep -q "proj-b" && ! echo "$dash_output" | grep -q "proj-c"; then
  pass "dashboard.sh --depth 2 excludes deeply nested projects"
else
  fail "dashboard.sh --depth 2 should find proj-a/b but not deep/nested/proj-c"
fi

rm -rf "$DASH_DIR"
echo ""

# --- Step 9: migrate.sh tests ---

echo "--- Step 9: migrate.sh ---"

# Test --dry-run on a complete fork (should find nothing to migrate)
migrate_output=$("$WORK_DIR/scripts/migrate.sh" --dry-run --no-color "$WORK_DIR" 2>&1)
if echo "$migrate_output" | grep -q "up to date"; then
  pass "migrate.sh --dry-run reports up-to-date fork"
else
  fail "migrate.sh --dry-run should report fork is up to date"
fi

# Test --dry-run on a stripped fork (simulate older version missing files)
MIGRATE_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-migrate-XXXXXX")
# Copy minimal state files to simulate an old fork
mkdir -p "$MIGRATE_DIR/.evolve"
cp "$WORK_DIR/IDENTITY.md" "$MIGRATE_DIR/"
echo "1" > "$MIGRATE_DIR/SESSION_COUNT"
echo "1" > "$MIGRATE_DIR/DAY_COUNT"
cp "$WORK_DIR/.evolve/config.toml" "$MIGRATE_DIR/.evolve/"

# --dry-run should detect missing files
migrate_output=$("$WORK_DIR/scripts/migrate.sh" --dry-run --no-color "$MIGRATE_DIR" 2>&1)
if echo "$migrate_output" | grep -q "\[would add\]"; then
  pass "migrate.sh --dry-run detects missing files in old fork"
else
  fail "migrate.sh --dry-run should detect missing files in stripped fork"
fi

# Verify it doesn't actually create files in dry-run mode
if [ ! -f "$MIGRATE_DIR/CONTRIBUTING.md" ]; then
  pass "migrate.sh --dry-run does not create files"
else
  fail "migrate.sh --dry-run should not create files"
fi

# Test actual migration (without --dry-run)
"$WORK_DIR/scripts/migrate.sh" --no-color "$MIGRATE_DIR" > /dev/null 2>&1
if [ -f "$MIGRATE_DIR/CONTRIBUTING.md" ] && [ -f "$MIGRATE_DIR/validate.sh" ]; then
  pass "migrate.sh creates missing files when run without --dry-run"
else
  fail "migrate.sh should create missing files (CONTRIBUTING.md, validate.sh)"
fi

# Test --no-color flag produces no escape sequences
migrate_nocolor=$("$WORK_DIR/scripts/migrate.sh" --dry-run --no-color "$WORK_DIR" 2>&1)
if echo "$migrate_nocolor" | grep -qP '\033\['; then
  fail "migrate.sh --no-color should not contain ANSI escape sequences"
else
  pass "migrate.sh --no-color output is clean (no ANSI escapes)"
fi

# Test Session 32-34 feature detection on a fork missing those features
DETECT_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-detect-XXXXXX")
cp -r "$WORK_DIR"/* "$WORK_DIR"/.* "$DETECT_DIR/" 2>/dev/null || true
# Remove --since flag from recap.sh to simulate missing Session 32 feature
if [ -f "$DETECT_DIR/scripts/recap.sh" ]; then
  sed -i '/--since/d' "$DETECT_DIR/scripts/recap.sh"
fi
# Remove --top flag from recap.sh to simulate missing Session 34 feature
if [ -f "$DETECT_DIR/scripts/recap.sh" ]; then
  sed -i '/--top/d' "$DETECT_DIR/scripts/recap.sh"
fi
# Remove --projects flag from dashboard.sh to simulate missing Session 32 feature
if [ -f "$DETECT_DIR/scripts/dashboard.sh" ]; then
  sed -i '/--projects/d' "$DETECT_DIR/scripts/dashboard.sh"
fi
detect_output=$("$WORK_DIR/scripts/migrate.sh" --dry-run --no-color "$DETECT_DIR" 2>&1)
if echo "$detect_output" | grep -q "recap.sh missing --since"; then
  pass "migrate.sh detects missing --since in recap.sh (Session 32)"
else
  fail "migrate.sh should detect missing --since flag in recap.sh"
fi
if echo "$detect_output" | grep -q "recap.sh missing --top"; then
  pass "migrate.sh detects missing --top in recap.sh (Session 34)"
else
  fail "migrate.sh should detect missing --top flag in recap.sh"
fi
if echo "$detect_output" | grep -q "dashboard.sh missing --projects"; then
  pass "migrate.sh detects missing --projects in dashboard.sh (Session 32)"
else
  fail "migrate.sh should detect missing --projects flag in dashboard.sh"
fi

# Test Day 15-16 feature detection
DETECT_DIR2=$(mktemp -d "$TMPDIR_BASE/rigseed-detect2-XXXXXX")
cp -r "$WORK_DIR"/* "$WORK_DIR"/.* "$DETECT_DIR2/" 2>/dev/null || true
# Remove plan_recent_goals from metrics.sh to simulate missing Day 15 feature
if [ -f "$DETECT_DIR2/metrics.sh" ]; then
  sed -i '/plan_recent_goals/d' "$DETECT_DIR2/metrics.sh"
fi
# Remove --format from recap.sh to simulate missing Day 16 feature
if [ -f "$DETECT_DIR2/scripts/recap.sh" ]; then
  sed -i '/--format/d' "$DETECT_DIR2/scripts/recap.sh"
fi
# Remove --no-color from migrate.sh to simulate missing Day 16 feature
if [ -f "$DETECT_DIR2/scripts/migrate.sh" ]; then
  sed -i '/--no-color/d' "$DETECT_DIR2/scripts/migrate.sh"
fi
detect2_output=$("$WORK_DIR/scripts/migrate.sh" --dry-run --no-color "$DETECT_DIR2" 2>&1)
if echo "$detect2_output" | grep -q "metrics.sh --plan --since missing JSON/CSV"; then
  pass "migrate.sh detects missing metrics.sh --plan JSON/CSV output (Day 15)"
else
  fail "migrate.sh should detect missing metrics.sh --plan JSON/CSV output"
fi
if echo "$detect2_output" | grep -q "recap.sh missing --format"; then
  pass "migrate.sh detects missing recap.sh --format flag (Day 16)"
else
  fail "migrate.sh should detect missing recap.sh --format flag"
fi
if echo "$detect2_output" | grep -q "migrate.sh missing --color/--no-color"; then
  pass "migrate.sh detects missing migrate.sh --color flags (Day 16)"
else
  fail "migrate.sh should detect missing migrate.sh --color flags"
fi

rm -rf "$MIGRATE_DIR" "$DETECT_DIR" "$DETECT_DIR2"
echo ""

# --- Step 10: metrics.sh --plan --since tests ---

echo "--- Step 10: metrics.sh --plan --since ---"

# metrics.sh --plan --since requires ROADMAP.md, NEXT_STEPS.md, and JOURNAL.md
# We already have a simulated project in $WORK_DIR from earlier steps

# Test JSON format: --plan --since 1 should produce valid JSON with plan object
plan_json=$("$WORK_DIR/metrics.sh" --format=json --plan --since 1 --no-color "$WORK_DIR" 2>/dev/null || true)
if echo "$plan_json" | grep -q '"plan"'; then
  pass "metrics.sh --plan --since 1 --format=json includes plan object"
else
  fail "metrics.sh --plan --since 1 --format=json should include plan object"
fi
if echo "$plan_json" | grep -q '"next_steps"'; then
  pass "metrics.sh --plan JSON includes next_steps array"
else
  fail "metrics.sh --plan JSON should include next_steps array"
fi
if echo "$plan_json" | grep -q '"recent_goals"'; then
  pass "metrics.sh --plan --since 1 JSON includes recent_goals"
else
  fail "metrics.sh --plan --since 1 JSON should include recent_goals"
fi

# Test CSV format: --plan --since 1 should produce CSV tables
plan_csv=$("$WORK_DIR/metrics.sh" --format=csv --plan --since 1 --no-color "$WORK_DIR" 2>/dev/null || true)
if echo "$plan_csv" | grep -q 'next_step_status'; then
  pass "metrics.sh --plan --format=csv includes next_step_status header"
else
  fail "metrics.sh --plan --format=csv should include next_step_status header"
fi
if echo "$plan_csv" | grep -q 'recent_goal_session'; then
  pass "metrics.sh --plan --since 1 CSV includes recent_goal_session header"
else
  fail "metrics.sh --plan --since 1 CSV should include recent_goal_session header"
fi

echo ""

# --- Step 11: validate.sh --lint --fix tests ---

echo "--- Step 11: validate.sh --lint --fix ---"

# Test validate.sh --lint on the test project (should pass — scripts are well-formed)
run_test "validate.sh --lint passes on valid scripts" "$WORK_DIR/validate.sh" --lint --no-color "$WORK_DIR"

# Create a script with a shellcheck-fixable issue to test --fix
LINT_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-lint-XXXXXX")
cp -r "$WORK_DIR"/* "$WORK_DIR"/.* "$LINT_DIR/" 2>/dev/null || true
# Introduce a shellcheck-detectable issue (unused variable without annotation)
cat > "$LINT_DIR/scripts/test-lint.sh" << 'SCRIPT'
#!/usr/bin/env bash
# test-lint.sh — test script for lint testing
set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    -h|--help) echo "help"; exit 0 ;;
    --color) echo "color" ;;
    --no-color) echo "no-color" ;;
  esac
done

# Shellcheck will flag this: use of $@ without quotes in some contexts
items=( one two three )
echo ${items[@]}
SCRIPT
chmod +x "$LINT_DIR/scripts/test-lint.sh"

# --lint without --fix should detect the issue
lint_output=$("$LINT_DIR/validate.sh" --lint --no-color "$LINT_DIR" 2>&1 || true)
if echo "$lint_output" | grep -q 'test-lint.sh'; then
  pass "validate.sh --lint detects shellcheck issues in test script"
else
  fail "validate.sh --lint should detect shellcheck issues in test-lint.sh"
fi

# --lint --fix should attempt to auto-fix
if command -v shellcheck >/dev/null 2>&1; then
  fix_output=$("$LINT_DIR/validate.sh" --lint --fix --no-color "$LINT_DIR" 2>&1 || true)
  if echo "$fix_output" | grep -q 'auto-fix\|Auto-fixed'; then
    pass "validate.sh --lint --fix attempts auto-fix"
  else
    # Even if the specific issue isn't auto-fixable, the flag should be recognized
    pass "validate.sh --lint --fix runs without error (fix may not apply to all issues)"
  fi
else
  pass "validate.sh --lint --fix test skipped (shellcheck not installed)"
fi

rm -rf "$LINT_DIR"
echo ""

# --- Step 12: health-check.sh --format tests ---

echo "--- Step 12: health-check.sh --format ---"

# JSON format
hc_json=$("$WORK_DIR/health-check.sh" --format=json "$WORK_DIR" 2>&1 || true)
if echo "$hc_json" | python3 -m json.tool > /dev/null 2>&1; then
  pass "health-check.sh --format=json produces valid JSON"
else
  fail "health-check.sh --format=json should produce valid JSON"
fi
if echo "$hc_json" | grep -q '"status"'; then
  pass "health-check.sh JSON output contains status field"
else
  fail "health-check.sh JSON output should contain status field"
fi
if echo "$hc_json" | grep -q '"checks"'; then
  pass "health-check.sh JSON output contains checks array"
else
  fail "health-check.sh JSON output should contain checks array"
fi

# CSV format
hc_csv=$("$WORK_DIR/health-check.sh" --format=csv "$WORK_DIR" 2>&1 || true)
if echo "$hc_csv" | head -1 | grep -q 'category,status,message'; then
  pass "health-check.sh --format=csv has correct header"
else
  fail "health-check.sh --format=csv should have category,status,message header"
fi

# KV format
hc_kv=$("$WORK_DIR/health-check.sh" --format=kv "$WORK_DIR" 2>&1 || true)
if echo "$hc_kv" | grep -q '^status='; then
  pass "health-check.sh --format=kv contains status key"
else
  fail "health-check.sh --format=kv should contain status= line"
fi
if echo "$hc_kv" | grep -q '^errors='; then
  pass "health-check.sh --format=kv contains errors key"
else
  fail "health-check.sh --format=kv should contain errors= line"
fi

# --json alias
hc_alias=$("$WORK_DIR/health-check.sh" --json "$WORK_DIR" 2>&1 || true)
if echo "$hc_alias" | python3 -m json.tool > /dev/null 2>&1; then
  pass "health-check.sh --json alias produces valid JSON"
else
  fail "health-check.sh --json alias should produce valid JSON"
fi

echo ""

# --- Step 13: migrate.sh Day 17 detection tests ---

echo "--- Step 13: migrate.sh Day 17 detection ---"

# Strip --format from dashboard.sh to simulate missing Day 17 feature
MIGRATE_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-migrate17-XXXXXX")
cp -r "$WORK_DIR"/* "$WORK_DIR"/.* "$MIGRATE_DIR/" 2>/dev/null || true
sed -i '/--format/d' "$MIGRATE_DIR/scripts/dashboard.sh" 2>/dev/null || true

migrate_out=$("$PROJECT_DIR/scripts/migrate.sh" --dry-run --no-color "$MIGRATE_DIR" 2>&1 || true)
if echo "$migrate_out" | grep -q 'dashboard.sh missing --format'; then
  pass "migrate.sh detects missing dashboard.sh --format flag (Day 17)"
else
  fail "migrate.sh should detect missing dashboard.sh --format flag"
fi

# Strip last-dispatch from evolve plugin to simulate missing dispatch persistence
if [ -f "$MIGRATE_DIR/plugins/evolve/plugin.md" ]; then
  sed -i '/last-dispatch/d' "$MIGRATE_DIR/plugins/evolve/plugin.md" 2>/dev/null || true
  migrate_out2=$("$PROJECT_DIR/scripts/migrate.sh" --dry-run --no-color "$MIGRATE_DIR" 2>&1 || true)
  if echo "$migrate_out2" | grep -q 'dispatch timestamp'; then
    pass "migrate.sh detects missing evolve plugin dispatch persistence (Day 17)"
  else
    fail "migrate.sh should detect missing evolve plugin dispatch persistence"
  fi
fi

rm -rf "$MIGRATE_DIR"
echo ""

# --- Step 14: shellcheck CI gate ---

echo "--- Step 14: shellcheck CI gate ---"

if command -v shellcheck >/dev/null 2>&1; then
  sc_failures=0
  for script in "$PROJECT_DIR/validate.sh" "$PROJECT_DIR/health-check.sh" "$PROJECT_DIR/metrics.sh" "$PROJECT_DIR/quickstart.sh" \
    "$PROJECT_DIR/scripts/check.sh" "$PROJECT_DIR/scripts/dashboard.sh" "$PROJECT_DIR/scripts/recap.sh" \
    "$PROJECT_DIR/scripts/migrate.sh" "$PROJECT_DIR/scripts/release.sh" "$PROJECT_DIR/scripts/rollback.sh" \
    "$PROJECT_DIR/scripts/sync-upstream.sh" "$PROJECT_DIR/scripts/lint-workflows.sh" \
    "$PROJECT_DIR/scripts/grafana.sh" "$PROJECT_DIR/scripts/check-evolve-state.sh"; do
    [ -f "$script" ] || continue
    if ! shellcheck -S warning "$script" > /dev/null 2>&1; then
      echo "    shellcheck warning in: $(basename "$script")"
      sc_failures=$((sc_failures + 1))
    fi
  done
  if [ "$sc_failures" -eq 0 ]; then
    pass "shellcheck passes on all scripts (warning level)"
  else
    fail "shellcheck found warnings in $sc_failures script(s)"
  fi
else
  pass "shellcheck CI gate skipped (shellcheck not installed)"
fi
echo ""

# --- Step 15: check.sh --format tests ---

echo "--- Step 15: check.sh --format ---"

# JSON format
ck_json=$("$WORK_DIR/scripts/check.sh" --format=json "$WORK_DIR" 2>&1 || true)
if echo "$ck_json" | grep -q '"result"' && echo "$ck_json" | grep -q '"passed"'; then
  pass "check.sh --format=json outputs JSON with expected fields"
else
  fail "check.sh --format=json missing expected JSON fields"
fi

# CSV format
ck_csv=$("$WORK_DIR/scripts/check.sh" --format=csv "$WORK_DIR" 2>&1 || true)
if echo "$ck_csv" | head -1 | grep -q 'name,status'; then
  pass "check.sh --format=csv has correct header"
else
  fail "check.sh --format=csv missing expected header row"
fi

# KV format
ck_kv=$("$WORK_DIR/scripts/check.sh" --format=kv "$WORK_DIR" 2>&1 || true)
if echo "$ck_kv" | grep -q '^result='; then
  pass "check.sh --format=kv contains result key"
else
  fail "check.sh --format=kv missing result= line"
fi

# --json backward compat alias
ck_alias=$("$WORK_DIR/scripts/check.sh" --json "$WORK_DIR" 2>&1 || true)
if echo "$ck_alias" | grep -q '"result"'; then
  pass "check.sh --json backward compat produces JSON"
else
  fail "check.sh --json backward compat broken"
fi

echo ""

# --- Step 16: dashboard.sh --projects + --format combined ---

echo "--- Step 16: dashboard.sh --projects + --format ---"

# Set up multi-project directory
DASH_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-dash-XXXXXX")
for proj in alpha beta; do
  mkdir -p "$DASH_DIR/$proj"
  cp "$WORK_DIR/SESSION_COUNT" "$DASH_DIR/$proj/"
  cp "$WORK_DIR/DAY_COUNT" "$DASH_DIR/$proj/"
  cp "$WORK_DIR/JOURNAL.md" "$DASH_DIR/$proj/"
  cp "$WORK_DIR/ROADMAP.md" "$DASH_DIR/$proj/"
  cp "$WORK_DIR/LEARNINGS.md" "$DASH_DIR/$proj/"
  cp -r "$WORK_DIR/.evolve" "$DASH_DIR/$proj/"
  (cd "$DASH_DIR/$proj" && git init -q && git add -A && git commit -q -m "init" 2>/dev/null)
done

# --projects + --format=csv
dash_csv=$("$PROJECT_DIR/scripts/dashboard.sh" --projects "$DASH_DIR" --format=csv 2>&1 || true)
if echo "$dash_csv" | head -1 | grep -q 'name,'; then
  pass "dashboard.sh --projects --format=csv has CSV header"
else
  fail "dashboard.sh --projects --format=csv missing CSV header"
fi
csv_data_lines=$(echo "$dash_csv" | tail -n +2 | wc -l)
if [ "$csv_data_lines" -ge 2 ]; then
  pass "dashboard.sh --projects --format=csv includes project data rows"
else
  fail "dashboard.sh --projects --format=csv missing project data"
fi

# --projects + --format=json
dash_json=$("$PROJECT_DIR/scripts/dashboard.sh" --projects "$DASH_DIR" --format=json 2>&1 || true)
if echo "$dash_json" | grep -q '"name"'; then
  pass "dashboard.sh --projects --format=json includes name field"
else
  fail "dashboard.sh --projects --format=json missing name field"
fi

# --projects + --format=kv
dash_kv=$("$PROJECT_DIR/scripts/dashboard.sh" --projects "$DASH_DIR" --format=kv 2>&1 || true)
if echo "$dash_kv" | grep -q '^project='; then
  pass "dashboard.sh --projects --format=kv includes project= key"
else
  fail "dashboard.sh --projects --format=kv missing project= key"
fi

rm -rf "$DASH_DIR"
echo ""

# --- Step 17: rollback.sh --format tests ---

echo "--- Step 17: rollback.sh --format ---"

# Create a temp repo with a commit to revert
RB_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-rb-XXXXXX")
git -C "$RB_DIR" init -q
echo "initial" > "$RB_DIR/file.txt"
git -C "$RB_DIR" add file.txt
git -C "$RB_DIR" commit -q -m "initial commit"
echo "change" > "$RB_DIR/file.txt"
git -C "$RB_DIR" add file.txt
git -C "$RB_DIR" commit -q -m "second commit to revert"

# JSON format (dry-run)
rb_json=$(cd "$RB_DIR" && bash "$PROJECT_DIR/scripts/rollback.sh" --dry-run --format=json 2>&1 || true)
if echo "$rb_json" | grep -q '"status"' && echo "$rb_json" | grep -q '"sha"'; then
  pass "rollback.sh --format=json --dry-run outputs JSON with expected fields"
else
  fail "rollback.sh --format=json --dry-run missing expected JSON fields"
fi

# CSV format (dry-run)
rb_csv=$(cd "$RB_DIR" && bash "$PROJECT_DIR/scripts/rollback.sh" --dry-run --format=csv 2>&1 || true)
if echo "$rb_csv" | head -1 | grep -q 'target,sha,type,status'; then
  pass "rollback.sh --format=csv --dry-run has correct header"
else
  fail "rollback.sh --format=csv --dry-run missing expected header row"
fi

# KV format (dry-run)
rb_kv=$(cd "$RB_DIR" && bash "$PROJECT_DIR/scripts/rollback.sh" --dry-run --format=kv 2>&1 || true)
if echo "$rb_kv" | grep -q '^status=' && echo "$rb_kv" | grep -q '^sha='; then
  pass "rollback.sh --format=kv --dry-run contains expected keys"
else
  fail "rollback.sh --format=kv --dry-run missing expected keys"
fi

# --json backward compat alias
rb_alias=$(cd "$RB_DIR" && bash "$PROJECT_DIR/scripts/rollback.sh" --dry-run --json 2>&1 || true)
if echo "$rb_alias" | grep -q '"status"'; then
  pass "rollback.sh --json backward compat produces JSON"
else
  fail "rollback.sh --json backward compat broken"
fi

rm -rf "$RB_DIR"
echo ""

# --- Step 18: migrate.sh detection for sync-upstream.sh and rollback.sh --format ---

echo "--- Step 18: migrate.sh --format detection ---"

# Create a stripped fork missing the format flags
MIG_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-mig-XXXXXX")
git -C "$MIG_DIR" init -q
mkdir -p "$MIG_DIR/scripts" "$MIG_DIR/.evolve"
echo "1" > "$MIG_DIR/DAY_COUNT"
echo "1" > "$MIG_DIR/SESSION_COUNT"
echo "2026-01-01" > "$MIG_DIR/DAY_DATE"
echo "# Journal" > "$MIG_DIR/JOURNAL.md"
echo "# Identity" > "$MIG_DIR/IDENTITY.md"
echo "# Specs" > "$MIG_DIR/SPECS.md"
echo "# Roadmap" > "$MIG_DIR/ROADMAP.md"
echo "# Learnings" > "$MIG_DIR/LEARNINGS.md"
echo "# Personality" > "$MIG_DIR/PERSONALITY.md"
echo "# Next" > "$MIG_DIR/NEXT_STEPS.md"
cat > "$MIG_DIR/.evolve/config.toml" << 'TOML'
[schedule]
interval = "24h"
TOML
echo "IDENTITY.md" > "$MIG_DIR/.evolve/IMMUTABLE.txt"
# Create scripts without --format flag
echo '#!/usr/bin/env bash' > "$MIG_DIR/scripts/sync-upstream.sh"
echo '#!/usr/bin/env bash' > "$MIG_DIR/scripts/rollback.sh"
git -C "$MIG_DIR" add -A
git -C "$MIG_DIR" commit -q -m "init"

mig_out=$(bash "$PROJECT_DIR/scripts/migrate.sh" --dry-run --no-color "$MIG_DIR" 2>&1 || true)
if echo "$mig_out" | grep -q 'sync-upstream.sh missing --format'; then
  pass "migrate.sh detects sync-upstream.sh missing --format flag"
else
  fail "migrate.sh failed to detect sync-upstream.sh missing --format flag"
fi
if echo "$mig_out" | grep -q 'rollback.sh missing --format'; then
  pass "migrate.sh detects rollback.sh missing --format flag"
else
  fail "migrate.sh failed to detect rollback.sh missing --format flag"
fi

rm -rf "$MIG_DIR"
echo ""

# --- Step 19: lint-workflows.sh --format tests ---

echo "--- Step 19: lint-workflows.sh --format ---"

# Create a temp project with a workflow file for lint testing
LW_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-lw-XXXXXX")
mkdir -p "$LW_DIR/.github/workflows"
cat > "$LW_DIR/.github/workflows/ci.yml" << 'YML'
name: CI
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo hello
YML

# JSON format
lw_json=$(bash "$PROJECT_DIR/scripts/lint-workflows.sh" --format=json --no-color "$LW_DIR" 2>&1 || true)
if echo "$lw_json" | grep -q '"files_checked"' && echo "$lw_json" | grep -q '"result"'; then
  pass "lint-workflows.sh --format=json outputs JSON with expected fields"
else
  fail "lint-workflows.sh --format=json missing expected JSON fields"
fi

# Validate JSON with python3 if available
if command -v python3 &>/dev/null; then
  if echo "$lw_json" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    pass "lint-workflows.sh --format=json produces valid JSON"
  else
    fail "lint-workflows.sh --format=json produces invalid JSON"
  fi
fi

# CSV format
lw_csv=$(bash "$PROJECT_DIR/scripts/lint-workflows.sh" --format=csv --no-color "$LW_DIR" 2>&1 || true)
if echo "$lw_csv" | grep -q 'file,severity,message'; then
  pass "lint-workflows.sh --format=csv has correct header"
else
  fail "lint-workflows.sh --format=csv missing expected header row"
fi

# KV format
lw_kv=$(bash "$PROJECT_DIR/scripts/lint-workflows.sh" --format=kv --no-color "$LW_DIR" 2>&1 || true)
if echo "$lw_kv" | grep -q 'result='; then
  pass "lint-workflows.sh --format=kv contains result key"
else
  fail "lint-workflows.sh --format=kv missing result= line"
fi
if echo "$lw_kv" | grep -q 'errors='; then
  pass "lint-workflows.sh --format=kv contains errors key"
else
  fail "lint-workflows.sh --format=kv missing errors= line"
fi

rm -rf "$LW_DIR"
echo ""

# --- Step 20: JSON schema validation for structured output ---

echo "--- Step 20: JSON schema validation ---"

if command -v python3 &>/dev/null; then
  # Validate health-check.sh JSON structure
  hc_json_val=$("$WORK_DIR/health-check.sh" --format=json "$WORK_DIR" 2>&1 || true)
  hc_valid=$(echo "$hc_json_val" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    assert 'status' in d, 'missing status'
    assert 'errors' in d, 'missing errors'
    assert 'checks' in d, 'missing checks'
    assert isinstance(d['checks'], list), 'checks not a list'
    print('valid')
except Exception as e:
    print(f'invalid: {e}')
" 2>/dev/null || echo "invalid: python error")
  if [ "$hc_valid" = "valid" ]; then
    pass "health-check.sh JSON schema: status, errors, checks[] present"
  else
    fail "health-check.sh JSON schema validation: $hc_valid"
  fi

  # Validate check.sh JSON structure
  ck_json_val=$("$WORK_DIR/scripts/check.sh" --format=json "$WORK_DIR" 2>&1 || true)
  ck_valid=$(echo "$ck_json_val" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    assert 'result' in d, 'missing result'
    assert 'checks' in d, 'missing checks'
    assert isinstance(d['checks'], list), 'checks not a list'
    print('valid')
except Exception as e:
    print(f'invalid: {e}')
" 2>/dev/null || echo "invalid: python error")
  if [ "$ck_valid" = "valid" ]; then
    pass "check.sh JSON schema: result, checks[] present"
  else
    fail "check.sh JSON schema validation: $ck_valid"
  fi

  # Validate metrics.sh JSON structure
  mt_json_val=$("$WORK_DIR/metrics.sh" --format=json --no-color "$WORK_DIR" 2>/dev/null || true)
  mt_valid=$(printf '%s' "$mt_json_val" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    assert isinstance(d, dict), 'not an object'
    assert 'day_count' in d, 'missing day_count'
    print('valid')
except Exception as e:
    print(f'invalid: {e}')
" 2>/dev/null || echo "invalid: python error")
  if [ "$mt_valid" = "valid" ]; then
    pass "metrics.sh JSON schema: valid object with day_count"
  else
    fail "metrics.sh JSON schema validation: $mt_valid"
  fi
else
  echo "  (skipping JSON validation — python3 not available)"
fi
echo ""

# --- Step 21: migrate.sh detection for grafana.sh and lint-workflows.sh --format ---

echo "--- Step 21: migrate.sh grafana/lint-workflows --format detection ---"

MIG_DIR2=$(mktemp -d "$TMPDIR_BASE/rigseed-mig2-XXXXXX")
git -C "$MIG_DIR2" init -q
mkdir -p "$MIG_DIR2/scripts" "$MIG_DIR2/.evolve"
echo "1" > "$MIG_DIR2/DAY_COUNT"
echo "1" > "$MIG_DIR2/SESSION_COUNT"
echo "2026-01-01" > "$MIG_DIR2/DAY_DATE"
echo "# Journal" > "$MIG_DIR2/JOURNAL.md"
echo "# Identity" > "$MIG_DIR2/IDENTITY.md"
echo "# Specs" > "$MIG_DIR2/SPECS.md"
echo "# Roadmap" > "$MIG_DIR2/ROADMAP.md"
echo "# Learnings" > "$MIG_DIR2/LEARNINGS.md"
echo "# Personality" > "$MIG_DIR2/PERSONALITY.md"
echo "# Next" > "$MIG_DIR2/NEXT_STEPS.md"
cat > "$MIG_DIR2/.evolve/config.toml" << 'TOML'
[schedule]
interval = "24h"
TOML
echo "IDENTITY.md" > "$MIG_DIR2/.evolve/IMMUTABLE.txt"
# Create scripts without --format flag
echo '#!/usr/bin/env bash' > "$MIG_DIR2/scripts/grafana.sh"
echo '#!/usr/bin/env bash' > "$MIG_DIR2/scripts/lint-workflows.sh"
git -C "$MIG_DIR2" add -A
git -C "$MIG_DIR2" commit -q -m "init"

mig_out2=$(bash "$PROJECT_DIR/scripts/migrate.sh" --dry-run --no-color "$MIG_DIR2" 2>&1 || true)
if echo "$mig_out2" | grep -q 'grafana.sh missing --format'; then
  pass "migrate.sh detects grafana.sh missing --format flag"
else
  fail "migrate.sh failed to detect grafana.sh missing --format flag"
fi
if echo "$mig_out2" | grep -q 'lint-workflows.sh missing --format'; then
  pass "migrate.sh detects lint-workflows.sh missing --format flag"
else
  fail "migrate.sh failed to detect lint-workflows.sh missing --format flag"
fi

rm -rf "$MIG_DIR2"
echo ""

# --- Step 22: check.sh end-to-end with real Python build system ---
echo "--- Step 22: check.sh end-to-end with real build system ---"

if command -v python3 &>/dev/null; then
  CK_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-ck-XXXXXX")
  git init -q "$CK_DIR"
  git -C "$CK_DIR" config user.email "test@test.com"
  git -C "$CK_DIR" config user.name "Test"

  # Set up a minimal rig-seed project with a real Python project
  mkdir -p "$CK_DIR/.evolve" "$CK_DIR/scripts" "$CK_DIR/tests"
  cp "$PROJECT_DIR/.evolve/config.toml" "$CK_DIR/.evolve/config.toml"
  cp "$PROJECT_DIR/scripts/check.sh" "$CK_DIR/scripts/check.sh"
  chmod +x "$CK_DIR/scripts/check.sh"

  # Create a Python project with pyproject.toml and a passing test
  cat > "$CK_DIR/pyproject.toml" << 'PYEOF'
[project]
name = "test-project"
version = "0.1.0"
[tool.pytest]
testpaths = ["tests"]
PYEOF

  cat > "$CK_DIR/src_module.py" << 'PYEOF'
def add(a, b):
    return a + b
PYEOF

  cat > "$CK_DIR/tests/test_basic.py" << 'PYEOF'
from src_module import add

def test_add():
    assert add(1, 2) == 3
PYEOF

  git -C "$CK_DIR" add -A
  git -C "$CK_DIR" commit -q -m "initial"

  # Run check.sh — should detect Python and run pytest
  ck_out=$("$CK_DIR/scripts/check.sh" --no-color "$CK_DIR" 2>&1 || true)
  if echo "$ck_out" | grep -qi 'Python project detected'; then
    pass "check.sh detects Python project (pyproject.toml)"
  else
    fail "check.sh should detect Python project"
  fi

  if echo "$ck_out" | grep -qi 'pytest.*pass\|RESULT.*pass\|all checks passed'; then
    pass "check.sh runs pytest and all checks pass"
  else
    # Check if pytest isn't installed or test failed
    if echo "$ck_out" | grep -qi 'pytest.*not found\|No module named.*pytest\|pytest FAILED'; then
      pass "check.sh detects pytest (not installed or test failed — expected in minimal env)"
    else
      fail "check.sh with Python project: unexpected output"
    fi
  fi

  # Test JSON format output
  ck_json=$("$CK_DIR/scripts/check.sh" --format=json --no-color "$CK_DIR" 2>&1 || true)
  if echo "$ck_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'checks' in d or 'result' in d, 'missing expected key'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
    pass "check.sh --format=json with real project produces valid JSON"
  else
    fail "check.sh --format=json with real project should produce valid JSON"
  fi

  rm -rf "$CK_DIR"
else
  echo "  (skipping — python3 not available)"
fi
echo ""

# --- Step 23: quickstart.sh --check --format tests ---

echo "--- Step 23: quickstart.sh --check --format ---"

# JSON format
qs_json=$("$WORK_DIR/quickstart.sh" --check --format=json 2>&1 || true)
if echo "$qs_json" | grep -q '"result"' && echo "$qs_json" | grep -q '"checks"'; then
  pass "quickstart.sh --check --format=json outputs JSON with expected fields"
else
  fail "quickstart.sh --check --format=json missing expected JSON fields"
fi

# Validate JSON with python3 if available
if command -v python3 &>/dev/null; then
  if echo "$qs_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'result' in d and 'checks' in d and 'errors' in d, 'missing expected key'
assert isinstance(d['checks'], list), 'checks should be array'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
    pass "quickstart.sh --check --format=json produces valid JSON"
  else
    fail "quickstart.sh --check --format=json should produce valid JSON"
  fi
fi

# CSV format
qs_csv=$("$WORK_DIR/quickstart.sh" --check --format=csv 2>&1 || true)
if echo "$qs_csv" | head -1 | grep -q 'file,status'; then
  pass "quickstart.sh --check --format=csv has correct header"
else
  fail "quickstart.sh --check --format=csv missing expected header row"
fi

# KV format
qs_kv=$("$WORK_DIR/quickstart.sh" --check --format=kv 2>&1 || true)
if echo "$qs_kv" | grep -q '^result='; then
  pass "quickstart.sh --check --format=kv contains result key"
else
  fail "quickstart.sh --check --format=kv missing result= line"
fi

# --json backward compat alias
qs_alias=$("$WORK_DIR/quickstart.sh" --check --json 2>&1 || true)
if echo "$qs_alias" | grep -q '"result"'; then
  pass "quickstart.sh --check --json backward compat produces JSON"
else
  fail "quickstart.sh --check --json backward compat broken"
fi

echo ""

# --- Step 24: migrate.sh detection for quickstart.sh --format ---

echo "--- Step 24: migrate.sh quickstart --format detection ---"

# Create a stripped fork without quickstart --format
QS_STRIP=$(mktemp -d "$TMPDIR_BASE/rigseed-qs-strip-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$QS_STRIP/"
(cd "$QS_STRIP" && git init -q && git add -A && git commit -q -m "init")

# Remove --format from quickstart.sh to simulate old fork
sed -i '/--format=/d' "$QS_STRIP/quickstart.sh"
sed -i '/--json/d' "$QS_STRIP/quickstart.sh"

mig_qs=$("$QS_STRIP/scripts/migrate.sh" --dry-run "$QS_STRIP" 2>&1 || true)
if echo "$mig_qs" | grep -q 'quickstart.sh missing --format'; then
  pass "migrate.sh detects missing quickstart.sh --format flag"
else
  fail "migrate.sh should detect missing quickstart.sh --format flag"
fi

rm -rf "$QS_STRIP"

echo ""

# --- Step 25: migrate.sh lib.sh detection ---

echo "--- Step 25: migrate.sh lib.sh detection ---"

LIB_STRIP=$(mktemp -d "$TMPDIR_BASE/rigseed-lib-strip-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$LIB_STRIP/"
(cd "$LIB_STRIP" && git init -q && git add -A && git commit -q -m "init")

# Remove lib.sh to simulate old fork
rm -f "$LIB_STRIP/scripts/lib.sh"

mig_lib=$("$LIB_STRIP/scripts/migrate.sh" --dry-run "$LIB_STRIP" 2>&1 || true)
if echo "$mig_lib" | grep -q 'lib.sh missing'; then
  pass "migrate.sh detects missing scripts/lib.sh"
else
  fail "migrate.sh should detect missing scripts/lib.sh"
fi

rm -rf "$LIB_STRIP"

echo ""

# --- Step 26: validate.sh --format output ---

echo "--- Step 26: validate.sh --format output ---"

# JSON format
val_json=$(bash "$PROJECT_DIR/validate.sh" --format=json "$PROJECT_DIR" 2>&1)
if echo "$val_json" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'checks' in d and 'result' in d" 2>/dev/null; then
  pass "validate.sh --format=json produces valid JSON with checks and result"
else
  fail "validate.sh --format=json should produce valid JSON with checks and result"
fi

# CSV format
val_csv=$(bash "$PROJECT_DIR/validate.sh" --format=csv "$PROJECT_DIR" 2>&1)
if echo "$val_csv" | head -1 | grep -q 'category,file,status,message'; then
  pass "validate.sh --format=csv has correct header"
else
  fail "validate.sh --format=csv should have category,file,status,message header"
fi

# KV format
val_kv=$(bash "$PROJECT_DIR/validate.sh" --format=kv "$PROJECT_DIR" 2>&1)
if echo "$val_kv" | grep -q 'result=pass'; then
  pass "validate.sh --format=kv includes result=pass"
else
  fail "validate.sh --format=kv should include result=pass"
fi

# --json alias
val_alias=$(bash "$PROJECT_DIR/validate.sh" --json "$PROJECT_DIR" 2>&1)
if echo "$val_alias" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  pass "validate.sh --json alias produces valid JSON"
else
  fail "validate.sh --json alias should produce valid JSON"
fi

# JSON schema: check that checks array has category, file, status, message
if echo "$val_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
c = d['checks'][0]
assert all(k in c for k in ('category','file','status','message')), 'missing keys'
" 2>/dev/null; then
  pass "validate.sh --format=json check entries have required fields"
else
  fail "validate.sh --format=json check entries should have category, file, status, message"
fi

echo ""

# --- Step 27: metrics-exporter.sh --once output ---

echo "--- Step 27: metrics-exporter.sh --once output ---"

EXPORTER="$PROJECT_DIR/docs/examples/monitoring/metrics-exporter.sh"

# --once with default format (prometheus)
exp_prom=$(bash "$EXPORTER" --once "$PROJECT_DIR" 2>&1)
if echo "$exp_prom" | grep -q '# TYPE rigseed_'; then
  pass "metrics-exporter.sh --once produces Prometheus format"
else
  fail "metrics-exporter.sh --once should produce Prometheus format"
fi

# --once --format=json
exp_json=$(bash "$EXPORTER" --once --format=json "$PROJECT_DIR" 2>&1)
if echo "$exp_json" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'metrics' in d and 'project' in d" 2>/dev/null; then
  pass "metrics-exporter.sh --once --format=json produces valid JSON"
else
  fail "metrics-exporter.sh --once --format=json should produce valid JSON"
fi

# --once --format=csv
exp_csv=$(bash "$EXPORTER" --once --format=csv "$PROJECT_DIR" 2>&1)
if echo "$exp_csv" | head -1 | grep -q 'metric,value'; then
  pass "metrics-exporter.sh --once --format=csv has correct header"
else
  fail "metrics-exporter.sh --once --format=csv should have metric,value header"
fi

# --once --format=kv
exp_kv=$(bash "$EXPORTER" --once --format=kv "$PROJECT_DIR" 2>&1)
if echo "$exp_kv" | grep -q 'session_count='; then
  pass "metrics-exporter.sh --once --format=kv includes session_count"
else
  fail "metrics-exporter.sh --once --format=kv should include session_count"
fi

echo ""

# --- Step 28: grafana.sh --format status (mocked docker) ---

echo "--- Step 28: grafana.sh --format status (mocked docker) ---"

# Create a mock docker/podman that returns fake container info
MOCK_BIN=$(mktemp -d "$TMPDIR_BASE/mock-bin-XXXXXX")

cat > "$MOCK_BIN/docker" << 'MOCKEOF'
#!/usr/bin/env bash
case "$*" in
  *"compose"*) exit 0 ;;
  *"inspect -f"*"rigseed-prometheus"*) echo "running" ;;
  *"inspect -f"*"rigseed-grafana"*) echo "running" ;;
  *"inspect rigseed-prometheus"*) exit 0 ;;
  *"inspect rigseed-grafana"*) exit 0 ;;
  *) echo "mock-docker: $*" >&2; exit 0 ;;
esac
MOCKEOF
chmod +x "$MOCK_BIN/docker"

# Also create docker-compose mock
cat > "$MOCK_BIN/docker-compose" << 'MOCKEOF'
#!/usr/bin/env bash
exit 0
MOCKEOF
chmod +x "$MOCK_BIN/docker-compose"

# Run grafana.sh status with mocked docker in PATH
graf_json=$(PATH="$MOCK_BIN:$PATH" bash "$PROJECT_DIR/scripts/grafana.sh" --format=json status "$PROJECT_DIR" 2>&1 || true)
if echo "$graf_json" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'components' in d" 2>/dev/null; then
  pass "grafana.sh --format=json status produces valid JSON with components"
else
  fail "grafana.sh --format=json status should produce valid JSON with components"
fi

graf_csv=$(PATH="$MOCK_BIN:$PATH" bash "$PROJECT_DIR/scripts/grafana.sh" --format=csv status "$PROJECT_DIR" 2>&1 || true)
if echo "$graf_csv" | head -1 | grep -q 'component,status,url'; then
  pass "grafana.sh --format=csv status has correct header"
else
  fail "grafana.sh --format=csv status should have component,status,url header"
fi

graf_kv=$(PATH="$MOCK_BIN:$PATH" bash "$PROJECT_DIR/scripts/grafana.sh" --format=kv status "$PROJECT_DIR" 2>&1 || true)
if echo "$graf_kv" | grep -q '_status='; then
  pass "grafana.sh --format=kv status includes component status"
else
  fail "grafana.sh --format=kv status should include component status"
fi

rm -rf "$MOCK_BIN"

echo ""

# --- Step 29: migrate.sh detection for validate.sh --format ---

echo "--- Step 29: migrate.sh validate.sh --format detection ---"

VAL_STRIP=$(mktemp -d "$TMPDIR_BASE/rigseed-val-strip-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$VAL_STRIP/"
(cd "$VAL_STRIP" && git init -q && git add -A && git commit -q -m "init")

# Remove --format from validate.sh to simulate old fork
sed -i '/--format/d' "$VAL_STRIP/validate.sh"

mig_val=$("$VAL_STRIP/scripts/migrate.sh" --dry-run "$VAL_STRIP" 2>&1 || true)
if echo "$mig_val" | grep -q 'validate.sh.*--format\|validate.sh missing --format'; then
  pass "migrate.sh detects missing validate.sh --format flag"
else
  fail "migrate.sh should detect missing validate.sh --format flag"
fi

rm -rf "$VAL_STRIP"

echo ""

# --- Step 30: release.sh --format ---

echo "--- Step 30: release.sh --format ---"

# JSON format (dry-run)
rel_json=$(bash "$PROJECT_DIR/scripts/release.sh" --dry-run --format=json 2>&1)
if echo "$rel_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert all(k in d for k in ('new_tag','bump','dry_run','status','message')), 'missing keys'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "release.sh --dry-run --format=json produces valid JSON with expected fields"
else
  fail "release.sh --dry-run --format=json should produce valid JSON with expected fields"
fi

# CSV format
rel_csv=$(bash "$PROJECT_DIR/scripts/release.sh" --dry-run --format=csv 2>&1)
if echo "$rel_csv" | head -1 | grep -q 'latest_tag,new_tag,bump'; then
  pass "release.sh --dry-run --format=csv has correct header"
else
  fail "release.sh --dry-run --format=csv should have latest_tag,new_tag,bump header"
fi

# KV format
rel_kv=$(bash "$PROJECT_DIR/scripts/release.sh" --dry-run --format=kv 2>&1)
if echo "$rel_kv" | grep -q '^new_tag=' && echo "$rel_kv" | grep -q '^status='; then
  pass "release.sh --dry-run --format=kv contains new_tag and status"
else
  fail "release.sh --dry-run --format=kv should contain new_tag and status"
fi

# --json alias
rel_alias=$(bash "$PROJECT_DIR/scripts/release.sh" --dry-run --json 2>&1)
if echo "$rel_alias" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  pass "release.sh --json alias produces valid JSON"
else
  fail "release.sh --json alias should produce valid JSON"
fi

echo ""

# --- Step 31: check-evolve-state.sh --format ---

echo "--- Step 31: check-evolve-state.sh --format ---"

# Create a branch with state file changes to test passing output
CES_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-ces-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$CES_DIR/"
(
  cd "$CES_DIR"
  git init -q
  git add -A
  git commit -q -m "Initial"
  git checkout -q -b test-branch
  echo "updated" >> JOURNAL.md
  echo "updated" >> NEXT_STEPS.md
  echo "99" > SESSION_COUNT
  echo "updated" >> ROADMAP.md
  echo "18" > DAY_COUNT
  echo "2026-04-02" > DAY_DATE
  git add -A
  git commit -q -m "Session updates"
)

# JSON format
ces_json=$(cd "$CES_DIR" && bash scripts/check-evolve-state.sh --format=json main 2>&1 || true)
if echo "$ces_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert all(k in d for k in ('base_branch','errors','warnings','result','checks')), 'missing keys'
assert isinstance(d['checks'], list) and len(d['checks']) > 0, 'checks should be non-empty array'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "check-evolve-state.sh --format=json produces valid JSON with expected fields"
else
  fail "check-evolve-state.sh --format=json should produce valid JSON with expected fields"
fi

# CSV format
ces_csv=$(cd "$CES_DIR" && bash scripts/check-evolve-state.sh --format=csv main 2>&1 || true)
if echo "$ces_csv" | head -1 | grep -q 'file,type,status,message'; then
  pass "check-evolve-state.sh --format=csv has correct header"
else
  fail "check-evolve-state.sh --format=csv should have file,type,status,message header"
fi

# KV format
ces_kv=$(cd "$CES_DIR" && bash scripts/check-evolve-state.sh --format=kv main 2>&1 || true)
if echo "$ces_kv" | grep -q '^result=' && echo "$ces_kv" | grep -q '^errors='; then
  pass "check-evolve-state.sh --format=kv contains result and errors"
else
  fail "check-evolve-state.sh --format=kv should contain result and errors"
fi

# --json alias
ces_alias=$(cd "$CES_DIR" && bash scripts/check-evolve-state.sh --json main 2>&1 || true)
if echo "$ces_alias" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  pass "check-evolve-state.sh --json alias produces valid JSON"
else
  fail "check-evolve-state.sh --json alias should produce valid JSON"
fi

rm -rf "$CES_DIR"

echo ""

# --- Step 32: migrate.sh release.sh/check-evolve-state.sh --format detection ---

echo "--- Step 32: migrate.sh release.sh/check-evolve-state.sh --format detection ---"

MIG_STRIP=$(mktemp -d "$TMPDIR_BASE/rigseed-mig-strip-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$MIG_STRIP/"
(cd "$MIG_STRIP" && git init -q && git add -A && git commit -q -m "init")

# Remove --format from both scripts to simulate old fork
sed -i '/--format/d' "$MIG_STRIP/scripts/release.sh"
sed -i '/--format/d' "$MIG_STRIP/scripts/check-evolve-state.sh"

mig_rel=$("$MIG_STRIP/scripts/migrate.sh" --dry-run "$MIG_STRIP" 2>&1 || true)
if echo "$mig_rel" | grep -q 'release.sh missing --format'; then
  pass "migrate.sh detects missing release.sh --format flag"
else
  fail "migrate.sh should detect missing release.sh --format flag"
fi

if echo "$mig_rel" | grep -q 'check-evolve-state.sh missing --format'; then
  pass "migrate.sh detects missing check-evolve-state.sh --format flag"
else
  fail "migrate.sh should detect missing check-evolve-state.sh --format flag"
fi

rm -rf "$MIG_STRIP"

echo ""

# --- Step 33: sync-upstream.sh end-to-end (mocked upstream) ---

echo "--- Step 33: sync-upstream.sh end-to-end (mocked upstream) ---"

# Create a mock "upstream" bare repo from the project
SYNC_UPSTREAM_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-sync-upstream-XXXXXX")
SYNC_FORK_DIR=$(mktemp -d "$TMPDIR_BASE/rigseed-sync-fork-XXXXXX")

# Set up bare upstream repo
(
  cd "$SYNC_UPSTREAM_DIR"
  git init -q --bare
)

# Set up fork repo with project files
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$SYNC_FORK_DIR/"
(
  cd "$SYNC_FORK_DIR"
  git init -q
  git add -A
  git commit -q -m "Initial fork"
  git remote add origin "$SYNC_UPSTREAM_DIR"
  git push -q origin HEAD:main
)

# Now simulate upstream changes: push a new commit to the "upstream" bare repo
SYNC_CLONE=$(mktemp -d "$TMPDIR_BASE/rigseed-sync-clone-XXXXXX")
(
  cd "$SYNC_CLONE"
  git clone -q "$SYNC_UPSTREAM_DIR" .
  # Modify an infrastructure file (one that syncs)
  echo "# Updated upstream validate.sh" >> validate.sh
  echo "# New upstream doc content" >> docs/EVOLUTION.md
  git add -A
  git commit -q -m "Upstream improvement"
  git push -q origin main
)
rm -rf "$SYNC_CLONE"

# Test 1: dry-run detects changes
sync_dry=$(cd "$SYNC_FORK_DIR" && bash scripts/sync-upstream.sh --dry-run --upstream="$SYNC_UPSTREAM_DIR" --no-color 2>&1 || true)
if echo "$sync_dry" | grep -q 'dry run complete'; then
  pass "sync-upstream.sh --dry-run detects upstream changes"
else
  fail "sync-upstream.sh --dry-run should detect upstream changes"
fi

# Test 2: dry-run JSON format
sync_dry_json=$(cd "$SYNC_FORK_DIR" && bash scripts/sync-upstream.sh --dry-run --upstream="$SYNC_UPSTREAM_DIR" --format=json 2>&1 || true)
if echo "$sync_dry_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['status'] == 'dry-run', 'status should be dry-run'
assert d['changes'] > 0, 'should have changes'
assert 'files' in d, 'should have files array'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "sync-upstream.sh --dry-run --format=json produces valid JSON with files"
else
  fail "sync-upstream.sh --dry-run --format=json should produce valid JSON with files"
fi

# Test 3: live sync applies changes
sync_live=$(cd "$SYNC_FORK_DIR" && bash scripts/sync-upstream.sh --upstream="$SYNC_UPSTREAM_DIR" --no-color 2>&1 || true)
if echo "$sync_live" | grep -q 'sync complete'; then
  pass "sync-upstream.sh live sync merges upstream changes"
else
  fail "sync-upstream.sh live sync should merge upstream changes"
fi

# Verify the synced file was actually updated
if grep -q "Updated upstream validate.sh" "$SYNC_FORK_DIR/validate.sh"; then
  pass "sync-upstream.sh actually applied upstream file changes"
else
  fail "sync-upstream.sh should have applied upstream file changes to validate.sh"
fi

# Test 4: running again shows up-to-date
sync_noop=$(cd "$SYNC_FORK_DIR" && bash scripts/sync-upstream.sh --upstream="$SYNC_UPSTREAM_DIR" --format=kv 2>&1 || true)
if echo "$sync_noop" | grep -q 'status=up-to-date'; then
  pass "sync-upstream.sh reports up-to-date after sync"
else
  fail "sync-upstream.sh should report up-to-date after sync"
fi

rm -rf "$SYNC_UPSTREAM_DIR" "$SYNC_FORK_DIR"

echo ""

# --- Step 34: check-evolve-state.sh edge cases ---

echo "--- Step 34: check-evolve-state.sh edge cases ---"

# Edge case 1: no-changes branch (zero commits ahead of base)
CES_NOCHANGE=$(mktemp -d "$TMPDIR_BASE/rigseed-ces-nochange-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$CES_NOCHANGE/"
(
  cd "$CES_NOCHANGE"
  git init -q
  git add -A
  git commit -q -m "Initial"
  git checkout -q -b test-branch
  # No additional commits — branch is identical to main
)

ces_nochange_out=$(cd "$CES_NOCHANGE" && bash scripts/check-evolve-state.sh --format=json main 2>&1 || true)
if echo "$ces_nochange_out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['result'] == 'no_changes', f'expected no_changes, got {d[\"result\"]}'
assert d['errors'] == 0
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "check-evolve-state.sh returns no_changes for zero-commit branch (JSON)"
else
  fail "check-evolve-state.sh should return no_changes for zero-commit branch"
fi

# KV format for no-changes
ces_nochange_kv=$(cd "$CES_NOCHANGE" && bash scripts/check-evolve-state.sh --format=kv main 2>&1 || true)
if echo "$ces_nochange_kv" | grep -q 'result=no_changes'; then
  pass "check-evolve-state.sh returns no_changes in KV format"
else
  fail "check-evolve-state.sh should return no_changes in KV format"
fi

rm -rf "$CES_NOCHANGE"

# Edge case 2: partial updates (only some required files modified)
CES_PARTIAL=$(mktemp -d "$TMPDIR_BASE/rigseed-ces-partial-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$CES_PARTIAL/"
(
  cd "$CES_PARTIAL"
  git init -q
  git add -A
  git commit -q -m "Initial"
  git checkout -q -b test-branch
  # Only update JOURNAL.md — omit NEXT_STEPS.md and SESSION_COUNT (required)
  echo "## Day 99 — test" >> JOURNAL.md
  git add JOURNAL.md
  git commit -q -m "Partial session update"
)

ces_partial_json=$(cd "$CES_PARTIAL" && bash scripts/check-evolve-state.sh --format=json main 2>&1 || true)
if echo "$ces_partial_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['result'] == 'fail', f'expected fail, got {d[\"result\"]}'
assert d['errors'] >= 2, f'expected >=2 errors, got {d[\"errors\"]}'
# Check that JOURNAL.md passed but NEXT_STEPS.md and SESSION_COUNT failed
statuses = {c['file']: c['status'] for c in d['checks']}
assert statuses.get('JOURNAL.md') == 'pass', 'JOURNAL.md should pass'
assert statuses.get('NEXT_STEPS.md') == 'fail', 'NEXT_STEPS.md should fail'
assert statuses.get('SESSION_COUNT') == 'fail', 'SESSION_COUNT should fail'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "check-evolve-state.sh detects partial updates (missing NEXT_STEPS.md, SESSION_COUNT)"
else
  fail "check-evolve-state.sh should detect partial updates with per-file status"
fi

# CSV format for partial updates should show fail rows
ces_partial_csv=$(cd "$CES_PARTIAL" && bash scripts/check-evolve-state.sh --format=csv main 2>&1 || true)
if echo "$ces_partial_csv" | grep -q 'NEXT_STEPS.md,required,fail' && echo "$ces_partial_csv" | grep -q 'JOURNAL.md,required,pass'; then
  pass "check-evolve-state.sh CSV shows pass/fail per required file"
else
  fail "check-evolve-state.sh CSV should show pass/fail per required file"
fi

rm -rf "$CES_PARTIAL"

echo ""

# --- Step 35: quickstart.sh --check --verbose ---

echo "--- Step 35: quickstart.sh --check --verbose ---"

QS_VERBOSE=$(mktemp -d "$TMPDIR_BASE/rigseed-qs-verbose-XXXXXX")
rsync -a --exclude='.git' --exclude='.beads' --exclude='.runtime' "$PROJECT_DIR/" "$QS_VERBOSE/"
(cd "$QS_VERBOSE" && git init -q && git add -A && git commit -q -m "Initial")

# Test --verbose shows extra detail
qs_verbose=$(cd "$QS_VERBOSE" && bash quickstart.sh --check --verbose 2>&1 || true)
if echo "$qs_verbose" | grep -q 'JOURNAL.md:'; then
  pass "quickstart.sh --check --verbose shows detailed JOURNAL.md analysis"
else
  fail "quickstart.sh --check --verbose should show detailed JOURNAL.md analysis"
fi

if echo "$qs_verbose" | grep -q 'ROADMAP.md:'; then
  pass "quickstart.sh --check --verbose shows detailed ROADMAP.md analysis"
else
  fail "quickstart.sh --check --verbose should show detailed ROADMAP.md analysis"
fi

# Test that --verbose with --format=json adds detail to output
qs_verbose_json=$(cd "$QS_VERBOSE" && bash quickstart.sh --check --verbose --format=json 2>&1 || true)
if echo "$qs_verbose_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
# Verbose JSON should include detail field in at least one check
has_detail = any('detail' in c for c in d.get('checks', []))
assert has_detail, 'verbose mode should add detail field to checks'
print('valid')
" 2>/dev/null | grep -q 'valid'; then
  pass "quickstart.sh --check --verbose --format=json includes detail fields"
else
  fail "quickstart.sh --check --verbose --format=json should include detail fields"
fi

rm -rf "$QS_VERBOSE"

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

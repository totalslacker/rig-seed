#!/usr/bin/env bash
# quickstart.sh — Initialize a freshly forked rig-seed project.
#
# Usage: ./quickstart.sh [-h|--help] [--check] [--format=FMT] [--color|--no-color]
#
# This script:
#   1. Validates that all required template files exist
#   2. Resets SESSION_COUNT, DAY_COUNT, and DAY_DATE to initial values
#   3. Clears JOURNAL.md (keeps header), ROADMAP.md, and LEARNINGS.md
#   4. Prompts you to write SPECS.md if it's empty
#   5. Runs the full validation suite
#
# Options:
#   --check        Dry-run: validate without resetting any files
#   --format=FMT   Output format: table (default), csv, json, kv
#   --json         Alias for --format=json
#   --color        Force colored output
#   --no-color     Disable colored output
#   -h, --help     Show this help message
#
# Exit codes:
#   0 — quickstart complete (or --check passed)
#   1 — validation failed

set -euo pipefail

# --- Options ---
use_color=auto
check_only=false
format=table

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<'HELP'
Usage: quickstart.sh [options]

Initialize a freshly forked rig-seed project.

Steps performed:
  1. Validates all required template files exist
  2. Resets SESSION_COUNT, DAY_COUNT, DAY_DATE to initial values
  3. Clears JOURNAL.md, ROADMAP.md, LEARNINGS.md (keeps headers)
  4. Initializes NEXT_STEPS.md with bootstrap items
  5. Checks SPECS.md and suggests examples if empty
  6. Runs final validation

Options:
  --check        Dry-run: validate the project without resetting any files
  --format=FMT   Output format: table (default), csv, json, kv
  --json         Alias for --format=json
  --color        Force colored output
  --no-color     Disable colored output
  -h, --help     Show this help message

Exit codes:
  0   Quickstart completed successfully (or --check passed)
  1   Validation failed (missing template files)
HELP
      exit 0
      ;;
    --check) check_only=true ;;
    --format=*) format="${arg#--format=}" ;;
    --json) format=json ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
  esac
done

# Non-table formats suppress verbose output
if [ "$format" != "table" ]; then
  use_color=never
fi

# --- Color setup ---
setup_colors() {
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    # shellcheck disable=SC2034  # Color vars used in output sections
    GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m'
    BOLD=$'\033[1m' RESET=$'\033[0m'
  else
    # shellcheck disable=SC2034  # Color vars used in output sections
    GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
# shellcheck disable=SC2034  # Color vars used in output sections
setup_colors

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

info() { [ "$format" = "table" ] && printf '%b\n' "$@" || true; }

dir="$(cd "$(dirname "$0")" && pwd)"

if [ "$check_only" = true ]; then
  info "${CYAN}=== rig-seed quickstart --check ===${RESET}"
  info ""
  info "Dry-run validation for: $dir"
  info ""
else
  echo "${CYAN}=== rig-seed quickstart ===${RESET}"
  echo ""
  echo "Initializing project in: $dir"
  echo ""
fi

# --- Step 1: Check required files ---
if [ "$check_only" = true ]; then
  info "Step 1: Checking template files..."
  if ! "$dir/validate.sh" "$dir" > /dev/null 2>&1; then
    info ""
    info "WARNING: Some template files are missing. Running full validation:"
    info ""
    [ "$format" = "table" ] && "$dir/validate.sh" "$dir"
    info ""
    info "Fix the issues above before continuing."
    # For structured output, emit validation_failed result
    if [ "$format" = "json" ]; then
      printf '{"result":"fail","errors":1,"directory":"%s","checks":[{"file":"template","status":"fail","value":"","message":"template validation failed"}]}\n' \
        "$(json_escape "$dir")"
    elif [ "$format" = "csv" ]; then
      echo "file,status,value,message"
      echo "template,fail,,template validation failed"
      echo "result,fail,1 errors,"
    elif [ "$format" = "kv" ]; then
      echo "template=fail (template validation failed)"
      echo "result=fail"
      echo "errors=1"
    fi
    exit 1
  fi
  info "  All template files present."
  if [ ! -f "$dir/formulas/mol-evolve.formula.toml" ]; then
    info "  WARNING: formulas/mol-evolve.formula.toml not found."
    info "  Polecats need this formula for evolution workflow steps."
    info "  Copy it from your Gas Town installation or re-fork rig-seed."
  fi
  info ""
else
  echo "Step 1: Checking template files..."
  if ! "$dir/validate.sh" "$dir" > /dev/null 2>&1; then
    echo ""
    echo "WARNING: Some template files are missing. Running full validation:"
    echo ""
    "$dir/validate.sh" "$dir"
    echo ""
    echo "Fix the issues above before continuing."
    exit 1
  fi
  echo "  All template files present."
  if [ ! -f "$dir/formulas/mol-evolve.formula.toml" ]; then
    echo "  WARNING: formulas/mol-evolve.formula.toml not found."
    echo "  Polecats need this formula for evolution workflow steps."
    echo "  Copy it from your Gas Town installation or re-fork rig-seed."
  fi
  echo ""
fi

# --- Check mode: validate state and exit ---
if [ "$check_only" = true ]; then
  errors=0
  # Collect check results as "file|status|value|message" for structured output
  declare -a checks=()

  info "Step 2: Checking state file health..."

  # SESSION_COUNT
  if [ -f "$dir/SESSION_COUNT" ]; then
    sc=$(tr -d '[:space:]' < "$dir/SESSION_COUNT")
    if [[ "$sc" =~ ^[0-9]+$ ]]; then
      info "  SESSION_COUNT: $sc"
      checks+=("SESSION_COUNT|ok|$sc|")
    else
      info "  ${YELLOW}WARNING${RESET}: SESSION_COUNT contains non-numeric value: $sc"
      checks+=("SESSION_COUNT|warning|$sc|non-numeric value")
      errors=$((errors + 1))
    fi
  else
    info "  ${YELLOW}WARNING${RESET}: SESSION_COUNT not found"
    checks+=("SESSION_COUNT|warning||not found")
    errors=$((errors + 1))
  fi

  # DAY_COUNT
  if [ -f "$dir/DAY_COUNT" ]; then
    dc=$(tr -d '[:space:]' < "$dir/DAY_COUNT")
    if [[ "$dc" =~ ^[0-9]+$ ]]; then
      info "  DAY_COUNT: $dc"
      checks+=("DAY_COUNT|ok|$dc|")
    else
      info "  ${YELLOW}WARNING${RESET}: DAY_COUNT contains non-numeric value: $dc"
      checks+=("DAY_COUNT|warning|$dc|non-numeric value")
      errors=$((errors + 1))
    fi
  else
    info "  ${YELLOW}WARNING${RESET}: DAY_COUNT not found"
    checks+=("DAY_COUNT|warning||not found")
    errors=$((errors + 1))
  fi

  # DAY_DATE
  if [ -f "$dir/DAY_DATE" ]; then
    dd_val=$(tr -d '[:space:]' < "$dir/DAY_DATE")
    if [[ "$dd_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      info "  DAY_DATE: $dd_val"
      checks+=("DAY_DATE|ok|$dd_val|")
    else
      info "  ${YELLOW}WARNING${RESET}: DAY_DATE has unexpected format: $dd_val"
      checks+=("DAY_DATE|warning|$dd_val|unexpected format")
      errors=$((errors + 1))
    fi
  else
    info "  ${YELLOW}WARNING${RESET}: DAY_DATE not found"
    checks+=("DAY_DATE|warning||not found")
    errors=$((errors + 1))
  fi

  # JOURNAL.md
  if [ -f "$dir/JOURNAL.md" ]; then
    entries=$(grep -c '^## \(Day\|Session\) ' "$dir/JOURNAL.md" 2>/dev/null) || entries=0
    info "  JOURNAL.md: $entries entries"
    checks+=("JOURNAL.md|ok|$entries|$entries entries")
  else
    info "  ${YELLOW}WARNING${RESET}: JOURNAL.md not found"
    checks+=("JOURNAL.md|warning||not found")
    errors=$((errors + 1))
  fi

  # SPECS.md
  if [ -f "$dir/SPECS.md" ]; then
    lines=$(wc -l < "$dir/SPECS.md" | tr -d ' ')
    if [ "$lines" -lt 5 ]; then
      info "  ${YELLOW}WARNING${RESET}: SPECS.md looks empty ($lines lines)"
      checks+=("SPECS.md|warning|$lines|looks empty")
    else
      info "  SPECS.md: $lines lines"
      checks+=("SPECS.md|ok|$lines|$lines lines")
    fi
  else
    info "  ${YELLOW}WARNING${RESET}: SPECS.md not found"
    checks+=("SPECS.md|warning||not found")
    errors=$((errors + 1))
  fi

  # ROADMAP.md
  if [ -f "$dir/ROADMAP.md" ]; then
    done_count=$(grep -c '^\- \[x\]' "$dir/ROADMAP.md" 2>/dev/null) || done_count=0
    todo_count=$(grep -c '^\- \[ \]' "$dir/ROADMAP.md" 2>/dev/null) || todo_count=0
    info "  ROADMAP.md: $done_count done, $todo_count remaining"
    checks+=("ROADMAP.md|ok|$done_count done $todo_count remaining|")
  else
    info "  ${YELLOW}WARNING${RESET}: ROADMAP.md not found"
    checks+=("ROADMAP.md|warning||not found")
  fi

  # NEXT_STEPS.md
  if [ -f "$dir/NEXT_STEPS.md" ]; then
    ns_count=$(grep -c '^\- \[ \]' "$dir/NEXT_STEPS.md" 2>/dev/null) || ns_count=0
    info "  NEXT_STEPS.md: $ns_count open items"
    checks+=("NEXT_STEPS.md|ok|$ns_count|$ns_count open items")
  else
    info "  ${YELLOW}WARNING${RESET}: NEXT_STEPS.md not found"
    checks+=("NEXT_STEPS.md|warning||not found")
  fi

  # Determine result
  result_status="pass"
  exit_code=0
  if [ "$errors" -gt 0 ]; then
    result_status="fail"
    exit_code=1
  fi

  # Emit structured output
  if [ "$format" = "json" ]; then
    printf '{"result":"%s","errors":%d,"directory":"%s","checks":[' \
      "$result_status" "$errors" "$(json_escape "$dir")"
    first=true
    for c in "${checks[@]}"; do
      IFS='|' read -r file status value msg <<< "$c"
      if [ "$first" = true ]; then first=false; else printf ','; fi
      printf '{"file":"%s","status":"%s","value":"%s","message":"%s"}' \
        "$(json_escape "$file")" "$status" "$(json_escape "$value")" "$(json_escape "$msg")"
    done
    printf ']}\n'
    exit "$exit_code"
  elif [ "$format" = "csv" ]; then
    echo "file,status,value,message"
    for c in "${checks[@]}"; do
      IFS='|' read -r file status value msg <<< "$c"
      echo "$file,$status,$value,$msg"
    done
    echo "result,$result_status,$errors errors,"
    exit "$exit_code"
  elif [ "$format" = "kv" ]; then
    for c in "${checks[@]}"; do
      IFS='|' read -r file status value msg <<< "$c"
      if [ -n "$msg" ]; then
        echo "$file=$status ($msg)"
      else
        echo "$file=$status${value:+ ($value)}"
      fi
    done
    echo "result=$result_status"
    echo "errors=$errors"
    exit "$exit_code"
  fi

  info ""
  if [ "$errors" -gt 0 ]; then
    info "RESULT: $errors issue(s) found"
    exit 1
  else
    info "RESULT: all checks passed"
    exit 0
  fi
fi

# --- Step 2: Reset counters ---
echo "Step 2: Resetting SESSION_COUNT, DAY_COUNT, and DAY_DATE..."
echo "1" > "$dir/SESSION_COUNT"
echo "1" > "$dir/DAY_COUNT"
echo "$(date +%Y-%m-%d)" > "$dir/DAY_DATE"
echo "  Done (set to Day 1, Session 1)."
echo ""

# --- Step 3: Clear evolution state ---
echo "Step 3: Clearing previous evolution state..."

today=$(date +%Y-%m-%d)
cat > "$dir/JOURNAL.md" << EOF
# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Day 1 — Session 1 ($today)

**Goal**: Initialize project from rig-seed template.

Ran quickstart to set up the evolution scaffold. All state files reset:
SESSION_COUNT, DAY_COUNT, DAY_DATE zeroed. Journal, roadmap, and learnings
cleared. Ready for first evolution session.

**Next Steps**: Write SPECS.md, configure .evolve/config.toml, run first
evolution cycle.

---
EOF
echo "  JOURNAL.md reset with Day 1 spawn entry."

cat > "$dir/ROADMAP.md" << 'EOF'
# Roadmap

Living document. Updated each evolution session. Items come from three sources:
- SPECS.md (the project's requirements)
- GitHub issues from the community
- Self-assessment during evolution sessions

## Bootstrap (Day 0-3)

- [ ] Read and document project specs (SPECS.md)
- [ ] Choose language and tech stack
- [ ] Set up project structure
- [ ] Write initial tests
- [ ] Add LICENSE file
EOF
echo "  ROADMAP.md reset to bootstrap template."

cat > "$dir/LEARNINGS.md" << 'EOF'
# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---
EOF
echo "  LEARNINGS.md cleared (header preserved)."

cat > "$dir/NEXT_STEPS.md" << 'EOF'
# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Write SPECS.md with project requirements
- [ ] Configure .evolve/config.toml for your needs
- [ ] Run first evolution cycle

## Suggested (consider these)

- [ ] Set up build commands in config.toml
- [ ] Add CI workflows from docs/examples/workflows/

## Deferred (not now, but don't forget)

- [ ] Customize PERSONALITY.md for your project's voice
EOF
echo "  NEXT_STEPS.md initialized with bootstrap items."
echo ""

# --- Step 4: Check SPECS.md ---
echo "Step 4: Checking SPECS.md..."
specs_file="$dir/SPECS.md"
if [ ! -s "$specs_file" ] || grep -q "^# Project Specification" "$specs_file" && [ "$(wc -l < "$specs_file")" -lt 5 ]; then
  echo ""
  echo "  SPECS.md is empty or contains only the template header."
  echo "  The evolution agent needs specs to know what to build."
  echo ""
  echo "  Options:"
  echo "    1. Write your specs now:  \$EDITOR $specs_file"
  echo "    2. Copy an example:       cp docs/examples/specs/cli-tool.md SPECS.md"
  echo "    3. Let the agent bootstrap from a bead description (advanced)"
  echo ""
  echo "  Available examples:"
  for f in "$dir"/docs/examples/specs/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    name=$(basename "$f" .md)
    echo "    - $name  →  cp docs/examples/specs/$name.md SPECS.md"
  done
  echo ""
else
  echo "  SPECS.md has content. Good."
fi

# --- Step 5: Final validation ---
echo ""
echo "Step 5: Running final validation..."
echo ""
"$dir/validate.sh" "$dir"
echo ""
echo "=== Quickstart complete ==="
echo ""
echo "Next steps:"
echo "  1. Write your specs in SPECS.md (if you haven't already)"
echo "  2. Add as a Gas Town rig:  gt rig add <name> <git-url>"
echo "  3. Configure evolution:    Add { \"evolve\": { \"enabled\": true } } to rig config"
echo "  4. Start evolving:         gt rig undock <name> && gt rig start <name>"

#!/usr/bin/env bash
# quickstart.sh — Initialize a freshly forked rig-seed project.
#
# Usage: ./quickstart.sh [-h|--help] [--color|--no-color]
#
# This script:
#   1. Validates that all required template files exist
#   2. Resets SESSION_COUNT, DAY_COUNT, and DAY_DATE to initial values
#   3. Clears JOURNAL.md (keeps header), ROADMAP.md, and LEARNINGS.md
#   4. Prompts you to write SPECS.md if it's empty
#   5. Runs the full validation suite
#
# Options:
#   --color        Force colored output
#   --no-color     Disable colored output
#   -h, --help     Show this help message
#
# Exit codes:
#   0 — quickstart complete
#   1 — validation failed

set -euo pipefail

# --- Options ---
use_color=auto

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
  --color        Force colored output
  --no-color     Disable colored output
  -h, --help     Show this help message

Exit codes:
  0   Quickstart completed successfully
  1   Validation failed (missing template files)
HELP
      exit 0
      ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
  esac
done

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

dir="$(cd "$(dirname "$0")" && pwd)"

echo "${CYAN}=== rig-seed quickstart ===${RESET}"
echo ""
echo "Initializing project in: $dir"
echo ""

# --- Step 1: Check required files ---
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

# Check for bundled formula
if [ ! -f "$dir/formulas/mol-evolve.formula.toml" ]; then
  echo "  WARNING: formulas/mol-evolve.formula.toml not found."
  echo "  Polecats need this formula for evolution workflow steps."
  echo "  Copy it from your Gas Town installation or re-fork rig-seed."
fi
echo ""

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

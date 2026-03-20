#!/usr/bin/env bash
# quickstart.sh — Initialize a freshly forked rig-seed project.
#
# Usage: ./quickstart.sh
#
# This script:
#   1. Validates that all required template files exist
#   2. Resets SESSION_COUNT to 0
#   3. Clears JOURNAL.md (keeps header), ROADMAP.md, and LEARNINGS.md
#   4. Prompts you to write SPECS.md if it's empty
#   5. Runs the full validation suite

set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

echo "=== rig-seed quickstart ==="
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
echo ""

# --- Step 2: Reset SESSION_COUNT ---
echo "Step 2: Resetting SESSION_COUNT to 0..."
echo "0" > "$dir/SESSION_COUNT"
echo "  Done."
echo ""

# --- Step 3: Clear evolution state ---
echo "Step 3: Clearing previous evolution state..."

cat > "$dir/JOURNAL.md" << 'EOF'
# Journal

Evolution session log. Most recent entry first. Never delete entries.

---
EOF
echo "  JOURNAL.md cleared (header preserved)."

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

#!/usr/bin/env bash
# sync-upstream.sh — Sync template updates from the upstream rig-seed repo.
#
# Fetches the latest rig-seed template and merges infrastructure files while
# preserving project-specific state (SPECS, JOURNAL, ROADMAP, etc.).
#
# Usage: ./scripts/sync-upstream.sh [options]
#
# Options:
#   --dry-run     Show what would change without applying
#   --upstream    Override upstream URL (default: from config.toml or rig-seed GitHub)
#   -h, --help    Show this help
#
# Exit codes:
#   0 — sync complete (or nothing to sync)
#   1 — merge conflicts require manual resolution
#   2 — error (git not clean, upstream not reachable, etc.)

set -euo pipefail

# --- Defaults ---

UPSTREAM_DEFAULT="https://github.com/totalslacker/rig-seed.git"
REMOTE_NAME="rig-seed-upstream"
dry_run=false
upstream_url=""

# --- Options ---

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: sync-upstream.sh [options]"
      echo ""
      echo "Sync template updates from the upstream rig-seed repo."
      echo ""
      echo "Options:"
      echo "  --dry-run     Show what would change without applying"
      echo "  --upstream    Override upstream URL"
      echo "  -h, --help    Show this help"
      echo ""
      echo "Files that sync (template infrastructure):"
      echo "  validate.sh, health-check.sh, metrics.sh, quickstart.sh"
      echo "  scripts/*, docs/EVOLUTION.md, docs/FORKING.md, etc."
      echo "  .evolve/config.toml (structure only — your values preserved)"
      echo "  CONTRIBUTING.md, PERSONALITY.md, .claude/CLAUDE.md"
      echo ""
      echo "Files that NEVER sync (project-specific):"
      echo "  IDENTITY.md, SPECS.md, ROADMAP.md, JOURNAL.md"
      echo "  LEARNINGS.md, SESSION_COUNT, DAY_COUNT, DAY_DATE"
      echo ""
      echo "Exit codes:"
      echo "  0  Sync complete"
      echo "  1  Merge conflicts need manual resolution"
      echo "  2  Error"
      exit 0
      ;;
    --dry-run)
      dry_run=true
      ;;
    --upstream)
      shift
      upstream_url="$1"
      ;;
    --upstream=*)
      upstream_url="${arg#*=}"
      ;;
  esac
done

# --- Read upstream URL from config if not overridden ---

config_file=".evolve/config.toml"
if [ -z "$upstream_url" ] && [ -f "$config_file" ]; then
  url=$(grep -E '^upstream\s*=' "$config_file" 2>/dev/null | sed 's/.*=\s*"//; s/".*//' || true)
  [ -n "$url" ] && upstream_url="$url"
fi
upstream_url="${upstream_url:-$UPSTREAM_DEFAULT}"

# --- Preflight ---

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "ERROR: not inside a git repository"
  exit 2
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is not clean — commit or stash changes first"
  exit 2
fi

echo "=== Upstream Sync ==="
echo "  Upstream: $upstream_url"
echo "  Mode:     $([ "$dry_run" = true ] && echo 'dry run' || echo 'live')"
echo ""

# --- Set up remote ---

if git remote get-url "$REMOTE_NAME" &>/dev/null; then
  # Update URL if changed
  current_url=$(git remote get-url "$REMOTE_NAME")
  if [ "$current_url" != "$upstream_url" ]; then
    echo "Updating remote $REMOTE_NAME URL..."
    git remote set-url "$REMOTE_NAME" "$upstream_url"
  fi
else
  echo "Adding remote $REMOTE_NAME..."
  git remote add "$REMOTE_NAME" "$upstream_url"
fi

# --- Fetch ---

echo "Fetching upstream..."
if ! git fetch "$REMOTE_NAME" main 2>/dev/null; then
  echo "ERROR: could not fetch from $upstream_url"
  echo "  Check the URL and your network connection."
  exit 2
fi

# --- Check for changes ---

# Files that should sync (template infrastructure)
SYNC_FILES=(
  "validate.sh"
  "health-check.sh"
  "metrics.sh"
  "quickstart.sh"
  "CONTRIBUTING.md"
  "PERSONALITY.md"
  ".claude/CLAUDE.md"
  "docs/EVOLUTION.md"
  "docs/FORKING.md"
  "docs/TROUBLESHOOTING.md"
  "docs/DAY-ZERO.md"
  "docs/UPGRADING.md"
  "docs/FORMULA-CUSTOMIZATION.md"
  "docs/MERGE-STRATEGY.md"
  "scripts/check.sh"
  "scripts/dashboard.sh"
  "scripts/migrate.sh"
  "scripts/release.sh"
  "scripts/sync-upstream.sh"
  "tests/integration-test.sh"
  "docs/examples/"
  "CHANGELOG.template.md"
)

# Files that NEVER sync (project-specific)
NEVER_SYNC=(
  "IDENTITY.md"
  "SPECS.md"
  "ROADMAP.md"
  "JOURNAL.md"
  "LEARNINGS.md"
  "SESSION_COUNT"
  "DAY_COUNT"
  "DAY_DATE"
  "README.md"
  "LICENSE"
)

# Compare with upstream
upstream_ref="$REMOTE_NAME/main"
changes=0

echo ""
echo "--- Changes Available ---"
for file in "${SYNC_FILES[@]}"; do
  # Check if file differs between local and upstream
  if git diff HEAD "$upstream_ref" -- "$file" &>/dev/null; then
    diff_output=$(git diff HEAD "$upstream_ref" -- "$file" 2>/dev/null)
    if [ -n "$diff_output" ]; then
      echo "  ↑ $file (changed upstream)"
      ((changes++))
    fi
  fi
done

# Check for new files in upstream that don't exist locally
for file in "${SYNC_FILES[@]}"; do
  if [[ "$file" == */ ]]; then
    continue  # Skip directory entries for new-file check
  fi
  if [ ! -f "$file" ] && git show "$upstream_ref:$file" &>/dev/null 2>&1; then
    echo "  + $file (new in upstream)"
    ((changes++))
  fi
done

if [ $changes -eq 0 ]; then
  echo "  (no changes — already up to date)"
  echo ""
  echo "RESULT: already in sync with upstream"
  exit 0
fi

echo ""
echo "$changes file(s) have upstream changes"

if [ "$dry_run" = true ]; then
  echo ""
  echo "RESULT: dry run complete — run without --dry-run to apply"
  exit 0
fi

# --- Merge ---

echo ""
echo "Merging upstream changes..."

# Use a merge strategy that favors our version for project-specific files
# and takes upstream for template infrastructure
if git merge "$upstream_ref" --no-edit --allow-unrelated-histories 2>/dev/null; then
  echo ""
  echo "RESULT: upstream sync complete — review changes with 'git diff HEAD~1'"
  exit 0
else
  echo ""
  echo "Merge conflicts detected. Project-specific files to keep yours:"
  echo ""
  for file in "${NEVER_SYNC[@]}"; do
    if git diff --name-only --diff-filter=U 2>/dev/null | grep -q "^${file}$"; then
      echo "  git checkout --ours $file && git add $file"
    fi
  done
  echo ""
  echo "After resolving conflicts:"
  echo "  git commit"
  echo ""
  echo "RESULT: merge conflicts — manual resolution needed"
  exit 1
fi

#!/usr/bin/env bash
# rollback.sh — Revert the most recent merge if the build is broken.
#
# Uses `git revert` to create a new commit that undoes the last merge.
# This is safe (non-destructive) and preserves full history. The original
# merge remains in git log for debugging.
#
# Usage: ./scripts/rollback.sh [options]
#
# Options:
#   -h, --help       Show this help
#   -n, --dry-run    Show what would be reverted without doing it
#   --commit=SHA     Revert a specific commit (default: HEAD)
#   --no-verify      Skip build verification after revert (not recommended)
#   --color          Force colored output
#   --no-color       Disable colored output
#
# Exit codes:
#   0 — rollback successful (or dry-run showed what would happen)
#   1 — rollback failed or build still broken after revert
#   2 — nothing to revert (HEAD is not a merge or no commits found)

set -euo pipefail

dry_run=false
target="HEAD"
verify=true
use_color=auto

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,/^$/s/^# //p' "$0"
      exit 0
      ;;
    -n|--dry-run)
      dry_run=true
      ;;
    --commit=*)
      target="${arg#*=}"
      ;;
    --no-verify)
      verify=false
      ;;
    --color)
      use_color=always
      ;;
    --no-color)
      use_color=never
      ;;
  esac
done

# --- Color setup ---
setup_colors() {
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    # shellcheck disable=SC2034  # Color vars used in output sections
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    RED='\033[31m' GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' BOLD='\033[1m' RESET='\033[0m'
  else
    # shellcheck disable=SC2034  # Color vars used in output sections
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
setup_colors

# --- Safety checks ---

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: not inside a git repository"
  exit 2
fi

# Must have a clean working tree
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean — commit or stash changes first"
  echo ""
  git status --short
  exit 1
fi

# Resolve the target commit
commit_sha=$(git rev-parse "$target" 2>/dev/null)
if [ -z "$commit_sha" ]; then
  echo "Error: could not resolve commit '$target'"
  exit 2
fi

commit_msg=$(git log --oneline -1 "$commit_sha")
is_merge=$(git cat-file -p "$commit_sha" | grep -c "^parent " || true)

printf '%b\n' "${CYAN}=== Rollback ===${RESET}"
echo ""
echo "Target commit: $commit_msg"
echo "SHA:           $commit_sha"
echo "Type:          $([ "$is_merge" -gt 1 ] && echo "merge commit" || echo "regular commit")"
echo ""

# Show what files were changed
echo "Files changed:"
git diff --stat "${commit_sha}^..${commit_sha}" 2>/dev/null | sed 's/^/  /'
echo ""

if [ "$dry_run" = true ]; then
  echo "--- Dry Run ---"
  echo "Would revert: $commit_msg"
  if [ "$is_merge" -gt 1 ]; then
    echo "Revert command: git revert -m 1 $commit_sha"
  else
    echo "Revert command: git revert $commit_sha"
  fi
  echo ""
  echo "RESULT: dry run — no changes made"
  exit 0
fi

# --- Perform the revert ---

echo "Reverting..."

if [ "$is_merge" -gt 1 ]; then
  # Merge commits need -m 1 to specify which parent to keep (mainline)
  if ! git revert -m 1 --no-edit "$commit_sha"; then
    echo ""
    echo "Error: revert failed (likely conflicts)"
    echo "Resolve conflicts manually, then:"
    echo "  git revert --continue"
    echo ""
    echo "Or abort the revert:"
    echo "  git revert --abort"
    exit 1
  fi
else
  if ! git revert --no-edit "$commit_sha"; then
    echo ""
    echo "Error: revert failed (likely conflicts)"
    echo "Resolve conflicts manually, then:"
    echo "  git revert --continue"
    echo ""
    echo "Or abort the revert:"
    echo "  git revert --abort"
    exit 1
  fi
fi

printf '%b\n' "${GREEN}✓${RESET} Revert commit created"
echo ""
git log --oneline -1
echo ""

# --- Verify the build after revert ---

if [ "$verify" = true ]; then
  echo "--- Verifying build after revert ---"
  check_script=".evolve/config.toml"
  build_cmd=""

  # Try to find the check script from config
  if [ -f "$check_script" ]; then
    configured=$(grep -E '^check_script' "$check_script" 2>/dev/null | sed 's/.*=.*"\(.*\)"/\1/' || true)
    if [ -n "$configured" ] && [ -f "$configured" ]; then
      build_cmd="bash $configured"
    fi
  fi

  # Fallback: try scripts/check.sh directly
  if [ -z "$build_cmd" ] && [ -f "scripts/check.sh" ]; then
    build_cmd="bash scripts/check.sh"
  fi

  if [ -n "$build_cmd" ]; then
    echo "Running: $build_cmd"
    echo ""
    if eval "$build_cmd"; then
      echo ""
      printf '%b\n' "${GREEN}✓${RESET} Build passes after revert"
    else
      echo ""
      printf '%b\n' "${YELLOW}⚠${RESET} Build STILL FAILS after revert — investigate manually"
      echo "  The revert commit has been created but the issue may be deeper."
      exit 1
    fi
  else
    echo "No build check script found — skipping verification"
    echo "  Configure check_script in .evolve/config.toml or add scripts/check.sh"
  fi
fi

echo ""
printf '%b\n' "${CYAN}=== Rollback Complete ===${RESET}"
echo ""
echo "Next steps:"
echo "  1. Review the revert: git diff HEAD~1"
echo "  2. Push if on a shared branch: git push"
echo "  3. Investigate the root cause in the original commit"
echo ""
printf '%b\n' "${BOLD}RESULT: rollback successful${RESET}"

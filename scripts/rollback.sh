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
#   --format=FMT     Output format: table (default), csv, json, kv
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
format=table

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
    --format=*)
      format="${arg#*=}"
      ;;
    --json)
      format=json
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
commit_type=$([ "$is_merge" -gt 1 ] && echo "merge" || echo "regular")
files_changed=$(git diff --name-only "${commit_sha}^..${commit_sha}" 2>/dev/null | wc -l | tr -d ' ')

# --- Structured output for dry-run ---
if [ "$dry_run" = true ]; then
  if [ "$format" = "json" ]; then
    printf '{"action":"dry_run","target":"%s","type":"%s","files_changed":%s,"message":"%s"}\n' \
      "$commit_sha" "$commit_type" "$files_changed" "$(echo "$commit_msg" | sed 's/"/\\"/g')"
    exit 0
  elif [ "$format" = "csv" ]; then
    echo "action,target,type,files_changed,message"
    echo "dry_run,$commit_sha,$commit_type,$files_changed,\"$commit_msg\""
    exit 0
  elif [ "$format" = "kv" ]; then
    echo "action=dry_run"
    echo "target=$commit_sha"
    echo "type=$commit_type"
    echo "files_changed=$files_changed"
    echo "message=$commit_msg"
    exit 0
  fi
  # table format
  printf '%b\n' "${CYAN}=== Rollback ===${RESET}"
  echo ""
  echo "Target commit: $commit_msg"
  echo "SHA:           $commit_sha"
  echo "Type:          $commit_type commit"
  echo ""
  echo "Files changed:"
  git diff --stat "${commit_sha}^..${commit_sha}" 2>/dev/null | sed 's/^/  /'
  echo ""
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

printf '%b\n' "${CYAN}=== Rollback ===${RESET}"
echo ""
echo "Target commit: $commit_msg"
echo "SHA:           $commit_sha"
echo "Type:          $commit_type commit"
echo ""

# Show what files were changed
echo "Files changed:"
git diff --stat "${commit_sha}^..${commit_sha}" 2>/dev/null | sed 's/^/  /'
echo ""

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

# --- Structured output for completed rollback ---
if [ "$format" = "json" ]; then
  printf '{"action":"reverted","target":"%s","type":"%s","files_changed":%s,"result":"success"}\n' \
    "$commit_sha" "$commit_type" "$files_changed"
  exit 0
elif [ "$format" = "csv" ]; then
  echo "action,target,type,files_changed,result"
  echo "reverted,$commit_sha,$commit_type,$files_changed,success"
  exit 0
elif [ "$format" = "kv" ]; then
  echo "action=reverted"
  echo "target=$commit_sha"
  echo "type=$commit_type"
  echo "files_changed=$files_changed"
  echo "result=success"
  exit 0
fi

printf '%b\n' "${CYAN}=== Rollback Complete ===${RESET}"
echo ""
echo "Next steps:"
echo "  1. Review the revert: git diff HEAD~1"
echo "  2. Push if on a shared branch: git push"
echo "  3. Investigate the root cause in the original commit"
echo ""
printf '%b\n' "${BOLD}RESULT: rollback successful${RESET}"

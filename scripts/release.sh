#!/usr/bin/env bash
# release.sh — Tag a new semver release based on the latest git tag.
#
# Usage:
#   ./scripts/release.sh              # Auto-increment patch (v0.1.0 → v0.1.1)
#   ./scripts/release.sh patch        # Same as above
#   ./scripts/release.sh minor        # v0.1.1 → v0.2.0
#   ./scripts/release.sh major        # v0.2.0 → v1.0.0
#   ./scripts/release.sh auto         # Detect bump from conventional commits
#   ./scripts/release.sh --dry-run    # Show what would happen without doing it
#
# Options:
#   -h, --help       Show this help
#   --dry-run        Show what would happen without creating a tag
#   --format=FORMAT  Output format: table (default), csv, json, kv
#   --json           Alias for --format=json
#   --color          Force colored output
#   --no-color       Disable colored output
#
# Bump types:
#   auto    Detect from conventional commits since last tag:
#           - "BREAKING CHANGE:" or "!:" in commit → major
#           - "feat:" or "feat(...):" → minor
#           - Everything else → patch
#
# If no tags exist yet, starts at v0.1.0.

set -euo pipefail

# --- Parse options ---
BUMP=""
DRY_RUN=false
use_color=auto
format=table

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: $(basename "$0") [options] [major|minor|patch]"
      echo ""
      echo "Tag a new semver release based on the latest git tag."
      echo ""
      echo "Options:"
      echo "  --dry-run        Show what would happen without creating a tag"
      echo "  --format=FORMAT  Output format: table (default), csv, json, kv"
      echo "  --json           Alias for --format=json"
      echo "  --color          Force colored output"
      echo "  --no-color       Disable colored output"
      echo "  -h, --help       Show this help"
      echo ""
      echo "Bump types:"
      echo "  major        Increment major version (v1.2.3 → v2.0.0)"
      echo "  minor        Increment minor version (v1.2.3 → v1.3.0)"
      echo "  patch        Increment patch version (v1.2.3 → v1.2.4) [default]"
      echo "  auto         Detect from conventional commits since last tag"
      echo ""
      echo "If no tags exist yet, starts at v0.1.0."
      exit 0
      ;;
    --dry-run) DRY_RUN=true ;;
    --format=*)
      format="${arg#*=}"
      case "$format" in
        table|csv|json|kv) ;;
        *)
          echo "Error: unknown format '$format' (expected: table, csv, json, kv)" >&2
          exit 1
          ;;
      esac
      ;;
    --json) format=json ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    major|minor|patch|auto) BUMP="$arg" ;;
    *)
      echo "Error: unknown option '$arg'" >&2
      echo "Usage: $(basename "$0") [--dry-run] [--color|--no-color] [major|minor|patch]" >&2
      exit 1
      ;;
  esac
done

BUMP="${BUMP:-patch}"

# --- Auto-detect bump from conventional commits ---

detect_bump_from_commits() {
  local since_ref="$1"
  local log_range=""
  if [ -n "$since_ref" ]; then
    log_range="${since_ref}..HEAD"
  else
    log_range="HEAD"
  fi
  local commits
  commits=$(git log "$log_range" --pretty=format:"%s%n%b" 2>/dev/null || true)
  if [ -z "$commits" ]; then
    echo "patch"
    return
  fi
  # Check for breaking changes
  if echo "$commits" | grep -qiE '^[a-z]+(\(.+\))?!:|BREAKING CHANGE:'; then
    echo "major"
    return
  fi
  # Check for features
  if echo "$commits" | grep -qE '^feat(\(.+\))?:'; then
    echo "minor"
    return
  fi
  echo "patch"
}

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

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Structured output and exit
output_result() {
  local status="$1" message="$2"
  case "$format" in
    json)
      printf '{"latest_tag":"%s","new_tag":"%s","bump":"%s","dry_run":%s,"status":"%s","message":"%s"}\n' \
        "$(json_escape "${LATEST_TAG:-none}")" "$(json_escape "$NEW_TAG")" "$BUMP" \
        "$( $DRY_RUN && echo true || echo false )" \
        "$(json_escape "$status")" "$(json_escape "$message")"
      ;;
    csv)
      echo "latest_tag,new_tag,bump,dry_run,status,message"
      printf '%s,%s,%s,%s,%s,%s\n' \
        "$(csv_escape "${LATEST_TAG:-none}")" "$(csv_escape "$NEW_TAG")" "$BUMP" \
        "$( $DRY_RUN && echo true || echo false )" \
        "$(csv_escape "$status")" "$(csv_escape "$message")"
      ;;
    kv)
      printf 'latest_tag=%s\n' "${LATEST_TAG:-none}"
      printf 'new_tag=%s\n' "$NEW_TAG"
      printf 'bump=%s\n' "$BUMP"
      printf 'dry_run=%s\n' "$( $DRY_RUN && echo true || echo false )"
      printf 'status=%s\n' "$status"
      printf 'message=%s\n' "$message"
      ;;
  esac
}

# Find latest semver tag
LATEST_TAG=$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)

if [[ -z "$LATEST_TAG" ]]; then
    MAJOR=0; MINOR=1; PATCH=0
    [ "$format" = "table" ] && printf '%b\n' "${YELLOW}No existing tags found. Starting at v0.1.0${RESET}"
else
    # Strip leading 'v' and split
    VERSION="${LATEST_TAG#v}"
    MAJOR="${VERSION%%.*}"
    REST="${VERSION#*.}"
    MINOR="${REST%%.*}"
    PATCH="${REST#*.}"
    [ "$format" = "table" ] && printf '%b\n' "Latest tag: ${BOLD}$LATEST_TAG${RESET}"
fi

# Resolve auto bump from conventional commits
if [ "$BUMP" = "auto" ]; then
    BUMP=$(detect_bump_from_commits "${LATEST_TAG:-}")
    [ "$format" = "table" ] && printf '%b\n' "${CYAN}Auto-detected bump: $BUMP${RESET}"
fi

# Increment
case "$BUMP" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"
[ "$format" = "table" ] && printf '%b\n' "New tag: ${BOLD}$NEW_TAG${RESET} ($BUMP bump)"

if $DRY_RUN; then
    if [ "$format" != "table" ]; then
      output_result "dry_run" "Would create and push tag: $NEW_TAG"
    else
      printf '%b\n' "${CYAN}[dry-run]${RESET} Would create and push tag: $NEW_TAG"
    fi
    exit 0
fi

# Create annotated tag
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
[ "$format" = "table" ] && printf '%b\n' "${GREEN}Created tag: $NEW_TAG${RESET}"

# Push tag
git push origin "$NEW_TAG"
[ "$format" = "table" ] && printf '%b\n' "${GREEN}Pushed tag: $NEW_TAG${RESET}"

if [ "$format" != "table" ]; then
  output_result "released" "Release $NEW_TAG complete"
else
  echo ""
  printf '%b\n' "${GREEN}Release $NEW_TAG complete.${RESET}"
fi

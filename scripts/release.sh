#!/usr/bin/env bash
# release.sh — Tag a new semver release based on the latest git tag.
#
# Usage:
#   ./scripts/release.sh              # Auto-increment patch (v0.1.0 → v0.1.1)
#   ./scripts/release.sh patch        # Same as above
#   ./scripts/release.sh minor        # v0.1.1 → v0.2.0
#   ./scripts/release.sh major        # v0.2.0 → v1.0.0
#   ./scripts/release.sh --dry-run    # Show what would happen without doing it
#
# If no tags exist yet, starts at v0.1.0.

set -euo pipefail

# --- Parse options ---
BUMP=""
DRY_RUN=false
use_color=auto

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: $(basename "$0") [options] [major|minor|patch]"
      echo ""
      echo "Tag a new semver release based on the latest git tag."
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would happen without creating a tag"
      echo "  --color      Force colored output"
      echo "  --no-color   Disable colored output"
      echo "  -h, --help   Show this help"
      echo ""
      echo "Bump types:"
      echo "  major        Increment major version (v1.2.3 → v2.0.0)"
      echo "  minor        Increment minor version (v1.2.3 → v1.3.0)"
      echo "  patch        Increment patch version (v1.2.3 → v1.2.4) [default]"
      echo ""
      echo "If no tags exist yet, starts at v0.1.0."
      exit 0
      ;;
    --dry-run) DRY_RUN=true ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    major|minor|patch) BUMP="$arg" ;;
    *)
      echo "Error: unknown option '$arg'" >&2
      echo "Usage: $(basename "$0") [--dry-run] [--color|--no-color] [major|minor|patch]" >&2
      exit 1
      ;;
  esac
done

BUMP="${BUMP:-patch}"

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

# Find latest semver tag
LATEST_TAG=$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)

if [[ -z "$LATEST_TAG" ]]; then
    MAJOR=0; MINOR=1; PATCH=0
    printf '%b\n' "${YELLOW}No existing tags found. Starting at v0.1.0${RESET}"
else
    # Strip leading 'v' and split
    VERSION="${LATEST_TAG#v}"
    MAJOR="${VERSION%%.*}"
    REST="${VERSION#*.}"
    MINOR="${REST%%.*}"
    PATCH="${REST#*.}"
    printf '%b\n' "Latest tag: ${BOLD}$LATEST_TAG${RESET}"
fi

# Increment
case "$BUMP" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"
printf '%b\n' "New tag: ${BOLD}$NEW_TAG${RESET} ($BUMP bump)"

if $DRY_RUN; then
    printf '%b\n' "${CYAN}[dry-run]${RESET} Would create and push tag: $NEW_TAG"
    exit 0
fi

# Create annotated tag
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
printf '%b\n' "${GREEN}Created tag: $NEW_TAG${RESET}"

# Push tag
git push origin "$NEW_TAG"
printf '%b\n' "${GREEN}Pushed tag: $NEW_TAG${RESET}"

echo ""
printf '%b\n' "${GREEN}Release $NEW_TAG complete.${RESET}"

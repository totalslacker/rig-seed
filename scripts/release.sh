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

BUMP="${1:-patch}"
DRY_RUN=false

if [[ "$BUMP" == "--dry-run" ]]; then
    DRY_RUN=true
    BUMP="${2:-patch}"
fi

if [[ "$BUMP" != "major" && "$BUMP" != "minor" && "$BUMP" != "patch" ]]; then
    echo "Usage: $0 [--dry-run] [major|minor|patch]"
    echo "  Default: patch"
    exit 1
fi

# Find latest semver tag
LATEST_TAG=$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)

if [[ -z "$LATEST_TAG" ]]; then
    MAJOR=0; MINOR=1; PATCH=0
    echo "No existing tags found. Starting at v0.1.0"
else
    # Strip leading 'v' and split
    VERSION="${LATEST_TAG#v}"
    MAJOR="${VERSION%%.*}"
    REST="${VERSION#*.}"
    MINOR="${REST%%.*}"
    PATCH="${REST#*.}"
    echo "Latest tag: $LATEST_TAG"
fi

# Increment
case "$BUMP" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"
echo "New tag: $NEW_TAG ($BUMP bump)"

if $DRY_RUN; then
    echo "[dry-run] Would create and push tag: $NEW_TAG"
    exit 0
fi

# Create annotated tag
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
echo "Created tag: $NEW_TAG"

# Push tag
git push origin "$NEW_TAG"
echo "Pushed tag: $NEW_TAG"

echo ""
echo "Release $NEW_TAG complete."

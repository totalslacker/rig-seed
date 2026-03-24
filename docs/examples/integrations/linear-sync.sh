#!/usr/bin/env bash
# linear-sync.sh — Sync beads issues to Linear.
#
# Creates or updates Linear issues that mirror open beads. Maintains a local
# mapping file so syncs are idempotent. Optionally pulls status changes back.
#
# Prerequisites:
#   - LINEAR_API_KEY environment variable set
#   - LINEAR_TEAM_ID environment variable set (your team's UUID)
#   - curl and jq installed
#   - bd CLI available
#
# Usage: ./linear-sync.sh [options]
#   --pull       Pull status updates from Linear back to beads
#   --dry-run    Show what would be done without making changes
#   --help       Show this help message
#
# Mapping file: .beads-external-map.json (gitignored)

set -euo pipefail

# --- Options ---

pull=false
dry_run=false

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: linear-sync.sh [options]"
      echo ""
      echo "Sync beads issues to Linear."
      echo ""
      echo "Options:"
      echo "  --pull       Pull status updates from Linear back to beads"
      echo "  --dry-run    Show what would be synced without making changes"
      echo "  -h, --help   Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  LINEAR_API_KEY    Linear API key (required)"
      echo "  LINEAR_TEAM_ID    Linear team UUID (required)"
      echo ""
      echo "The mapping between bead IDs and Linear issue IDs is stored in"
      echo ".beads-external-map.json in the project root."
      exit 0
      ;;
    --pull)
      pull=true
      ;;
    -n|--dry-run)
      dry_run=true
      ;;
  esac
done

# --- Validation ---

if [ -z "${LINEAR_API_KEY:-}" ]; then
  echo "Error: LINEAR_API_KEY environment variable is not set." >&2
  echo "Get your API key from: https://linear.app/settings/api" >&2
  exit 1
fi

if [ -z "${LINEAR_TEAM_ID:-}" ]; then
  echo "Error: LINEAR_TEAM_ID environment variable is not set." >&2
  echo "Find your team ID in Linear settings or via the API." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if ! command -v bd &>/dev/null; then
  echo "Error: bd (beads CLI) is required but not found in PATH." >&2
  exit 1
fi

# --- Constants ---

MAP_FILE=".beads-external-map.json"
LINEAR_API="https://api.linear.app/graphql"

# Initialize mapping file if it doesn't exist
if [ ! -f "$MAP_FILE" ]; then
  echo '{}' > "$MAP_FILE"
fi

# --- Helpers ---

linear_query() {
  local query="$1"
  curl -s -X POST "$LINEAR_API" \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}

get_mapped_id() {
  local bead_id="$1"
  jq -r ".[\"$bead_id\"].external_id // empty" "$MAP_FILE"
}

save_mapping() {
  local bead_id="$1" external_id="$2"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp
  tmp=$(mktemp)
  jq --arg bid "$bead_id" --arg eid "$external_id" --arg ts "$now" \
    '.[$bid] = {"external_id": $eid, "platform": "linear", "synced_at": $ts}' \
    "$MAP_FILE" > "$tmp" && mv "$tmp" "$MAP_FILE"
}

# Map bead status to Linear state name
status_to_linear() {
  case "$1" in
    open)        echo "Todo" ;;
    in_progress) echo "In Progress" ;;
    closed)      echo "Done" ;;
    blocked)     echo "Blocked" ;;
    *)           echo "Backlog" ;;
  esac
}

# Map bead type to Linear label
type_to_label() {
  case "$1" in
    bug)     echo "Bug" ;;
    task)    echo "Feature" ;;
    *)       echo "" ;;
  esac
}

# --- Push: beads → Linear ---

push_sync() {
  echo "=== Syncing beads → Linear ==="
  echo ""

  # Get all non-closed beads
  local beads
  beads=$(bd list --format=json 2>/dev/null || echo "[]")

  if [ "$beads" = "[]" ]; then
    echo "  ℹ No beads found."
    return 0
  fi

  local count=0
  local created=0
  local updated=0

  # Process each bead
  echo "$beads" | jq -c '.[]' | while IFS= read -r bead; do
    local bead_id title status bead_type
    bead_id=$(echo "$bead" | jq -r '.id')
    title=$(echo "$bead" | jq -r '.title')
    status=$(echo "$bead" | jq -r '.status')
    bead_type=$(echo "$bead" | jq -r '.type // "task"')

    local linear_id
    linear_id=$(get_mapped_id "$bead_id")

    if [ -n "$linear_id" ]; then
      # Update existing Linear issue
      local linear_state
      linear_state=$(status_to_linear "$status")
      if [ "$dry_run" = true ]; then
        echo "  [dry-run] Would update $linear_id ($title) → status: $linear_state"
      else
        echo "  ▶ Updating $linear_id: $title → $linear_state"
        # Note: actual state update requires resolving state ID from name
        # This is a simplified example
        linear_query "mutation { issueUpdate(id: \"$linear_id\", input: { title: \"[$bead_id] $title\" }) { success } }" > /dev/null
        ((updated++))
      fi
    else
      # Create new Linear issue
      if [ "$dry_run" = true ]; then
        echo "  [dry-run] Would create Linear issue: [$bead_id] $title"
      else
        echo "  ▶ Creating: [$bead_id] $title"
        local response
        response=$(linear_query "mutation { issueCreate(input: { teamId: \"$LINEAR_TEAM_ID\", title: \"[$bead_id] $title\", description: \"Synced from beads. Bead ID: $bead_id\" }) { success issue { id identifier } } }")

        local new_id
        new_id=$(echo "$response" | jq -r '.data.issueCreate.issue.identifier // empty')
        if [ -n "$new_id" ]; then
          save_mapping "$bead_id" "$new_id"
          echo "  ✓ Created $new_id"
          ((created++))
        else
          echo "  ✗ Failed to create issue for $bead_id"
          echo "    Response: $response" >&2
        fi
      fi
    fi
    ((count++))
  done

  echo ""
  echo "Processed $count bead(s). Created: $created, Updated: $updated"
}

# --- Pull: Linear → beads ---

pull_sync() {
  echo "=== Pulling Linear → beads ==="
  echo ""

  # Read all mappings
  local mapped_count
  mapped_count=$(jq 'length' "$MAP_FILE")

  if [ "$mapped_count" -eq 0 ]; then
    echo "  ℹ No mapped issues. Run a push sync first."
    return 0
  fi

  # For each mapped bead, check Linear status
  jq -r 'to_entries[] | select(.value.platform == "linear") | "\(.key) \(.value.external_id)"' "$MAP_FILE" | \
  while read -r bead_id linear_id; do
    # Query Linear for current state
    local response
    response=$(linear_query "{ issue(id: \"$linear_id\") { state { name } } }")
    local linear_state
    linear_state=$(echo "$response" | jq -r '.data.issue.state.name // empty')

    if [ -z "$linear_state" ]; then
      echo "  ⚠ Could not fetch status for $linear_id ($bead_id)"
      continue
    fi

    # Map Linear state back to bead status
    local bead_status
    case "$linear_state" in
      "Done"|"Completed"|"Cancelled") bead_status="closed" ;;
      "In Progress"|"In Review")      bead_status="in_progress" ;;
      "Blocked")                       bead_status="blocked" ;;
      *)                               bead_status="open" ;;
    esac

    if [ "$dry_run" = true ]; then
      echo "  [dry-run] Would update $bead_id → status: $bead_status (Linear: $linear_state)"
    else
      echo "  ▶ $bead_id: Linear says '$linear_state' → bead status '$bead_status'"
      bd update "$bead_id" --status="$bead_status" 2>/dev/null || \
        echo "  ⚠ Could not update bead $bead_id"
    fi
  done
}

# --- Main ---

if [ "$pull" = true ]; then
  pull_sync
else
  push_sync
fi

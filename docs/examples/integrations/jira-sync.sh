#!/usr/bin/env bash
# jira-sync.sh — Sync beads issues to Jira.
#
# Creates or updates Jira issues that mirror open beads. Maintains a local
# mapping file so syncs are idempotent. Optionally pulls status changes back.
#
# Prerequisites:
#   - JIRA_URL, JIRA_USER, JIRA_API_TOKEN, JIRA_PROJECT environment variables set
#   - curl and jq installed
#   - bd CLI available
#
# Usage: ./jira-sync.sh [options]
#   --pull       Pull status updates from Jira back to beads
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
      echo "Usage: jira-sync.sh [options]"
      echo ""
      echo "Sync beads issues to Jira."
      echo ""
      echo "Options:"
      echo "  --pull       Pull status updates from Jira back to beads"
      echo "  --dry-run    Show what would be synced without making changes"
      echo "  -h, --help   Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  JIRA_URL         Jira instance URL (e.g., https://yourcompany.atlassian.net)"
      echo "  JIRA_USER        Jira user email"
      echo "  JIRA_API_TOKEN   Jira API token"
      echo "  JIRA_PROJECT     Jira project key (e.g., PROJ)"
      echo ""
      echo "The mapping between bead IDs and Jira issue IDs is stored in"
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

for var in JIRA_URL JIRA_USER JIRA_API_TOKEN JIRA_PROJECT; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var environment variable is not set." >&2
    exit 1
  fi
done

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

# Initialize mapping file if it doesn't exist
if [ ! -f "$MAP_FILE" ]; then
  echo '{}' > "$MAP_FILE"
fi

# --- Helpers ---

jira_api() {
  local method="$1" endpoint="$2"
  shift 2
  curl -s -X "$method" \
    "${JIRA_URL}/rest/api/3${endpoint}" \
    -u "${JIRA_USER}:${JIRA_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "$@"
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
    '.[$bid] = {"external_id": $eid, "platform": "jira", "synced_at": $ts}' \
    "$MAP_FILE" > "$tmp" && mv "$tmp" "$MAP_FILE"
}

# Map bead type to Jira issue type
type_to_issuetype() {
  case "$1" in
    bug)  echo "Bug" ;;
    task) echo "Task" ;;
    *)    echo "Task" ;;
  esac
}

# --- Push: beads → Jira ---

push_sync() {
  echo "=== Syncing beads → Jira ==="
  echo ""

  local beads
  beads=$(bd list --format=json 2>/dev/null || echo "[]")

  if [ "$beads" = "[]" ]; then
    echo "  ℹ No beads found."
    return 0
  fi

  local count=0
  local created=0
  local updated=0

  echo "$beads" | jq -c '.[]' | while IFS= read -r bead; do
    local bead_id title status bead_type description
    bead_id=$(echo "$bead" | jq -r '.id')
    title=$(echo "$bead" | jq -r '.title')
    status=$(echo "$bead" | jq -r '.status')
    bead_type=$(echo "$bead" | jq -r '.type // "task"')
    description=$(echo "$bead" | jq -r '.description // ""')

    local jira_id
    jira_id=$(get_mapped_id "$bead_id")

    if [ -n "$jira_id" ]; then
      # Update existing Jira issue
      if [ "$dry_run" = true ]; then
        echo "  [dry-run] Would update $jira_id ($title)"
      else
        echo "  ▶ Updating $jira_id: $title"
        jira_api PUT "/issue/$jira_id" \
          -d "{\"fields\": {\"summary\": \"[$bead_id] $title\"}}" > /dev/null
        ((updated++))
      fi
    else
      # Create new Jira issue
      local issue_type
      issue_type=$(type_to_issuetype "$bead_type")

      if [ "$dry_run" = true ]; then
        echo "  [dry-run] Would create Jira $issue_type: [$bead_id] $title"
      else
        echo "  ▶ Creating: [$bead_id] $title"
        local response
        response=$(jira_api POST "/issue" \
          -d "{
            \"fields\": {
              \"project\": {\"key\": \"$JIRA_PROJECT\"},
              \"summary\": \"[$bead_id] $title\",
              \"description\": {
                \"type\": \"doc\",
                \"version\": 1,
                \"content\": [{
                  \"type\": \"paragraph\",
                  \"content\": [{\"type\": \"text\", \"text\": \"Synced from beads. Bead ID: $bead_id. $description\"}]
                }]
              },
              \"issuetype\": {\"name\": \"$issue_type\"}
            }
          }")

        local new_key
        new_key=$(echo "$response" | jq -r '.key // empty')
        if [ -n "$new_key" ]; then
          save_mapping "$bead_id" "$new_key"
          echo "  ✓ Created $new_key"
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

# --- Pull: Jira → beads ---

pull_sync() {
  echo "=== Pulling Jira → beads ==="
  echo ""

  local mapped_count
  mapped_count=$(jq 'length' "$MAP_FILE")

  if [ "$mapped_count" -eq 0 ]; then
    echo "  ℹ No mapped issues. Run a push sync first."
    return 0
  fi

  jq -r 'to_entries[] | select(.value.platform == "jira") | "\(.key) \(.value.external_id)"' "$MAP_FILE" | \
  while read -r bead_id jira_key; do
    local response
    response=$(jira_api GET "/issue/$jira_key?fields=status")
    local jira_status
    jira_status=$(echo "$response" | jq -r '.fields.status.name // empty')

    if [ -z "$jira_status" ]; then
      echo "  ⚠ Could not fetch status for $jira_key ($bead_id)"
      continue
    fi

    # Map Jira status to bead status
    local bead_status
    case "$jira_status" in
      "Done"|"Closed"|"Resolved") bead_status="closed" ;;
      "In Progress"|"In Review")  bead_status="in_progress" ;;
      "Blocked")                   bead_status="blocked" ;;
      *)                           bead_status="open" ;;
    esac

    if [ "$dry_run" = true ]; then
      echo "  [dry-run] Would update $bead_id → status: $bead_status (Jira: $jira_status)"
    else
      echo "  ▶ $bead_id: Jira says '$jira_status' → bead status '$bead_status'"
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

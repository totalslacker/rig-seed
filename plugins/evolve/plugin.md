+++
name = "evolve"
description = "Autonomous evolution cycle for rig-seed projects"
version = 2

[gate]
type = "cooldown"
duration = "8h"
+++

# Evolve Plugin — Autonomous Evolution

This plugin triggers evolution cycles for rigs that use the rig-seed
template. It runs during the Deacon's patrol cycle when the cooldown gate opens.
The plugin runs every 8h but checks each rig's `.evolve/config.toml` for its
own `schedule.interval` setting — rigs are only evolved when their individual
interval has elapsed since their last session.

## Execution

For each rig in the town, check if it has evolution enabled:

```bash
gt rig list --json 2>/dev/null
```

For each rig, check two things:
1. The rig's `config.json` has `"evolve": { "enabled": true }`
2. The rig's repo contains `.evolve/config.toml`

**Skip docked/parked rigs** — evolution only runs on active rigs.

```bash
gt rig status <rig>
# If DOCKED or PARKED → skip
```

For each evolution-enabled, active rig:

### 0. Check per-rig interval

Each rig can set its own evolution interval in `.evolve/config.toml`:
```toml
[schedule]
interval = "8h"   # or "24h", "12h", etc.
```

Read the rig's interval and check if enough time has passed since its last session:

```bash
RIG_DIR="$GT_ROOT/<rig>/mayor/rig"

# Get interval from .evolve/config.toml (default: 24h)
INTERVAL=$(grep 'interval' "$RIG_DIR/.evolve/config.toml" 2>/dev/null | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "24h")

# Check last session timestamp from JOURNAL.md (first date found)
LAST_SESSION=$(grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}' "$RIG_DIR/JOURNAL.md" 2>/dev/null | head -1)

# If LAST_SESSION exists and interval hasn't elapsed → skip this rig
# Parse interval: strip trailing 'h', multiply by 3600 for seconds
HOURS=$(echo "$INTERVAL" | sed 's/h$//')
if [ -n "$LAST_SESSION" ]; then
  LAST_EPOCH=$(date -d "$LAST_SESSION" +%s 2>/dev/null || echo 0)
  NOW_EPOCH=$(date +%s)
  ELAPSED_HOURS=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
  if [ "$ELAPSED_HOURS" -lt "$HOURS" ]; then
    echo "Skipping <rig>: last session ${ELAPSED_HOURS}h ago, interval is ${HOURS}h"
    continue  # Skip to next rig
  fi
fi
```

### 1. Read evolution state

```bash
# Read from the rig's mayor clone
DAY=$(cat "$RIG_DIR/DAY_COUNT" 2>/dev/null || echo 0)
NEXT_DAY=$((DAY + 1))

# Get last journal entry (first 20 lines after the separator)
head -25 "$RIG_DIR/JOURNAL.md" 2>/dev/null || echo "No journal yet"

# Get specs summary (first 5 lines)
head -5 "$RIG_DIR/SPECS.md" 2>/dev/null || echo "No specs yet"
```

### 2. Fetch GitHub issues (if configured)

Check if the rig's config.json has a `github_repo` field in the evolve section:

```bash
# Read evolve config from rig
GITHUB_REPO=$(cat "$GT_ROOT/<rig>/config.json" | jq -r '.evolve.github_repo // empty')

if [ -n "$GITHUB_REPO" ]; then
  # Read issue label from .evolve/config.toml (default: agent-input)
  LABEL="agent-input"
  ISSUES=$(gh issue list --repo "$GITHUB_REPO" --state open --label "$LABEL" \
    --limit 10 --json number,title,body,reactionGroups 2>/dev/null || echo "[]")
fi
```

### 3. Create evolution bead

```bash
bd create --rig <rig> \
  --title "Evolve <project>: Day $NEXT_DAY" \
  --type task \
  --priority 2 \
  --description "Evolution cycle Day $NEXT_DAY for <project>.

## Recent Journal
<last journal entry>

## Specs Summary
<first 5 lines of SPECS.md>

## GitHub Issues
<formatted issues list, or 'No open issues'>

## Instructions
Follow the mol-evolve formula steps. Read IDENTITY.md first."
```

### 4. Sling to the rig

```bash
gt sling <bead-id> <rig> --formula mol-evolve
```

This spawns a polecat, hooks the evolution bead, and starts the session.
The polecat follows the mol-evolve formula from there.

### 5. Log dispatch

```bash
echo "Evolved: <rig> Day $NEXT_DAY (bead: <id>)"
```

## Error Handling

- If bead creation fails: log error, skip this rig, continue to next
- If sling fails (e.g., rig is docked): log error, skip
- If gh CLI is unavailable: skip GitHub issues, proceed without them
- Never fail the entire plugin because one rig had an issue

## Notes

- The plugin iterates ALL rigs, not just one. This is intentional — as more
  rig-seed projects are added, they all get checked on the same cycle.
- The plugin cooldown (8h) is the shortest supported interval. Per-rig intervals
  are checked against each rig's `.evolve/config.toml` `schedule.interval`.
- Rigs with longer intervals (e.g. 24h) are skipped when the plugin runs and
  their interval hasn't elapsed yet.

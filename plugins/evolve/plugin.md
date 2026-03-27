+++
name = "evolve"
description = "Autonomous evolution cycle for rig-seed projects"
version = 1

[gate]
type = "cooldown"
duration = "24h"
+++

# Evolve Plugin — Daily Autonomous Evolution

This plugin triggers daily evolution cycles for rigs that use the rig-seed
template. It runs during the Deacon's patrol cycle when the cooldown gate opens.

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

### 1. Read evolution state

```bash
# Read from the rig's mayor clone
RIG_DIR="$GT_ROOT/<rig>/mayor/rig"
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
  rig-seed projects are added, they all evolve on the same schedule.
- Per-rig interval overrides from `.evolve/config.toml` are a future enhancement.
  Currently all rigs share the plugin's 24h cooldown.

# External Integrations

Examples of connecting rig-seed's beads-based work tracking to external
project management tools. These are bridge patterns — they sync state
between beads and an external system without replacing either.

## Available Integrations

| Integration | File | Description |
|-------------|------|-------------|
| Linear | [linear-sync.sh](linear-sync.sh) | Sync beads to Linear issues |
| Jira | [jira-sync.sh](jira-sync.sh) | Sync beads to Jira issues |

## How It Works

Both integrations follow the same pattern:

1. **Read beads** — Query open/closed beads via `bd list`
2. **Map to external issues** — Create or update issues in Linear/Jira
3. **Store mapping** — Keep a local `bead-id → external-id` mapping file
4. **Bidirectional** — Optionally pull status changes back from the external tool

## When to Use This

- **Team visibility**: Non-technical stakeholders track progress in Linear/Jira,
  while the evolution agent works through beads
- **Sprint planning**: Import beads into a sprint board for prioritization
- **Reporting**: Use Linear/Jira dashboards and charts that already exist
- **Compliance**: Some teams require all work to be tracked in a specific tool

## When NOT to Use This

- **Solo projects**: Beads + ROADMAP.md are enough
- **Small teams using Gas Town**: Everyone can read beads directly
- **Replace beads**: The external tool is a mirror, not the source of truth.
  Beads remain the canonical state because the evolution agent reads them.

## Setup

Both scripts require an API token set via environment variable:

```bash
# Linear
export LINEAR_API_KEY="lin_api_..."

# Jira
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_USER="you@company.com"
export JIRA_API_TOKEN="..."
export JIRA_PROJECT="PROJ"
```

## Usage

```bash
# Sync all open beads to Linear
./linear-sync.sh

# Sync to Jira with dry-run preview
./jira-sync.sh --dry-run

# Pull status updates back from Linear
./linear-sync.sh --pull
```

## Mapping File

Both scripts maintain a `.beads-external-map.json` file in the project root
(gitignored by default). This maps bead IDs to external issue IDs:

```json
{
  "rs-abc": { "external_id": "LIN-123", "platform": "linear", "synced_at": "2026-03-24T12:00:00Z" },
  "rs-def": { "external_id": "PROJ-456", "platform": "jira", "synced_at": "2026-03-24T12:00:00Z" }
}
```

## Customization

Edit the scripts to customize:
- **Field mapping**: Which bead fields map to which external fields
- **Status mapping**: How bead statuses (open, in_progress, closed) map to
  external statuses
- **Labels/tags**: Auto-apply labels based on bead type (bug, task, etc.)
- **Sync frequency**: Run manually, via cron, or as a post-session hook

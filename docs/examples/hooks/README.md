# Git Hook Examples

Pre-built git hooks for rig-seed projects.

## Available Hooks

| Hook | Purpose |
|------|---------|
| [pre-commit](pre-commit) | Runs validate.sh and checks immutable file protection before each commit |
| [post-session](post-session) | Posts journal diffs to Slack or Discord after each evolution session |
| [post-session-sync](post-session-sync) | Runs Linear/Jira integration sync after each session |

## Installation

```bash
# From your project root:
cp docs/examples/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# For post-session notifications (install as post-merge hook):
cp docs/examples/hooks/post-session .git/hooks/post-merge
chmod +x .git/hooks/post-merge
```

## What the Pre-Commit Hook Does

1. **Runs validate.sh** — ensures all required template files exist and
   SESSION_COUNT is valid. If validation fails, the commit is blocked.

2. **Checks immutable files** — reads `.evolve/IMMUTABLE.txt` and blocks
   commits that modify protected files or directories. This catches
   accidental edits to IDENTITY.md, the immutable list itself, and
   `.github/workflows/`.

## What the Post-Session Hook Does

Posts the latest JOURNAL.md diff to a Slack or Discord channel via webhook
after each evolution session is merged.

**Configuration:**

| Variable | Required | Description |
|----------|----------|-------------|
| `WEBHOOK_URL` | Yes | Slack or Discord incoming webhook URL |
| `NOTIFICATION_TARGET` | No | `"slack"` or `"discord"` (auto-detected from URL) |
| `PROJECT_NAME` | No | Name shown in notifications (default: repo name) |
| `MAX_DIFF_LINES` | No | Max journal lines to include (default: 40) |
| `DRY_RUN` | No | Set to `"1"` to print payload without sending |

**Test it without sending:**

```bash
DRY_RUN=1 ./docs/examples/hooks/post-session
```

## What the Post-Session-Sync Hook Does

Automatically runs the Linear or Jira sync script after a session is merged,
pushing new beads and roadmap changes to your external tracker.

**Configuration:**

| Variable | Required | Description |
|----------|----------|-------------|
| `SYNC_TARGET` | Yes | `"linear"` or `"jira"` |
| `SYNC_SCRIPT` | No | Path to sync script (auto-detected from target) |
| `SYNC_DIRECTION` | No | `"push"`, `"pull"`, or `"both"` (default: push) |
| `SYNC_DRY_RUN` | No | Set to `"1"` to preview without syncing |
| `SYNC_QUIET` | No | Set to `"1"` to suppress info output |

**Chain with notifications:**

```bash
# Run both post-session hooks (notification + sync):
cat docs/examples/hooks/post-session docs/examples/hooks/post-session-sync \
  > .git/hooks/post-merge && chmod +x .git/hooks/post-merge
```

**Test it without syncing:**

```bash
SYNC_TARGET=linear SYNC_DRY_RUN=1 ./docs/examples/hooks/post-session-sync
```

## Bypassing

For emergencies (e.g., a human intentionally modifying an immutable file):

```bash
git commit --no-verify
```

The `--no-verify` flag skips all hooks. Use sparingly.

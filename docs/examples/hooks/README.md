# Git Hook Examples

Pre-built git hooks for rig-seed projects.

## Available Hooks

| Hook | Purpose |
|------|---------|
| [pre-commit](pre-commit) | Runs validate.sh and checks immutable file protection before each commit |

## Installation

```bash
# From your project root:
cp docs/examples/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## What the Pre-Commit Hook Does

1. **Runs validate.sh** — ensures all required template files exist and
   DAY_COUNT is valid. If validation fails, the commit is blocked.

2. **Checks immutable files** — reads `.evolve/IMMUTABLE.txt` and blocks
   commits that modify protected files or directories. This catches
   accidental edits to IDENTITY.md, the immutable list itself, and
   `.github/workflows/`.

## Bypassing

For emergencies (e.g., a human intentionally modifying an immutable file):

```bash
git commit --no-verify
```

The `--no-verify` flag skips all hooks. Use sparingly.

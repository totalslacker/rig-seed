# The Evolution Process

How rig-seed projects evolve autonomously, step by step.

## Overview

Each evolution cycle is a single session where an AI agent reads the project
state, identifies improvements, implements them, and journals what happened.
The cycle is defined by the `mol-evolve` formula — a checklist the agent
follows in order.

## The mol-evolve Formula

### Step 1: Load State

Read all project state files to understand where things stand:

- **IDENTITY.md** — Who this project is (immutable constitution)
- **SPECS.md** — What we're building
- **JOURNAL.md** — What happened in previous sessions
- **ROADMAP.md** — Current priorities and future work
- **LEARNINGS.md** — Cached technical insights
- **SESSION_COUNT** — Current evolution session number (monotonic, increments every session)
- **DAY_COUNT** — Current evolution day number (increments only on calendar date change)
- **DAY_DATE** — Date of the last session (YYYY-MM-DD, used to detect day changes)

**Bootstrap mode:** If SPECS.md is empty, the agent reads specs from the bead
description and writes SPECS.md before proceeding. The first few days focus on
infrastructure (project structure, build system, tests).

### Step 2: Self-Assess

Read all source code in the repository. Evaluate:

- What works well?
- What's missing or broken?
- What would make this more useful to a real user?

The agent forms an honest assessment — not a wish list, but a diagnosis.

### Step 3: Fetch Community Input

Check for GitHub issues (tagged with the configured label, default:
`agent-input`). These represent real user feedback and take priority over
the agent's own assessment.

### Step 4: Select Work

Pick 1-3 improvements for this session. Priority order:

1. **Bugs** — Anything broken gets fixed first
2. **Community issues** — Real user requests
3. **Roadmap items** — Planned work from ROADMAP.md
4. **Self-identified** — Improvements the agent noticed during self-assessment

Each selected task gets a bead (`bd create`) for tracking.

### Step 5: Implement

Write the code. Guidelines:

- Tests first where possible
- Commit after each logical unit (small, atomic commits)
- Never delete existing tests
- Never modify files in `.evolve/IMMUTABLE.txt`

### Step 6: Self-Review

Before submitting, the agent reviews its own diff:

- Does it match what was intended?
- Are there any immutable file violations?
- Did any tests break?
- Is the code quality acceptable?

### Step 7: Build Check

Run **ALL** of the project's build, test, and lint commands — not just the
primary language. Projects with multiple build systems (e.g., Go backend +
TypeScript frontend) must pass every check before submitting.

**How the check works:**

1. If `scripts/check.sh` exists, run it. This is the canonical build gate
   that auto-detects all build systems and runs configured commands.
2. Otherwise, run commands from the `[build]` section of `.evolve/config.toml`.
3. As a fallback, run whatever is in the project's `.claude/CLAUDE.md` build
   instructions.

**Multi-build-system detection:** `scripts/check.sh` automatically detects:
- `go.mod` → runs `go build`, `go test`, `go vet`
- `package.json` (root or subdirectories like `frontend/`) → runs available
  npm scripts (`build`, `test`, `lint`, `typecheck`)
- `Cargo.toml` → runs `cargo build`, `cargo test`
- `pyproject.toml` → runs `pytest`, `mypy`, `ruff` as configured
- `Makefile` → runs standard targets as a fallback
- `.github/workflows/*.yml` → lints YAML syntax

**If any check fails:**

1. Attempt to fix (up to `max_fix_attempts` from config, default: 3)
2. If still failing, revert all changes
3. Journal the failure honestly

**This is a hard gate.** Code that doesn't compile in ANY configured build
system must NEVER be submitted. A broken main branch is never acceptable.

### Step 8: Update State

**MANDATORY — this step runs for EVERY session that produces commits, whether
it's a numbered evolution cycle or a direct-slung task.** The journal is the
project's memory. Skipping it means the next agent has no context for what
happened.

- **JOURNAL.md** — Write a new entry at the top. Use the dual-counter format:
  `## Day <D> — Session <N> (YYYY-MM-DD)` where `<N>` is the current
  SESSION_COUNT value and `<D>` is the current DAY_COUNT value.
  Every entry MUST include:
  - **Goal**: First line after the heading. States intent before describing work.
  - Work summary in the body.
  - **Next Steps**: Last section. Hands off context to the next session. MANDATORY.
  This applies to ALL sessions — evolution cycles, direct tasks, bug fixes.
  The journal is the project's memory. No session is exempt.
- **ROADMAP.md** — Check off completed items, add new ones if discovered
- **SESSION_COUNT** — Increment by 1 (every session counts)
- **DAY_COUNT** — Increment by 1 ONLY if today's date differs from the value
  in DAY_DATE. If the date is the same, leave DAY_COUNT unchanged.
- **DAY_DATE** — Update to today's date (YYYY-MM-DD)
- **LEARNINGS.md** — Record any new technical insights
- Close completed beads

**Why unconditional?** A direct-slung task (e.g., a bug fix dispatched by the
Mayor) still changes the codebase. The next evolution session needs to know what
changed and why. If the journal is stale, the agent wastes time re-discovering
context or makes conflicting changes.

### Step 8b: Close Addressed Issues

If this session addressed any GitHub issues, close them now:

```bash
gh issue close <number> --repo <owner>/<repo> --comment "Addressed in session <N>. <brief description of what was done>"
```

**Guidelines:**
- Only close issues you actually addressed — don't close aspirational items
- Include a brief comment explaining what was done so the reporter knows
- If an issue was partially addressed, comment with progress but leave it open
- Reference the session number so the journal entry can be cross-referenced

### Step 9: Submit

Push the branch and submit to the merge queue (`gt done`). The Refinery
reviews and merges if the build passes.

## Configuration

All evolution settings live in `.evolve/config.toml`:

```toml
[schedule]
interval = "24h"               # How often cycles run

[limits]
max_improvements_per_session = 3   # Don't try to do too much
bootstrap_days = 3                 # Infrastructure-first period

[github]
fetch_issues = true            # Pull GitHub issues into context
issue_label = "agent-input"    # Only issues with this label

[safety]
max_fix_attempts = 3           # Revert after N failed fixes
revert_on_failure = true       # Auto-revert on persistent failure
```

## Triggering Evolution

Evolution cycles can start in two ways:

1. **Automatic:** The Deacon's evolve plugin checks configured rigs on each
   patrol. If the cooldown has elapsed, it creates a bead and dispatches a
   polecat.

2. **Manual:** Create a bead with the `mol-evolve` formula attached and sling
   it to the rig.

## Steering the Agent

You don't need to write code to influence evolution:

- **File GitHub issues** with the `agent-input` label to request features or
  report bugs. The agent checks these each cycle.
- **Edit ROADMAP.md** to reprioritize upcoming work.
- **Edit SPECS.md** to change the project's direction.
- **Edit `.evolve/config.toml`** to adjust frequency or safety limits.
- **Read JOURNAL.md** to see what the agent has been doing and why.

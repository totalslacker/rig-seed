# Day Zero Walkthrough

A step-by-step tutorial for running your first evolution session after
forking rig-seed. By the end, you'll have a project that's ready to
evolve autonomously.

## Prerequisites

- A fork of rig-seed (or a fresh clone)
- Git configured with push access to your fork
- Gas Town installed and a rig registered (see [FORKING.md](FORKING.md))

## Step 1: Run the Quickstart

```bash
cd your-project
./quickstart.sh
```

This resets SESSION_COUNT to 0, clears the journal/roadmap/learnings to fresh
headers, and runs validation. If it fails, fix the issue it reports before
continuing.

## Step 2: Write Your Specs

Open `SPECS.md`. This is the most important file — it tells the evolution
agent what to build. Answer these questions:

1. **What is this project?** One sentence.
2. **What problem does it solve?** Who has this problem and why?
3. **What are the requirements?** Concrete, testable outcomes.
4. **What are the non-goals?** What should the agent NOT build?

See [docs/examples/specs/](examples/specs/) for templates by project type.

## Step 3: Set Your Personality

Copy one of the [personality variants](examples/personalities/) to
`PERSONALITY.md`, or write your own. This controls the agent's
communication style in journals, commits, and issue responses.

## Step 4: Configure Evolution

Edit `.evolve/config.toml` to set your evolution schedule and limits.
See [docs/examples/configs/](examples/configs/) for strategy presets:

- **Conservative**: 48-hour cycles, 1 change per session
- **Sprint**: 8-hour cycles, up to 3 changes per session
- **Issue-driven**: 24-hour cycles, community issues first

## Step 5: Set Up Your Build

Update `.claude/CLAUDE.md` with your project's actual build and test
commands. The evolution agent reads this file to know how to build and
verify changes:

```markdown
### Build & Test Commands

\```bash
make build    # Build the project
make test     # Run tests
make lint     # Run linter
\```
```

Without these, the agent can't verify its own work.

## Step 6: Add CI (Optional but Recommended)

Copy the example workflows from `docs/examples/workflows/` into your
`.github/workflows/` directory:

```bash
cp docs/examples/workflows/validate.yml .github/workflows/
cp docs/examples/workflows/lint-markdown.yml .github/workflows/
```

These catch structural problems before they reach main.

## Step 7: Run Validation

```bash
./validate.sh
```

All checks should pass. If any fail, the agent's first session will
spend time fixing structural issues instead of building features.

## Step 8: Run the Health Check (Optional)

```bash
./health-check.sh
```

This will show warnings for an empty journal and zero day count — that's
expected. It confirms the health-check infrastructure works.

## Step 9: Trigger Your First Evolution

Register the project as a Gas Town rig, dispatch a `mol-evolve` molecule,
and let it run. The agent will:

1. Read your SPECS.md
2. Create a ROADMAP.md from the specs
3. Pick the first improvement
4. Implement it, test it, journal it
5. Submit to the merge queue

After the first session, check:
- `JOURNAL.md` — did it write an honest entry?
- `ROADMAP.md` — does the plan make sense?
- `SESSION_COUNT` — should be `1`
- The git log — are commits atomic and well-described?

## What to Expect

**Day 1-3**: The agent sets up foundations — build system, tests, basic
structure. Commits will be frequent and small.

**Day 4-10**: Feature work begins. The agent follows the roadmap, picks
up community issues, and self-identifies improvements.

**Day 10+**: The project matures. Changes get smaller, more targeted.
The agent focuses on polish, edge cases, and documentation.

## Troubleshooting

If the agent doesn't evolve or produces broken builds, see
[TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common failure modes.

## Steering the Evolution

You don't have to be hands-off. Between sessions:
- **File GitHub issues** — the agent checks these and prioritizes real feedback
- **Edit ROADMAP.md** — reorder items, add new ones, remove bad ideas
- **Update SPECS.md** — if requirements change, say so
- **Review the journal** — if the agent is going off-track, add a note

# rig-seed

A template for building autonomously-evolving software projects with
[Gas Town](https://github.com/anthropics/gas-town).

## What Is This?

rig-seed is a scaffold you fork to create a new project that evolves itself.
Every day (or on your configured schedule), an AI agent:

1. Reads the project's specs, roadmap, and recent journal
2. Self-assesses the current state of the code
3. Picks 1-3 improvements to make
4. Implements them with tests
5. Journals what happened
6. Submits for automated merge (build-gated)

The agent is coordinated by Gas Town's Mayor, executed as a Polecat (worker),
and quality-gated by the Refinery (merge queue).

## Quick Start

### 1. Create your project

Fork this repo or use it as a GitHub template. This gives you all the
evolution state files with sensible defaults.

### 2. Write your specs

Open `SPECS.md` and describe what you want this project to become. Be
specific — the agent uses this to guide its work. If you leave it empty,
the agent will read specs from the bead description on its first run.

### 3. Add it as a Gas Town rig

```bash
gt rig add myproject <your-git-url>
```

### 4. Enable evolution

Add an `evolve` section to your rig's config:

```json
{ "evolve": { "enabled": true, "github_repo": "you/your-repo" } }
```

### 5. Start evolving

```bash
gt rig undock myproject && gt rig start myproject
```

The Deacon's evolve plugin triggers daily cycles automatically. Or trigger
one manually by creating a bead with the `mol-evolve` formula.

### 6. Guide the agent

- Check `JOURNAL.md` to see what the agent did each session
- File GitHub issues with the `agent-input` label to steer priorities
- Review `ROADMAP.md` for upcoming work
- Adjust `.evolve/config.toml` for schedule and limits

## Template Files

| File | Purpose | Mutable? |
|------|---------|----------|
| `IDENTITY.md` | Project constitution and rules | **No** (immutable) |
| `PERSONALITY.md` | Agent voice and communication style | Yes (rarely) |
| `SPECS.md` | What we're building (filled on first run) | Yes |
| `ROADMAP.md` | Priorities, milestones, future work | Yes |
| `JOURNAL.md` | Session log (append-only, never delete) | Append only |
| `LEARNINGS.md` | Accumulated technical insights | Yes |
| `DAY_COUNT` | Current evolution day number | Auto-incremented |
| `.evolve/config.toml` | Evolution settings (frequency, limits) | Yes |
| `.evolve/IMMUTABLE.txt` | Files the agent cannot modify | Human only |
| `.claude/CLAUDE.md` | Instructions for evolution workers | Yes |

## Validation

Run the template validation script to check that all required files are present:

```bash
./validate.sh
```

This is also available as an [example CI workflow](docs/examples/workflows/README.md)
you can add to your forked repo.

## Health Check

Monitor whether your forked project is actively evolving:

```bash
./health-check.sh
```

Checks DAY_COUNT progression, journal freshness, recent git activity, and
template validity. Configure thresholds via `MAX_COMMIT_AGE_DAYS` and
`MAX_JOURNAL_AGE_DAYS` environment variables (default: 7 days).

## Fork Quickstart

After forking, run the quickstart script to reset evolution state and get
your project ready:

```bash
./quickstart.sh
```

This resets DAY_COUNT, clears the journal/roadmap/learnings, and walks you
through writing your specs. See [example specs](docs/examples/specs/README.md)
for starter templates (CLI tool, web API, library).

## Documentation

- [Forking Guide](docs/FORKING.md) — What to do after you fork rig-seed
- [The Evolution Process](docs/EVOLUTION.md) — How `mol-evolve` works step by step
- [Example Specs](docs/examples/specs/README.md) — Starter SPECS.md files for common project types
- [Example Configs](docs/examples/configs/README.md) — `.evolve/config.toml` variants for different strategies
- [Example Roadmaps](docs/examples/roadmaps/README.md) — Starter ROADMAP.md files for common project types
- [Example CI Workflows](docs/examples/workflows/README.md) — GitHub Actions you can copy
- [Example Personalities](docs/examples/personalities/README.md) — PERSONALITY.md variants (formal, casual, minimal)
- [Example Git Hooks](docs/examples/hooks/README.md) — Pre-commit hook for validation and immutable file protection
- [Day Zero Walkthrough](docs/DAY-ZERO.md) — Step-by-step tutorial for your first evolution session
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Common problems and how to fix them
- [Project Plan](docs/PLAN.md) — Architecture and design decisions

## Inspired By

[yoyo-evolve](https://github.com/yologdev/yoyo-evolve) — a self-evolving coding
agent that grows one commit at a time.

## License

MIT

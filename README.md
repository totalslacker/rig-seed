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

1. **Fork this repo** (or use it as a GitHub template)
2. **Add it as a Gas Town rig:**
   ```bash
   gt rig add myproject <your-git-url>
   ```
3. **Write your specs** in `SPECS.md` — what should this project become?
4. **Enable evolution** in the rig config:
   ```json
   { "evolve": { "enabled": true, "github_repo": "you/your-repo" } }
   ```
5. **Watch it grow.** The Deacon plugin triggers daily evolution cycles.

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

## Inspired By

[yoyo-evolve](https://github.com/yologdev/yoyo-evolve) — a self-evolving coding
agent that grows one commit at a time.

## License

MIT

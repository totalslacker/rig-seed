# Contributing to rig-seed

## How Evolution Works

This project evolves autonomously. Every day, an AI agent (a Gas Town Polecat):

1. Reads the current state: SPECS.md, ROADMAP.md, JOURNAL.md, LEARNINGS.md
2. Self-assesses the codebase and identifies improvements
3. Picks 1-3 things to work on (bugs first, then community issues, then roadmap)
4. Implements with tests, commits atomically
5. Journals what happened honestly
6. Submits to the Refinery merge queue (build-gated)

## How You Can Contribute

### Steer the Agent

File a GitHub issue with the `agent-input` label. The agent reads these during
evolution cycles and prioritizes them. Be specific about what you want — the
agent responds better to concrete problems than vague suggestions.

### Direct Code Contributions

Pull requests are welcome. Keep in mind:

- **Don't modify `IDENTITY.md`** — it's the project's constitution
- **Don't delete journal entries** — JOURNAL.md is append-only
- **Don't modify `.evolve/IMMUTABLE.txt`** without discussion
- **Tests are required** for code changes once the project has a test suite

### Improve the Template

If you're improving rig-seed itself (not a project forked from it):

- Template documentation (README, this file, CLAUDE.md) — always welcome
- Evolution config defaults — propose changes with rationale
- New state files — discuss in an issue first

## Project Structure

```
rig-seed/
├── .claude/CLAUDE.md      # Instructions for evolution workers
├── .evolve/
│   ├── config.toml        # Evolution settings
│   └── IMMUTABLE.txt      # Protected files list
├── IDENTITY.md            # Project constitution (immutable)
├── PERSONALITY.md         # Agent voice and communication style
├── SPECS.md               # Project specification
├── ROADMAP.md             # Priorities and milestones
├── JOURNAL.md             # Session log (append-only)
├── LEARNINGS.md           # Technical insights
├── SESSION_COUNT           # Current evolution session number
└── README.md              # Project overview
```

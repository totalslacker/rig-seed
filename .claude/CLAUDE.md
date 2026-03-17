# CLAUDE.md — Evolution-Aware Project Instructions

This repository uses **rig-seed**, an autonomous evolution framework for
[Gas Town](https://github.com/anthropics/gas-town).

## For Polecats (Evolution Workers)

You are running an evolution session. Your work is guided by the `mol-evolve`
formula steps shown in your hook. Follow them in order.

### Key Files to Read First

1. **IDENTITY.md** — Who this project is. Immutable. Read it, internalize it.
2. **SPECS.md** — What we're building. If empty, bootstrap mode applies.
3. **ROADMAP.md** — Current priorities and milestones.
4. **JOURNAL.md** — Recent history. Check what was tried before.
5. **LEARNINGS.md** — Cached technical knowledge.
6. **DAY_COUNT** — Current evolution day number.
7. **.evolve/IMMUTABLE.txt** — Files you must never touch.

### Safety Rules

- **Never modify files listed in `.evolve/IMMUTABLE.txt`.**
- **Every change must pass the build.** If it breaks, fix it or revert.
- **Never delete existing tests.** Tests protect the project from regressions.
- **Commit frequently.** Small, atomic commits with descriptive messages.
- **Journal every session.** Write at the TOP of JOURNAL.md. Be honest.

### Build & Test Commands

*Populated during bootstrap. Check here after Day 1.*

```bash
# Example (replace with actual commands after bootstrap):
# cargo build          # Build
# cargo test           # Test
# cargo clippy         # Lint
```

### Work Tracking

Use Gas Town beads for all task tracking:
```bash
bd create --title "Description" --type task    # Create a task
bd update <id> --claim                          # Claim it
bd close <id>                                   # Complete it
```

### Discovered Issues

If you find bugs or improvements outside your current scope:
```bash
bd create --title "Found: <description>" --type bug --priority 2
```
Do NOT fix unrelated issues in your current branch.

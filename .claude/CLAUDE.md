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

This is a template repo — no build system yet. When you fork rig-seed and
choose a language/stack, update this section with your actual commands:

```bash
# Replace these with your project's commands after bootstrap:
# make build           # Build
# make test            # Test
# make lint            # Lint
```

### Evolution Day Flow

Each evolution session follows this pattern:
1. Read state files (IDENTITY, SPECS, JOURNAL, ROADMAP, LEARNINGS, DAY_COUNT)
2. If SPECS.md is empty, bootstrap: read specs from bead, write SPECS.md
3. Self-assess: read source code, identify weaknesses
4. Pick 1-3 improvements (bugs > community issues > roadmap > self-identified)
5. Implement with tests, commit after each logical unit
6. Journal the session at the TOP of JOURNAL.md
7. Update ROADMAP.md, increment DAY_COUNT, update LEARNINGS.md if applicable
8. Push and submit to merge queue

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

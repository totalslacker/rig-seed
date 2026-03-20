# Plan: rig-seed — Autonomous Evolution Framework for Gas Town

## Context

Inspired by [yoyo-evolve](https://github.com/yologdev/yoyo-evolve) (a self-evolving coding agent), we're building a **reusable template repo** that anyone can fork to create autonomously-evolving projects within Gas Town.

**yoyo-evolve's approach:** GitHub Actions cron fires daily → shell script orchestrates build/test/prompt → agent reads its own source, self-assesses, picks improvements, implements, journals → commit or revert → push.

**Our approach:** Same spirit, but orchestrated through Gas Town. A Deacon plugin triggers daily evolution cycles, the Mayor creates beads and slings work to polecats, the refinery gates merges. The template repo (`rig-seed`) contains the identity, personality, journal, and evolution state — fork it, configure it, add it as a rig, and it starts evolving.

## What We're Building

### 1. `rig-seed` template repo (the fork-and-go template)

A GitHub template repo containing:

```
rig-seed/
├── .claude/
│   └── CLAUDE.md            # Evolution-aware project instructions for polecats
├── .evolve/
│   ├── config.toml           # Evolution config (frequency, max improvements, etc.)
│   └── IMMUTABLE.txt         # Files the agent must never modify
├── IDENTITY.md               # Immutable constitution — who this project is (DO NOT MODIFY)
├── PERSONALITY.md             # Voice, tone, how the agent communicates
├── JOURNAL.md                 # Append-only session log (never delete entries)
├── ROADMAP.md                 # Living document — priorities, milestones, future
├── LEARNINGS.md               # Accumulated technical insights
├── SESSION_COUNT               # Integer: current evolution session
├── SPECS.md                   # User-provided project specification (filled on first run)
├── README.md                  # Template README explaining what this is
└── .gitignore
```

**Key files:**

- **IDENTITY.md** — Immutable. Similar to yoyo-evolve's: "I am a project that evolves itself. My first task is to understand what I'm building (from SPECS.md or user input), document the plan in ROADMAP.md, then get to work. I pick improvements, implement them, test them, and journal what happened." Never modified by the agent.

- **PERSONALITY.md** — The agent's voice. How it writes journal entries, how it communicates in issue responses, its character. Mutable (the agent can refine its own personality over time, though this should be rare and intentional).

- **SPECS.md** — Starts empty or with a placeholder. The bootstrapping phase fills this from user input (bead description, GitHub issue, or manual seed). Once filled, it's the "what are we building" document.

- **.evolve/config.toml** — Configurable settings:
  ```toml
  [schedule]
  interval = "24h"           # Default: once daily

  [limits]
  max_improvements_per_session = 3
  bootstrap_days = 3         # Days focused on infrastructure before features

  [github]
  fetch_issues = true        # Pull issues tagged "agent-input" into evolution context
  issue_label = "agent-input"

  [safety]
  max_fix_attempts = 3       # Revert after N failed build attempts
  revert_on_failure = true
  ```

- **.evolve/IMMUTABLE.txt** — List of files the agent cannot touch:
  ```
  IDENTITY.md
  .evolve/IMMUTABLE.txt
  .github/workflows/
  ```

### 2. Deacon plugin: `evolve` (generic, rig-configurable)

A **single generic plugin** that handles evolution for any rig that has rig-seed state files. Not per-rig plugins — one plugin that iterates configured rigs.

**Gate:** Cooldown-based, default 24h (reads from rig's `.evolve/config.toml`).

**What it does each cycle:**
1. Check which rigs have evolution enabled (look for `.evolve/config.toml` in each rig's repo)
2. For each evolution-enabled rig whose cooldown has elapsed:
   a. Fetch open GitHub issues (if configured) from the rig's repo
   b. Read current SESSION_COUNT, last JOURNAL.md entry
   c. Create a bead: "Evolve <project>: Day N" with context (issues, recent journal, specs summary)
   d. `gt sling <bead-id> <rig>` — dispatches a polecat

### 3. Evolution formula: `mol-evolve.formula.toml`

Steps (extends the standard polecat-work lifecycle):

```
1. load-state        — Read IDENTITY.md, SPECS.md, JOURNAL.md, ROADMAP.md, LEARNINGS.md, SESSION_COUNT
                       If SPECS.md is empty → bootstrap mode (read specs from bead description)
2. self-assess       — Read all source code, evaluate quality, identify weaknesses
3. fetch-community   — Read GitHub issues from bead description, prioritize by reactions
4. select-work       — Pick 1-3 improvements. Priority: bugs > community issues > roadmap > self-identified
                       Use beads for tracking: `bd create` for each task, claim them
5. implement         — Write code, tests first where possible, commit after each logical unit
6. self-review       — Review diff, check IMMUTABLE.txt compliance, look for issues
7. build-check       — Run configured build/test/lint commands. Fix or revert (max 3 attempts)
8. update-state      — Journal entry at top of JOURNAL.md, update ROADMAP.md, increment SESSION_COUNT,
                       update LEARNINGS.md if applicable, close completed beads
9. submit-mr         — Push branch, `gt mq submit` → enters refinery queue
10. await-verdict    — Wait for MERGED or FIX_NEEDED from refinery
11. self-clean       — On MERGED: `gt done`, session exits
```

**Bootstrap mode (Day 0-N, SPECS.md empty):**
- Step 1 detects empty SPECS.md
- Agent reads the bead description for project specs (the user provides these when first configuring)
- Writes SPECS.md, initial ROADMAP.md, sets up project structure (language, build system, initial files)
- First few days focus exclusively on infrastructure

### 4. Rig configuration for evolution

When adding a rig-seed-based project as a Gas Town rig, the rig's config.json gets an `evolve` section:

```json
{
  "evolve": {
    "enabled": true,
    "github_repo": "owner/repo"
  }
}
```

The rest of the config lives in the repo itself (`.evolve/config.toml`), keeping it version-controlled and forkable.

## Getting Started (Wire Up Your Project)

### Phase 1: Create your project repo
1. Fork or use `rig-seed` as a GitHub template to create your project repo
2. Add it as a Gas Town rig: `gt rig add <name> <git-url>`

### Phase 2: Configure your project
1. Write your project specs in `SPECS.md` — what should this project become?
2. Update `.evolve/config.toml` with your preferred schedule and limits
3. Add evolve settings to your rig's `config.json`:
   ```json
   { "evolve": { "enabled": true, "github_repo": "you/your-repo" } }
   ```

### Phase 3: Start evolving
1. Undock the rig: `gt rig undock <rig> && gt rig start <rig>`
2. The Deacon's evolve plugin will pick it up on the next patrol cycle
3. Or trigger manually: create a bead and sling it with the `mol-evolve` formula
4. Watch it bootstrap — first sessions focus on project structure and build system

### Phase 4: Iterate
1. Check JOURNAL.md to see what the agent did each day
2. File GitHub issues with the `agent-input` label to steer direction
3. Review ROADMAP.md for progress and upcoming work
4. Adjust `.evolve/config.toml` as needed (frequency, limits, etc.)

## Verification

1. **Template completeness:** All state files present with correct content, IDENTITY.md matches the spirit of yoyo-evolve
2. **Formula dry run:** Manually sling a test bead to a rig with the mol-evolve formula, verify it follows the steps
3. **Plugin trigger:** Verify the Deacon's plugin-run step picks up the evolve plugin and respects the cooldown gate
4. **End-to-end:** Trigger an evolution cycle for your project, watch the polecat self-assess, implement, journal, submit MR, and get merged by refinery
5. **Fork test:** Fork rig-seed into a new repo, add as a new rig, verify it bootstraps independently

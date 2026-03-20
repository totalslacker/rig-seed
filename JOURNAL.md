# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Session 13 (2026-03-20 08:40) — Session numbering, mandatory journal What's next (rs-cak)

Batch addressing Issues #1, #5, #14, #15, #16 — all related to journal and
session tracking:

1. **Renamed DAY_COUNT → SESSION_COUNT** across the entire template: the file
   itself, all scripts (validate.sh, quickstart.sh, health-check.sh, metrics.sh),
   all docs, integration tests, and hook examples. "Day" was misleading since
   sessions can run multiple times per day or skip days entirely.

2. **Updated journal format in PERSONALITY.md** to use
   `## Session N (YYYY-MM-DD HH:MM) — summary` with a mandatory "What's next:"
   line. Updated all three personality variant examples (formal, casual, minimal)
   to match.

3. **Made "What's next:" mandatory** in docs/EVOLUTION.md Step 8, so the next
   agent always knows where to pick up.

What's next: GitHub Actions metrics workflow, migration script for version upgrades.

---

## Session 13 — Metrics PR workflow, migration script (rs-i2f)

Two Ecosystem-phase items:

1. **Metrics PR comment workflow** (docs/examples/workflows/metrics-pr-comment.yml) —
   GitHub Actions workflow that runs metrics.sh on pull requests and posts evolution
   metrics (day count, session count, roadmap completion) as a PR comment. Uses a
   marker comment pattern to update existing comments instead of creating duplicates.
   Passes both human-readable and machine-readable metrics output to the comment body.

2. **Migration script** (scripts/migrate.sh) — Detects which rig-seed features are
   present in a fork and copies missing files from upstream. Checks are ordered by the
   day each feature was added (Day 1 through Day 13). Supports `--dry-run` to preview
   changes. Never overwrites existing files — only adds missing ones. Also flags
   config.toml sections that need manual review (like the release strategy added in
   Day 12).

Also: Updated workflows README with the new metrics workflow, added Migration section
to the main README.

What's next: Multi-project dashboard, Grafana/Prometheus integration example.

---

## Session 12 — Release script, release config, issue-closing docs (rs-yol)

Three Ecosystem-phase items addressing GitHub Issues #2, #3, and #6:

1. **Release script** (scripts/release.sh) — Reads latest semver tag, increments
   major/minor/patch, creates annotated tag, pushes. Supports `--dry-run`. Starts
   at v0.1.0 if no tags exist yet.

2. **Release config** (.evolve/config.toml `[release]` section) — Strategy options:
   `manual` (human runs the script), `per-session` (tag after every evolution
   cycle), `milestone` (tag when a roadmap phase completes). Configurable tag
   prefix and default bump level.

3. **Issue-closing guidance** — Added Step 8b to docs/EVOLUTION.md documenting when
   and how to close GitHub issues during evolution. Added "Issue Closing Voice"
   section to PERSONALITY.md with good/bad examples.

What's next: GitHub Actions metrics workflow, migration script for version upgrades.

---

## Session 11 — Upgrade guide, post-session hook, metrics script (rs-dt8)

Three final Sustainability-phase items, completing the milestone:

1. **Upgrade guide** (docs/UPGRADING.md) — How to pull new rig-seed features
   into an existing fork. Covers three methods: cherry-pick (recommended for
   targeted changes), selective merge (for batch updates), and manual copy.
   Includes a table of what to upgrade vs. what to never overwrite, conflict
   resolution guidance, and version tracking via a config entry.

2. **Post-session hook** (docs/examples/hooks/post-session) — Posts the latest
   JOURNAL.md diff to Slack or Discord via incoming webhook. Auto-detects
   platform from URL. Supports DRY_RUN mode for testing. Includes commit link
   for GitHub repos. Install as a post-merge hook to fire after Refinery merges.

3. **Metrics script** (metrics.sh) — Summarizes evolution history: session count,
   commits per session, velocity (sessions/week), roadmap progress, codebase
   size, and learnings count. Supports `--quiet` for machine-readable key=value
   output (useful for CI or dashboards).

Also: Updated README with Metrics section and Upgrading link. Updated hooks
README with post-session documentation. Added Ecosystem roadmap phase.

Sustainability milestone is now fully complete.

---

## Session 10 — Rename /rig-seed to /rig-spawn (rs-aw3)

Renamed the `/rig-seed` slash command to `/rig-spawn` to better reflect its
purpose (spawning new projects, not seeding).

Changes:
- Renamed `.claude/commands/rig-seed.md` → `.claude/commands/rig-spawn.md`
- Updated command header from `/rig-seed` to `/rig-spawn`
- Updated ROADMAP.md slash command reference
- Updated JOURNAL.md Session 9 entry to reflect new filename
- Preserved all "rig-seed" references that refer to the project name (not the command)

Addresses GitHub Issue #11.

---

## Session 9 — /rig-seed slash command for one-click project setup (rs-1te)

Built the `/rig-spawn` Claude Code custom command (`.claude/commands/rig-spawn.md`)
— an interactive wizard that takes a user from "I have an idea" to a fully
configured, self-evolving Gas Town rig.

The command guides through 10 steps:
1. Gather project summary
2. Choose project/rig name
3. Create repo (fork, new, or existing)
4. Register as a Gas Town rig (`gt rig add`)
5. Copy template files and run quickstart
6. Interactive SPECS.md planning with example templates
7. Write ROADMAP.md with phased milestones
8. Configure evolution interval and settings
9. Validate and commit
10. Optionally run first evolution session

Key design decisions:
- **Three repo paths**: fork (recommended), new repo, or existing repo
- **Error handling at each step**: gh not installed, repo name taken, auth failures
- **Example-driven planning**: Uses existing docs/examples/specs/ templates
- **Config walkthrough**: Explains tradeoffs of different evolution intervals
- Addresses GitHub Issue #10

---

## Session 8 — CLI polish and sustainability roadmap (rs-i83)

Three Sustainability-phase items:

1. **`--help` and `--quiet` flags** for validate.sh and health-check.sh — Both
   scripts now accept `-q`/`--quiet` (suppresses ok lines, only shows failures/
   warnings and the result) and `-h`/`--help`. Makes them CI-friendly: a quiet
   pass is zero output except the RESULT line.

2. **README documentation link** — docs/FORMULA-CUSTOMIZATION.md existed since
   Session 7 but was never linked in the README's Documentation section. Fixed.

3. **Sustainability roadmap phase** — All previous milestones (Bootstrap,
   Foundation, Growth, Maturity) were complete. Added a Sustainability phase
   with upgrade guide, notification hooks, and metrics ideas.

---

## Session 7 — Integration test, formula docs, health-check fix (rs-tdh)

Three Maturity-phase completions:

1. **Integration test** (tests/integration-test.sh) — End-to-end test that
   simulates a fork, runs quickstart, validates the template, simulates an
   evolution session, runs health-check, and verifies error detection. 11 test
   cases covering the full lifecycle. Uses a temp directory with a fresh git
   repo — no side effects on the real project.

2. **Formula customization docs** (docs/FORMULA-CUSTOMIZATION.md) — Documents
   how to customize mol-evolve for project-specific steps: config.toml build
   commands, CLAUDE.md agent instructions, custom validation checks. Includes
   examples for Go CLI, Python API, TypeScript library, and monorepo setups.
   Covers scope control (IMMUTABLE.txt, ROADMAP focusing, session size limits).

3. **Health-check journal header fix** — health-check.sh was only matching
   `## Day N` headers but the journal format changed to `## Session N` in
   Session 6. Now matches both patterns so existing and new forks work.

The Maturity roadmap is now complete. All items checked off.

---

## Session 6 (task) — Make journaling unconditional in mol-evolve docs (rs-06e)

Updated docs/EVOLUTION.md Step 8 (Update State) to make journaling mandatory for
every session that produces commits — not just numbered evolution cycles. Direct
tasks slung by the Mayor were previously at risk of skipping the journal, leaving
the next agent without context.

Changes:
- **docs/EVOLUTION.md**: Rewrote Step 8 with MANDATORY header, session numbering
  format (`## Session <N> — <summary> (<bead-id>)`), direct-task variant, and a
  "Why unconditional?" rationale section.
- **DAY_COUNT**: Incremented to 6 (even direct tasks count as sessions).

This addresses GitHub Issue #5 (journal must always be updated) and incorporates
the session numbering format from Issue #1.

---

## Day 6 — Personality variants, day-zero tutorial, pre-commit hook (rs-ndw)

Three Maturity-phase items:

1. **Personality variants** (docs/examples/personalities/) — Three PERSONALITY.md
   templates: formal (enterprise/compliance), casual (dev tools/personal projects),
   minimal (infrastructure/terse). Each has voice examples for journal, issues, and
   commits. README with a comparison table for picking.

2. **Day-zero walkthrough** (docs/DAY-ZERO.md) — Step-by-step tutorial from "I just
   forked" to "my first evolution session ran." Covers quickstart, writing specs,
   choosing personality and config, setting up build commands, adding CI, running
   validation, and what to expect in the first 10 days.

3. **Pre-commit hook** (docs/examples/hooks/pre-commit) — Runs validate.sh and
   checks staged files against .evolve/IMMUTABLE.txt. Blocks commits that modify
   protected files. Includes install instructions and bypass docs.

Next: integration test (fork → quickstart → validate → health-check), formula
customization docs.

---

## Day 5 — Health check, roadmap examples, personality polish (rs-ai3)

Three Growth-phase items knocked out:

1. **health-check.sh** — Monitors a running fork: DAY_COUNT progression, journal
   freshness, git activity recency, uncommitted changes, template validity. Thresholds
   configurable via env vars. Exits 0 for healthy, 1 for errors, warnings are non-fatal.

2. **Example roadmaps** (docs/examples/roadmaps/) — Starter ROADMAP.md files for CLI
   tools, web APIs, and libraries. Same fill-in-the-blank approach as the spec examples.
   Each has phased milestones with concrete checklist items.

3. **PERSONALITY.md voice examples** — Added roadmap update voice and PR/code review
   voice sections with good/bad examples. Growth phase is now complete.

Next: Maturity phase — day-zero tutorial, pre-commit hook example, integration test.

---

## Day 4 — Fork guide, config variants, changelog template (rs-jrd)

Growth phase begins. Three things that help forkers actually get going:

1. **Fork guide** (docs/FORKING.md) — End-to-end walkthrough: run quickstart,
   write specs, pick a config strategy, set up build commands, add CI, register
   as a rig. Includes a "what to keep vs. change" table and file protection tips.

2. **Config variants** (docs/examples/configs/) — Three `.evolve/config.toml`
   examples: conservative (48h/1 change), sprint (8h/3 changes), issue-driven
   (24h/community-focused). Each has inline comments explaining the tradeoffs.

3. **CHANGELOG template** (CHANGELOG.template.md) — Keep a Changelog format
   with Unreleased section pre-filled and a commented-out release example.
   Quickstart doesn't touch it; forkers copy it to CHANGELOG.md when ready.

Foundation was about having all the files. Growth is about making them useful.
Next: PERSONALITY voice examples, health-check script for running forks.

---

## Day 3 — Example specs, troubleshooting, and fork quickstart (rs-wup)

Three deliverables, all completing the Foundation milestone:

1. **Example SPECS.md variants** (docs/examples/specs/) — Three starter templates
   for CLI tools, web APIs, and libraries. Each has fill-in-the-blank sections so
   forkers don't stare at an empty SPECS.md. Includes a README explaining how to
   pick and copy.

2. **Troubleshooting guide** (docs/TROUBLESHOOTING.md) — Eight common failure
   modes with symptoms, causes, and fixes. Covers everything from "agent does
   nothing" to "cycles don't trigger." Written from real pain points observed
   during the first three evolution sessions.

3. **Fork quickstart script** (quickstart.sh) — Resets DAY_COUNT, clears
   journal/roadmap/learnings to fresh headers, checks for specs, runs validation.
   One command to go from "I just forked" to "ready to evolve."

Foundation milestone is now complete. All six items checked off. The template is
genuinely usable — fork it, run quickstart, write specs, add as a rig, go.
Growth phase next: fork detection, config variants, PERSONALITY improvements.

---

## Day 2 — Validation, CI examples, and formula docs (rs-egn)

Three deliverables this session, all called out in the Day 1 journal:

1. **validate.sh** — A shell script that checks all required template files
   exist, verifies DAY_COUNT is a valid integer, and confirms immutable files
   are present. Runs clean on the current repo. Intended as a CI gate for
   forked projects.

2. **Example CI workflows** (docs/examples/workflows/) — GitHub Actions for
   template validation and markdown linting. Placed in docs/ rather than
   .github/workflows/ because the workflows directory is immutable (human-
   controlled CI). Includes a README explaining how to copy them.

3. **docs/EVOLUTION.md** — Full documentation of the mol-evolve formula: all 9
   steps from load-state through submit, plus configuration reference and
   guidance on steering the agent via issues and ROADMAP edits.

Also updated README with a Validation section and Documentation links. Three
of four Foundation roadmap items are now complete; remaining: example SPECS.md
variants for common project types.

---

## Day 1 — Bootstrap: specs, docs, and guardrails (rs-nok)

Wrote SPECS.md from the bead description — rig-seed is a fork-and-go template,
not a runnable project. Added MIT LICENSE and CONTRIBUTING.md explaining how
the evolution process works and how humans can steer it. Expanded the README's
Quick Start from a terse 5-step list to a 6-section guide with context.
Updated CLAUDE.md with the evolution day flow so future polecats know the drill.
Tomorrow: example CI workflows and a template validation script.

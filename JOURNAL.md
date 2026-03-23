# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Day 7 — Session 24 (2026-03-23)

**Goal**: Complete all three NEXT_STEPS.md Priority items — Developer Experience phase improvements.

**Work Selection**: All three Priority items from NEXT_STEPS.md were concrete and independent. No new
community issues (#8 and #9 remain, both Gas Town internals). Developer Experience roadmap phase had
four unchecked items; this session addresses three of them. Also fixed a duplicate unchecked item in
the Polish roadmap section.

Three deliverables:

1. **`--json` output mode for check.sh** — New `--json` flag that outputs structured JSON with result
   status (passed/failed/no_checks), pass/fail/skip counts, and an array of individual check results.
   Follows the same pattern as dashboard.sh `--json`. Suppresses all human-readable output in JSON
   mode. Useful for CI integrations, dashboards, and programmatic consumption.

2. **ShellCheck CI workflow example** (docs/examples/workflows/shellcheck.yml) — Example GitHub
   Actions workflow that lints all `.sh` files with ShellCheck. Uses ludeeus/action-shellcheck with
   warning severity threshold. Triggers on push to main and PRs when shell scripts change. Includes
   source-following (`-x`) for accurate cross-file analysis.

3. **`--watch` mode for health-check.sh** — New `-w`/`--watch` flag that re-runs the health check
   continuously at a configurable interval (default 60 seconds). Shows timestamps on each run.
   Refactored the check logic into a `run_health_check` function to support the loop without
   duplicating code. Useful for monitoring during active development or after deployments.

Also: Removed duplicate unchecked Polish roadmap item (line 100 was an unchecked copy of the already-
checked line 102). Updated migrate.sh with Session 24 feature detection.

**Next Steps**: See NEXT_STEPS.md.

---

## Day 7 — Session 23 (2026-03-23)

**Goal**: Complete the last Polish item (output marker normalization), add community onboarding to README, and start a Developer Experience roadmap phase.

**Work Selection**: All three NEXT_STEPS.md Priority items addressed. No new community issues
(only #8 and #9 remain, both Gas Town internals). The last unchecked Polish item was concrete
and well-scoped. The README onboarding section and new roadmap phase round out the session.

Three deliverables:

1. **Output marker normalization** — Audited all 10 scripts for emoji vs text-only output
   markers. Found two conventions: root scripts (validate.sh, health-check.sh) used text-only
   (`ok:`, `FAIL:`, `WARN:`) while scripts/ directory scripts used emoji (`✓`, `✗`, `⚠`, `ℹ`).
   Standardized everything on emoji: updated validate.sh (`ok:` → `✓`, `FAIL:` → `✗`,
   `WARN:` → `⚠`), health-check.sh (same), migrate.sh (`[warning]` → `⚠`), and the
   integration test (`PASS:` → `✓`, `FAIL:` → `✗`). `RESULT:` and `Error:` text prefixes
   kept as-is (already consistent). This completes the Polish roadmap phase.

2. **Community & Onboarding section in README** — New section for first-time contributors to
   forked rig-seed projects. Four subsections: understanding the project (read state files,
   run health-check), steering the agent (file issues with `agent-input` label), contributing
   directly (validate + check commands, safety rules), and setting up your own fork (links
   to Quick Start and Day Zero tutorial).

3. **Developer Experience roadmap phase** — New phase with five items: `--json` output for
   check.sh, shellcheck in CI examples, Linear/Jira integration example, `--watch` mode for
   health-check.sh, plus the community onboarding section (already done). Gives future
   sessions clear, concrete work to pick from.

**Next Steps**: See NEXT_STEPS.md.

---

## Day 7 — Session 22 (2026-03-23)

**Goal**: Complete three Priority items from NEXT_STEPS.md — all Polish phase script and docs improvements.

**Work Selection**: All three NEXT_STEPS.md Priority items were concrete and independent. No community
issues (only #8 and #9 remain, both Gas Town internals). Roadmap Polish phase has four unchecked items;
this session addresses three of them.

Three deliverables:

1. **`--quiet` flag for check.sh** — Added `-q`/`--quiet` flag that suppresses passing checks, info
   lines, and section headers. In quiet mode, only failures and the RESULT line are printed, making
   the script CI-friendly. Follows the same pattern established by validate.sh and health-check.sh.
   Updated the help text and argument parsing to handle both `-q` and a directory argument.

2. **Error prefix standardization** — Audited all scripts and found two conventions: `FAIL:` for
   check/validation failures (validate.sh, health-check.sh) and `Error:` for runtime/operational
   errors (rollback.sh, migrate.sh, dashboard.sh). The only outlier was sync-upstream.sh using
   `ERROR:` — normalized to `Error:` to match the other operational scripts (3 occurrences).

3. **Architecture diagram links** — Added links to docs/ARCHITECTURE.md from docs/DAY-ZERO.md
   (in the Prerequisites section) and docs/FORKING.md (before the step-by-step guide), so new
   users can see the visual overview of state files, scripts, and the evolution cycle.

Also: Updated scripts/migrate.sh with Session 22 check.sh `--quiet` detection.

**Next Steps**: See NEXT_STEPS.md.

---

## Day 6 — Session 21 (2026-03-22)

**Goal**: Polish phase — architecture diagram, Bootstrap cleanup, script consistency improvements.

**Work Selection**: All three NEXT_STEPS.md Priority items were concrete and independent, so
this session addresses all of them. No community issues since Session 20 (only #8 and #9
remain, both Gas Town internals). Self-assessment via script audit revealed --help flag gaps
in check.sh and release.sh — included as quick wins.

Three deliverables:

1. **Architecture diagram** (docs/ARCHITECTURE.md) — ASCII diagrams showing the evolution
   cycle flow (Steps 1-9), annotated file tree with purpose descriptions for every state
   file, script, and doc, data flow diagram between state files and the evolution agent,
   and a guard rails summary table. Linked from README documentation section.

2. **Bootstrap N/A cleanup** — The three Bootstrap items that never applied to the template
   repo ("Choose language", "Set up project structure", "Write initial tests") were marked
   as resolved with explanations instead of left as dangling unchecked items.

3. **Polish roadmap phase** — New roadmap phase based on a script consistency audit. Found:
   3 scripts missing --help, 8 scripts missing --quiet, inconsistent error prefixes across
   scripts. Added --help to scripts/check.sh and scripts/release.sh as quick wins. Remaining
   items tracked in the roadmap for future sessions.

Also: Updated scripts/migrate.sh with Session 21 architecture detection.

**Next Steps**: See NEXT_STEPS.md. Key items: add --quiet to check.sh, standardize error
prefixes across scripts, link architecture docs from DAY-ZERO.md and FORKING.md.

---

## Day 6 — Session 20 (2026-03-22)

**Goal**: Close stale GitHub issues and complete the Planning roadmap phase (planning voice, `--plan` flag).

**Work Selection**: NEXT_STEPS.md had three priorities: Step 3.5 docs (already done in Session 19),
bead creation docs (also done), and closing stale issues. Combined issue cleanup with the two
remaining unchecked Planning roadmap items.

Three deliverables:

1. **Stale issue cleanup** — Closed 8 GitHub issues (#4, #7, #10, #11, #12, #13, #17, #18) that
   were all addressed in prior sessions but never closed. Each got a closing comment referencing
   the session that fixed it. Only #8 and #9 remain open (Gas Town internals, not this repo).

2. **Planning voice examples** (PERSONALITY.md) — New "Planning Voice" section with guidance on
   writing NEXT_STEPS.md and Work Selection sections: be decisive, give reasons, be concrete,
   separate must-do from nice-to-have. Good/bad examples included.

3. **`--plan` flag for metrics.sh** — New `-p`/`--plan` flag that outputs planning-relevant info:
   unchecked roadmap items grouped by phase, NEXT_STEPS.md items by category, and open GitHub
   issue count. Works with `-q` for machine-readable output. Also fixed a SIGPIPE crash in the
   `git log | head -1` pipe pattern that `pipefail` was catching.

Also: Updated ROADMAP with completed items, updated NEXT_STEPS.md for next session.

**Next Steps**: See NEXT_STEPS.md. Key items: add a Polish roadmap phase, add architecture
diagram, clean up N/A Bootstrap items.

---

## Day 6 — Session 19 (2026-03-22)

**Goal**: Investigate how planning works in rig-seed and implement structured planning improvements (Issue #18).

**Work Selection**: Issue #18 is the only new community issue since Session 18. The previous
session's next steps suggested considering a new roadmap phase or responding to community issues.
Issue #18 is a research/report task about planning itself — addressing it also creates the
opportunity to implement the improvements it investigates, which is a natural fit.

Three deliverables making evolution planning visible and structured:

1. **Planning investigation document** (docs/PLANNING.md) — Analyzed how work selection
   currently happens across 18 sessions. Found that specific, roadmap-aligned next steps
   get followed while vague suggestions don't. Identified four gaps: prose-only next steps,
   no explicit planning step, invisible work selection reasoning, and underused beads for
   planning. Proposed four concrete improvements with an implementation path.

2. **NEXT_STEPS.md structured planning handoff** — New state file that replaces the journal's
   prose "Next Steps" with a structured format: Priority (do first), Suggested (consider),
   and Deferred (park for later). Overwritten each session. Read at the start of the next.
   Updated validate.sh to check for it, quickstart.sh to initialize it, and migrate.sh to
   detect it in forks.

3. **Evolution formula updates** (docs/EVOLUTION.md) — Added Step 3.5 (Plan Session) between
   Fetch Community Input and Select Work: read NEXT_STEPS.md, reconcile with open beads/issues/
   roadmap, document reasoning. Added NEXT_STEPS.md to Step 4 priority hierarchy (slot 3, after
   bugs and community issues). Added "Work Selection" as a mandatory journal section. Made bead
   creation before implementation mandatory in Step 4 documentation.

Also:
- Added Planning roadmap phase with completed and future items
- Updated README template files table with NEXT_STEPS.md and documentation links section
- Added learning: specific next steps get followed, vague ones don't
- Updated migration script with Session 19 feature detection

**Next Steps**: See NEXT_STEPS.md for structured planning. Key items: close stale GitHub
issues addressed in prior sessions, add planning voice examples to PERSONALITY.md, consider
a `--plan` flag for metrics.sh.

---

## Day 5 — Session 18 (2026-03-21)

**Goal**: Complete the Resilience roadmap phase — CI workflow lint, rollback script, and pre-submit CI trigger.

Three deliverables completing the Resilience milestone:

1. **CI workflow lint script** (scripts/lint-workflows.sh) — Validates GitHub Actions workflow
   files beyond basic YAML syntax. Checks for deprecated action versions (checkout@v1-v3,
   setup-*@v1-v2), missing required top-level keys (name, on, jobs), security anti-patterns
   (pull_request_target without explicit permissions, hardcoded secrets), and best-practice
   warnings (continue-on-error hiding failures). Supports `--quiet` for CI and `--help`.
   Exits 0 if all checks pass, 1 if errors found.

2. **Rollback script** (scripts/rollback.sh) — Safely reverts the most recent merge when the
   build is broken. Uses `git revert` to create a new commit (non-destructive, preserves
   history). Handles both merge commits (`-m 1`) and regular commits. Verifies working tree
   is clean before starting. Automatically runs the build check script after reverting to
   confirm the fix. Supports `--dry-run` to preview without acting and `--commit=SHA` to
   target a specific commit. On conflict, provides resolution commands.

3. **Pre-submit CI workflow** (docs/examples/workflows/pre-submit-ci.yml) — Example GitHub
   Actions workflow that runs the full build/test suite on branches BEFORE merge to main.
   Triggers on push to non-main branches and PRs targeting main. Includes a `ci-gate` job
   that can be required in branch protection rules. Uses `concurrency` with
   `cancel-in-progress` to save CI minutes on rapid pushes.

Also:
- Updated docs/examples/workflows/README.md with pre-submit-ci.yml entry
- Updated README.md with Workflow Lint and Rollback sections
- Updated scripts/migrate.sh with Session 18 feature detection
- Checked off all three Resilience roadmap items — milestone complete

**Next Steps**: The Resilience phase is now complete. Consider a new roadmap phase
(Community? Polish? Observability?) or stabilize and respond to community issues.
Issues #8 and #9 relate to Gas Town internals (refinery merge behavior), not this
template repo — they should be addressed in the gastown rig.

---

## Day 5 — Session 17 (2026-03-21)

**Goal**: Address CRITICAL Issue #17 (multi-build-system validation) and Issue #4 (upstream template sync).

Two deliverables targeting build reliability and template maintenance:

1. **Multi-build-system check script** (scripts/check.sh) — Canonical build gate that
   auto-detects all build systems in a project and runs every check. Detects Go (go.mod),
   Node.js (package.json, including subdirectories like frontend/), Rust (Cargo.toml),
   Python (pyproject.toml), and Makefile targets. Also runs any commands configured in
   the `[build]` section of config.toml. Parses TOML for explicit commands, then scans
   for build system markers. Checks GitHub Actions YAML syntax when workflows are present.
   Reports passed/failed/skipped counts. Addresses the root cause of Issue #17: polecats
   only running the primary language's build, missing failures in secondary build systems
   (e.g., TypeScript frontend in a Go project).

2. **Upstream template sync script** (scripts/sync-upstream.sh) — Fetches the latest
   rig-seed template and merges infrastructure files while preserving project-specific
   state. Adds/updates a `rig-seed-upstream` remote, fetches main, and attempts merge.
   Reports changes available upstream in dry-run mode. On conflicts, suggests resolution
   commands (keep yours for state files, take upstream for scripts). Reads upstream URL
   from the new `[template]` config section. Addresses Issue #4 (upstream sync for
   consumer projects).

Also:
- Updated docs/EVOLUTION.md Step 7 with multi-build-system validation docs
- Added `[build]` section to config.toml with check_script and commands
- Added `[template]` section to config.toml with upstream URL and sync mode
- Updated docs/UPGRADING.md with sync-upstream.sh as Method 0 (recommended)
- Updated README with Build Check and Upstream Sync sections
- Updated scripts/migrate.sh to detect Session 17 features
- Added Resilience roadmap phase with completed and future items

**Next Steps**: CI workflow lint for modified workflows, rollback script for broken merges,
pre-submit CI trigger (run CI on branch before merge).

---

## Day 4 — Session 16 (2026-03-20)

**Goal**: Add Prometheus/Grafana monitoring integration example (last Ecosystem roadmap item).

Built a complete monitoring stack example in `docs/examples/monitoring/`:

1. **Prometheus metrics exporter** (metrics-exporter.sh) — A lightweight bash HTTP
   server that wraps `metrics.sh -q` and serves Prometheus text format on `:9142/metrics`.
   Uses netcat for zero-dependency HTTP serving. Converts all numeric key=value pairs
   to `rigseed_*` gauge metrics with a `project` label derived from the directory name.
   Skips non-numeric values (dates, "n/a") gracefully.

2. **Prometheus scrape config** (prometheus.yml) — Example configuration with a 5-minute
   scrape interval (appropriate for evolution metrics that change infrequently). Includes
   commented-out multi-project setup.

3. **Grafana dashboard** (grafana-dashboard.json) — Pre-built dashboard with 10 panels:
   stat panels for session count, day count, roadmap %, commits, learnings, and velocity;
   time-series panels for sessions, roadmap progress (stacked), codebase size, and commits
   over time. Includes a `project` template variable for multi-project filtering.

4. **Setup guide** (README.md) — Architecture overview, quick start (exporter → Prometheus
   → Grafana), multi-project monitoring, Docker Compose example, and full metrics reference
   table.

Also: Updated migration script with Session 16 monitoring check, added Monitoring link to
README documentation section.

Ecosystem milestone is now fully complete — all items checked off.

**Next Steps**: Consider a new roadmap phase (Community? Polish?) or let the project
stabilize and respond to community issues.

---

## Day 4 — Session 15 (2026-03-20)

**Goal**: Multi-project dashboard, merge strategy guide, quickstart spawn journal entry (Issues #12, #13, roadmap).

Three deliverables:

1. **Multi-project dashboard** (scripts/dashboard.sh) — Aggregates evolution metrics
   across multiple rig-seed forks. Outputs a comparison table with day count, sessions,
   commits, roadmap progress, learnings, and velocity per project. Supports `--json`
   for dashboard/API integrations and `-q` for machine-readable key=value output.
   Validates each directory is a rig-seed project before gathering metrics.

2. **Merge strategy guide** (docs/MERGE-STRATEGY.md) — Documents three merge strategies
   for rig-spawn users: Refinery (auto-merge, default), PR-based (human review), and
   Hybrid (auto for small changes, PR for large). Includes config.toml examples,
   CLAUDE.md guidance for PR repos, and a comparison table. Also added `[merge]`
   section to .evolve/config.toml with all strategy options.

3. **Quickstart Day 1 journal entry** — Updated quickstart.sh to write a Day 1 spawn
   journal entry when initializing a new fork, so the first agent session has context.
   Counters now start at 1 (not 0) since the quickstart itself is the first session.

Also: Updated migration script with dashboard and merge strategy checks, added
Merge Strategy Guide and Dashboard sections to README.

**Next Steps**: Grafana/Prometheus integration example for long-running monitoring.

---

## Day 4 — Session 14 (2026-03-20)

**Goal**: Implement dual Day/Session tracking with mandatory Goal and Next Steps in journal format.

Added DAY_COUNT (calendar day counter) and DAY_DATE (last session date) files alongside
SESSION_COUNT. Updated journal format to `## Day N — Session M (YYYY-MM-DD)` with
mandatory **Goal** and **Next Steps** sections. Updated PERSONALITY.md with format docs
and examples, docs/EVOLUTION.md with counter semantics, validate.sh with DAY_COUNT/DAY_DATE
checks, quickstart.sh to reset all three counters, metrics.sh to report day count separately,
health-check.sh to parse all header formats, migrate.sh to detect new files, and
integration tests for the new counters.

**Next Steps**: Multi-project dashboard, Grafana/Prometheus integration example.

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

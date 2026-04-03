# Roadmap

Living document. Updated each evolution session. Items come from three sources:
- SPECS.md (the project's requirements)
- GitHub issues from the community
- Self-assessment during evolution sessions

## Bootstrap (Day 0-3)

- [x] Read and document project specs (SPECS.md)
- [x] Add LICENSE file (MIT)
- [x] Add CONTRIBUTING.md explaining the evolution process
- [x] Improve README with clearer getting-started instructions
- [x] Improve .claude/CLAUDE.md with evolution day flow
- [x] ~Choose language and tech stack~ — N/A: template repo has no runtime code
- [x] ~Set up project structure~ — N/A: structure IS the state files and scripts
- [x] ~Write initial tests~ — N/A for template; integration test covers the template itself (Session 7)

## Foundation (Day 4-10)

- [x] Add example CI workflows (in docs/examples/workflows/, since .github/workflows/ is immutable)
- [x] Add a template validation script (validate.sh)
- [x] Document the mol-evolve formula steps in detail (docs/EVOLUTION.md)
- [x] Add example SPECS.md variants for common project types (CLI tool, web API, library)
- [x] Add troubleshooting guide for common evolution failures (docs/TROUBLESHOOTING.md)
- [x] Add fork quickstart script (quickstart.sh)

## Growth (Day 4+)

- [x] Add fork guide with customization guidance (docs/FORKING.md)
- [x] Add example .evolve/config.toml variants for different evolution strategies
- [x] Add a CHANGELOG.md template for forked projects
- [x] Improve PERSONALITY.md with more voice examples
- [x] Add health-check script for running forks (is the agent evolving? are builds passing?)
- [x] Add example ROADMAP.md variants for different project types

## Maturity (Day 6+)

- [x] Add example PERSONALITY.md variants (formal, casual, minimal)
- [x] Add a "day zero" walkthrough tutorial for first-time users
- [x] Add pre-commit hook example that runs validate.sh
- [x] Integration test: fork → quickstart → validate → health-check round-trip
- [x] Document how to customize the evolution formula for project-specific steps
- [x] Fix health-check.sh to recognize both "## Day" and "## Session" journal headers

## Sustainability (Day 8+)

- [x] Add `--help` and `--quiet` flags to validate.sh and health-check.sh
- [x] Add missing Formula Customization link to README documentation section
- [x] Build `/rig-spawn` slash command for one-click project setup (Issue #10)
- [x] Rename `/rig-seed` slash command to `/rig-spawn` (Issue #11)
- [x] Add upgrade guide for existing forks when rig-seed adds new files/features
- [x] Add example post-session hook that posts journal diffs to Slack/Discord
- [x] Add metrics script that summarizes evolution history (sessions, improvements, velocity)

## Ecosystem (Day 11+)

- [x] Add release tagging script with semver auto-increment (Issue #6)
- [x] Add configurable release strategy to .evolve/config.toml (Issue #3)
- [x] Document auto-closing GitHub issues in evolution workflow (Issue #2)
- [x] Add example GitHub Actions workflow that runs metrics.sh and posts results to PR comments
- [x] Add migration script that detects rig-seed version and applies incremental upgrades
- [x] Rename DAY_COUNT to SESSION_COUNT, adopt session numbering everywhere (Issues #1, #5, #14, #15, #16)
- [x] Add dual Day/Session tracking with DAY_COUNT, DAY_DATE, mandatory Goal and Next Steps (Issues #1, #5, #14, #15, #16)
- [x] Add multi-project dashboard that aggregates metrics across multiple forks
- [x] Add merge strategy guide for rig-spawn users (refinery vs PR-based vs hybrid) (Issue #13)
- [x] Update quickstart.sh to write Day 1 spawn journal entry (Issue #12)
- [x] Add example Grafana/Prometheus integration for long-running evolution monitoring

## Resilience (Day 5+)

- [x] Add multi-build-system check script with auto-detection (Issue #17, #7)
- [x] Add upstream template sync script for consumer projects (Issue #4)
- [x] Add `[build]` config section with check_script and multi-command support
- [x] Add `[template]` config section for upstream sync settings
- [x] Update EVOLUTION.md Step 7 with multi-build-system validation guidance
- [x] Add CI workflow lint for modified `.github/workflows/` files
- [x] Add rollback script for reverting broken merges automatically
- [x] Add pre-submit CI trigger (run CI on branch before merge, not after)

## Planning (Day 6+)

- [x] Investigate how planning works in rig-seed and write docs/PLANNING.md (Issue #18)
- [x] Create NEXT_STEPS.md structured planning handoff file
- [x] Add Step 3.5 (Plan Session) to docs/EVOLUTION.md formula documentation
- [x] Add "Work Selection" section to journal entry format in EVOLUTION.md
- [x] Update README with NEXT_STEPS.md in template files table and planning doc link
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update)
- [x] Add planning voice examples to PERSONALITY.md
- [x] Add `--plan` flag to metrics.sh for planning-relevant output
- [x] Close stale GitHub issues addressed in prior sessions

## Polish (Day 6+)

- [x] Add architecture diagram documenting state files, scripts, and evolution flow
- [x] Clean up N/A Bootstrap roadmap items
- [x] Add `--help` flag to scripts/check.sh and scripts/release.sh
- [x] Add `-q`/`--quiet` flag to scripts/check.sh for CI-friendly output
- [x] Standardize error message prefixes across all scripts (Error: for operational, FAIL: for checks)
- [x] Add architecture diagram link to docs/DAY-ZERO.md and docs/FORKING.md
- [x] Normalize emoji vs text-only output markers across all scripts

## Developer Experience (Day 8+)

- [x] Add Community & Onboarding section to README for first-time fork contributors
- [x] Add `--json` output mode to check.sh (like dashboard.sh has)
- [x] Add shellcheck linting to CI workflow examples
- [x] Add example integration with Linear/Jira for beads-based project tracking
- [x] Add a `--watch` mode to health-check.sh for continuous monitoring

## Script Quality (Day 8+)

- [x] Add script output conventions doc (docs/SCRIPT-CONVENTIONS.md)
- [x] Add `--color`/`--no-color` flags to validate.sh and health-check.sh
- [x] Add `--color`/`--no-color` flags to remaining scripts (check.sh, dashboard.sh, lint-workflows.sh, rollback.sh)
- [x] Add a "session recap" script that summarizes the latest journal entry (scripts/recap.sh)
- [x] Add `--format=table|csv|json|kv` to metrics.sh for flexible output

## Automation (Day 9+)

- [x] Add post-session hook example that runs integration sync scripts automatically
- [x] Add validation for .beads-external-map.json in validate.sh (warn if malformed)
- [x] Add `--color`/`--no-color` to metrics.sh (last script without color support)
- [x] Add a `--diff` mode to recap.sh that shows the git diff from the latest session
- [x] Add shellcheck annotations or `# shellcheck disable=` directives to any flagged patterns
- [x] Add a pre-session hook example that runs health-check.sh before starting work
- [x] Add a `--lint` mode to validate.sh that checks script conventions compliance
- [x] Add a `--watch` mode to metrics.sh for continuous monitoring (like health-check.sh --watch)
- [x] Add example CI workflow that runs post-session-sync hook on merge

## Community Issues (Day 11+)

- [x] Bundle mol-evolve.formula.toml in the template (Issue #22)
- [x] Include time and timezone in JOURNAL.md session entries (Issue #20)
- [x] Add pre-submit validation for required state file updates (Issue #21)
- [x] Add acceptance evaluation step before closing issues (Issue #19)
- [x] Add example CI workflow that runs check-evolve-state.sh as a pre-merge gate
- [x] Add `--summary` mode to dashboard.sh for one-line-per-project output
- [x] Add `--help` and `--color`/`--no-color` flags to quickstart.sh
- [x] Add RESULT line to migrate.sh

## Usability (Day 13+)

- [x] Add `--color`/`--no-color` to sync-upstream.sh and release.sh (Day 13)
- [x] Add `--since N` flag to recap.sh for multi-session recaps (Day 13)
- [x] Add `--summary`/`-s` flag to metrics.sh for one-line output (Day 13)
- [x] Add `--check` mode to quickstart.sh for dry-run validation (Day 13)
- [x] Add `--projects DIR` flag to dashboard.sh for auto-discovery (Day 13)
- [x] Add `--since N` flag to metrics.sh --plan for recent session goals (Day 13)
- [x] Add `--top N` flag to recap.sh for limiting displayed entries (Day 13)
- [x] Add `--depth N` flag to dashboard.sh --projects for search depth control (Day 13)
- [x] Add integration tests for --check, --top, --projects, --depth flags (Day 13)
- [x] Fix integration test assertions for quickstart Day 1 behavior (Day 13)

## Monitoring (Day 14+)

- [x] Add turnkey Grafana setup script (scripts/grafana.sh) with start/stop/status/logs (Day 14)
- [x] Add working docker-compose.yml for Prometheus + Grafana (Day 14)
- [x] Add Grafana auto-provisioning (datasource + dashboard, no manual import) (Day 14)
- [x] Update monitoring README with clear quick-start docs (Day 14)
- [x] Add `--plan --since` support to metrics.sh JSON and CSV output formats (Day 15)
- [x] Add shellcheck integration to validate.sh --lint (Day 15)
- [x] Add migrate.sh detection for Session 32-34 and Day 14 features (Day 15)
- [x] Add `--format=table|csv|json|kv` to recap.sh (Day 16)
- [x] Add `--color`/`--no-color` flags to migrate.sh (Day 16)
- [x] Add integration tests for migrate.sh --dry-run and feature detection (Day 16)
- [x] Add integration tests for metrics.sh --plan --since in JSON/CSV formats (Day 17)
- [x] Add `--fix` mode to validate.sh --lint for auto-applying shellcheck suggestions (Day 17)
- [x] Add migrate.sh detection for Day 15-16 features (Day 17)
- [x] Add `--format=table|csv|json|kv` to dashboard.sh (Day 17)
- [x] Add integration tests for recap.sh --format csv/kv, dashboard.sh --format, validate.sh --lint --fix (Day 17)
- [x] Fix Issue #23: persist evolve plugin dispatch timestamp to disk (Day 17)
- [x] Add `--format=table|csv|json|kv` flag to health-check.sh (Day 17)
- [x] Add migrate.sh detection for Day 17 features (dashboard --format, health-check --format, dispatch persistence) (Day 17)
- [x] Add integration tests for health-check.sh --format and migrate.sh Day 17 detection (Day 17)
- [x] Add shellcheck CI gate to integration tests (Day 17)
- [x] Add `--format=table|csv|json|kv` flag to check.sh (Day 17)
- [x] Add `--format=table|csv|json|kv` flag to sync-upstream.sh and rollback.sh (Day 17)
- [x] Fix metrics.sh `grep -c || echo 0` double-output bug (Day 17)

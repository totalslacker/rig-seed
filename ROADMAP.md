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
- [ ] Choose language and tech stack based on specs (N/A — template repo)
- [ ] Set up project structure (N/A — template repo, structure is the state files)
- [ ] Write initial tests (N/A until forked projects add code)

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
- [ ] Add example GitHub Actions workflow that runs metrics.sh and posts results to PR comments
- [ ] Add migration script that detects rig-seed version and applies incremental upgrades
- [ ] Add multi-project dashboard that aggregates metrics across multiple forks
- [ ] Add example Grafana/Prometheus integration for long-running evolution monitoring

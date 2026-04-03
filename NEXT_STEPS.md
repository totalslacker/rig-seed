# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add `--format` to metrics.sh `--summary` mode for structured one-line output
- [ ] Add `--lint --format` integration tests (validate.sh --lint with --format=json/csv/kv)
- [ ] Add end-to-end integration test for release.sh (create real tag in temp repo, verify semver increment)

## Suggested (consider these)

- [ ] Add CHANGELOG entry for release.sh and check-evolve-state.sh --format flags
- [ ] Add `--verbose` to other --check scripts (health-check.sh, validate.sh)
- [ ] Add sync-upstream.sh conflict resolution test (divergent state file changes)
- [ ] Add migrate.sh detection for quickstart.sh --verbose flag

## Deferred (not now, but don't forget)

- [x] Add end-to-end test for sync-upstream.sh (done Day 18 Session 47)
- [x] Add check-evolve-state.sh edge case tests (done Day 18 Session 47)
- [x] Add --verbose flag for quickstart.sh --check (done Day 18 Session 47)
- [x] Consolidate json_escape function into a shared shell library (done Day 17 Session 44 — scripts/lib.sh)
- [x] Add `--format` to validate.sh (done Day 17 Session 45)
- [x] Add `--format`/`--once` to metrics-exporter.sh (done Day 17 Session 45)
- [x] Add grafana.sh --format integration test (done Day 17 Session 45)
- [x] Add `--format` to release.sh and check-evolve-state.sh (done Day 17 Session 46)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

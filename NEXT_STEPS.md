# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add `--lint --format` integration tests for validate.sh --fix mode (--lint --fix --format=json/csv/kv)
- [ ] Add CHANGELOG entry for metrics.sh --summary --format and release.sh e2e test
- [ ] Add `--verbose` to other --check scripts (health-check.sh, validate.sh)

## Suggested (consider these)

- [ ] Add sync-upstream.sh conflict resolution test (divergent state file changes)
- [ ] Add metrics.sh --summary --format=json schema validation test
- [ ] Add release.sh JSON format test for actual (non-dry-run) release

## Deferred (not now, but don't forget)

- [x] Add `--format` to metrics.sh `--summary` mode (done Day 19 Session 48)
- [x] Add validate.sh `--lint --format` integration tests (done Day 19 Session 48)
- [x] Add end-to-end integration test for release.sh (done Day 19 Session 48)
- [x] Add migrate.sh detection for quickstart.sh --verbose flag (done Day 19 Session 48)
- [x] Add end-to-end test for sync-upstream.sh (done Day 18 Session 47)
- [x] Add check-evolve-state.sh edge case tests (done Day 18 Session 47)
- [x] Add --verbose flag for quickstart.sh --check (done Day 18 Session 47)
- [x] Consolidate json_escape function into a shared shell library (done Day 17 Session 44 — scripts/lib.sh)
- [x] Add `--format` to validate.sh (done Day 17 Session 45)
- [x] Add `--format`/`--once` to metrics-exporter.sh (done Day 17 Session 45)
- [x] Add grafana.sh --format integration test (done Day 17 Session 45)
- [x] Add `--format` to release.sh and check-evolve-state.sh (done Day 17 Session 46)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

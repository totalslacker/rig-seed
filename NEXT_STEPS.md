# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add sync-upstream.sh conflict resolution test for KV format with file list
- [ ] Add metrics.sh --plan --since --format=csv schema validation test
- [ ] Add dashboard.sh --projects --format=csv/kv integration tests

## Suggested (consider these)

- [ ] Add health-check.sh --watch --format=json test (watch mode with structured output)
- [ ] Add check-evolve-state.sh partial update tests for CSV/KV format
- [ ] Add validate.sh --lint --format=csv with real shellcheck issues test

## Deferred (not now, but don't forget)

- [x] Add sync-upstream.sh conflict resolution test for CSV format (done Day 19 Session 51)
- [x] Add migrate.sh integration test for validate.sh --verbose detection (done Day 19 Session 51)
- [x] Add health-check.sh --verbose --format=csv/kv integration tests (done Day 19 Session 51)
- [x] Add validate.sh --verbose --format=csv/kv integration tests (done Day 19 Session 51)
- [x] Add release.sh JSON format test for actual (non-dry-run) release (done Day 19 Session 51)
- [x] Add metrics.sh --plan --since --format=json schema validation test (done Day 19 Session 51)
- [x] Add `--verbose` flag to validate.sh for detailed check output (done Day 19 Session 50)
- [x] Add sync-upstream.sh conflict resolution test (done Day 19 Session 50)
- [x] Add metrics.sh --summary --format=json schema validation test (done Day 19 Session 50)
- [x] Add `--verbose` to health-check.sh (done Day 19 Session 49)
- [x] Add validate.sh `--lint --fix --format` integration tests (done Day 19 Session 49)
- [x] Add CHANGELOG entries for recent features (done Day 19 Session 49)
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

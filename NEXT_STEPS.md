# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add end-to-end test for sync-upstream.sh (mocking upstream remote)
- [ ] Add a `--verbose` flag to quickstart.sh --check for detailed state file analysis
- [ ] Add integration test coverage for check-evolve-state.sh edge cases (no-changes branch, partial updates)

## Suggested (consider these)

- [ ] Add `--format` to metrics.sh `--summary` mode for structured one-line output
- [ ] Add `--lint --format` integration tests (validate.sh --lint with --format=json/csv/kv)
- [ ] Add end-to-end integration test for release.sh (create real tag in temp repo, verify semver increment)
- [ ] Add CHANGELOG entry for release.sh and check-evolve-state.sh --format flags

## Deferred (not now, but don't forget)

- [x] Consolidate json_escape function into a shared shell library (done Day 17 Session 44 — scripts/lib.sh)
- [x] Add `--format` to validate.sh (done Day 17 Session 45)
- [x] Add `--format`/`--once` to metrics-exporter.sh (done Day 17 Session 45)
- [x] Add grafana.sh --format integration test (done Day 17 Session 45)
- [x] Add `--format` to release.sh and check-evolve-state.sh (done Day 17 Session 46)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

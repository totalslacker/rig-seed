# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--format` flag to scripts/release.sh and scripts/check-evolve-state.sh
- [ ] Add end-to-end test for sync-upstream.sh (mocking upstream remote)
- [ ] Add a --verbose flag to quickstart.sh --check for detailed state file analysis

## Suggested (consider these)

- [ ] Add `--format` flag to docs/examples/hooks scripts for structured output
- [ ] Add integration test for metrics-exporter.sh Prometheus server mode (using nc mock)
- [ ] Add a --watch mode to validate.sh for continuous monitoring (like health-check.sh)

## Deferred (not now, but don't forget)

- [x] Consolidate json_escape function into a shared shell library (done Day 17 Session 44 — scripts/lib.sh)
- [x] Add `--format` flag to validate.sh (done Day 17 Session 45)
- [x] Add `--format` support to metrics-exporter.sh (done Day 17 Session 45)
- [x] Add integration test for grafana.sh --format with mocked docker (done Day 17 Session 45)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

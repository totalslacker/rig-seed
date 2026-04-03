# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--format` flag to scripts/release.sh and scripts/check-evolve-state.sh
- [ ] Add end-to-end test for sync-upstream.sh (mocking upstream remote)
- [ ] Add a `--verbose` flag to quickstart.sh --check for detailed state file analysis

## Suggested (consider these)

- [ ] Add `--format` to metrics.sh `--summary` mode for structured one-line output
- [ ] Add `--lint --format` integration tests (validate.sh --lint with --format=json/csv/kv)
- [ ] Add `--once --format` to grafana.sh for one-shot status dump without docker

## Deferred (not now, but don't forget)

- [x] Consolidate json_escape function into a shared shell library (done Day 17 Session 44 — scripts/lib.sh)
- [x] Add `--format` to validate.sh (done Day 17 Session 45)
- [x] Add `--format`/`--once` to metrics-exporter.sh (done Day 17 Session 45)
- [x] Add grafana.sh --format integration test (done Day 17 Session 45)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

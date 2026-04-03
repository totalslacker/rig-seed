# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--format` flag to validate.sh for structured output (last major script without it)
- [ ] Add `--format` support to metrics-exporter.sh for structured Prometheus output
- [ ] Add integration test for grafana.sh --format (mocking docker status)

## Suggested (consider these)

- [ ] Add `--format` flag to scripts/release.sh and scripts/check-evolve-state.sh
- [ ] Add end-to-end test for sync-upstream.sh (mocking upstream remote)
- [ ] Add a --verbose flag to quickstart.sh --check for detailed state file analysis

## Deferred (not now, but don't forget)

- [ ] Consolidate json_escape function into a shared shell library (reduces duplication but adds source dependency — may hurt portability for forks)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

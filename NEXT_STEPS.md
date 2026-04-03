# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add end-to-end test for check.sh with a real build system (Go or Python project)
- [ ] Add `--format` flag to quickstart.sh for structured output
- [ ] Add a CHANGELOG entry for the --format standardization across all scripts

## Suggested (consider these)

- [ ] Add `--format` support to metrics-exporter.sh for structured Prometheus output
- [ ] Add integration test for grafana.sh --format (mocking docker status)
- [ ] Consolidate json_escape function into a shared shell library to reduce duplication

## Deferred (not now, but don't forget)

- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

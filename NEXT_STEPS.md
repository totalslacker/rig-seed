# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--format` flag to sync-upstream.sh and rollback.sh for consistent output
- [ ] Add migrate.sh detection for check.sh --format in integration tests
- [ ] Close stale GitHub issues (#8, #9) with notes directing to gastown rig

## Suggested (consider these)

- [ ] Add `--format` flag to remaining scripts without it (grafana.sh, lint-workflows.sh)
- [ ] Add JSON schema validation for structured output in tests (validate JSON with python3)
- [ ] Add end-to-end test for check.sh with a real build system (Go or Python project)

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

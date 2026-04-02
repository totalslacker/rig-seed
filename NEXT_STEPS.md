# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add dashboard.sh --format integration tests with multi-project discovery (--projects + --format=csv)
- [ ] Add shellcheck CI gate to integration tests (run shellcheck on all scripts as a test step)
- [ ] Add `--format` flag to check.sh for standardized output across all scripts

## Suggested (consider these)

- [ ] Add migrate.sh detection for health-check.sh --format in integration tests
- [ ] Add `--format` flag to sync-upstream.sh and rollback.sh for consistent output
- [ ] Close stale GitHub issues (#8, #9) with notes directing to gastown rig

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

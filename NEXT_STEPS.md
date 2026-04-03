# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--format` flag to lint-workflows.sh and grafana.sh for complete script standardization
- [ ] Add migrate.sh detection for check.sh --format, rollback.sh --format, sync-upstream.sh --format
- [ ] Add integration tests for rollback.sh --format and sync-upstream.sh --format output

## Suggested (consider these)

- [ ] Close stale GitHub issues (#8, #9) with notes directing to gastown rig
- [ ] Add `--format` flag to release.sh for consistent output
- [ ] Audit all scripts for the `grep -c ... || echo "0"` double-output bug pattern

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

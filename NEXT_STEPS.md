# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a `--summary` mode to dashboard.sh that shows one-line-per-project output
- [ ] Add example CI workflow that runs shellcheck on all scripts as a gate
- [ ] Add a `--since` flag to recap.sh to show entries from the last N sessions

## Suggested (consider these)

- [ ] Add `--help` and `--color`/`--no-color` to quickstart.sh (found by validate.sh --lint)
- [ ] Add RESULT line to migrate.sh (found by validate.sh --lint)
- [ ] Add `--color`/`--no-color` to sync-upstream.sh and release.sh (found by validate.sh --lint)

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

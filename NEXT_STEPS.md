# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a `--lint` mode to validate.sh that checks script conventions compliance
- [ ] Add a `--watch` mode to metrics.sh for continuous monitoring (like health-check.sh --watch)
- [ ] Add example CI workflow that runs post-session-sync hook on merge

## Suggested (consider these)

- [ ] Add a `--summary` mode to dashboard.sh that shows one-line-per-project output
- [ ] Add example CI workflow that runs shellcheck on all scripts as a gate
- [ ] Add a `--since` flag to recap.sh to show entries from the last N sessions

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a `--diff` mode to recap.sh that shows the git diff from the latest session — quick session review
- [ ] Add shellcheck annotations or `# shellcheck disable=` directives to any flagged patterns — code quality
- [ ] Add a pre-session hook example that runs health-check.sh before starting work — extends the hooks ecosystem

## Suggested (consider these)

- [ ] Add a `--lint` mode to validate.sh that checks script conventions compliance
- [ ] Add a `--watch` mode to metrics.sh for continuous monitoring (like health-check.sh --watch)
- [ ] Add example CI workflow that runs post-session-sync hook on merge

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

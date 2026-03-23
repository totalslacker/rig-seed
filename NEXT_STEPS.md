# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--json` output mode to check.sh (like dashboard.sh has) — Developer Experience phase
- [ ] Add shellcheck linting to the CI workflow examples — catches common script bugs
- [ ] Add a `--watch` mode to health-check.sh for continuous monitoring

## Suggested (consider these)

- [ ] Add example integration with Linear/Jira for beads-based project tracking
- [ ] Add a script output conventions doc (emoji markers, RESULT: line, Error: prefix)
- [ ] Add `--color`/`--no-color` flags to scripts for terminal-aware output

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

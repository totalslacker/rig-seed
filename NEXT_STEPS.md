# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--color`/`--no-color` flags to remaining scripts (check.sh, dashboard.sh, lint-workflows.sh, rollback.sh) — Script Quality phase, pattern established in Session 25
- [ ] Add a "session recap" script that summarizes the latest journal entry — useful for quick status checks
- [ ] Add `--format=table|csv|json` to metrics.sh — replace the separate -q and --json modes with a unified format flag

## Suggested (consider these)

- [ ] Add a post-session hook example that runs the integration sync scripts automatically
- [ ] Add validation for .beads-external-map.json in validate.sh (warn if present but malformed)
- [ ] Consider a new roadmap phase (Automation? Observability?) for post-Script-Quality work

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

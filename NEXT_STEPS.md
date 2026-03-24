# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a post-session hook example that runs the integration sync scripts automatically — extends the hooks ecosystem
- [ ] Add validation for .beads-external-map.json in validate.sh (warn if present but malformed) — catches broken integration configs
- [ ] Consider a new roadmap phase (Automation? Observability?) for post-Script-Quality work — all current phases are complete

## Suggested (consider these)

- [ ] Add `--color`/`--no-color` to metrics.sh (currently the only script without color support)
- [ ] Add a `--diff` mode to recap.sh that shows the git diff from the latest session
- [ ] Add shellcheck annotations or `# shellcheck disable=` directives to any flagged patterns

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a `--format` flag to recap.sh (table/csv/json/kv) matching metrics.sh conventions
- [ ] Add `--no-color` flag to migrate.sh output
- [ ] Add integration test coverage for migrate.sh --dry-run and Session 32-34 feature detection

## Suggested (consider these)

- [ ] Add integration test for metrics.sh --plan --since in JSON and CSV formats
- [ ] Add `--fix` mode to validate.sh --lint that auto-applies shellcheck suggestions
- [ ] Add migrate.sh detection for Day 15 features (metrics.sh plan JSON/CSV, shellcheck lint)

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

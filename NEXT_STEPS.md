# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--since` support to metrics.sh --plan in JSON and CSV output formats
- [ ] Add shellcheck CI pass for all scripts as part of validate.sh --lint
- [ ] Add migrate.sh detection for Session 32-34 features (--since, --summary, --check, --top, --depth, --projects)

## Suggested (consider these)

- [ ] Add a `--format` flag to recap.sh (table/csv/json/kv) matching metrics.sh conventions
- [ ] Add `--no-color` flag to migrate.sh output
- [ ] Add integration test coverage for migrate.sh --dry-run

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

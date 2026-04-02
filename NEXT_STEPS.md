# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add integration test for metrics.sh --plan --since in JSON and CSV formats
- [ ] Add `--fix` mode to validate.sh --lint that auto-applies shellcheck suggestions
- [ ] Add migrate.sh detection for Day 15-16 features (metrics.sh plan JSON/CSV, shellcheck lint, recap.sh --format, migrate.sh --color)

## Suggested (consider these)

- [ ] Add `--format` flag to dashboard.sh (table/csv/json/kv) matching metrics.sh/recap.sh conventions
- [ ] Add recap.sh --format integration tests (csv, kv output modes)
- [ ] Add Issue #23 fix: persist evolve plugin dispatch timestamp to disk

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

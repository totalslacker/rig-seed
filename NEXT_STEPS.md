# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add a `--top N` flag to recap.sh --short for showing just the N most recent goals
- [ ] Add integration test coverage for new --check, --projects, and --since flags
- [ ] Add a `--dry-run` mode to migrate.sh that reports what would be applied without changing files

## Suggested (consider these)

- [ ] Add `--since` support to metrics.sh --plan in JSON and CSV output formats
- [ ] Add a `--depth N` flag to dashboard.sh --projects to control search depth
- [ ] Add shellcheck CI pass for all scripts as part of validate.sh --lint

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

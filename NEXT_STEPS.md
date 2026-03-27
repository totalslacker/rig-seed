# Next Steps

Updated at the end of each evolution session. Read at the start of the next.
Replaces the journal's prose "Next Steps" with structured, machine-readable
planning intent.

## Priority (do these first)

- [ ] Add `--color`/`--no-color` to sync-upstream.sh and release.sh (found by validate.sh --lint)
- [ ] Add a `--since` flag to recap.sh to show entries from the last N sessions
- [ ] Add a `--summary` flag to metrics.sh for quick one-line output (mirrors dashboard.sh --summary)

## Suggested (consider these)

- [ ] Add a `--check` mode to quickstart.sh that validates without resetting (dry-run validation)
- [ ] Add a `--projects` flag to dashboard.sh that auto-discovers rig-seed projects under a directory
- [ ] Add `set -euo pipefail` audit across all scripts (some may be missing pipefail)

## Deferred (not now, but don't forget)

- [ ] Issues #8, #9 are about Gas Town refinery internals — they belong in the gastown rig, not here
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

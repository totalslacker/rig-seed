# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

### Example specs work best as fill-in-the-blank templates

Pure example specs (fully filled out for a fake project) are less useful than
templates with `[PLACEHOLDER]` sections. Users don't want to read about a fake
project — they want to fill in their own details. The `[e.g., "..."]` pattern
gives enough context to understand each section while making it obvious what to
replace.

---

### Config examples need inline comments, not just a README

Users copy config files and tweak them locally. If the explanation is only in a
README, they lose context as soon as they paste the file. Each config variant
should have comments explaining *why* each value is set that way, not just what
it does. The README then covers strategy selection, not individual settings.

---

### Health checks should warn, not fail, on missing activity

A fork that hasn't committed in 5 days isn't necessarily broken — the human
might be on vacation or the schedule might be weekly. Use warnings for
activity-based checks (commit recency, journal freshness) and only fail on
structural problems (missing files, invalid DAY_COUNT). This keeps the script
useful for monitoring without crying wolf on intentionally slow cadences.

---

### Day-zero tutorials should be opinionated about order

New users don't know which files matter most. A "read all the docs" approach
leads to paralysis. The day-zero tutorial works best as a numbered sequence
with decision points: "Step 2: Write specs. Here's what to answer." Linking
to examples at each step (not up front) keeps people moving forward instead
of wandering through a docs tree.

---

### Pre-commit hooks should check immutable files against staging, not the working tree

Checking `git diff --cached --name-only` catches only what's about to be
committed. Checking the working tree would block commits even when the
immutable file change isn't staged, which is confusing. The staging area is
the right boundary for a pre-commit hook.

---

### Scripts that parse journal headers must handle format evolution

The journal header format changed from `## Day N` to `## Session N` in
Session 6. Any script that greps for journal entries (health-check.sh, future
analytics tools) must match both patterns: `^## \(Day\|Session\) `. When
introducing format changes to state files, audit all scripts that parse them.

---

### Shell scripts need `--quiet` for CI and `--help` for discoverability

Scripts used in CI pipelines (validate.sh, health-check.sh) should support a
quiet mode that only prints failures and the final result line. Verbose output
is useful interactively but creates noise in CI logs. A simple `info()` wrapper
that checks a `$quiet` flag is enough — no need for a logging framework. Also
add `--help` so users don't have to read the source to learn about env vars
and exit codes.

---

### Migration scripts should detect features, not versions

Rig-seed doesn't have a version number — features were added incrementally across
sessions. A migration script that checks "version >= X" would require maintaining
a version mapping. Instead, check for the presence of each feature (file exists?
config key present?) and add what's missing. This is idempotent, order-independent,
and works regardless of when the fork was created. It also handles partial forks
(where someone cherry-picked some features but not others).

---

### PR comment workflows should use marker comments

When a GitHub Actions workflow posts metrics as a PR comment, it should include a
hidden HTML marker (`<!-- rig-seed-metrics -->`) and search for it before creating
new comments. This prevents duplicate comments on every push — the workflow finds
and updates the existing comment instead. The `actions/github-script` action makes
this easy via the GitHub REST API.

---

### Immutable directories require indirect examples

`.github/workflows/` is in IMMUTABLE.txt, meaning evolution agents can't create
or modify CI files directly. To provide CI templates, put example workflow files
in `docs/examples/workflows/` with instructions to copy them. This keeps CI
human-controlled while still giving forked projects a running start.

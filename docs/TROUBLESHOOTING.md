# Troubleshooting

Common problems when running rig-seed evolution and how to fix them.

---

## Agent does nothing on first run

**Symptom:** The evolution agent starts, reads state files, then exits without
making changes.

**Cause:** `SPECS.md` is empty and the bead description doesn't contain specs
either. The agent has nothing to build.

**Fix:** Write your project specification in `SPECS.md` before starting
evolution. See [example specs](examples/specs/README.md) for templates.

---

## Agent modifies immutable files

**Symptom:** The agent edits `IDENTITY.md` or files in `.github/workflows/`.

**Cause:** The agent's instructions weren't loaded properly, or `.evolve/IMMUTABLE.txt`
is missing or malformed.

**Fix:**
1. Run `./validate.sh` to check that `.evolve/IMMUTABLE.txt` exists and is
   correctly formatted
2. Verify `.claude/CLAUDE.md` contains the safety rules section
3. Check that the agent reads IMMUTABLE.txt during its load-state step

---

## Build fails and agent keeps retrying

**Symptom:** The agent tries the same fix 3+ times, each time getting the same
build error.

**Cause:** The `max_fix_attempts` safety limit may not be working, or the agent
isn't reading the build output carefully.

**Fix:**
1. Check `.evolve/config.toml` — `max_fix_attempts` should be set (default: 3)
2. Ensure `revert_on_failure = true` so the agent reverts after exhausting attempts
3. Check the journal — if the agent journals the failure honestly, the next
   session can learn from it

---

## SESSION_COUNT doesn't increment

**Symptom:** Multiple evolution sessions run but SESSION_COUNT stays the same.

**Cause:** The agent's update-state step failed or was skipped, often because
an earlier step errored out.

**Fix:**
1. Check `JOURNAL.md` — if there's no entry for the session, the agent likely
   crashed before reaching update-state
2. Manually set SESSION_COUNT to the correct value
3. Check the agent's logs for errors during the session

---

## Journal entries are vague or repetitive

**Symptom:** Every journal entry says "Made improvements to the codebase" or
similar generic text.

**Cause:** `PERSONALITY.md` may not have strong enough voice guidance, or the
agent isn't reading it.

**Fix:**
1. Review `PERSONALITY.md` — the journal voice section should have specific
   examples of good and bad entries
2. Add more "bad example" entries showing what to avoid
3. Check `.claude/CLAUDE.md` to ensure it references PERSONALITY.md

---

## Validation script fails after fork

**Symptom:** `./validate.sh` reports missing files in a freshly forked repo.

**Cause:** Some files may have been added to `.gitignore` by mistake, or the
fork didn't include all branches.

**Fix:**
1. Run `./validate.sh` and address each `FAIL` line
2. Common missing files after fork: `LICENSE` (if you chose a different license),
   `CONTRIBUTING.md` (if you deleted it)
3. All files listed in the "Required State Files" section of validate.sh must
   exist — create empty ones if needed

---

## Agent creates too many changes per session

**Symptom:** Sessions produce massive diffs touching many files, making review
difficult.

**Cause:** `max_improvements_per_session` in config.toml may be set too high,
or the agent is interpreting one improvement as multiple file changes.

**Fix:**
1. Set `max_improvements_per_session = 1` in `.evolve/config.toml` for tighter
   focus
2. Add guidance in `.claude/CLAUDE.md` emphasizing small, atomic changes
3. Review the roadmap — if items are too broad, break them into smaller tasks

---

## Evolution cycles don't trigger automatically

**Symptom:** You've configured everything but no evolution beads appear.

**Cause:** The Deacon's evolve plugin may not be picking up your rig, or the
cooldown hasn't elapsed.

**Fix:**
1. Verify your rig config has `"evolve": { "enabled": true }` set
2. Check that `.evolve/config.toml` exists in your repo (the plugin looks for this)
3. Check the Deacon's patrol logs for errors related to your rig
4. Try triggering manually: create a bead with the `mol-evolve` formula attached

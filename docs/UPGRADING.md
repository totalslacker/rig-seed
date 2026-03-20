# Upgrading Your Fork

How to pull new features from rig-seed into an existing forked project.

## When to upgrade

rig-seed occasionally adds new files, scripts, or documentation. Check the
[rig-seed JOURNAL.md](https://github.com/anthropics/rig-seed/blob/main/JOURNAL.md)
for recent sessions, or compare your fork against upstream:

```bash
# Add rig-seed as an upstream remote (one-time)
git remote add upstream https://github.com/anthropics/rig-seed.git

# See what changed upstream since you forked
git fetch upstream
git log --oneline HEAD..upstream/main
```

## What to upgrade

Not everything in rig-seed should be pulled into your fork. Use this table
to decide:

| Category | Files | Pull updates? | Why |
|----------|-------|---------------|-----|
| **Scripts** | `validate.sh`, `health-check.sh`, `quickstart.sh` | Yes | Bug fixes and new flags benefit your project |
| **Documentation** | `docs/*.md`, `docs/examples/**` | Selectively | New guides and examples are useful; skip if you've diverged |
| **State files** | `JOURNAL.md`, `ROADMAP.md`, `LEARNINGS.md`, `SESSION_COUNT` | **Never** | These are YOUR project's state — upstream values are rig-seed's |
| **Identity** | `IDENTITY.md`, `SPECS.md` | **Never** | Your specs are different from rig-seed's |
| **Config** | `.evolve/config.toml`, `.claude/CLAUDE.md` | Selectively | Compare for new options, but keep your customizations |
| **Immutable list** | `.evolve/IMMUTABLE.txt` | Review only | Check if new entries make sense for your project |

## Upgrade methods

### Method 1: Cherry-pick specific commits (recommended)

Best when you only want a few changes:

```bash
git fetch upstream
git log --oneline upstream/main   # Find commits you want

# Cherry-pick specific commits
git cherry-pick <commit-hash>
```

### Method 2: Merge upstream selectively

Best when multiple sessions have accumulated and you want a batch update:

```bash
git fetch upstream

# Create a branch for the merge so you can review
git checkout -b upgrade-from-upstream

# Merge but don't auto-commit — review each change
git merge upstream/main --no-commit --no-ff

# Unstage your state files (NEVER overwrite these)
git reset HEAD JOURNAL.md ROADMAP.md LEARNINGS.md SESSION_COUNT SPECS.md PERSONALITY.md

# Review what's left
git diff --cached --stat

# Commit the parts you want
git checkout -- JOURNAL.md ROADMAP.md LEARNINGS.md SESSION_COUNT SPECS.md PERSONALITY.md
git commit -m "chore: upgrade from rig-seed upstream"
```

### Method 3: Manual copy

Best for one or two files:

```bash
git fetch upstream

# View a specific file from upstream
git show upstream/main:validate.sh > /tmp/validate.sh.new
diff validate.sh /tmp/validate.sh.new

# If it looks good, copy it in
cp /tmp/validate.sh.new validate.sh
git add validate.sh && git commit -m "chore: update validate.sh from upstream"
```

## After upgrading

1. **Run validate.sh** — make sure the template is still valid:
   ```bash
   ./validate.sh
   ```

2. **Run your tests** — confirm nothing broke:
   ```bash
   # your build/test commands
   ```

3. **Check `.evolve/config.toml`** — upstream may have added new config keys.
   Compare your file against the latest default:
   ```bash
   git show upstream/main:.evolve/config.toml
   ```

4. **Read the upstream JOURNAL.md** — skim recent entries for context on what
   changed and why:
   ```bash
   git show upstream/main:JOURNAL.md | head -60
   ```

## Handling conflicts

Conflicts during merge are normal — your fork has diverged from the template.

**Safe to resolve by keeping yours:**
- `JOURNAL.md`, `ROADMAP.md`, `LEARNINGS.md`, `SESSION_COUNT` — always keep yours
- `SPECS.md`, `PERSONALITY.md` — always keep yours
- `.claude/CLAUDE.md` — keep yours (but check upstream for new sections)

**Safe to resolve by taking upstream:**
- `validate.sh`, `health-check.sh` — unless you've added custom checks
- `docs/examples/**` — upstream examples are authoritative

**Needs manual review:**
- `.evolve/config.toml` — merge new keys into your existing values
- `.evolve/IMMUTABLE.txt` — keep your additions, add any new upstream entries
- `README.md` — your README should be project-specific, not rig-seed's

## Version tracking

rig-seed doesn't use formal releases. Track your baseline with a note in
your project:

```bash
# Record which rig-seed commit you're based on
echo "rig-seed-base: $(git log upstream/main -1 --format=%H)" >> .evolve/config.toml
```

This makes future upgrades easier — you can diff from your baseline:

```bash
base=$(grep rig-seed-base .evolve/config.toml | cut -d' ' -f2)
git log --oneline "$base"..upstream/main
```

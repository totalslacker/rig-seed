---
description: One-click setup wizard for a new self-evolving Gas Town project
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: [project idea or name]
---

# /rig-spawn — New Self-Evolving Project Setup

You are guiding the user through setting up a new Gas Town rig that evolves
autonomously using the rig-seed template. This is an interactive wizard — ask
questions at each step and wait for confirmation before proceeding.

User's input (if any): $ARGUMENTS

## Step 1: Gather Project Summary

If the user provided a project idea in $ARGUMENTS, use it. Otherwise, ask:

> What are you building? Give me a 2-3 sentence summary of the project.
> (e.g., "A CLI tool that manages dotfiles across machines" or
> "A REST API for tracking reading lists")

Wait for their answer. Summarize back what you understood and confirm.

## Step 2: Choose Project Name and Rig Name

Based on the project summary, suggest:
- **Repo name**: A short, lowercase, hyphenated name (e.g., `dotfile-sync`)
- **Rig name**: Same as repo name unless there's a conflict

Present your suggestions and ask:

> I'd suggest calling it `<name>`. Does that work, or would you prefer something else?

If the user has a preference, use theirs. The rig name must be a valid directory
name (lowercase, hyphens ok, no spaces).

## Step 3: Create the Repository

Ask the user which approach they prefer:

> How would you like to set up the repo?
> 1. **Fork rig-seed on GitHub** (recommended — preserves template link)
> 2. **Create a new repo** and copy template files in
> 3. **Use an existing repo** (I already have one)

### Option 1: Fork
```bash
gh repo fork totalslacker/rig-seed --clone --fork-name <repo-name>
cd <repo-name>
```

### Option 2: New repo
```bash
gh repo create <repo-name> --public --clone
cd <repo-name>
# Then copy template files (Step 5)
```

### Option 3: Existing repo
Ask for the repo path or URL:
> What's the path to your existing repo (or the GitHub URL)?

Confirm the repo exists and is a git repository.

**Error handling:**
- If `gh` is not installed: suggest `brew install gh` or `apt install gh`
- If repo name is taken: ask for an alternative name
- If auth fails: suggest `gh auth login`

## Step 4: Register as a Gas Town Rig

Run the rig registration command. Get the repo URL first:

```bash
# Get the remote URL
REPO_URL=$(git remote get-url origin)
# Register with Gas Town
gt rig add <rig-name> "$REPO_URL"
```

If `gt rig add` fails (name taken, URL invalid), report the error and ask
the user how to proceed.

## Step 5: Copy Template Files

If the user forked (Option 1), files are already present — run quickstart:

```bash
./quickstart.sh
```

If the user created a new repo (Option 2) or is using an existing repo
(Option 3), copy the template files from rig-seed. The essential files are:

```
IDENTITY.md          — Project identity (user will customize)
SPECS.md             — Empty, to be filled in next step
ROADMAP.md           — Empty roadmap template
JOURNAL.md           — Empty journal with header
LEARNINGS.md         — Empty learnings with header
PERSONALITY.md       — Default evolution personality
DAY_COUNT            — Set to 0
CONTRIBUTING.md      — How to contribute
CHANGELOG.template.md — Changelog template
.evolve/config.toml  — Evolution configuration
.evolve/IMMUTABLE.txt — Protected files list
.claude/CLAUDE.md    — Agent instructions
validate.sh          — Template validation
health-check.sh      — Fork health check
quickstart.sh        — Fork quickstart script
```

For each file, read it from the rig-seed repo and write it to the new project.
The rig-seed source files are at:
- If this command is running from Gas Town Mayor: check for the rigseed rig path
- Otherwise: fetch from `https://raw.githubusercontent.com/totalslacker/rig-seed/main/<file>`

After copying, run:
```bash
chmod +x validate.sh health-check.sh quickstart.sh
./quickstart.sh
```

## Step 6: Interactive Planning — Write SPECS.md

This is the most important step. Guide the user through writing their SPECS.md.

Show them the example specs for reference:
> I have example specs for different project types. Which is closest to yours?
> - **CLI tool** (command-line application)
> - **Web API** (REST/GraphQL backend)
> - **Library** (reusable package)
> - **Other** (I'll describe it)

Based on their choice, read the corresponding example from
`docs/examples/specs/` and use it as a template.

Walk through each section of SPECS.md with them:

1. **What is it?** — One paragraph describing the project
2. **Purpose** — Why does this exist? What problem does it solve?
3. **Requirements** — Bulleted list of must-haves
4. **Non-Goals** — What this project explicitly will NOT do

Write the completed SPECS.md to their repo.

## Step 7: Write ROADMAP.md

Based on the specs, help the user create their initial roadmap:

> Based on your specs, here's a suggested roadmap. Each phase should have 3-6
> concrete, checkable items.

Suggest phases based on their project type:
- **Bootstrap** (Day 0-3): Project structure, basic tests, CI setup
- **Foundation** (Day 4-10): Core functionality, documentation
- **Growth** (Day 10+): Features, polish, community

Show the suggested roadmap and ask:
> Does this look right? Want to add, remove, or reorder anything?

Write the finalized ROADMAP.md.

## Step 8: Configure Evolution

Read their current `.evolve/config.toml` and walk through key settings:

> Let's configure how your project evolves. Here are the key settings:
>
> - **Evolution interval**: How often should it evolve? (default: 24h)
>   - `24h` — Daily evolution (recommended for most projects)
>   - `8h` — Sprint mode (3x daily, aggressive)
>   - `48h` — Conservative (every other day)
>
> - **Max improvements per session**: How many things per cycle? (default: 3)
>
> - **GitHub issues**: Should the agent pull community issues? (default: yes)

Update config.toml with their choices.

## Step 9: Validate and Commit

Run validation to confirm everything is set up correctly:

```bash
./validate.sh
```

If validation passes, commit and push:

```bash
git add -A
git commit -m "chore: initialize from rig-seed template

Set up project specs, roadmap, and evolution config.
Ready for first evolution session."
git push -u origin main
```

If validation fails, fix the issues and re-run.

## Step 10: First Evolution (Optional)

Ask the user:

> Your project is ready to evolve! Would you like to:
> 1. **Run a test evolution session now** (interactive, you watch it work)
> 2. **Enable automatic evolution** (set it and forget it)
> 3. **Done for now** (you'll start evolution later)

### Option 1: Interactive session
Explain what will happen and guide them through watching the first cycle.

### Option 2: Automatic evolution
```bash
gt rig evolve <rig-name> --enable
```
If this command doesn't exist yet, explain that automatic scheduling is
configured via Gas Town's Mayor and the rig's config.toml interval.

### Option 3: Done
Confirm setup is complete:
> Your project is set up and ready. When you want to start evolution:
> - The Mayor will pick it up based on your config.toml schedule
> - Or run an evolution cycle manually from the Mayor's session

## Completion

Summarize what was created:
- Repository location
- Rig name
- Key files written (SPECS.md, ROADMAP.md, config)
- Next steps

> Your project is alive. It will read its specs, assess itself, pick
> improvements, and evolve — one session at a time. Check JOURNAL.md
> after the first cycle to see what it did.

# Merge Strategy Guide

When setting up a new rig-seed project, you need to decide how completed
evolution work lands on `main`. This choice affects how much human oversight
the project has.

## Option 1: Refinery Merge (Default)

The polecat pushes its branch, the Refinery tests it and fast-forwards to
`main` automatically. No human review step.

**Best for:**
- Personal projects and experiments
- Trusted, well-tested codebases with strong CI
- High-velocity evolution (multiple sessions per day)

**Configuration** (`.evolve/config.toml`):
```toml
[merge]
strategy = "refinery"   # Refinery auto-merges after tests pass
```

**How it works:**
1. Polecat implements changes and pushes branch
2. Polecat runs `gt done` to submit to merge queue
3. Refinery runs tests, then fast-forwards `main`
4. No human intervention needed

## Option 2: PR-Based Merge

The polecat pushes its branch and creates a GitHub pull request. A human
reviews the PR and merges it manually.

**Best for:**
- Team projects where humans review all changes
- Projects with compliance or audit requirements
- Early-stage projects where you want to watch the agent closely

**Configuration** (`.evolve/config.toml`):
```toml
[merge]
strategy = "pr"         # Polecat creates PR, human merges
require_approval = true # PR must be approved before merge
require_ci = true       # CI must pass before merge
```

**How it works:**
1. Polecat implements changes and pushes branch
2. Polecat creates a GitHub PR with a summary of changes
3. CI runs on the PR (if configured)
4. Human reviews, requests changes if needed, approves
5. Human (or GitHub auto-merge) merges the PR
6. Polecat runs `gt done` after PR is approved and CI is green

**Additional CLAUDE.md guidance for PR repos:**

Add this to your project's `.claude/CLAUDE.md` if using PR-based merging:
```markdown
### Merge Workflow
This project uses PR-based merging. Polecats:
- Push branches and create PRs (never push directly to main)
- Monitor CI status and address review feedback
- Run `gt done` only after PR is approved and CI passes
```

## Option 3: Hybrid

Use Refinery for routine evolution sessions but require PRs for large changes
(new features, breaking changes, dependency updates).

**Configuration** (`.evolve/config.toml`):
```toml
[merge]
strategy = "hybrid"
pr_threshold = 3        # Require PR if more than 3 files changed
pr_labels = ["breaking", "security", "deps"]  # Require PR for these labels
```

## Choosing a Strategy

| Factor | Refinery | PR-Based | Hybrid |
|--------|----------|----------|--------|
| Speed | Fast | Slow (waits for review) | Medium |
| Oversight | Low | High | Medium |
| Setup complexity | Simple | Moderate | Moderate |
| Good for solo devs | Yes | Overkill | Maybe |
| Good for teams | Risky | Yes | Yes |

**Rule of thumb:** If you'd want to review a human's PRs on this project,
you should review the agent's PRs too. Use PR-based merging.

# Forking rig-seed

What to do after you fork this repo and want to build your own evolving project.

## Step-by-step

### 1. Run the quickstart

```bash
./quickstart.sh
```

This resets DAY_COUNT to 0, clears the journal/roadmap/learnings, and checks
for specs. It's the fastest way from "I just forked" to "ready to evolve."

### 2. Write SPECS.md

This is the most important file in your fork. The agent reads it every session
to understand what it's building. Be specific about:

- What the project does (one paragraph)
- Core requirements (bulleted list)
- Non-goals (what you explicitly don't want)

See [example specs](examples/specs/README.md) for starter templates.

### 3. Customize your identity

Edit `PERSONALITY.md` to define how the agent communicates. The defaults are
fine for most projects, but if you want a different journal voice, commit style,
or tone, change it here.

**Do NOT edit `IDENTITY.md`** — it's immutable and defines the core rules all
rig-seed projects share.

### 4. Choose your evolution strategy

Copy one of the [example configs](examples/configs/README.md) to
`.evolve/config.toml`, or tune the defaults:

| Strategy | Interval | Max improvements | Good for |
|----------|----------|------------------|----------|
| Daily (default) | 24h | 3 | Active development |
| Conservative | 48h | 1 | Stable projects, careful iteration |
| Sprint | 8h | 3 | Rapid prototyping, hackathons |

### 5. Set up your build

Update `.claude/CLAUDE.md` with your actual build and test commands. The
template has placeholder comments — replace them:

```bash
# Replace these with your project's commands:
make build           # Build
make test            # Test
make lint            # Lint
```

The agent runs these to verify its work. Without real build commands, there's
no quality gate.

### 6. Add CI (optional but recommended)

Copy the [example workflows](examples/workflows/README.md) to
`.github/workflows/` in your fork. The validation workflow catches missing
files; the lint workflow catches broken markdown.

### 7. Add as a Gas Town rig

```bash
gt rig add myproject <your-git-url>
```

Then enable evolution in your rig config and start it.

## What to keep, what to change

| File | Keep or change? | Notes |
|------|-----------------|-------|
| `IDENTITY.md` | **Keep** | Immutable. Shared rules for all rig-seed forks. |
| `PERSONALITY.md` | Change if you want | Your agent's voice. |
| `SPECS.md` | **Must change** | Describes YOUR project. |
| `ROADMAP.md` | Quickstart clears it | Agent rebuilds from your specs. |
| `JOURNAL.md` | Quickstart clears it | Agent writes new entries. |
| `LEARNINGS.md` | Quickstart clears it | Agent accumulates project-specific knowledge. |
| `.evolve/config.toml` | Tune to taste | Controls schedule and limits. |
| `.evolve/IMMUTABLE.txt` | Add your own files | Protect files the agent shouldn't touch. |
| `.claude/CLAUDE.md` | **Must change** | Add your build/test/lint commands. |
| `validate.sh` | Keep or extend | Add your own validation checks. |
| `quickstart.sh` | Keep | Only used once after forking. |

## Protecting your files

Add paths to `.evolve/IMMUTABLE.txt` to prevent the agent from modifying them.
Common additions:

```
# Your additions:
migrations/           # Database migrations need human review
.env.example          # Environment template
deploy/               # Deployment configs
```

## Steering the agent after bootstrap

Once your fork is running, guide it by:

1. **Filing issues** with the `agent-input` label — the agent reads these
2. **Editing ROADMAP.md** — reorder priorities, add milestones
3. **Reading JOURNAL.md** — see what the agent did and course-correct
4. **Adjusting config.toml** — slow down or speed up evolution

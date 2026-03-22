# Architecture

How rig-seed's state files, scripts, and evolution flow connect.

## Evolution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    EVOLUTION CYCLE                           │
│                                                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌────────┐  │
│  │ 1. Load  │──▶│ 2. Assess│──▶│ 3. Fetch │──▶│3.5 Plan│  │
│  │  State   │   │          │   │  Issues  │   │ Session│  │
│  └──────────┘   └──────────┘   └──────────┘   └───┬────┘  │
│       │                                            │        │
│       │reads                                       │        │
│       ▼                                            ▼        │
│  ┌──────────┐                              ┌──────────┐     │
│  │  State   │                              │ 4. Select│     │
│  │  Files   │◀─────────────────────────────│   Work   │     │
│  │ (below)  │         updates              └────┬─────┘     │
│  └──────────┘                                   │           │
│       ▲                                         ▼           │
│       │                                    ┌──────────┐     │
│       │                                    │5. Implem-│     │
│       │                                    │   ent    │     │
│       │                                    └────┬─────┘     │
│       │                                         │           │
│       │                              ┌──────────┤           │
│       │                              ▼          ▼           │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐ ┌────────┐     │
│  │ 8. State │◀──│ 7. Build │◀──│ 6. Self- │ │ Tests  │     │
│  │  Update  │   │  Check   │   │  Review  │ │        │     │
│  └────┬─────┘   └──────────┘   └──────────┘ └────────┘     │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────┐                                               │
│  │ 9. Push  │──▶ Refinery merge queue ──▶ main              │
│  └──────────┘                                               │
└─────────────────────────────────────────────────────────────┘
```

## State Files

These files are the agent's persistent memory. Read at the start of each
session, updated at the end.

```
rigseed/
├── IDENTITY.md        🔒 Constitution (immutable)
├── SPECS.md           📋 What we're building
├── ROADMAP.md         🗺️  Priorities and milestones
├── JOURNAL.md         📖 Session log (append-only)
├── LEARNINGS.md       💡 Cached technical insights
├── NEXT_STEPS.md      ➡️  Planning handoff to next session
├── PERSONALITY.md     🗣️  Agent voice and style
├── SESSION_COUNT      🔢 Monotonic session counter
├── DAY_COUNT          📅 Calendar day counter
├── DAY_DATE           📅 Date of last session
│
├── .evolve/
│   ├── config.toml    ⚙️  Schedule, limits, safety settings
│   └── IMMUTABLE.txt  🔒 Protected file list
│
├── scripts/
│   ├── check.sh       🔨 Multi-build-system gate
│   ├── dashboard.sh   📊 Multi-project metrics comparison
│   ├── lint-workflows.sh  🔍 CI workflow validator
│   ├── migrate.sh     ⬆️  Incremental feature upgrade
│   ├── release.sh     🏷️  Semver tag management
│   ├── rollback.sh    ⏪ Safe revert for broken merges
│   └── sync-upstream.sh   🔄 Template sync from upstream
│
├── validate.sh        ✅ Template completeness checker
├── health-check.sh    🏥 Running fork health monitor
├── metrics.sh         📈 Evolution metrics summary
├── quickstart.sh      🚀 Fork initialization wizard
│
└── docs/
    ├── EVOLUTION.md         Step-by-step formula docs
    ├── ARCHITECTURE.md      This file
    ├── FORKING.md           Fork guide
    ├── DAY-ZERO.md          First-session tutorial
    ├── PLANNING.md          Planning investigation
    ├── MERGE-STRATEGY.md    Merge strategy guide
    ├── TROUBLESHOOTING.md   Common problems
    ├── UPGRADING.md         Upgrade guide
    ├── FORMULA-CUSTOMIZATION.md  Customizing mol-evolve
    ├── PLAN.md              Architecture decisions
    └── examples/            Configs, specs, workflows, etc.
```

## Data Flow

```
                  ┌───────────┐
                  │  GitHub   │
                  │  Issues   │
                  └─────┬─────┘
                        │ fetched in Step 3
                        ▼
┌──────────┐    ┌───────────────┐    ┌──────────┐
│NEXT_STEPS│───▶│   EVOLUTION   │───▶│ JOURNAL  │
│   .md    │    │    AGENT      │    │   .md    │
└──────────┘    │  (polecat)    │    └──────────┘
                │               │
┌──────────┐    │  reads ───▶   │    ┌──────────┐
│ SPECS.md │───▶│  assesses     │───▶│ ROADMAP  │
└──────────┘    │  implements   │    │   .md    │
                │  journals     │    └──────────┘
┌──────────┐    │               │
│LEARNINGS │◀──▶│               │    ┌──────────┐
│   .md    │    └───────┬───────┘    │ SESSION  │
└──────────┘            │            │ _COUNT   │
                        │ commits    └──────────┘
                        ▼
                ┌───────────────┐
                │   Refinery    │
                │ (merge queue) │
                └───────┬───────┘
                        │ merges
                        ▼
                ┌───────────────┐
                │     main      │
                └───────────────┘
```

## Guard Rails

| Mechanism | Purpose |
|-----------|---------|
| `IMMUTABLE.txt` | Prevents agent from modifying protected files |
| `validate.sh` | Ensures all template files are present and valid |
| `scripts/check.sh` | Hard build gate — broken code never merges |
| `health-check.sh` | Detects stalled or broken evolution forks |
| `scripts/rollback.sh` | Safe revert when a bad merge reaches main |
| Refinery merge queue | Build-gated automated merge to main |
| `JOURNAL.md` | Mandatory session logging — no silent changes |

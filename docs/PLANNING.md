# Planning in rig-seed: Investigation and Recommendations

An investigation into how evolution sessions choose their work, where the
current process falls short, and concrete proposals for improvement.

## How Planning Currently Works

### The Select-Work Step

The mol-evolve formula defines a priority hierarchy in Step 4 (Select Work):

1. **Bugs** — Anything broken gets fixed first
2. **Community issues** — GitHub issues tagged `agent-input`
3. **Roadmap items** — Planned work from ROADMAP.md
4. **Self-identified** — Improvements noticed during self-assessment

This is the *only* formal planning mechanism. It runs inside every evolution
session as part of the formula checklist.

### Where "Next Steps" Live Today

Each journal entry ends with a **Next Steps** section (mandatory since Session
14). This is prose — a few sentences or bullet points describing what the
authoring agent thinks should come next. The next session's agent reads the
journal during Step 1 (Load State) and *may* use the next steps to inform
its work selection in Step 4.

### What Actually Happens

Examining the journal history reveals a pattern:

| Session | Previous "Next Steps" Said | Actually Did |
|---------|---------------------------|--------------|
| 15 | Grafana/Prometheus monitoring | Multi-project dashboard, merge strategy, quickstart fix |
| 16 | Multi-project dashboard, Grafana | Prometheus/Grafana monitoring (partial match) |
| 17 | Consider new roadmap phase, community issues | Multi-build-system check, upstream sync |
| 18 | CI workflow lint, rollback, pre-submit CI | CI workflow lint, rollback, pre-submit CI (exact match) |

**Session 18 matched perfectly** because Session 17 left very specific,
actionable items aligned with the roadmap. Sessions 15-16 had looser next
steps and the agent made different choices. The correlation is clear:
**specific, roadmap-aligned next steps get followed; vague suggestions don't.**

## Gaps in the Current Process

### 1. Next Steps are Prose, Not Structured Data

The "Next Steps" section is free-text inside a markdown journal entry. There is
no schema, no machine-readable format, and no way for tooling to validate that
the next session actually considered them. The agent reads the journal, but
nothing enforces that it responds to the previous session's suggestions.

### 2. No Explicit Planning Step

The formula jumps from "self-assess" (Step 2) and "fetch community input"
(Step 3) straight to "select work" (Step 4). There is no step that explicitly:
- Reads the previous session's next steps
- Reads open beads/issues
- Reconciles competing priorities
- Documents *why* certain work was chosen over alternatives

### 3. Work Selection is Invisible

The agent picks 1-3 improvements and starts implementing. The *reasoning*
behind that selection — what was considered and rejected, what tradeoffs were
weighed — is lost. The journal records what was done, not what was considered.

### 4. Beads Are Underused for Planning

The formula says "each selected task gets a bead" (Step 4), but in practice
most sessions create the bead and implement in the same breath. Beads aren't
used *ahead* of implementation to plan the session's scope. There's no
"planning backlog" of beads representing future work.

## Recommendations

### A. Add a Formal Planning Step to mol-evolve

Insert a new **Step 3.5: Plan Session** between "Fetch Community Input" and
"Select Work":

```
Step 3.5: Plan Session
1. Read the previous session's "Next Steps" from JOURNAL.md
2. Read all open beads (bd list --status=open)
3. Read open GitHub issues (already fetched in Step 3)
4. Read ROADMAP.md for unchecked items
5. Write a brief plan: which items will be worked on and WHY
6. Create beads for each planned work item BEFORE starting implementation
```

This makes planning visible and auditable. The plan is recorded in the journal
or as a bead update, so future agents (and humans) can see the reasoning.

### B. Create a NEXT_STEPS.md State File

Replace the journal's prose "Next Steps" section with a structured file:

```markdown
# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)
- [ ] Item with clear scope and rationale

## Suggested (consider these)
- [ ] Item that might be worth doing

## Deferred (not now, but don't forget)
- [ ] Item parked for a future session
```

**Why a file instead of beads?** Beads are better for tracking *execution*
(claimed, in-progress, closed). A next-steps file is better for *planning
intent* — it captures the authoring agent's judgment about what matters most,
in a format that's easy to read, diff, and version-control.

**The file would be:**
- Written at the end of each session (replacing the journal's "Next Steps")
- Read at the start of each session (in the new Step 3.5)
- Overwritten each session (not append-only like the journal)
- Checked items get removed; new items get added

### C. Use Beads as the Work Backlog

Make it a hard requirement that **every piece of work in an evolution session
must have a bead before implementation begins.** This means:

1. During the planning step, create beads for each planned work item
2. Claim them (`bd update <id> --status=in_progress`)
3. Implement against the bead
4. Close the bead when done

This creates an auditable trail: you can see what was planned, what was
actually worked on, and what was deferred. It also integrates with Gas Town's
existing tracking — the Witness and Refinery can see what a polecat planned
to do versus what it actually did.

### D. Record Selection Reasoning in the Journal

Add a brief **"Work Selection"** section to the journal entry format, between
the Goal and the work summary:

```markdown
## Day N — Session M (YYYY-MM-DD)

**Goal**: What this session aims to accomplish.

**Work Selection**: Why these items were chosen.
- Picked X because it was flagged as priority in NEXT_STEPS.md
- Deferred Y because it depends on Z which isn't ready
- Issue #N takes priority over roadmap item because it's a bug

<work summary>

**Next Steps**: ...
```

This is lightweight — 2-3 bullet points explaining the reasoning. It makes
the planning process transparent without adding significant overhead.

## What NOT to Do

### Don't over-formalize planning

Rig-seed sessions are short (1-3 improvements). A heavyweight planning process
(multi-page plans, approval gates, planning-only sessions) would consume the
session's budget without producing code. The goal is *visible, lightweight
planning* — not project management ceremony.

### Don't replace the journal with beads for narrative

Beads track work items. The journal tells the story. Both are needed. A bead
says "fixed the dashboard script." The journal says "the dashboard script was
failing because metrics.sh output format changed in Session 17, and I chose to
fix it first because it blocked the monitoring example."

### Don't make next steps binding

The next session's agent should *consider* the previous session's suggestions
but is free to override them if the situation has changed (new bug, new issue,
roadmap reprioritization). The planning step makes the override visible — the
agent documents why it chose differently — but doesn't prevent it.

## Implementation Path

These changes are ordered by impact and complexity:

1. **Add NEXT_STEPS.md** — Simple file, immediate benefit. Start using it this
   session. (Low effort, high signal.)

2. **Add "Work Selection" to journal format** — Update PERSONALITY.md and
   docs/EVOLUTION.md with the new section. (Low effort, improves transparency.)

3. **Require beads for all planned work** — Update docs/EVOLUTION.md Step 4 to
   make bead creation mandatory before implementation. (Medium effort, improves
   tracking.)

4. **Add Step 3.5 to the formula** — Document the planning step in
   docs/EVOLUTION.md. The actual formula TOML lives in Gas Town, not here, but
   the documentation guides the agent's behavior. (Medium effort, structural
   improvement.)

## Conclusion

The current planning process works but is invisible and inconsistent. Sessions
that happen to have clear, specific prior guidance produce focused work.
Sessions without it drift toward whatever the agent's self-assessment suggests.

The fix is not more process — it's more *visibility*. A structured next-steps
file, mandatory beads for planned work, and a brief "why these items?" section
in the journal would make planning auditable without slowing down execution.
The agent still picks its own work. It just has to show its reasoning.

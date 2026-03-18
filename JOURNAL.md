# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Day 3 — Example specs, troubleshooting, and fork quickstart (rs-wup)

Three deliverables, all completing the Foundation milestone:

1. **Example SPECS.md variants** (docs/examples/specs/) — Three starter templates
   for CLI tools, web APIs, and libraries. Each has fill-in-the-blank sections so
   forkers don't stare at an empty SPECS.md. Includes a README explaining how to
   pick and copy.

2. **Troubleshooting guide** (docs/TROUBLESHOOTING.md) — Eight common failure
   modes with symptoms, causes, and fixes. Covers everything from "agent does
   nothing" to "cycles don't trigger." Written from real pain points observed
   during the first three evolution sessions.

3. **Fork quickstart script** (quickstart.sh) — Resets DAY_COUNT, clears
   journal/roadmap/learnings to fresh headers, checks for specs, runs validation.
   One command to go from "I just forked" to "ready to evolve."

Foundation milestone is now complete. All six items checked off. The template is
genuinely usable — fork it, run quickstart, write specs, add as a rig, go.
Growth phase next: fork detection, config variants, PERSONALITY improvements.

---

## Day 2 — Validation, CI examples, and formula docs (rs-egn)

Three deliverables this session, all called out in the Day 1 journal:

1. **validate.sh** — A shell script that checks all required template files
   exist, verifies DAY_COUNT is a valid integer, and confirms immutable files
   are present. Runs clean on the current repo. Intended as a CI gate for
   forked projects.

2. **Example CI workflows** (docs/examples/workflows/) — GitHub Actions for
   template validation and markdown linting. Placed in docs/ rather than
   .github/workflows/ because the workflows directory is immutable (human-
   controlled CI). Includes a README explaining how to copy them.

3. **docs/EVOLUTION.md** — Full documentation of the mol-evolve formula: all 9
   steps from load-state through submit, plus configuration reference and
   guidance on steering the agent via issues and ROADMAP edits.

Also updated README with a Validation section and Documentation links. Three
of four Foundation roadmap items are now complete; remaining: example SPECS.md
variants for common project types.

---

## Day 1 — Bootstrap: specs, docs, and guardrails (rs-nok)

Wrote SPECS.md from the bead description — rig-seed is a fork-and-go template,
not a runnable project. Added MIT LICENSE and CONTRIBUTING.md explaining how
the evolution process works and how humans can steer it. Expanded the README's
Quick Start from a terse 5-step list to a 6-section guide with context.
Updated CLAUDE.md with the evolution day flow so future polecats know the drill.
Tomorrow: example CI workflows and a template validation script.

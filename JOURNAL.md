# Journal

Evolution session log. Most recent entry first. Never delete entries.

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

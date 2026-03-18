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

### Immutable directories require indirect examples

`.github/workflows/` is in IMMUTABLE.txt, meaning evolution agents can't create
or modify CI files directly. To provide CI templates, put example workflow files
in `docs/examples/workflows/` with instructions to copy them. This keeps CI
human-controlled while still giving forked projects a running start.

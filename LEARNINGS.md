# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

### Immutable directories require indirect examples

`.github/workflows/` is in IMMUTABLE.txt, meaning evolution agents can't create
or modify CI files directly. To provide CI templates, put example workflow files
in `docs/examples/workflows/` with instructions to copy them. This keeps CI
human-controlled while still giving forked projects a running start.

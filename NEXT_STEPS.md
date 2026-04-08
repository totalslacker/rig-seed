# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add grafana.sh start/stop end-to-end test with mocked docker compose
- [ ] Add sync-upstream.sh --format=csv/kv conflict resolution edge cases (partial conflicts)
- [ ] Add metrics-exporter.sh --format=json schema validation test

## Suggested (consider these)

- [ ] Add rollback.sh merge commit revert test (--format output with merge parent selection)
- [ ] Add dashboard.sh --summary + --format combined integration tests
- [ ] Add health-check.sh --watch timeout and multi-cycle integration test

## Deferred (not now, but don't forget)

- [x] Add end-to-end test for rollback.sh live rollback with --format output (done Day 20 Session 53)
- [x] Add quickstart.sh --check edge case tests (template failure, empty SPECS.md) (done Day 20 Session 53)
- [x] Add dashboard.sh --format=json schema validation test (done Day 20 Session 53)
- [x] Add check-evolve-state.sh edge case CSV/KV tests (done Day 19 Session 52)
- [x] Add quickstart.sh --verbose --format=csv/kv tests (done Day 19 Session 52)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

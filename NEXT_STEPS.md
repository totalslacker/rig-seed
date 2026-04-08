# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add end-to-end test for rollback.sh live (non-dry-run) rollback with --format output
- [ ] Add quickstart.sh --check edge case tests (missing state files, empty SPECS.md)
- [ ] Add dashboard.sh --format=json schema validation test

## Suggested (consider these)

- [ ] Add grafana.sh start/stop end-to-end test with mocked docker compose
- [ ] Add sync-upstream.sh --format=csv/kv conflict resolution edge cases (partial conflicts)
- [ ] Add metrics-exporter.sh --format=json schema validation test

## Deferred (not now, but don't forget)

- [x] Add check-evolve-state.sh edge case CSV/KV tests (done Day 19 Session 52)
- [x] Add quickstart.sh --verbose --format=csv/kv tests (done Day 19 Session 52)
- [x] Add check-evolve-state.sh --format=csv/kv integration tests with edge cases (done Day 19 Session 52)
- [x] Add dashboard.sh --format=kv integration test (already existed)
- [x] Add rollback.sh --format integration tests (already existed)
- [x] Add grafana.sh --format=csv/kv integration tests with mocked docker (already existed)
- [x] Add lint-workflows.sh --format integration tests (already existed)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add metrics-exporter.sh --once --format=csv/kv schema validation tests
- [ ] Add grafana.sh status with dead exporter PID detection test
- [ ] Add sync-upstream.sh dry-run with partial changes detection test

## Suggested (consider these)

- [ ] Add validate.sh --lint --fix end-to-end test with real shellcheck issue and verification
- [ ] Add recap.sh --format=json schema validation test (check types and values)
- [ ] Add check.sh multi-build-system detection test (go.mod + package.json)

## Deferred (not now, but don't forget)

- [x] Add rollback.sh merge commit revert test (done Day 20 Session 55)
- [x] Add dashboard.sh --summary + --format combined integration tests (done Day 20 Session 55)
- [x] Add health-check.sh --watch timeout and multi-cycle integration test (done Day 20 Session 55)
- [x] Add grafana.sh start/stop e2e test with mocked docker compose (done Day 20 Session 54)
- [x] Add sync-upstream.sh --format=csv/kv conflict edge cases (done Day 20 Session 54)
- [x] Add metrics-exporter.sh --format=json schema validation test (done Day 20 Session 54)
- [x] Add end-to-end test for rollback.sh live rollback with --format output (done Day 20 Session 53)
- [x] Add quickstart.sh --check edge case tests (template failure, empty SPECS.md) (done Day 20 Session 53)
- [x] Add dashboard.sh --format=json schema validation test (done Day 20 Session 53)
- [x] Add check-evolve-state.sh edge case CSV/KV tests (done Day 19 Session 52)
- [x] Add quickstart.sh --verbose --format=csv/kv tests (done Day 19 Session 52)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add validate.sh --lint --fix end-to-end test with real shellcheck issue and verification
- [ ] Add recap.sh --format=json schema validation test (check types and values)
- [ ] Add integration test for check.sh JSON escaping with special characters in check names

## Suggested (consider these)

- [ ] Add grafana.sh --port custom port test (verify non-default port propagates)
- [ ] Add sync-upstream.sh live merge (non-conflict) with --format=json/csv/kv tests
- [ ] Add metrics-exporter.sh Prometheus format negative test (verify non-numeric values skipped)

## Deferred (not now, but don't forget)

- [x] Add grafana.sh status with dead exporter PID detection test (done Day 21 Session 58)
- [x] Add sync-upstream.sh dry-run with partial changes detection test (done Day 21 Session 58)
- [x] Add check.sh multi-build-system detection test (done Day 21 Session 58)
- [x] Add metrics-exporter.sh --once --format=csv/kv schema validation tests (done Day 21 Session 56)
- [x] Fix JSON/CSV escaping in check.sh and dashboard.sh (done Day 21 Session 56)
- [x] Add dashboard.sh --summary --format=json/csv/kv support (done Day 21 Session 56)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

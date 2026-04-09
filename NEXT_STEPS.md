# Next Steps

Updated at the end of each evolution session. Read at the start of the next.

## Priority (do these first)

- [ ] Add release.sh --format=csv/kv with actual tag creation test
- [ ] Add health-check.sh --verbose --watch combined mode test
- [ ] Add quickstart.sh --check --verbose edge case (missing IDENTITY.md) test

## Suggested (consider these)

- [ ] Add metrics.sh --watch --format=json multi-cycle test (verify valid JSON per cycle)
- [ ] Add dashboard.sh --projects --depth with nested invalid dirs edge case test
- [ ] Add validate.sh --lint --format=json schema validation for all lint categories

## Deferred (not now, but don't forget)

- [x] Add validate.sh --lint missing RESULT line test (done Day 21 Session 61)
- [x] Add dashboard.sh --projects mixed valid/invalid dirs test (done Day 21 Session 61)
- [x] Add metrics.sh --watch timeout and multi-cycle test (done Day 21 Session 61)
- [x] Add validate.sh --lint --fix e2e test with real shellcheck warning (done Day 21 Session 59)
- [x] Add recap.sh --format=json schema validation test (done Day 21 Session 59)
- [x] Add check.sh JSON escaping test with special characters (done Day 21 Session 59)
- [x] Add grafana.sh --port custom port test (done Day 21 Session 60)
- [x] Add sync-upstream.sh live merge (non-conflict) with --format=json/csv/kv tests (done Day 21 Session 60)
- [x] Add metrics-exporter.sh Prometheus format negative test (done Day 21 Session 60)
- [x] Add grafana.sh status with dead exporter PID detection test (done Day 21 Session 58)
- [x] Add sync-upstream.sh dry-run with partial changes detection test (done Day 21 Session 58)
- [x] Add check.sh multi-build-system detection test (done Day 21 Session 58)
- [x] Add metrics-exporter.sh --once --format=csv/kv schema validation tests (done Day 21 Session 56)
- [x] Fix JSON/CSV escaping in check.sh and dashboard.sh (done Day 21 Session 56)
- [x] Add dashboard.sh --summary --format=json/csv/kv support (done Day 21 Session 56)
- [ ] Make bead creation mandatory before implementation in Step 4 (needs Gas Town formula update, not a rig-seed change)

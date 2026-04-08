# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Initial project setup from rig-seed template
- `--format=table|csv|json|kv` flag on all scripts: metrics.sh, recap.sh, dashboard.sh,
  health-check.sh, check.sh, sync-upstream.sh, rollback.sh, lint-workflows.sh, grafana.sh
- `--json` alias on all scripts for quick JSON output
- `--format` support for metrics.sh `--summary` mode (table, csv, json, kv output)
- `--verbose` / `-v` flag for health-check.sh with detailed journal, ROADMAP, and SPECS analysis
- `--verbose` / `-v` flag for validate.sh with detailed SPECS, ROADMAP, JOURNAL, and NEXT_STEPS analysis
- JSON schema validation in integration tests
- End-to-end test for check.sh with real Python build system
- End-to-end tests for release.sh with real tag creation (patch/minor/major bumps, dry-run)
- Integration tests for validate.sh `--lint --fix --format` (combined --fix and --format flags)
- Integration tests for sync-upstream.sh conflict resolution with divergent state files
- Integration tests for metrics.sh `--summary --format=json` schema validation
- migrate.sh detection for missing `--format` and `--verbose` flags on all scripts

### Changed

### Fixed
- Fixed `grep -c ... || echo "0"` bug across all scripts — when grep found 0 matches,
  the variable was set to `"0\n0"` instead of `"0"`, causing arithmetic errors

### Removed

<!--
## [0.1.0] - YYYY-MM-DD

### Added
- First feature

### Changed
- Updated dependency X

### Fixed
- Bug in Y

### Removed
- Deprecated Z
-->

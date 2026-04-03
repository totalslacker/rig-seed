# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Initial project setup from rig-seed template
- `--format=table|csv|json|kv` flag on all scripts: metrics.sh, recap.sh, dashboard.sh,
  health-check.sh, check.sh, sync-upstream.sh, rollback.sh, lint-workflows.sh, grafana.sh
- `--json` alias on all scripts for quick JSON output
- JSON schema validation in integration tests
- End-to-end test for check.sh with real Python build system
- migrate.sh detection for missing `--format` flags on all scripts

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

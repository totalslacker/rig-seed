#!/usr/bin/env bash
# migrate.sh — Detect rig-seed version and apply incremental upgrades.
#
# Usage: ./scripts/migrate.sh [-n|--dry-run] [-h|--help] [directory]
#
# Checks which rig-seed features are present in a fork and offers to add
# missing ones. Non-destructive: never overwrites existing files that have
# been customized.
#
# Exit codes:
#   0 — migration complete (or nothing to do)
#   1 — not a valid rig-seed project

set -euo pipefail

# --- Options ---

dry_run=false
dir=""

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: scripts/migrate.sh [options] [directory]"
      echo ""
      echo "Detect rig-seed version and apply incremental upgrades to a fork."
      echo ""
      echo "Options:"
      echo "  -n, --dry-run   Show what would be done without making changes"
      echo "  -h, --help      Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory       Path to the rig-seed fork (default: current directory)"
      exit 0
      ;;
    -n|--dry-run)
      dry_run=true
      ;;
    *)
      dir="$arg"
      ;;
  esac
done

dir="${dir:-.}"

# --- Validation ---

if [ ! -f "$dir/IDENTITY.md" ]; then
  echo "Error: $dir does not appear to be a rig-seed project (missing IDENTITY.md)." >&2
  exit 1
fi
if [ ! -f "$dir/SESSION_COUNT" ] && [ ! -f "$dir/DAY_COUNT" ]; then
  echo "Error: $dir does not appear to be a rig-seed project (missing SESSION_COUNT and DAY_COUNT)." >&2
  exit 1
fi

# --- Helpers ---

added=0
skipped=0

check_file() {
  local path="$1"
  local description="$2"
  local source="$3"

  if [ -f "$dir/$path" ]; then
    return
  fi

  added=$((added + 1))
  if [ "$dry_run" = true ]; then
    echo "  [would add] $path — $description"
  else
    echo "  [adding] $path — $description"
    mkdir -p "$dir/$(dirname "$path")"
    cp "$source" "$dir/$path"
  fi
}

check_executable() {
  local path="$1"
  local description="$2"
  local source="$3"

  if [ -f "$dir/$path" ]; then
    return
  fi

  added=$((added + 1))
  if [ "$dry_run" = true ]; then
    echo "  [would add] $path — $description"
  else
    echo "  [adding] $path — $description"
    mkdir -p "$dir/$(dirname "$path")"
    cp "$source" "$dir/$path"
    chmod +x "$dir/$path"
  fi
}

check_config_key() {
  local key="$1"
  local description="$2"

  if [ ! -f "$dir/.evolve/config.toml" ]; then
    echo "  [warning] .evolve/config.toml missing — cannot check $key"
    skipped=$((skipped + 1))
    return
  fi

  if grep -q "$key" "$dir/.evolve/config.toml" 2>/dev/null; then
    return
  fi

  skipped=$((skipped + 1))
  echo "  [manual] config.toml missing '$key' — $description"
  echo "           See the upstream .evolve/config.toml for the new section."
}

# --- Detect rig-seed source ---
# Try to find the upstream rig-seed to copy files from.
# Priority: sibling directory, then script's own repo.

script_dir="$(cd "$(dirname "$0")" && pwd)"
seed_root="$(dirname "$script_dir")"

# If running from within the fork itself, use the script's repo as source
if [ -f "$seed_root/IDENTITY.md" ]; then
  source_root="$seed_root"
else
  echo "Error: Cannot locate rig-seed source files." >&2
  echo "Run this script from a rig-seed checkout or pass the fork path as argument." >&2
  exit 1
fi

# --- Migration checks ---
# Ordered roughly by when each feature was added (earliest first).

echo "=== rig-seed Migration ==="
echo ""
echo "Checking: $dir"
if [ "$dry_run" = true ]; then
  echo "Mode: dry run (no changes will be made)"
fi
echo ""

# Day 1: Core files
echo "Core files:"
check_file "CONTRIBUTING.md" "Contribution guide" "$source_root/CONTRIBUTING.md"
check_file "PERSONALITY.md" "Evolution personality" "$source_root/PERSONALITY.md"
echo "  ok"
echo ""

# Day 2: Validation and docs
echo "Validation & docs:"
check_executable "validate.sh" "Template validation script" "$source_root/validate.sh"
check_file "docs/EVOLUTION.md" "Evolution formula documentation" "$source_root/docs/EVOLUTION.md"
echo "  ok"
echo ""

# Day 3: Quickstart and troubleshooting
echo "Quickstart & troubleshooting:"
check_executable "quickstart.sh" "Fork quickstart script" "$source_root/quickstart.sh"
check_file "docs/TROUBLESHOOTING.md" "Troubleshooting guide" "$source_root/docs/TROUBLESHOOTING.md"
echo "  ok"
echo ""

# Day 4: Fork guide and config examples
echo "Fork guide & examples:"
check_file "docs/FORKING.md" "Fork customization guide" "$source_root/docs/FORKING.md"
check_file "CHANGELOG.template.md" "Changelog template" "$source_root/CHANGELOG.template.md"
echo "  ok"
echo ""

# Day 5: Health check
echo "Health check:"
check_executable "health-check.sh" "Fork health monitoring" "$source_root/health-check.sh"
echo "  ok"
echo ""

# Day 6: Personality variants and day-zero
echo "Day-zero & advanced docs:"
check_file "docs/DAY-ZERO.md" "Day-zero tutorial" "$source_root/docs/DAY-ZERO.md"
check_file "docs/FORMULA-CUSTOMIZATION.md" "Formula customization guide" "$source_root/docs/FORMULA-CUSTOMIZATION.md"
echo "  ok"
echo ""

# Day 9: Slash command
echo "Slash command:"
check_file ".claude/commands/rig-spawn.md" "Project setup wizard" "$source_root/.claude/commands/rig-spawn.md"
echo "  ok"
echo ""

# Day 11: Upgrade guide and metrics
echo "Upgrade & metrics:"
check_file "docs/UPGRADING.md" "Upgrade guide" "$source_root/docs/UPGRADING.md"
check_executable "metrics.sh" "Evolution metrics script" "$source_root/metrics.sh"
echo "  ok"
echo ""

# Day 12: Release script and config
echo "Release tooling:"
check_executable "scripts/release.sh" "Release tagging script" "$source_root/scripts/release.sh"
check_config_key "release" "Release strategy configuration (added Day 12)"
echo "  ok"
echo ""

# Day 13: Migration script itself
echo "Migration tooling:"
check_executable "scripts/migrate.sh" "This migration script" "$source_root/scripts/migrate.sh"
echo "  ok"
echo ""

# Day 14: Day/Session tracking
echo "Day/Session tracking:"
check_file "DAY_COUNT" "Calendar day counter" "$source_root/DAY_COUNT"
check_file "DAY_DATE" "Last session date tracker" "$source_root/DAY_DATE"
echo "  ok"
echo ""

# Session 15: Dashboard and merge strategy
echo "Dashboard & merge strategy:"
check_executable "scripts/dashboard.sh" "Multi-project metrics dashboard" "$source_root/scripts/dashboard.sh"
check_file "docs/MERGE-STRATEGY.md" "Merge strategy guide" "$source_root/docs/MERGE-STRATEGY.md"
check_config_key "merge" "Merge strategy configuration (added Session 15)"
echo "  ok"
echo ""

# Session 16: Monitoring integration
echo "Monitoring integration:"
check_executable "docs/examples/monitoring/metrics-exporter.sh" "Prometheus metrics exporter" "$source_root/docs/examples/monitoring/metrics-exporter.sh"
check_file "docs/examples/monitoring/prometheus.yml" "Prometheus scrape config" "$source_root/docs/examples/monitoring/prometheus.yml"
check_file "docs/examples/monitoring/grafana-dashboard.json" "Grafana dashboard" "$source_root/docs/examples/monitoring/grafana-dashboard.json"
check_file "docs/examples/monitoring/README.md" "Monitoring setup guide" "$source_root/docs/examples/monitoring/README.md"
echo "  ok"
echo ""

# Session 17: Build check script and upstream sync
echo "Build check & upstream sync:"
check_executable "scripts/check.sh" "Multi-build-system check script" "$source_root/scripts/check.sh"
check_executable "scripts/sync-upstream.sh" "Upstream template sync" "$source_root/scripts/sync-upstream.sh"
check_config_key "build" "Build check configuration (added Session 17)"
check_config_key "template" "Upstream sync configuration (added Session 17)"
echo "  ok"
echo ""

# --- Summary ---

echo "================================"
if [ "$added" -eq 0 ] && [ "$skipped" -eq 0 ]; then
  echo "Your fork is up to date with rig-seed."
elif [ "$dry_run" = true ]; then
  echo "Would add $added file(s). $skipped item(s) need manual review."
  echo "Run without --dry-run to apply changes."
else
  echo "Added $added file(s). $skipped item(s) need manual review."
  echo ""
  echo "Next steps:"
  echo "  1. Review the added files and customize as needed"
  echo "  2. Run ./validate.sh to confirm everything is valid"
  echo "  3. Commit: git add -A && git commit -m 'chore: migrate to latest rig-seed'"
fi

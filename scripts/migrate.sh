#!/usr/bin/env bash
# migrate.sh — Detect rig-seed version and apply incremental upgrades.
#
# Usage: ./scripts/migrate.sh [-n|--dry-run] [--color|--no-color] [-h|--help] [directory]
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
use_color=auto
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
      echo "  --color         Force colored output"
      echo "  --no-color      Disable colored output"
      echo "  -h, --help      Show this help message"
      echo ""
      echo "Arguments:"
      echo "  directory       Path to the rig-seed fork (default: current directory)"
      exit 0
      ;;
    -n|--dry-run)
      dry_run=true
      ;;
    --color)
      use_color=always
      ;;
    --no-color)
      use_color=never
      ;;
    *)
      dir="$arg"
      ;;
  esac
done

dir="${dir:-.}"

# --- Color setup ---
setup_colors() {
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    # shellcheck disable=SC2034  # Color vars used in output sections
    GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' BOLD='\033[1m' RESET='\033[0m'
  else
    # shellcheck disable=SC2034  # Color vars used in output sections
    GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}
setup_colors

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
    printf '  %b[would add]%b %s — %s\n' "$CYAN" "$RESET" "$path" "$description"
  else
    printf '  %b[adding]%b %s — %s\n' "$GREEN" "$RESET" "$path" "$description"
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
    printf '  %b[would add]%b %s — %s\n' "$CYAN" "$RESET" "$path" "$description"
  else
    printf '  %b[adding]%b %s — %s\n' "$GREEN" "$RESET" "$path" "$description"
    mkdir -p "$dir/$(dirname "$path")"
    cp "$source" "$dir/$path"
    chmod +x "$dir/$path"
  fi
}

check_config_key() {
  local key="$1"
  local description="$2"

  if [ ! -f "$dir/.evolve/config.toml" ]; then
    printf '  %b⚠%b .evolve/config.toml missing — cannot check %s\n' "$YELLOW" "$RESET" "$key"
    skipped=$((skipped + 1))
    return
  fi

  if grep -q "$key" "$dir/.evolve/config.toml" 2>/dev/null; then
    return
  fi

  skipped=$((skipped + 1))
  printf '  %b[manual]%b config.toml missing '\''%s'\'' — %s\n' "$YELLOW" "$RESET" "$key" "$description"
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

printf '%b=== rig-seed Migration ===%b\n' "$BOLD" "$RESET"
echo ""
printf 'Checking: %b%s%b\n' "$CYAN" "$dir" "$RESET"
if [ "$dry_run" = true ]; then
  printf 'Mode: %bdry run%b (no changes will be made)\n' "$YELLOW" "$RESET"
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

# Session 18: Workflow lint, rollback, pre-submit CI
echo "Workflow lint, rollback & pre-submit CI:"
check_executable "scripts/lint-workflows.sh" "CI workflow lint script" "$source_root/scripts/lint-workflows.sh"
check_executable "scripts/rollback.sh" "Rollback script for broken merges" "$source_root/scripts/rollback.sh"
check_file "docs/examples/workflows/pre-submit-ci.yml" "Pre-submit CI workflow example" "$source_root/docs/examples/workflows/pre-submit-ci.yml"
echo "  ok"
echo ""

# Session 19: Planning investigation and NEXT_STEPS.md
echo "Planning & structured handoff:"
check_file "NEXT_STEPS.md" "Structured planning handoff" "$source_root/NEXT_STEPS.md"
check_file "docs/PLANNING.md" "Planning investigation & recommendations" "$source_root/docs/PLANNING.md"
echo "  ok"
echo ""

# Session 20: Planning voice in PERSONALITY.md and --plan flag in metrics.sh
echo "Session 20 enhancements (in-file updates):"
if [ -f "$dir/PERSONALITY.md" ] && ! grep -q '## Planning Voice' "$dir/PERSONALITY.md" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " PERSONALITY.md missing Planning Voice section (added Session 20)"
  echo "        Compare with upstream to add planning guidance."
fi
if [ -f "$dir/metrics.sh" ] && ! grep -q '\-\-plan' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh missing --plan flag (added Session 20)"
  echo "        Compare with upstream to add planning output."
fi
echo "  ok"
echo ""

# Session 21: Architecture diagram
echo "Architecture documentation:"
check_file "docs/ARCHITECTURE.md" "Architecture diagram and file map" "$source_root/docs/ARCHITECTURE.md"
echo "  ok"
echo ""

# Session 22: check.sh --quiet flag
echo "Session 22 enhancements (in-file updates):"
if [ -f "$dir/scripts/check.sh" ] && ! grep -q '\-\-quiet' "$dir/scripts/check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/check.sh missing --quiet flag (added Session 22)"
  echo "        Compare with upstream to add quiet mode support."
fi
echo "  ok"
echo ""

# Session 23: emoji output markers in validate.sh and health-check.sh
echo "Session 23 enhancements (in-file updates):"
if [ -f "$dir/validate.sh" ] && grep -q 'echo "FAIL:' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh uses text-only markers (emoji markers added Session 23)"
  echo "        Compare with upstream to update ok:/FAIL:/WARN: to ✓/✗/⚠."
fi
if [ -f "$dir/health-check.sh" ] && grep -q 'echo "FAIL:' "$dir/health-check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " health-check.sh uses text-only markers (emoji markers added Session 23)"
  echo "        Compare with upstream to update ok:/FAIL:/WARN: to ✓/✗/⚠."
fi
echo "  ok"
echo ""

# Session 24: --json for check.sh, shellcheck workflow, --watch for health-check.sh
echo "Session 24 enhancements (in-file updates):"
if [ -f "$dir/scripts/check.sh" ] && ! grep -q '\-\-json' "$dir/scripts/check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/check.sh is missing --json support (added Session 24)"
  echo "        Compare with upstream to add JSON output mode."
fi
check_file "docs/examples/workflows/shellcheck.yml" "Shellcheck CI workflow" "$source_root/docs/examples/workflows/shellcheck.yml"
if [ -f "$dir/health-check.sh" ] && ! grep -q '\-\-watch' "$dir/health-check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " health-check.sh is missing --watch mode (added Session 24)"
  echo "        Compare with upstream to add continuous monitoring."
fi
echo "  ok"
echo ""

# Session 25: Script conventions doc, color flags, integrations
echo "Session 25 enhancements:"
check_file "docs/SCRIPT-CONVENTIONS.md" "Script output conventions doc" "$source_root/docs/SCRIPT-CONVENTIONS.md"
check_file "docs/examples/integrations/README.md" "External integrations guide" "$source_root/docs/examples/integrations/README.md"
check_executable "docs/examples/integrations/linear-sync.sh" "Linear sync script" "$source_root/docs/examples/integrations/linear-sync.sh"
check_executable "docs/examples/integrations/jira-sync.sh" "Jira sync script" "$source_root/docs/examples/integrations/jira-sync.sh"
if [ -f "$dir/validate.sh" ] && ! grep -q '\-\-no-color' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh missing --color/--no-color flags (added Session 25)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/health-check.sh" ] && ! grep -q '\-\-no-color' "$dir/health-check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " health-check.sh missing --color/--no-color flags (added Session 25)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
echo "  ok"
echo ""

# Session 26: Color flags for remaining scripts, session recap, metrics --format
echo "Session 26 enhancements:"
check_executable "scripts/recap.sh" "Session recap script" "$source_root/scripts/recap.sh"
if [ -f "$dir/scripts/check.sh" ] && ! grep -q '\-\-no-color' "$dir/scripts/check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/check.sh missing --color/--no-color flags (added Session 26)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/scripts/dashboard.sh" ] && ! grep -q '\-\-no-color' "$dir/scripts/dashboard.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/dashboard.sh missing --color/--no-color flags (added Session 26)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/scripts/lint-workflows.sh" ] && ! grep -q '\-\-no-color' "$dir/scripts/lint-workflows.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/lint-workflows.sh missing --color/--no-color flags (added Session 26)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/scripts/rollback.sh" ] && ! grep -q '\-\-no-color' "$dir/scripts/rollback.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/rollback.sh missing --color/--no-color flags (added Session 26)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/metrics.sh" ] && ! grep -q '\-\-format=' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh missing --format flag (added Session 26)"
  echo "        Compare with upstream to add table/csv/json/kv output format support."
fi
echo "  ok"
echo ""

# Session 27: Post-session-sync hook, validate.sh integration check, metrics.sh color
echo "Session 27 enhancements:"
check_executable "docs/examples/hooks/post-session-sync" "Post-session integration sync hook" "$source_root/docs/examples/hooks/post-session-sync"
if [ -f "$dir/validate.sh" ] && ! grep -q 'beads-external-map' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh missing .beads-external-map.json validation (added Session 27)"
  echo "        Compare with upstream to add integration config checking."
fi
if [ -f "$dir/metrics.sh" ] && ! grep -q '\-\-no-color' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh missing --color/--no-color flags (added Session 27)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
echo "  ok"
echo ""

# Session 28: recap.sh --diff mode, shellcheck annotations, pre-session hook
echo "Session 28 enhancements:"
check_executable "docs/examples/hooks/pre-session" "Pre-session health check hook" "$source_root/docs/examples/hooks/pre-session"
if [ -f "$dir/scripts/recap.sh" ] && ! grep -q '\-\-diff' "$dir/scripts/recap.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/recap.sh missing --diff flag (added Session 28)"
  echo "        Compare with upstream to add git diff display mode."
fi
echo "  ok"
echo ""

# Session 29: validate.sh --lint, metrics.sh --watch, post-session-sync CI workflow
echo "Session 29 enhancements:"
check_file "docs/examples/workflows/post-session-sync.yml" "Post-session sync CI workflow" "$source_root/docs/examples/workflows/post-session-sync.yml"
if [ -f "$dir/validate.sh" ] && ! grep -q '\-\-lint' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh missing --lint flag (added Session 29)"
  echo "        Compare with upstream to add script conventions linting."
fi
if [ -f "$dir/metrics.sh" ] && ! grep -q '\-\-watch' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh missing --watch flag (added Session 29)"
  echo "        Compare with upstream to add continuous monitoring mode."
fi
echo "  ok"
echo ""

# Session 30: bundled formula, check-evolve-state.sh, acceptance evaluation step
echo "Session 30 enhancements:"
if [ ! -f "$dir/formulas/mol-evolve.formula.toml" ]; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " formulas/mol-evolve.formula.toml missing (added Session 30)"
  echo "        Copy from upstream rig-seed to bundle the evolution formula."
fi
if [ ! -f "$dir/scripts/check-evolve-state.sh" ]; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/check-evolve-state.sh missing (added Session 30)"
  echo "        Pre-submit validation for required state file updates."
fi
echo "  ok"
echo ""

# Session 31: dashboard.sh --summary, check-evolve-state CI workflow, quickstart.sh flags
echo "Session 31 enhancements:"
check_file "docs/examples/workflows/check-evolve-state.yml" "Check-evolve-state CI workflow" "$source_root/docs/examples/workflows/check-evolve-state.yml"
if [ -f "$dir/scripts/dashboard.sh" ] && ! grep -q '\-\-summary' "$dir/scripts/dashboard.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/dashboard.sh missing --summary flag (added Session 31)"
  echo "        Compare with upstream to add one-line-per-project output mode."
fi
if [ -f "$dir/quickstart.sh" ] && ! grep -q '\-\-help' "$dir/quickstart.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " quickstart.sh missing --help flag (added Session 31)"
  echo "        Compare with upstream to add help and color flag support."
fi
echo "  ok"
echo ""

# Session 32: recap.sh --since, metrics.sh --summary, quickstart.sh --check, dashboard.sh --projects
echo "Session 32 enhancements (in-file updates):"
if [ -f "$dir/scripts/recap.sh" ] && ! grep -q '\-\-since' "$dir/scripts/recap.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/recap.sh missing --since flag (added Session 32)"
  echo "        Compare with upstream to add multi-session recap support."
fi
if [ -f "$dir/metrics.sh" ] && ! grep -q '\-\-summary' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh missing --summary flag (added Session 32)"
  echo "        Compare with upstream to add one-line summary output."
fi
if [ -f "$dir/quickstart.sh" ] && ! grep -q '\-\-check' "$dir/quickstart.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " quickstart.sh missing --check flag (added Session 32)"
  echo "        Compare with upstream to add dry-run validation mode."
fi
if [ -f "$dir/scripts/dashboard.sh" ] && ! grep -q '\-\-projects' "$dir/scripts/dashboard.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/dashboard.sh missing --projects flag (added Session 32)"
  echo "        Compare with upstream to add auto-discovery mode."
fi
echo "  ok"
echo ""

# Session 33-34: recap.sh --top, dashboard.sh --depth, metrics.sh --plan --since in JSON/CSV
echo "Session 33-34 enhancements (in-file updates):"
if [ -f "$dir/scripts/recap.sh" ] && ! grep -q '\-\-top' "$dir/scripts/recap.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/recap.sh missing --top flag (added Session 34)"
  echo "        Compare with upstream to add entry limit for --since output."
fi
if [ -f "$dir/scripts/dashboard.sh" ] && ! grep -q '\-\-depth' "$dir/scripts/dashboard.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/dashboard.sh missing --depth flag (added Session 34)"
  echo "        Compare with upstream to add search depth control for --projects."
fi
echo "  ok"
echo ""

# Day 14: Grafana turnkey setup, shellcheck in validate.sh --lint
echo "Day 14+ enhancements:"
check_executable "scripts/grafana.sh" "Turnkey Grafana dashboard setup" "$source_root/scripts/grafana.sh"
check_file "docs/examples/monitoring/docker-compose.yml" "Monitoring docker-compose" "$source_root/docs/examples/monitoring/docker-compose.yml"
check_file "docs/examples/monitoring/provisioning/datasources/prometheus.yml" "Grafana datasource provisioning" "$source_root/docs/examples/monitoring/provisioning/datasources/prometheus.yml"
check_file "docs/examples/monitoring/provisioning/dashboards/rigseed.yml" "Grafana dashboard provisioning" "$source_root/docs/examples/monitoring/provisioning/dashboards/rigseed.yml"
if [ -f "$dir/validate.sh" ] && ! grep -q 'shellcheck' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh --lint missing shellcheck integration (added Day 15)"
  echo "        Compare with upstream to add shell syntax linting."
fi
echo "  ok"
echo ""

# Day 15-16 enhancements: metrics.sh plan JSON/CSV, shellcheck lint, recap.sh --format, migrate.sh --color, validate.sh --fix
echo "Day 15-16 enhancements (in-file updates):"
if [ -f "$dir/metrics.sh" ] && ! grep -q 'plan_recent_goals' "$dir/metrics.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " metrics.sh --plan --since missing JSON/CSV output (added Day 15)"
  echo "        Compare with upstream to add plan data in JSON and CSV formats."
fi
if [ -f "$dir/scripts/recap.sh" ] && ! grep -q '\-\-format' "$dir/scripts/recap.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/recap.sh missing --format flag (added Day 16)"
  echo "        Compare with upstream to add table/csv/json/kv output format support."
fi
if [ -f "$dir/scripts/migrate.sh" ] && ! grep -q '\-\-no-color' "$dir/scripts/migrate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/migrate.sh missing --color/--no-color flags (added Day 16)"
  echo "        Compare with upstream to add terminal-aware color output."
fi
if [ -f "$dir/validate.sh" ] && ! grep -q '\-\-fix' "$dir/validate.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " validate.sh --lint missing --fix mode (added Day 17)"
  echo "        Compare with upstream to add auto-apply shellcheck suggestions."
fi
echo "  ok"
echo ""

# Day 17 enhancements: dashboard.sh --format, evolve plugin disk persistence
echo "Day 17 enhancements (in-file updates):"
if [ -f "$dir/scripts/dashboard.sh" ] && ! grep -q '\-\-format' "$dir/scripts/dashboard.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " scripts/dashboard.sh missing --format flag (added Day 17)"
  echo "        Compare with upstream to add table/csv/json/kv output format support."
fi
if [ -f "$dir/plugins/evolve/plugin.md" ] && ! grep -q 'last-dispatch' "$dir/plugins/evolve/plugin.md" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " evolve plugin missing disk-persisted dispatch timestamp (added Day 17)"
  echo "        Compare with upstream to add .evolve/.last-dispatch cooldown persistence."
fi
if [ -f "$dir/health-check.sh" ] && ! grep -q '\-\-format' "$dir/health-check.sh" 2>/dev/null; then
  printf '  %bNOTE:%b' "$YELLOW" "$RESET"; echo " health-check.sh missing --format flag (added Day 17)"
  echo "        Compare with upstream to add table/csv/json/kv output format support."
fi
echo "  ok"
echo ""

# --- Summary ---

printf '%b================================%b\n' "$BOLD" "$RESET"
if [ "$added" -eq 0 ] && [ "$skipped" -eq 0 ]; then
  printf '%b✓%b Your fork is up to date with rig-seed.\n' "$GREEN" "$RESET"
  echo ""
  printf 'RESULT: %bPASS%b (up to date)\n' "$GREEN" "$RESET"
elif [ "$dry_run" = true ]; then
  echo "Would add $added file(s). $skipped item(s) need manual review."
  echo "Run without --dry-run to apply changes."
  echo ""
  printf 'RESULT: %bPASS%b (%d to add, %d manual)\n' "$GREEN" "$RESET" "$added" "$skipped"
else
  echo "Added $added file(s). $skipped item(s) need manual review."
  echo ""
  echo "Next steps:"
  echo "  1. Review the added files and customize as needed"
  echo "  2. Run ./validate.sh to confirm everything is valid"
  echo "  3. Commit: git add -A && git commit -m 'chore: migrate to latest rig-seed'"
  echo ""
  printf 'RESULT: %bPASS%b (%d added, %d manual)\n' "$GREEN" "$RESET" "$added" "$skipped"
fi

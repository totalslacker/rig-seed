# Script Output Conventions

All rig-seed shell scripts follow a consistent set of output conventions.
This document is the authoritative reference. Follow these conventions when
writing new scripts or customizing existing ones for a forked project.

## Output Markers

Scripts use Unicode emoji markers for check results and status indicators:

| Marker | Meaning | When to use |
|--------|---------|-------------|
| `✓` | Check passed | A validation or build check succeeded |
| `✗` | Check failed | A validation or build check failed |
| `⚠` | Warning | Non-fatal concern (e.g., stale data, missing optional file) |
| `ℹ` | Info | Informational note (e.g., detected build system, optional directory missing) |
| `▶` | Running | A check or command is about to execute |

Example output:
```
  ✓ Project identity
  ✗ missing Roadmap (ROADMAP.md)
  ⚠ SPECS.md exists but is empty (SPECS.md)
  ℹ Go project detected (go.mod)
  ▶ go build
```

### Indentation

Check results are indented with two spaces (`  ✓`, `  ✗`). This visually
separates them from section headers and the RESULT line.

## Section Headers

Use `===` for top-level sections and `---` for subsections:

```
=== Required State Files ===
  ✓ Project identity
  ✓ Roadmap

--- Auto-Detected Build Systems ---
  ℹ Go project detected (go.mod)
  ▶ go build
  ✓ go build passed
```

## The RESULT Line

Every script that runs checks MUST print a final `RESULT:` line summarizing the
outcome. This is the one line that CI systems and other scripts should parse.

```
RESULT: all checks passed
RESULT: 3 check(s) failed
RESULT: no build systems detected — add [build] commands to .evolve/config.toml
```

The RESULT line is always printed, even in `--quiet` mode. It appears after a
blank line to separate it from the check output.

## Error Prefixes

Two distinct prefixes, used consistently across all scripts:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `Error:` | Runtime/operational error | `Error: directory does not exist` |
| `✗` (marker) | Check/validation failure | `✗ missing Roadmap (ROADMAP.md)` |

`Error:` is for problems that prevent the script from running (bad input,
missing dependencies, I/O failures). Check markers (`✗`, `⚠`) are for
problems found by the script's checks.

Operational errors go to stderr. Check results go to stdout.

## Standard Flags

All scripts support these flags where applicable:

### `--help` / `-h`

Print usage information and exit. Every script MUST support this. Include:
- Usage line with arguments
- Description of what the script does
- Options list with descriptions
- Exit codes

### `--quiet` / `-q`

Suppress passing checks, info lines, and section headers. Only print failures,
warnings, and the RESULT line. Makes scripts CI-friendly — a quiet pass is
minimal output.

Implementation pattern:
```bash
quiet=false
info() {
  [ "$quiet" = true ] || echo "$@"
}
# Always print failures:
echo "  ✗ something failed"
# Only print passing checks via info():
info "  ✓ something passed"
# Always print RESULT:
echo "RESULT: all checks passed"
```

### `--json`

Output structured JSON instead of human-readable text. Supported by check.sh
and dashboard.sh. The JSON object includes a `result` field and structured
data. All human-readable output is suppressed in JSON mode.

### `--dry-run` / `-n`

Preview what the script would do without making changes. Supported by
rollback.sh, migrate.sh, release.sh, and sync-upstream.sh.

### `--color` / `--no-color`

Control colored output. By default, scripts detect whether stdout is a terminal
and enable color automatically. Use `--color` to force color on (e.g., when
piping to `less -R`) or `--no-color` to force it off (e.g., for log files).
The `NO_COLOR` environment variable (see https://no-color.org/) also disables
color.

## Color Conventions

When color is enabled, scripts use these ANSI colors:

| Color | ANSI Code | Used for |
|-------|-----------|----------|
| Green | `\033[32m` | Passing checks (`✓`), success RESULT |
| Red | `\033[31m` | Failing checks (`✗`), failure RESULT |
| Yellow | `\033[33m` | Warnings (`⚠`) |
| Cyan | `\033[36m` | Info markers (`ℹ`), section headers |
| Bold | `\033[1m` | RESULT line |
| Reset | `\033[0m` | After every colored span |

Implementation pattern:
```bash
# Color setup — auto-detect terminal, respect --no-color and NO_COLOR
use_color=auto
setup_colors() {
  if [ "$use_color" = "never" ] || [ -n "${NO_COLOR:-}" ]; then
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  elif [ "$use_color" = "always" ] || [ -t 1 ]; then
    RED='\033[31m' GREEN='\033[32m' YELLOW='\033[33m'
    CYAN='\033[36m' BOLD='\033[1m' RESET='\033[0m'
  else
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}

# Usage in output:
printf "  ${GREEN}✓${RESET} %s\n" "$label"
printf "  ${RED}✗${RESET} %s\n" "$label"
printf "  ${YELLOW}⚠${RESET} %s\n" "$label"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (all checks passed, operation completed) |
| `1` | Failure (checks failed, invalid input, operational error) |

Scripts do not use other exit codes. The distinction between "checks failed"
and "script error" is communicated via the output (RESULT line vs Error:
prefix), not the exit code.

## Writing a New Script

Follow this skeleton:

```bash
#!/usr/bin/env bash
# scriptname.sh — One-line description.
set -euo pipefail

# Color and option setup
use_color=auto
quiet=false

for arg in "$@"; do
  case "$arg" in
    -h|--help) ... ; exit 0 ;;
    -q|--quiet) quiet=true ;;
    --color) use_color=always ;;
    --no-color) use_color=never ;;
    *) dir="$arg" ;;
  esac
done

setup_colors  # Initialize color variables

# ... run checks ...

echo "RESULT: ..."
```

#!/usr/bin/env bash
# lib.sh — Shared shell functions for rig-seed scripts.
#
# Source this file from any script that needs json_escape or csv_escape:
#   LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
#   # shellcheck source=scripts/lib.sh
#   source "${LIB_DIR}/lib.sh"
#
# Or from root-level scripts:
#   # shellcheck source=scripts/lib.sh
#   source "$(cd "$(dirname "$0")" && pwd)/scripts/lib.sh"

# Escape a string for safe embedding in a JSON value.
# Handles backslashes, double quotes, newlines, tabs, and control characters.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  # Strip other control characters that would produce invalid JSON
  printf '%s' "$s" | tr -d '\000-\010\013\014\016-\037'
}

# Escape a string for safe embedding in a CSV field.
# Doubles internal quotes and wraps in quotes.
csv_escape() {
  local s="$1"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

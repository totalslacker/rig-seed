#!/usr/bin/env bash
# metrics-exporter.sh — Expose metrics.sh output as Prometheus metrics.
#
# Usage: ./metrics-exporter.sh [project-directory]
#
# Environment:
#   EXPORTER_PORT  Port to listen on (default: 9142)
#
# Listens on the specified port and serves Prometheus text format on /metrics.
# Runs metrics.sh -q on each request and converts key=value pairs to
# Prometheus gauge metrics with a rigseed_ prefix.
#
# Requirements: bash, metrics.sh, nc (netcat) or ncat

set -euo pipefail

PORT="${EXPORTER_PORT:-9142}"
PROJECT_DIR="${1:-.}"
METRICS_SCRIPT=""

# Locate metrics.sh relative to the project directory
if [ -f "$PROJECT_DIR/metrics.sh" ]; then
  METRICS_SCRIPT="$PROJECT_DIR/metrics.sh"
else
  echo "Error: metrics.sh not found in $PROJECT_DIR" >&2
  exit 1
fi

# Derive project label from directory name
PROJECT_LABEL=$(basename "$(cd "$PROJECT_DIR" && pwd)")

# Detect netcat variant
NC_CMD=""
if command -v ncat &>/dev/null; then
  NC_CMD="ncat"
elif command -v nc &>/dev/null; then
  NC_CMD="nc"
else
  echo "Error: netcat (nc or ncat) is required" >&2
  exit 1
fi

# Convert metrics.sh quiet output to Prometheus text format
generate_metrics() {
  local output
  output=$("$METRICS_SCRIPT" -q "$PROJECT_DIR" 2>/dev/null) || true

  echo "# HELP rigseed_day_count Current evolution day number"
  echo "# TYPE rigseed_day_count gauge"
  echo "# HELP rigseed_session_counter Total session counter value"
  echo "# TYPE rigseed_session_counter gauge"
  echo "# HELP rigseed_session_count Number of journal entries"
  echo "# TYPE rigseed_session_count gauge"
  echo "# HELP rigseed_total_commits Total git commits"
  echo "# TYPE rigseed_total_commits gauge"
  echo "# HELP rigseed_commits_per_session Average commits per session"
  echo "# TYPE rigseed_commits_per_session gauge"
  echo "# HELP rigseed_age_days Project age in days"
  echo "# TYPE rigseed_age_days gauge"
  echo "# HELP rigseed_sessions_per_week Session velocity (sessions per week)"
  echo "# TYPE rigseed_sessions_per_week gauge"
  echo "# HELP rigseed_files_in_repo Files tracked by git"
  echo "# TYPE rigseed_files_in_repo gauge"
  echo "# HELP rigseed_total_lines Total lines in repository"
  echo "# TYPE rigseed_total_lines gauge"
  echo "# HELP rigseed_roadmap_checked Roadmap items completed"
  echo "# TYPE rigseed_roadmap_checked gauge"
  echo "# HELP rigseed_roadmap_unchecked Roadmap items remaining"
  echo "# TYPE rigseed_roadmap_unchecked gauge"
  echo "# HELP rigseed_roadmap_pct Roadmap completion percentage"
  echo "# TYPE rigseed_roadmap_pct gauge"
  echo "# HELP rigseed_learnings_count Number of learnings entries"
  echo "# TYPE rigseed_learnings_count gauge"

  while IFS='=' read -r key value; do
    [ -z "$key" ] && continue
    # Skip non-numeric values (like dates or "n/a")
    case "$value" in
      n/a|"") continue ;;
      *[!0-9.]*) continue ;;
    esac
    # Strip trailing % from roadmap_pct
    value="${value%\%}"
    echo "rigseed_${key}{project=\"${PROJECT_LABEL}\"} ${value}"
  done <<< "$output"
}

# Build HTTP response
build_response() {
  local path="$1"
  local body status

  if [ "$path" = "/metrics" ] || [ "$path" = "/metrics/" ]; then
    body=$(generate_metrics)
    status="200 OK"
  elif [ "$path" = "/" ]; then
    body="rig-seed metrics exporter. Visit /metrics for Prometheus metrics."
    status="200 OK"
  else
    body="Not Found"
    status="404 Not Found"
  fi

  local content_length=${#body}
  printf "HTTP/1.1 %s\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" \
    "$status" "$content_length" "$body"
}

echo "rig-seed metrics exporter listening on :${PORT}"
echo "  Project: ${PROJECT_DIR}"
echo "  Metrics: http://localhost:${PORT}/metrics"
echo ""
echo "Press Ctrl+C to stop."

# Main serve loop
while true; do
  # Read the HTTP request, extract the path, respond
  {
    read -r request_line || true
    # Parse method and path from "GET /metrics HTTP/1.1"
    path=$(echo "$request_line" | awk '{print $2}')
    path="${path:-/}"

    # Consume remaining headers
    while IFS= read -r header; do
      header="${header%%$'\r'}"
      [ -z "$header" ] && break
    done

    build_response "$path"
  } | {
    if [ "$NC_CMD" = "ncat" ]; then
      ncat -l -p "$PORT" --recv-timeout 5000 --send-timeout 5000
    else
      nc -l -p "$PORT" -q 1 2>/dev/null || nc -l "$PORT" 2>/dev/null
    fi
  }
done

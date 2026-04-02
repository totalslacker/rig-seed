#!/usr/bin/env bash
# grafana.sh — Turnkey Grafana + Prometheus setup for rig-seed monitoring.
#
# Usage: ./scripts/grafana.sh <command> [project-dirs...]
#
# Commands:
#   start   Start Prometheus, Grafana, and the metrics exporter
#   stop    Stop all containers and the exporter
#   status  Show running state of each component
#   logs    Tail container logs (Ctrl+C to stop)
#
# Arguments:
#   project-dirs  One or more rig-seed project directories to monitor.
#                 Defaults to the current directory.
#
# Options:
#   -h, --help          Show this help
#   --format=FORMAT     Output format: table (default), csv, json, kv (status command)
#   --json              Alias for --format=json
#   --color             Force colored output
#   --no-color          Disable colored output
#   -p, --port PORT     Grafana port (default: 3000)
#
# Requirements: docker (or podman), docker compose (or podman-compose)
#
# The script:
#   1. Checks for Docker/Podman
#   2. Starts Prometheus + Grafana via docker compose
#   3. Starts metrics-exporter.sh for each project directory
#   4. Auto-provisions the Grafana dashboard (no manual import needed)
#   5. Prints the dashboard URL

set -euo pipefail

# --- Resolve script and project paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONITORING_DIR="$REPO_ROOT/docs/examples/monitoring"

# --- Color setup ---
USE_COLOR=""
if [ -t 1 ]; then
  USE_COLOR=1
fi

# --- Defaults ---
GRAFANA_PORT=3000
COMMAND=""
PROJECT_DIRS=()
FORMAT=table

# --- Argument parsing ---
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "Usage: $(basename "$0") <command> [options] [project-dirs...]"
      echo ""
      echo "Commands:"
      echo "  start   Start Prometheus, Grafana, and the metrics exporter"
      echo "  stop    Stop all containers and the exporter"
      echo "  status  Show running state of each component"
      echo "  logs    Tail container logs (Ctrl+C to stop)"
      echo ""
      echo "Options:"
      echo "  -h, --help          Show this help"
      echo "  -p, --port PORT     Grafana port (default: 3000)"
      echo "  --format=FORMAT     Output format: table (default), csv, json, kv (status command)"
      echo "  --json              Alias for --format=json"
      echo "  --color             Force colored output"
      echo "  --no-color          Disable colored output"
      echo ""
      echo "Arguments:"
      echo "  project-dirs     One or more rig-seed project directories to monitor."
      echo "                   Defaults to the current directory."
      echo ""
      echo "Requirements: docker (or podman), docker compose"
      exit 0
      ;;
    --format=*)
      FORMAT="${1#*=}"
      case "$FORMAT" in
        table|csv|json|kv) ;;
        *) echo "Error: unknown format '$FORMAT' (expected: table, csv, json, kv)" >&2; exit 1 ;;
      esac
      shift ;;
    --json) FORMAT=json; shift ;;
    --color) USE_COLOR=1; shift ;;
    --no-color) USE_COLOR=""; shift ;;
    -p|--port) GRAFANA_PORT="$2"; shift 2 ;;
    start|stop|status|logs)
      COMMAND="$1"; shift ;;
    -*)
      echo "Error: unknown option: $1" >&2
      echo "Run $(basename "$0") --help for usage." >&2
      exit 1
      ;;
    *)
      PROJECT_DIRS+=("$1"); shift ;;
  esac
done

# --- Color helpers ---
if [ -n "$USE_COLOR" ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN="" YELLOW="" RED="" BOLD="" RESET=""
fi

info()  { printf "${BOLD}%s${RESET}\n" "$*"; }
ok()    { printf "${GREEN}OK${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}WARN${RESET} %s\n" "$*"; }
fail()  { printf "${RED}Error:${RESET} %s\n" "$*" >&2; }

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# --- Validate command ---
if [ -z "$COMMAND" ]; then
  fail "No command specified."
  echo "Usage: $(basename "$0") <start|stop|status|logs> [project-dirs...]" >&2
  exit 1
fi

# Default to current directory if no projects specified
if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
  PROJECT_DIRS=("$REPO_ROOT")
fi

# --- Detect container runtime ---
COMPOSE_CMD=""
CONTAINER_CMD=""

detect_runtime() {
  if command -v docker &>/dev/null; then
    CONTAINER_CMD="docker"
    if docker compose version &>/dev/null 2>&1; then
      COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null; then
      COMPOSE_CMD="docker-compose"
    fi
  elif command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
    if command -v podman-compose &>/dev/null; then
      COMPOSE_CMD="podman-compose"
    fi
  fi

  if [ -z "$CONTAINER_CMD" ]; then
    fail "Docker or Podman is required but not found."
    echo "Install Docker: https://docs.docker.com/get-docker/" >&2
    exit 1
  fi

  if [ -z "$COMPOSE_CMD" ]; then
    fail "Docker Compose (or podman-compose) is required but not found."
    echo "Install: https://docs.docker.com/compose/install/" >&2
    exit 1
  fi
}

# --- PID file for exporter processes ---
EXPORTER_PIDFILE="/tmp/rigseed-exporter.pids"

# --- Start exporters for each project directory ---
start_exporters() {
  local port=9142
  local pids=()

  for dir in "${PROJECT_DIRS[@]}"; do
    local abs_dir
    abs_dir="$(cd "$dir" 2>/dev/null && pwd)" || {
      warn "Directory not found: $dir (skipping)"
      continue
    }

    # Verify it looks like a rig-seed project
    if [ ! -f "$abs_dir/metrics.sh" ]; then
      warn "No metrics.sh in $abs_dir (skipping)"
      continue
    fi

    info "Starting exporter on :$port for $abs_dir"
    EXPORTER_PORT="$port" "$MONITORING_DIR/metrics-exporter.sh" "$abs_dir" &
    pids+=("$!:$port:$abs_dir")
    port=$((port + 1))
  done

  # Save PIDs for later cleanup
  printf '%s\n' "${pids[@]}" > "$EXPORTER_PIDFILE"
}

# --- Stop exporters ---
stop_exporters() {
  if [ -f "$EXPORTER_PIDFILE" ]; then
    while IFS=: read -r pid port dir; do
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        ok "Stopped exporter (PID $pid, port $port)"
      fi
    done < "$EXPORTER_PIDFILE"
    rm -f "$EXPORTER_PIDFILE"
  fi
}

# --- Commands ---

cmd_start() {
  detect_runtime
  info "Starting rig-seed monitoring stack..."

  # Update prometheus targets for multi-project
  local targets=""
  local port=9142
  for dir in "${PROJECT_DIRS[@]}"; do
    if [ -n "$targets" ]; then targets="$targets, "; fi
    targets="${targets}'host.docker.internal:${port}'"
    port=$((port + 1))
  done

  # Start containers
  info "Starting Prometheus + Grafana containers..."
  GRAFANA_PORT="$GRAFANA_PORT" $COMPOSE_CMD -f "$MONITORING_DIR/docker-compose.yml" up -d 2>&1

  # Start exporters
  start_exporters

  echo ""
  ok "Monitoring stack is running!"
  echo ""
  info "Dashboard: http://localhost:${GRAFANA_PORT}"
  info "Login:     admin / admin"
  info "Prometheus: http://localhost:9090"
  echo ""
  echo "Run '$(basename "$0") stop' to shut everything down."
}

cmd_stop() {
  detect_runtime
  info "Stopping rig-seed monitoring stack..."

  # Stop exporters first
  stop_exporters

  # Stop containers
  $COMPOSE_CMD -f "$MONITORING_DIR/docker-compose.yml" down 2>&1

  ok "Monitoring stack stopped."
}

cmd_status() {
  detect_runtime

  # Collect status data
  local prom_state="not_running"
  local graf_state="not_running"
  local exporters=()

  if $CONTAINER_CMD inspect rigseed-prometheus &>/dev/null 2>&1; then
    prom_state=$($CONTAINER_CMD inspect -f '{{.State.Status}}' rigseed-prometheus 2>/dev/null || echo "unknown")
  fi

  if $CONTAINER_CMD inspect rigseed-grafana &>/dev/null 2>&1; then
    graf_state=$($CONTAINER_CMD inspect -f '{{.State.Status}}' rigseed-grafana 2>/dev/null || echo "unknown")
  fi

  if [ -f "$EXPORTER_PIDFILE" ]; then
    while IFS=: read -r pid port dir; do
      if kill -0 "$pid" 2>/dev/null; then
        exporters+=("running|$port|$pid|$(basename "$dir")")
      else
        exporters+=("dead|$port|$pid|$(basename "$dir")")
      fi
    done < "$EXPORTER_PIDFILE"
  fi

  # --- Format output ---

  if [ "$FORMAT" = "json" ]; then
    printf '{"prometheus":"%s","grafana":"%s","grafana_port":%d,"exporters":[' \
      "$prom_state" "$graf_state" "$GRAFANA_PORT"
    local first=true
    for e in "${exporters[@]}"; do
      IFS='|' read -r estat eport epid edir <<< "$e"
      if [ "$first" = true ]; then first=false; else printf ','; fi
      printf '{"status":"%s","port":%s,"pid":%s,"project":"%s"}' \
        "$estat" "$eport" "$epid" "$(json_escape "$edir")"
    done
    printf ']}\n'
    return
  fi

  if [ "$FORMAT" = "csv" ]; then
    printf 'component,status,url\n'
    printf 'prometheus,%s,http://localhost:9090\n' "$prom_state"
    printf 'grafana,%s,http://localhost:%d\n' "$graf_state" "$GRAFANA_PORT"
    for e in "${exporters[@]}"; do
      IFS='|' read -r estat eport epid edir <<< "$e"
      printf 'exporter_%s,%s,http://localhost:%s/metrics\n' "$edir" "$estat" "$eport"
    done
    return
  fi

  if [ "$FORMAT" = "kv" ]; then
    printf 'prometheus=%s\n' "$prom_state"
    printf 'grafana=%s\n' "$graf_state"
    printf 'grafana_port=%d\n' "$GRAFANA_PORT"
    for e in "${exporters[@]}"; do
      IFS='|' read -r estat eport epid edir <<< "$e"
      printf 'exporter_%s=%s\n' "$edir" "$estat"
      printf 'exporter_%s_port=%s\n' "$edir" "$eport"
    done
    return
  fi

  # Default: table format
  info "rig-seed monitoring stack status"
  echo ""

  if [ "$prom_state" = "running" ]; then
    ok "Prometheus  http://localhost:9090  (running)"
  elif [ "$prom_state" = "not_running" ]; then
    echo "   Prometheus  (not running)"
  else
    warn "Prometheus  ($prom_state)"
  fi

  if [ "$graf_state" = "running" ]; then
    ok "Grafana     http://localhost:${GRAFANA_PORT}  (running)"
  elif [ "$graf_state" = "not_running" ]; then
    echo "   Grafana     (not running)"
  else
    warn "Grafana     ($graf_state)"
  fi

  if [ ${#exporters[@]} -eq 0 ]; then
    echo "   Exporter    (not running)"
  else
    for e in "${exporters[@]}"; do
      IFS='|' read -r estat eport epid edir <<< "$e"
      if [ "$estat" = "running" ]; then
        ok "Exporter    http://localhost:${eport}/metrics  (PID $epid, $edir)"
      else
        warn "Exporter    port $eport  (dead, was PID $epid)"
      fi
    done
  fi
}

cmd_logs() {
  detect_runtime
  $COMPOSE_CMD -f "$MONITORING_DIR/docker-compose.yml" logs -f 2>&1
}

# --- Dispatch ---
case "$COMMAND" in
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  status) cmd_status ;;
  logs)   cmd_logs ;;
esac

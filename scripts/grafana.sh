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
#   -h, --help       Show this help
#   --color          Force colored output
#   --no-color       Disable colored output
#   -p, --port PORT  Grafana port (default: 3000)
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
      echo "  -h, --help       Show this help"
      echo "  -p, --port PORT  Grafana port (default: 3000)"
      echo "  --color          Force colored output"
      echo "  --no-color       Disable colored output"
      echo ""
      echo "Arguments:"
      echo "  project-dirs     One or more rig-seed project directories to monitor."
      echo "                   Defaults to the current directory."
      echo ""
      echo "Requirements: docker (or podman), docker compose"
      exit 0
      ;;
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
  info "rig-seed monitoring stack status"
  echo ""

  # Check containers
  local prometheus_running=false
  local grafana_running=false

  if $CONTAINER_CMD inspect rigseed-prometheus &>/dev/null 2>&1; then
    local prom_state
    prom_state=$($CONTAINER_CMD inspect -f '{{.State.Status}}' rigseed-prometheus 2>/dev/null || echo "unknown")
    if [ "$prom_state" = "running" ]; then
      ok "Prometheus  http://localhost:9090  (running)"
      prometheus_running=true
    else
      warn "Prometheus  ($prom_state)"
    fi
  else
    echo "   Prometheus  (not running)"
  fi

  if $CONTAINER_CMD inspect rigseed-grafana &>/dev/null 2>&1; then
    local graf_state
    graf_state=$($CONTAINER_CMD inspect -f '{{.State.Status}}' rigseed-grafana 2>/dev/null || echo "unknown")
    if [ "$graf_state" = "running" ]; then
      ok "Grafana     http://localhost:${GRAFANA_PORT}  (running)"
      grafana_running=true
    else
      warn "Grafana     ($graf_state)"
    fi
  else
    echo "   Grafana     (not running)"
  fi

  # Check exporters
  if [ -f "$EXPORTER_PIDFILE" ]; then
    while IFS=: read -r pid port dir; do
      if kill -0 "$pid" 2>/dev/null; then
        ok "Exporter    http://localhost:${port}/metrics  (PID $pid, $(basename "$dir"))"
      else
        warn "Exporter    port $port  (dead, was PID $pid)"
      fi
    done < "$EXPORTER_PIDFILE"
  else
    echo "   Exporter    (not running)"
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

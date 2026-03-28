# Monitoring Example: Prometheus + Grafana

Long-running rig-seed projects benefit from time-series monitoring. This
example provides a turnkey Prometheus + Grafana stack that visualizes
`metrics.sh` output over time.

## Quick Start

```bash
# From your rig-seed project root:
./scripts/grafana.sh start
```

That's it. Open http://localhost:3000 (login: admin / admin) and the
rig-seed dashboard is already there.

To stop everything:
```bash
./scripts/grafana.sh stop
```

## Architecture

```
metrics.sh -q → metrics-exporter.sh → :9142/metrics → Prometheus → Grafana
```

1. **metrics-exporter.sh** — Lightweight HTTP server that runs `metrics.sh -q`
   on each Prometheus scrape and returns Prometheus text format.
2. **prometheus.yml** — Scrape config pointing at the exporter.
3. **docker-compose.yml** — Runs Prometheus + Grafana containers with
   auto-provisioned data source and dashboard.
4. **grafana-dashboard.json** — Pre-built Grafana dashboard (auto-loaded,
   no manual import needed).

## Commands

| Command | Description |
|---------|-------------|
| `grafana.sh start [dirs...]` | Start the full stack (containers + exporter) |
| `grafana.sh stop` | Stop containers and exporters |
| `grafana.sh status` | Show running state of each component |
| `grafana.sh logs` | Tail Prometheus + Grafana container logs |

### Options

| Flag | Description |
|------|-------------|
| `-p, --port PORT` | Grafana port (default: 3000) |
| `--color / --no-color` | Force or disable colored output |
| `-h, --help` | Show usage |

## Multi-Project Monitoring

Monitor multiple rig-seed projects by passing their directories:

```bash
./scripts/grafana.sh start ~/projects/alpha ~/projects/beta
```

Each project gets its own exporter on a sequential port (9142, 9143, ...).
The `project` label in Prometheus distinguishes them in the dashboard.

## Manual Setup (Without grafana.sh)

If you prefer to run components individually:

### 1. Start the exporter

```bash
./docs/examples/monitoring/metrics-exporter.sh /path/to/project
# Or set a custom port:
EXPORTER_PORT=9142 ./docs/examples/monitoring/metrics-exporter.sh
```

> **Requirements:** `bash`, `nc` (netcat). No external dependencies.
> Uses `ncat` (nmap's netcat) if available, falls back to `nc -l -p`.

### 2. Start the containers

```bash
docker compose -f docs/examples/monitoring/docker-compose.yml up -d
```

The dashboard and data source are auto-provisioned — no manual import step.

### 3. Open Grafana

Navigate to http://localhost:3000 (admin / admin). The rig-seed Evolution
Dashboard loads automatically as the home dashboard.

## Requirements

- **Docker** (or Podman) with Docker Compose
- **bash** and **nc** (netcat) for the metrics exporter
- `metrics.sh` in the project root (standard rig-seed file)

## Metrics Reference

| Prometheus Metric | Type | Description |
|-------------------|------|-------------|
| `rigseed_day_count` | gauge | Current evolution day |
| `rigseed_session_counter` | gauge | Total session count |
| `rigseed_session_count` | gauge | Journal entries count |
| `rigseed_total_commits` | gauge | Git commits |
| `rigseed_commits_per_session` | gauge | Avg commits per session |
| `rigseed_age_days` | gauge | Project age in days |
| `rigseed_sessions_per_week` | gauge | Session velocity |
| `rigseed_files_in_repo` | gauge | Files tracked by git |
| `rigseed_total_lines` | gauge | Total lines of code |
| `rigseed_roadmap_checked` | gauge | Roadmap items completed |
| `rigseed_roadmap_unchecked` | gauge | Roadmap items remaining |
| `rigseed_roadmap_pct` | gauge | Roadmap completion (0-100) |
| `rigseed_learnings_count` | gauge | Learnings entries |

All metrics include a `project` label derived from the directory name.

## Troubleshooting

### Exporter can't find metrics.sh
The exporter looks for `metrics.sh` in the project directory passed as an
argument (or the current directory). Make sure you're pointing at a rig-seed
project root.

### Prometheus can't reach the exporter
Inside Docker, `localhost` refers to the container, not the host. The
`docker-compose.yml` uses `host.docker.internal` to bridge this gap.
If that doesn't work on your system (some Linux setups), try:
```bash
# Add to docker-compose.yml under prometheus service:
network_mode: host
```

### Dashboard shows "No data"
1. Check the exporter is running: `curl http://localhost:9142/metrics`
2. Check Prometheus targets: http://localhost:9090/targets
3. Verify the project label matches what the dashboard expects

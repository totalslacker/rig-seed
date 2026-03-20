# Monitoring Example: Prometheus + Grafana

Long-running rig-seed projects benefit from time-series monitoring. This
example shows how to expose `metrics.sh` output as Prometheus metrics and
visualize them in Grafana.

## Architecture

```
metrics.sh -q → metrics-exporter.sh → :9142/metrics → Prometheus → Grafana
```

1. **metrics-exporter.sh** — A lightweight HTTP server that runs `metrics.sh -q`
   on each scrape and returns Prometheus text format.
2. **prometheus.yml** — Scrape config for Prometheus.
3. **grafana-dashboard.json** — Pre-built Grafana dashboard.

## Quick Start

### 1. Start the exporter

```bash
# From your rig-seed project root:
./docs/examples/monitoring/metrics-exporter.sh

# Or specify a port and project path:
EXPORTER_PORT=9142 ./docs/examples/monitoring/metrics-exporter.sh /path/to/project
```

The exporter listens on `http://localhost:9142/metrics` by default.

> **Requirements:** `bash`, `nc` (netcat). No external dependencies.
> Uses `ncat` (nmap's netcat) if available, falls back to `nc -l -p`.

### 2. Configure Prometheus

Copy `prometheus.yml` or add the scrape config to your existing setup:

```yaml
scrape_configs:
  - job_name: 'rigseed'
    scrape_interval: 5m
    static_configs:
      - targets: ['localhost:9142']
```

A 5-minute interval is fine — metrics change only when sessions run (typically
hours apart). Adjust based on your evolution schedule.

### 3. Import the Grafana dashboard

1. Open Grafana → Dashboards → Import
2. Upload `grafana-dashboard.json` or paste its contents
3. Select your Prometheus data source

## Multi-Project Monitoring

To monitor multiple rig-seed projects, run one exporter per project on
different ports:

```bash
EXPORTER_PORT=9142 ./metrics-exporter.sh ~/projects/alpha &
EXPORTER_PORT=9143 ./metrics-exporter.sh ~/projects/beta &
```

Then add each as a separate target in `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'rigseed'
    scrape_interval: 5m
    static_configs:
      - targets: ['localhost:9142', 'localhost:9143']
        labels:
          project: 'alpha'
      - targets: ['localhost:9143']
        labels:
          project: 'beta'
```

Or use the `project` label from the exporter output to distinguish them.

## Docker Compose (Optional)

For a turnkey local stack, create a `docker-compose.yml`:

```yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

Update `prometheus.yml` targets to use `host.docker.internal:9142` so
Prometheus inside Docker can reach the exporter on the host.

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

# Observability Stack

This directory contains the full Docker Compose observability stack for DebianTrace Pro.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Grafana | 3000 | Dashboards, alerts, unified query UI |
| Prometheus | 9090 | Metrics scraping and PromQL |
| ClickHouse | 8123 (HTTP) / 9000 (native) | High-speed columnar event analytics |
| Loki | 3100 | Log aggregation |
| Tempo | 3200 | Distributed tracing backend (OTLP/Zipkin) |
| Node Exporter | 9100 | Host system metrics |
| cAdvisor | 8080 | Container resource metrics |

## Quick Start

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f grafana

# Stop
docker compose down
```

Or use the shell aliases (after install):

```bash
obs-up      # start
obs-status  # status
obs-down    # stop
obs-logs    # tail logs
```

## Grafana Login

URL: http://localhost:3000  
Username: `admin`  
Password: `tracepro2024`

> Change this password before exposing Grafana to any network.

## Data Sources

All data sources are provisioned automatically from `grafana/provisioning/datasources/datasources.yml`:
- Prometheus (default)
- Loki
- Tempo (with trace-to-logs correlation to Loki)
- ClickHouse

## Prometheus Retention

Default: **90 days**. Change in `docker-compose.yml`:

```yaml
command:
  - '--storage.tsdb.retention.time=90d'  # change here
```

## ClickHouse

Connect via the `ch` alias or directly:

```bash
docker exec -it clickhouse clickhouse-client
```

HTTP interface: http://localhost:8123/play (browser SQL editor)

## Customising

- **Add a Grafana dashboard**: drop a JSON file into `grafana/provisioning/dashboards/` (create a `dashboards.yml` loader config alongside it)
- **Add a Prometheus scrape target**: edit `prometheus/prometheus.yml` and run `docker compose restart prometheus`
- **Change ClickHouse settings**: edit `clickhouse/config.xml` and restart the container

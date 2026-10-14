# 13 — Telemetry & Alerting Daemon

A long-running HTTP service that ingests service telemetry readings, classifies threshold alerts, enforces a bounded SQLite retention window using prefix slice views (`ids[0:dropCount]`), and exposes real-time ARC memory and reference-cycle diagnostics over `/health`.

## What It Exercises

- **HTTP Routing (`std/web/router`, `std/web/server`)** — `POST /ingest`, `GET /samples`, `GET /alerts`, `GET /health`, and `DELETE /samples/:id`.
- **Declarative Persistence (`std/orm` + `[db]` / `[column]` / `[json]` tags)** — `MetricSample` maps directly to SQLite and JSON without intermediate DTOs.
- **Fat-Slice Header Views (`comp_error.md #114`)** — `enforceRetention()` slices the oldest primary keys via `ids[0:dropCount]` and evicts them on every overflow ingest so database storage stays bounded across multi-hour runs.
- **ARC Heap & Cycle Introspection (`Skink_rc_live_bytes`, `Skink_rc_detect_cycles`)** — `/health` and `--soak` mode report live object counts, live/peak bytes, and Tarjan SCC reference-cycle counts.

## Running

```bash
# Run the unit and sustained-load soak test suite
SKINK_HOME=/path/to/skink skink -t code/daemon_test.skink

# Build the daemon binary
SKINK_HOME=/path/to/skink skink -o telemetry_daemon code/main.skink

# Run a 2,000-request sustained soak with exit-time cycle verification
SKINK_RC_DETECT_CYCLES=1 SKINK_RC_STRICT_CYCLES=1 ./telemetry_daemon --soak 2000

# Or start the live HTTP server on :8090
./telemetry_daemon
```

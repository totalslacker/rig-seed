# Project Specification

## What This Is

An HTTP API service that [WHAT IT DOES — e.g., "manages team task boards with
real-time updates and role-based access"].

## Purpose

[WHY IT EXISTS — e.g., "We need a lightweight task tracker that integrates with
our existing SSO and doesn't require a SaaS subscription."]

## Requirements

### API Surface
- [Core resources — e.g., "CRUD for boards, lists, and cards"]
- [Auth — e.g., "JWT tokens via /auth/login, refresh via /auth/refresh"]
- [Format — e.g., "JSON request/response, standard HTTP status codes"]

### Data
- Database: [e.g., "PostgreSQL", "SQLite for dev, Postgres for prod"]
- Migrations: [e.g., "SQL migration files in db/migrations/"]
- Key entities: [e.g., "User, Board, List, Card, Comment"]

### Operations
- Language/framework: [e.g., "Go with chi router", "Python with FastAPI"]
- Health check: GET /health returns 200 with version info
- Logging: structured JSON logs to stdout
- Config: environment variables, no config files

### Quality
- Tests: unit tests for handlers, integration tests hitting a real database
- CI: lint, test, build, docker image on every push

## Non-Goals

- [e.g., "No frontend — API only, consumed by existing React app"]
- [e.g., "No file uploads in v1"]

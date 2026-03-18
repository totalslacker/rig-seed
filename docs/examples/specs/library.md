# Project Specification

## What This Is

A [LANGUAGE] library that [WHAT IT DOES — e.g., "provides a type-safe query
builder for SQL databases without requiring an ORM"].

## Purpose

[WHY IT EXISTS — e.g., "Existing query builders either generate unsafe SQL via
string concatenation or require a full ORM. This library sits in between —
type-safe query construction with zero runtime overhead."]

## Requirements

### Public API
- [Core type/function — e.g., "Query.select(), Query.where(), Query.join()"]
- [Builder pattern — e.g., "Chainable methods that return new query objects"]
- [Output — e.g., ".build() returns (sql_string, params) tuple"]

### Supported Targets
- [e.g., "PostgreSQL and SQLite dialects"]
- [e.g., "Async and sync execution via optional feature flags"]

### Package Distribution
- Registry: [e.g., "crates.io", "PyPI", "npm"]
- Versioning: semver, public API changes require major version bump
- Docs: generated API docs published on every release

### Quality
- Language: [e.g., "Rust", "TypeScript", "Python"]
- Tests: unit tests for query generation, integration tests against real databases
- Benchmarks: [e.g., "Query construction time vs raw string building"]
- CI: lint, test, docs, publish on tag

## Non-Goals

- [e.g., "Not an ORM — no model definitions, no migrations, no connection pooling"]
- [e.g., "No query execution — returns SQL strings, caller handles execution"]

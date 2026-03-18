# Project Specification

## What This Is

A command-line tool that [WHAT IT DOES — e.g., "converts Markdown files to
styled PDFs with configurable templates"].

## Purpose

[WHY IT EXISTS — e.g., "Existing tools require LaTeX or produce ugly output.
This tool should produce good-looking PDFs with zero configuration while
supporting custom templates for power users."]

## Requirements

### Core Functionality
- [Primary verb — e.g., "Convert .md files to .pdf"]
- [Secondary verb — e.g., "Support custom CSS templates via --template flag"]
- [Input/output — e.g., "Accept file paths or stdin, output to file or stdout"]

### CLI Interface
- Subcommands: [e.g., "convert, validate, templates list"]
- Config file: [e.g., "~/.config/toolname/config.toml"]
- Exit codes: 0 success, 1 user error, 2 internal error

### Quality
- Language: [e.g., "Go", "Rust", "Python"]
- Tests: unit tests for core logic, integration tests for CLI behavior
- CI: lint, test, build on every push

## Non-Goals

- [What this is NOT — e.g., "Not a Markdown editor or previewer"]
- [Scope limit — e.g., "No GUI, no web interface"]

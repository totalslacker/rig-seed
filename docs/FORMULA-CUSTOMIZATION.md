# Customizing the Evolution Formula

The `mol-evolve` formula defines the step-by-step workflow an agent follows
during each evolution session. While the default formula works well out of the
box, you can customize it to fit your project's specific needs.

## When to Customize

Customize the formula when your project has:

- **Build steps** that differ from the default (e.g., Docker builds, multi-stage
  compilation, database migrations)
- **Testing requirements** beyond simple `make test` (e.g., integration tests,
  E2E tests, contract tests)
- **Deployment checks** the agent should verify before submitting
- **Code generation** steps that must run before or after implementation
- **External dependencies** that need validation (API availability, service health)

## The Default Formula Steps

The standard `mol-evolve` formula has 9 steps (documented fully in
[EVOLUTION.md](EVOLUTION.md)):

1. **Load State** — Read IDENTITY, SPECS, JOURNAL, ROADMAP, LEARNINGS, SESSION_COUNT
2. **Self-Assess** — Read source code, identify weaknesses
3. **Fetch Community Input** — Check GitHub issues
4. **Select Work** — Pick 1-3 improvements
5. **Implement** — Write code with tests
6. **Self-Review** — Review the diff
7. **Build Check** — Run build/test/lint
8. **Update State** — Journal, roadmap, day count, learnings
9. **Submit** — Push and run `gt done`

## How to Add Project-Specific Steps

### Via `.evolve/config.toml`

Add custom commands to the build check step:

```toml
[build]
# Commands run during Step 7 (Build Check)
# Each command must exit 0 for the step to pass
commands = [
  "npm run build",
  "npm test",
  "npm run lint",
  "npm run typecheck",        # Add type checking
  "npm run test:integration", # Add integration tests
]

[build.pre]
# Commands run BEFORE implementation (Step 5)
# Useful for code generation, dependency installation
commands = [
  "npm install",
  "npm run codegen",
]

[build.post]
# Commands run AFTER build check passes (between Step 7 and 8)
# Useful for deployment verification, artifact generation
commands = [
  "./scripts/check-bundle-size.sh",
]
```

### Via `.claude/CLAUDE.md`

For steps that require agent judgment (not just command execution), add
instructions to `.claude/CLAUDE.md`. The agent reads this file at the start
of every session.

```markdown
## Build & Test Commands

- `make build` — Compile the project
- `make test` — Run unit tests
- `make test-integration` — Run integration tests (requires local DB)
- `make lint` — Run linter

## Project-Specific Evolution Rules

- **Database migrations**: If you modify any `migrations/` file, run
  `make migrate-check` to verify the migration is reversible.
- **API changes**: If you modify files in `api/`, update the OpenAPI spec
  in `docs/openapi.yml` and run `make api-validate`.
- **Performance**: Never add a dependency larger than 50KB without noting
  the tradeoff in JOURNAL.md.
```

### Via Custom Validation Script

Extend `validate.sh` with project-specific checks. The health-check and
quickstart scripts both call `validate.sh`, so your custom checks
automatically become part of the lifecycle.

```bash
# Add to validate.sh after the standard checks:

echo ""
echo "=== Project-Specific Checks ==="

# Check that generated files are up to date
if [ -f "$dir/src/generated/types.ts" ]; then
  if [ "$dir/schema.graphql" -nt "$dir/src/generated/types.ts" ]; then
    echo "FAIL: generated types are stale — run 'npm run codegen'"
    ((errors++))
  else
    echo "  ok: generated types are current"
  fi
fi

# Check bundle size budget
if [ -f "$dir/dist/bundle.js" ]; then
  size=$(wc -c < "$dir/dist/bundle.js")
  if [ "$size" -gt 500000 ]; then
    echo "WARN: bundle size ($size bytes) exceeds 500KB budget"
  else
    echo "  ok: bundle size within budget ($size bytes)"
  fi
fi
```

## Examples by Project Type

### CLI Tool (Go)

```toml
# .evolve/config.toml
[build]
commands = [
  "go build ./...",
  "go test ./...",
  "go vet ./...",
  "golangci-lint run",
]
```

### Web API (Python/FastAPI)

```toml
# .evolve/config.toml
[build]
commands = [
  "pip install -e '.[dev]'",
  "pytest",
  "mypy src/",
  "ruff check src/",
]

[build.post]
commands = [
  "python -c 'from app.main import app; print(\"Import OK\")'",
]
```

### Library (TypeScript)

```toml
# .evolve/config.toml
[build]
commands = [
  "npm ci",
  "npm run build",
  "npm test",
  "npm run lint",
  "npm run typecheck",
]

[build.post]
commands = [
  "npm pack --dry-run",  # Verify package builds correctly
]
```

### Full-Stack App (monorepo)

```toml
# .evolve/config.toml
[build]
commands = [
  "npm ci --workspaces",
  "npm run build --workspaces",
  "npm test --workspaces",
  "npm run lint --workspaces",
]

[build.pre]
commands = [
  "docker compose up -d postgres redis",  # Start service dependencies
  "npm run db:migrate",
]

[build.post]
commands = [
  "npm run test:e2e",
  "docker compose down",
]
```

## Controlling Evolution Scope

### Limiting What the Agent Can Change

Use `.evolve/IMMUTABLE.txt` to protect files from agent modification:

```
# Infrastructure the agent shouldn't touch
.github/workflows/
docker-compose.yml
Makefile

# Configuration that needs human review
.env.example
tsconfig.json
```

### Focusing the Agent's Attention

Edit `ROADMAP.md` to guide what the agent works on. Items at the top of the
unchecked list get priority. Use clear, actionable descriptions:

```markdown
## Current Sprint

- [ ] Add retry logic to the HTTP client (max 3 retries, exponential backoff)
- [ ] Fix: `parse_config` panics on empty input (see issue #42)
- [ ] Add `--verbose` flag to CLI output
```

### Adjusting Session Size

```toml
[limits]
max_improvements_per_session = 1  # Conservative: one thing at a time
# max_improvements_per_session = 3  # Default: up to three changes
# max_improvements_per_session = 5  # Aggressive: for rapid iteration
```

## Debugging Formula Issues

If the evolution agent isn't following your custom steps:

1. **Check `.claude/CLAUDE.md`** — Are your instructions clear and specific?
2. **Check `.evolve/config.toml`** — Are command paths correct? Test them manually.
3. **Read JOURNAL.md** — The agent logs what it did and didn't do. Look for
   skipped steps or errors.
4. **Run `validate.sh`** — If it fails, the agent may be reverting changes
   because the build gate isn't passing.
5. **Check `health-check.sh`** — A healthy project should pass all checks.

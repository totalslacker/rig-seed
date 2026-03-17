# Example CI Workflows

These are example GitHub Actions workflows for rig-seed projects.

## How to use

Copy the workflows you want into `.github/workflows/` in your forked repo:

```bash
mkdir -p .github/workflows
cp docs/examples/workflows/validate.yml .github/workflows/
cp docs/examples/workflows/lint-markdown.yml .github/workflows/
```

> **Note:** `.github/workflows/` is listed in `.evolve/IMMUTABLE.txt`, which
> means the evolution agent cannot modify CI once you set it up. This is
> intentional — CI pipelines should be human-controlled.

## Available workflows

| File | What it does |
|------|-------------|
| `validate.yml` | Runs `validate.sh` to check all required template files exist |
| `lint-markdown.yml` | Lints markdown files using markdownlint-cli2 |

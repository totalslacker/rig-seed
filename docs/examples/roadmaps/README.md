# Example Roadmaps

Starter ROADMAP.md files for common project types. Copy one to your project
root and customize it.

## Which one?

| Template | Best for | Key milestones |
|----------|----------|----------------|
| `cli-tool.md` | Command-line tools, dev utilities | Parse args → core logic → polish UX |
| `web-api.md` | REST/GraphQL services, backends | Endpoints → auth → deploy |
| `library.md` | Reusable packages, SDKs | Core API → docs → publish |

## How to use

```bash
cp docs/examples/roadmaps/cli-tool.md ROADMAP.md
# Edit: remove phases that don't apply, add your own items
```

The agent treats unchecked `- [ ]` items as available work. Keep the roadmap
honest — if something is done, check it off. If something is no longer
relevant, delete it rather than leaving it unchecked.

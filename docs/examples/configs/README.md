# Example Evolution Configs

Example `.evolve/config.toml` files for different evolution strategies.
Copy one to `.evolve/config.toml` in your fork, or use them as reference
to tune the defaults.

## Available Strategies

| File | Strategy | Best for |
|------|----------|----------|
| [conservative.toml](conservative.toml) | Slow, careful iteration (48h, 1 change) | Stable projects, production systems |
| [sprint.toml](sprint.toml) | Fast iteration (8h, 3 changes) | Prototyping, hackathons, early development |
| [issue-driven.toml](issue-driven.toml) | Community-focused (24h, prioritizes issues) | Open-source projects with active users |

## Usage

```bash
cp docs/examples/configs/conservative.toml .evolve/config.toml
```

## Configuration Reference

See [EVOLUTION.md](../../EVOLUTION.md) for full documentation of each setting.

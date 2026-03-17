# Project Specification

## What rig-seed Is

rig-seed is the **autonomous evolution template** for Gas Town. It is the
scaffold that other projects fork to get self-evolving behavior.

## Purpose

Provide a fork-and-go template repo that:
1. Contains all the state files an evolution agent needs (identity, specs,
   journal, roadmap, learnings, day counter)
2. Includes sensible defaults for evolution configuration
3. Documents the process clearly so new users can get started quickly
4. Serves as a working example of the evolution framework in action

## Requirements

- **Template completeness**: All state files present with clear documentation
- **Self-documenting**: README, CONTRIBUTING, and CLAUDE.md guide both humans
  and agents through the evolution process
- **Safety rails**: Immutable file protection, build-gated merges, revert-on-failure
- **Configurable**: Schedule, limits, and GitHub integration via `.evolve/config.toml`
- **Forkable**: Clone it, write SPECS.md, add as a rig, and it starts evolving

## Non-Goals

- rig-seed does NOT contain the Deacon plugin or formula code (those live in
  Gas Town itself)
- rig-seed does NOT prescribe a language or tech stack — that's chosen by
  each forked project during bootstrap

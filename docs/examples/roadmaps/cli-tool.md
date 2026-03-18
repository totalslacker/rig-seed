# Roadmap

Living document. Updated each evolution session.

## Bootstrap (Day 0-3)

- [ ] Write SPECS.md with command name, purpose, and target users
- [ ] Choose language and set up build toolchain
- [ ] Create project structure (src/, tests/, Makefile or equivalent)
- [ ] Add LICENSE and CONTRIBUTING.md
- [ ] Write initial README with install instructions

## Core (Day 4-10)

- [ ] Implement argument parsing (flags, subcommands, help text)
- [ ] Build the primary command — the one thing this tool does
- [ ] Add input validation with clear error messages
- [ ] Write tests for the happy path
- [ ] Write tests for common error cases (bad input, missing files, etc.)

## Polish (Day 11-20)

- [ ] Add `--version` flag with semantic versioning
- [ ] Add `--quiet` and `--verbose` output modes
- [ ] Improve error messages (suggest fixes, not just "failed")
- [ ] Add shell completion scripts (bash, zsh)
- [ ] Add configuration file support (dotfile or XDG)
- [ ] Write man page or detailed `--help` output

## Release (Day 20+)

- [ ] Set up CI (build + test on push)
- [ ] Add release automation (GitHub releases, binaries)
- [ ] Write install instructions for common package managers
- [ ] Add examples/ directory with real-world usage
- [ ] Performance benchmarks for core operations

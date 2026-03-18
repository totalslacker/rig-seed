# Roadmap

Living document. Updated each evolution session.

## Bootstrap (Day 0-3)

- [ ] Write SPECS.md with library purpose, target audience, and API surface
- [ ] Choose language and set up build toolchain
- [ ] Create project structure (src/, tests/, examples/)
- [ ] Add LICENSE and CONTRIBUTING.md
- [ ] Write initial README with install and basic usage

## Core API (Day 4-12)

- [ ] Design public API surface (types, functions, error handling)
- [ ] Implement core functionality
- [ ] Write unit tests for every public function
- [ ] Write tests for edge cases and error paths
- [ ] Add input validation at API boundaries

## Documentation (Day 12-18)

- [ ] API reference docs (docstrings / rustdoc / godoc / JSDoc)
- [ ] Getting started guide with a complete example
- [ ] Write 2-3 example programs in examples/ directory
- [ ] Add CHANGELOG.md and start tracking changes
- [ ] Migration guide (if replacing an existing library)

## Publish (Day 18+)

- [ ] Set up CI (build + test + lint across supported versions)
- [ ] Package for distribution (npm, PyPI, crates.io, etc.)
- [ ] Semantic versioning and release automation
- [ ] Performance benchmarks for critical operations
- [ ] Compatibility testing (older language versions, common consumers)
- [ ] Badge setup (CI status, version, downloads)

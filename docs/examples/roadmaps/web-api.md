# Roadmap

Living document. Updated each evolution session.

## Bootstrap (Day 0-3)

- [ ] Write SPECS.md with API purpose, target consumers, and data model
- [ ] Choose framework and set up project structure
- [ ] Add LICENSE and CONTRIBUTING.md
- [ ] Write initial README with local development setup

## Core (Day 4-12)

- [ ] Define data models / schema
- [ ] Implement CRUD endpoints for primary resource
- [ ] Add request validation (reject bad input early)
- [ ] Add structured error responses (consistent format, useful messages)
- [ ] Write integration tests for each endpoint
- [ ] Add database migrations (if applicable)

## Auth & Security (Day 12-18)

- [ ] Add authentication (API keys, JWT, or OAuth)
- [ ] Add authorization (who can access what)
- [ ] Rate limiting
- [ ] Input sanitization and injection prevention
- [ ] CORS configuration
- [ ] Security-focused tests (auth bypass, injection, etc.)

## Production Readiness (Day 18+)

- [ ] Add health check endpoint (`/health` or `/status`)
- [ ] Structured logging (JSON, request IDs)
- [ ] API documentation (OpenAPI/Swagger)
- [ ] Set up CI (build + test + lint on push)
- [ ] Dockerfile and deployment configuration
- [ ] Load testing for critical endpoints
- [ ] Monitoring and alerting setup

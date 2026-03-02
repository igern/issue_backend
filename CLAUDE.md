# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Backend API server for an issue/team management system built in **Gleam** (compiles to Erlang/OTP) using the **Wisp** web framework with SQLite database and S3-compatible storage.

## Commands

```bash
gleam test                      # Run all tests
gleam format --check src test   # Check code formatting
gleam format src test           # Auto-format code
gleam build                     # Compile
gleam run                       # Start server on port 8080

# Local development requires S3 mock
docker-compose up -d            # Start Adobe S3 mock on :9090
```

## Architecture

### Entry Flow
`issue_backend.gleam` → loads `.env` → initializes SQLite with foreign keys → seeds directory_status_types → starts Mist HTTP server on port 8080

### Context Pattern
All handlers receive a `Context` record containing: SQLite connection, S3 credentials, and bucket name. Passed through router middleware chain.

### Module Structure
Each domain (user, auth, team, directory, issue, etc.) follows this pattern:
- `{domain}_router.gleam` - HTTP route handlers
- `{domain}_service.gleam` - Business logic & database operations
- `inputs/{input}.gleam` - Request DTOs with validation
- `outputs/{output}.gleam` - Response DTOs with JSON serialization

### Router Composition
Routers are middleware functions composed in `router.gleam`. Each domain router wraps the next, handling its own routes and passing through unmatched requests.

### Authentication
- Access tokens: 5-minute JWT (HS256) via custom `gwt` wrapper
- Refresh tokens: 6-month database-stored tokens
- Auth guard: `auth_guards.require_jwt(request)` extracts and validates JWT

### Error Handling
`ServiceError` union type in `response_utils.gleam` centralizes all errors. Use `map_service_errors` to convert service results to HTTP responses.

### Database
SQLite with raw SQL via `sqlight` library. Schema defined in `database.gleam` with tables: users, profiles, teams, team_profiles, directories, directory_statuses, directory_status_types, issues, refresh_tokens.

## Testing

Tests use in-memory SQLite (`:memory:`) and S3 mock container. `test/utils.gleam` provides:
- `with_context` - Creates initialized test database
- Fixtures: `next_create_user`, `next_create_profile`, `next_create_team`, etc.
- `bearer_header()` - Creates auth header from JWT
- `equal()` and `expect_status_code()` - Test assertions

## Key Dependencies

- **wisp** - Web framework
- **mist** - HTTP server
- **sqlight** - SQLite wrapper
- **bucket** - S3 client
- **argus** - Password hashing (Argon2)
- **birl** - Date/time
- **youid** - UUID generation

# lg-postgres

PostgreSQL 16 database for LicenseGuard platform.

## Features

- PostgreSQL 16 Alpine
- Auto-initialization via init.sql
- RBAC test data seeding
- Healthcheck support
- Persistent volumes
- External network (lg-internal)

## Database Schema

The database includes:
- Users and authentication
- Organizational units (DAG structure)
- Roles and permissions (RBAC)
- Resources and access control
- Menu items and user preferences
- API keys and secrets
- Tours and user progress

See `init.sql` for complete schema.

## Environment Variables

- `POSTGRES_USER` - Database user (default: licenseguard)
- `POSTGRES_PASSWORD` - Database password (required)
- `POSTGRES_DB` - Database name (default: licenseguard)
- `POSTGRES_PORT` - Expose port (default: 5432)

## Standalone Usage

```bash
# Create network first
docker network create lg-internal

# Start PostgreSQL
docker-compose up -d

# Connect
docker exec -it lg-infra-postgres psql -U licenseguard -d licenseguard

# Or from host
psql -h localhost -U licenseguard -d licenseguard
```

## Integration with lg-development

This repository is designed to be cloned by the [lg-development](https://github.com/WolfgangM81/lg-development) orchestrator.

```bash
cd lg-development
make prepare   # Clones this repo to repos/lg-postgres
make start     # Starts PostgreSQL with other services
```

## Migrations

Migrations are stored in `migrations/` directory. Apply manually or use a migration tool.

## Test Data

- `seed_rbac_test_data.sql` - RBAC test data (users, roles, permissions)
- `rollback_rbac_test_data.sql` - Rollback test data

## License

MIT

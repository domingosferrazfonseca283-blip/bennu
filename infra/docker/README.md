# Bennu production stack

The production Compose stack provides PostgreSQL, Redis, the FastAPI API, and the React/Vite dashboard behind Nginx.

## Required environment

Set `BENNU_DB_PASSWORD`, `BENNU_OIDC_ISSUER`, and `BENNU_OIDC_AUDIENCE` before startup. `BENNU_OWNER_EMAIL` defaults to the configured Bennu Owner address.

## Validation

Run:

```bash
docker compose -f infra/docker/docker-compose.prod.yml config
docker compose -f infra/docker/docker-compose.prod.yml build
docker compose -f infra/docker/docker-compose.prod.yml up -d
docker compose -f infra/docker/docker-compose.prod.yml ps
```

The API exposes `/health`; the dashboard proxies `/health` and `/api/` to the API.

Database migrations must be run by the deployment process before serving application traffic.

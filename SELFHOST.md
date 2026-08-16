# Self-host with prebuilt images

This fork automatically builds mem0 self-hosted images via GitHub Actions and
pushes them to GitHub Container Registry (ghcr.io) — no need to build from source.

## Images

| Image | Description |
|-------|-------------|
| `ghcr.io/zwldarren/mem0:latest` | mem0 server (FastAPI, port 8000) |
| `ghcr.io/zwldarren/mem0-dashboard:latest` | mem0 dashboard (Next.js, port 3000) |

Tags: `latest`, `main-<commit sha>`, `<YYYYMMDD>` (for rollback by date).

## Auto-update mechanism

- **Sync Upstream** workflow: every day at 02:00 UTC pulls updates from
  `mem0ai/mem0` and merges them into `main`, then triggers an image rebuild.
  If the merge conflicts, it opens a PR for manual resolution.
- **Build Docker Images** workflow: rebuilds daily at 03:00 UTC, and also on
  every push to `main` or manual trigger.

## Usage

```bash
docker pull ghcr.io/zwldarren/mem0:latest
```

Production deployment example (server + postgres + dashboard):

```yaml
services:
  mem0:
    image: ghcr.io/zwldarren/mem0:latest
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - APP_DB_NAME=mem0_app
      - JWT_SECRET=${JWT_SECRET}
      - AUTH_DISABLED=${AUTH_DISABLED:-false}

  postgres:
    image: pgvector/pgvector:pg17
    environment:
      - POSTGRES_USER=${POSTGRES_USER:-postgres}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD in .env}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -q -d postgres -U ${POSTGRES_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - postgres_db:/var/lib/postgresql/data

  mem0-dashboard:
    image: ghcr.io/zwldarren/mem0-dashboard:latest
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
      - API_INTERNAL_URL=http://mem0:8000
      - NEXT_PUBLIC_INSTANCE_NAME=Mem0

volumes:
  postgres_db:
```

> Note: the server image installs dependencies from `server/requirements.txt`
> (see `server/Dockerfile`). For the full dev setup with the `mem0ai` package
> installed from source, refer to the upstream `server/docker-compose.yaml`.

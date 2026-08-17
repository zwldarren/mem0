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

## One-command deployment

The repo root contains a zero-config `docker-compose.yml` (server + postgres +
dashboard). No `.env` file is required:

```bash
docker compose up -d
```

The only hard requirement is an LLM API key — mem0's server refuses to start
without one. Export it, or create a `.env` file (see `.env.example`):

```bash
OPENAI_API_KEY=sk-... docker compose up -d
```

Defaults (all overridable via `.env` or shell env):

- `POSTGRES_PASSWORD=mem0-postgres` — change it for anything beyond local use
- `JWT_SECRET` — auto-generated on first start and persisted in the
  `mem0_history` volume, so tokens survive restarts
- Ports: API on `8000`, dashboard on `3000`; postgres is internal only

Services:

- API: http://localhost:8000 (docs at `/docs`)
- Dashboard: http://localhost:3000 — open it and follow the setup wizard

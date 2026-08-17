#!/bin/sh
set -e

# The production image (python:3.12-slim) lacks libpq, so pure-python psycopg
# cannot import. Install the binary wheel at startup (no-op once installed).
pip install -q psycopg-binary

# Generate and persist a JWT secret on first start, unless one is provided
# via the environment (e.g. JWT_SECRET in .env). Persisting it in the
# /app/history volume keeps tokens valid across restarts.
if [ -z "$JWT_SECRET" ]; then
  if [ ! -f /app/history/jwt_secret ]; then
    python3 -c "import base64, os; print(base64.b64encode(os.urandom(48)).decode())" > /app/history/jwt_secret
  fi
  export JWT_SECRET="$(cat /app/history/jwt_secret)"
fi

# Run DB migrations, then start the API (the image CMD does not migrate)
alembic upgrade head
exec uvicorn main:app --host 0.0.0.0 --port 8000

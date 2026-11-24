# cube-semantic-layer-lab

A local PostgreSQL 17 database with the Internet Sales tables from Microsoft AdventureWorksDW.

- [Database](db/README.md) — source, schema, and DBeaver connection settings
- [Scripts](scripts/README.md) — import, validation, and expected results

## Quick start

Use Docker Compose v2 and Python 3.9 or newer. The first run needs internet access. Run these commands from the repo root.

```sh
test -f .env || cp .env.example .env
```

Set `POSTGRES_PASSWORD` in `.env` if it is empty. Git ignores this file.

```sh
docker compose up -d --wait
python3 scripts/dataset.py import
python3 scripts/dataset.py validate
```

PostgreSQL listens on `127.0.0.1:5432` by default. Use `docker compose stop` to stop it and keep the data.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/cryptgeon-1?utm_medium=integration&utm_source=button&utm_campaign=cryptgeon)

# Cryptgeon on Railway

One-click Railway template for [Cryptgeon](https://github.com/cupcakearmy/cryptgeon) **2.9.3**, a self-hosted service for self-destructing, end-to-end encrypted notes and files (like PrivNote).

## What it deploys

| Service | Source | What it does |
|---|---|---|
| `Cryptgeon` | this repo, `app/` (official image `cupcakearmy/cryptgeon:2.9.3`, pinned by digest) | Web UI and API on a public Railway domain. Health check: `/api/live` (also checks Redis). |
| `Redis` | Railway's Redis | Stores the encrypted notes. On a volume at `/data` with append-only persistence, so notes survive a redeploy or restart; capped at 200 MB with LRU eviction. |

Notes are encrypted in the browser. The key is in the link's `#fragment` and never reaches the server, so Redis holds only ciphertext.

## Variables

| Variable | Service | Default | Notes |
|---|---|---|---|
| `REDIS` | Cryptgeon | `${{Redis.REDIS_URL}}` | Private-network Redis URL with the generated password. |
| `PORT` | Cryptgeon | `8000` | Port the app listens on. |

No prompts. Optional settings you can add to the `Cryptgeon` service later (defaults set by `app/start.sh`):

| Variable | Default here | Upstream default | Meaning |
|---|---|---|---|
| `SIZE_LIMIT` | `10 MiB` | `1 KiB` | Max note/file size (max `512 MiB`; keep it well under the service's RAM). |
| `MAX_VIEWS` | `100` | `100` | Max views a note can allow. |
| `MAX_EXPIRATION` | `10080` (7 days) | `360` | Max lifetime in minutes. |
| `ALLOW_ADVANCED` | `true` | `true` | `false` makes every note one-view-only. |
| `ALLOW_FILES` | `true` | `true` | `false` allows text notes only. |
| `ID_LENGTH`, `THEME_*`, `IMPRINT_URL`, `IMPRINT_HTML`, `VERBOSITY` | upstream | | See the [upstream README](https://github.com/cupcakearmy/cryptgeon#environment-variables). |

## Resources

Runs on Railway's Free plan: the app idles at a few MB of RAM and Redis at a few MB plus the notes you store. The start script sizes Tokio's worker threads to the service's CPU limit, waits up to 120 s for Redis on first boot, and exits non-zero if Redis is missing so Railway restarts it.

## Persistence and privacy

Upstream runs Redis in RAM only, so a restart deletes every note. This template keeps Redis on a volume (append-only file) so unread notes survive redeploys. Only encrypted data is written. If you prefer RAM-only, change the Redis service's start command to drop `--appendonly yes` and use `--save ""`.

## Updates

Every service except Redis builds from this repo. When we bump the Cryptgeon version on `main`, Railway shows deployers an "update available" notice; read `CHANGELOG.md` before applying it. Redis is Railway's own image and is not changed by template updates.

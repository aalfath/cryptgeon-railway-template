# Changelog

## 2.9.3-1 (2026-11-24)

- First release: Cryptgeon 2.9.3 (`cupcakearmy/cryptgeon:2.9.3@sha256:0344b34ba5375b9cb5bc6740fd35d075d2a581ddb0fcd30e0494c62ba3408e87`) with Railway Redis on a volume (append-only, 200 MB LRU cap).
- `app/start.sh`: listens on `$PORT`, waits for Redis, sizes Tokio threads to the CPU limit, defaults `SIZE_LIMIT=10 MiB` and `MAX_EXPIRATION=7 days`.

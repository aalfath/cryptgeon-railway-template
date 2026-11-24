#!/bin/sh
# Railway wrapper for Cryptgeon: listen on $PORT, size the runtime to the
# service's CPU limit, wait for Redis on first boot, then exec the server so
# that any crash exits non-zero and Railway's ON_FAILURE policy restarts it.
set -eu

PORT="${PORT:-8000}"
export LISTEN_ADDR="${LISTEN_ADDR:-0.0.0.0:${PORT}}"
export FRONTEND_PATH="${FRONTEND_PATH:-/app/frontend}"

# Sensible defaults for a public deploy (all can be overridden with variables).
export SIZE_LIMIT="${SIZE_LIMIT:-10 MiB}"
export MAX_VIEWS="${MAX_VIEWS:-100}"
export MAX_EXPIRATION="${MAX_EXPIRATION:-10080}"
export VERBOSITY="${VERBOSITY:-warn}"

# Railway shows every host CPU inside a 1 vCPU service: size Tokio to the cgroup.
cpus=""
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != "max" ] && [ "${period:-0}" -gt 0 ] 2>/dev/null; then
    cpus=$(( (quota + period - 1) / period ))
  fi
fi
[ -n "$cpus" ] || cpus=$(nproc 2>/dev/null || echo 2)
[ "$cpus" -ge 1 ] 2>/dev/null || cpus=1
[ "$cpus" -le 4 ] || cpus=4
export TOKIO_WORKER_THREADS="${TOKIO_WORKER_THREADS:-$cpus}"

if [ -z "${REDIS:-}" ] || [ "$REDIS" = "redis://redis/" ]; then
  echo "start.sh: REDIS is not set; point it at your Redis service, e.g. \${{Redis.REDIS_URL}}" >&2
  exit 1
fi

# Wait (up to 120 s) for Redis: on a fresh project the private DNS name and
# Redis itself can take a minute to come up. Cryptgeon panics if Redis is down.
hostport=$(printf '%s' "$REDIS" | sed -E 's#^[a-z]+://##; s#^[^@/]*@##; s#[/?].*$##')
host=$(printf '%s' "$hostport" | sed -E 's#^\[([^]]+)\].*#\1#; t; s#:[0-9]+$##')
rport=$(printf '%s' "$hostport" | sed -nE 's#.*:([0-9]+)$#\1#p')
rport="${rport:-6379}"
i=0
until nc -z -w 3 "$host" "$rport" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 40 ]; then
    echo "start.sh: Redis at $host:$rport not reachable after 120 s; exiting so Railway restarts the service" >&2
    exit 1
  fi
  sleep 3
done

echo "start.sh: Cryptgeon on $LISTEN_ADDR, size limit $SIZE_LIMIT, $TOKIO_WORKER_THREADS worker thread(s)"
exec /app/cryptgeon

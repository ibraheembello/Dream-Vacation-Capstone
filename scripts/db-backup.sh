#!/usr/bin/env bash
# =============================================================================
# db-backup.sh: dump the PostgreSQL database to a compressed, timestamped file
# and prune backups older than the retention window.
#
# Runs against the Postgres container started by docker-compose (default name
# "dvapp-db"). Meant to be run by hand or from cron, e.g. daily at 02:00:
#   0 2 * * *  /home/ubuntu/app/scripts/db-backup.sh >> /var/log/dream-vacations/backup.log 2>&1
#
# Idempotent in effect: each run writes one new dated dump and removes expired
# ones; re-running never corrupts existing backups.
#
# Config via environment (all optional):
#   DB_CONTAINER    Postgres container name        (default: dvapp-db)
#   POSTGRES_USER   database user                  (default: dreamuser)
#   POSTGRES_DB     database name                  (default: dreamvacations)
#   BACKUP_DIR      where dumps are written        (default: ./backups)
#   RETENTION_DAYS  delete dumps older than N days (default: 7)
# =============================================================================
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-dvapp-db}"
POSTGRES_USER="${POSTGRES_USER:-dreamuser}"
POSTGRES_DB="${POSTGRES_DB:-dreamvacations}"
BACKUP_DIR="${BACKUP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

log() { printf '\033[1;32m[backup]\033[0m %s\n' "$*"; }

# Timestamp is derived from the system clock; no external state needed.
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTFILE="$BACKUP_DIR/${POSTGRES_DB}-${STAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

if ! docker ps --format '{{.Names}}' | grep -qx "$DB_CONTAINER"; then
  echo "Database container '$DB_CONTAINER' is not running" >&2
  exit 1
fi

log "Dumping '$POSTGRES_DB' from container '$DB_CONTAINER' -> $OUTFILE"
# pg_dump inside the container; compress on the host. Write to a temp file first
# so a failure never leaves a truncated .sql.gz behind.
TMPFILE="${OUTFILE}.partial"
if docker exec "$DB_CONTAINER" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$TMPFILE"; then
  mv "$TMPFILE" "$OUTFILE"
  log "Backup complete: $(du -h "$OUTFILE" | cut -f1)"
else
  rm -f "$TMPFILE"
  echo "pg_dump failed" >&2
  exit 1
fi

log "Pruning backups older than ${RETENTION_DAYS} day(s) ..."
find "$BACKUP_DIR" -name "${POSTGRES_DB}-*.sql.gz" -type f -mtime "+${RETENTION_DAYS}" -print -delete

log "Current backups:"
ls -1sh "$BACKUP_DIR"/"${POSTGRES_DB}"-*.sql.gz 2>/dev/null || log "  (none yet)"

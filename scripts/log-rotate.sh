#!/usr/bin/env bash
# =============================================================================
# log-rotate.sh: install log rotation for the app so disk never fills up.
#
# Two things get rotated:
#   1. App logs under /var/log/dream-vacations/*.log via a logrotate policy
#      (daily, 14 days kept, compressed).
#   2. Docker container logs, by capping json-file driver size in daemon.json
#      (10 MB x 3 files per container).
#
# Idempotent: writing the same config twice is a no-op, and the Docker daemon is
# only restarted when daemon.json actually changed.
#
# Usage:  sudo ./scripts/log-rotate.sh
# =============================================================================
set -euo pipefail

log() { printf '\033[1;33m[logrotate]\033[0m %s\n' "$*"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || { echo "run as root or install sudo" >&2; exit 1; }
  SUDO="sudo"
fi

APP_LOG_DIR="/var/log/dream-vacations"
LOGROTATE_CONF="/etc/logrotate.d/dream-vacations"
DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

# --- 1. App log rotation policy ---------------------------------------------
$SUDO mkdir -p "$APP_LOG_DIR"

$SUDO tee "$LOGROTATE_CONF" >/dev/null <<'CONF'
/var/log/dream-vacations/*.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
CONF
log "Installed logrotate policy at $LOGROTATE_CONF"

# Validate the policy (debug mode makes no changes).
$SUDO logrotate --debug "$LOGROTATE_CONF" >/dev/null && log "logrotate policy is valid."

# --- 2. Cap Docker container log size ---------------------------------------
DESIRED_DAEMON='{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}'

$SUDO mkdir -p /etc/docker
NEEDS_RESTART=0
if [ ! -f "$DOCKER_DAEMON_JSON" ] || ! diff -q <(printf '%s\n' "$DESIRED_DAEMON") "$DOCKER_DAEMON_JSON" >/dev/null 2>&1; then
  printf '%s\n' "$DESIRED_DAEMON" | $SUDO tee "$DOCKER_DAEMON_JSON" >/dev/null
  NEEDS_RESTART=1
  log "Wrote Docker log-rotation config to $DOCKER_DAEMON_JSON"
else
  log "Docker log-rotation config already current; skipping."
fi

if [ "$NEEDS_RESTART" -eq 1 ] && command -v systemctl >/dev/null 2>&1; then
  log "Restarting Docker to apply new log settings ..."
  $SUDO systemctl restart docker
fi

log "Done. New container logs are capped at 10MB x 3; app logs rotate daily (14 kept)."

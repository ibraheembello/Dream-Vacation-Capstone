#!/usr/bin/env bash
# =============================================================================
# setup-env.sh: prepare a host to run the Dream Vacation App.
#
# Installs Docker Engine + the Compose plugin (if missing) and creates a local
# .env from .env.example (if missing). Safe to run repeatedly: every step checks
# state first and skips work that is already done (idempotent).
#
# Usage:  ./scripts/setup-env.sh
# Target: Ubuntu / Debian (uses apt). Run as a sudo-capable user.
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Use sudo only when we are not already root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  have sudo || { echo "sudo not found and not running as root" >&2; exit 1; }
  SUDO="sudo"
fi

install_docker() {
  if have docker; then
    log "Docker already installed ($(docker --version)); skipping."
    return
  fi
  log "Installing Docker Engine from the official apt repository ..."
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y
  $SUDO apt-get install -y ca-certificates curl gnupg
  $SUDO install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
  fi
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
  $SUDO apt-get update -y
  $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  $SUDO systemctl enable --now docker
}

add_user_to_docker_group() {
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    log "User '$USER' already in the docker group; skipping."
  else
    log "Adding '$USER' to the docker group (log out/in to take effect) ..."
    $SUDO usermod -aG docker "$USER"
  fi
}

create_env_file() {
  if [ -f "$REPO_ROOT/.env" ]; then
    log ".env already exists; leaving it untouched."
  else
    log "Creating .env from .env.example (edit the secrets before deploying) ..."
    cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
  fi
}

install_docker
add_user_to_docker_group
create_env_file

log "Done. Bring the stack up with:  docker compose up -d --build"

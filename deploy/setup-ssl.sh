#!/usr/bin/env bash
# =============================================================================
# setup-ssl.sh: obtain and install a Let's Encrypt certificate for the app and
# enable automatic renewal. Run ON the EC2 host after the domain's A record
# already resolves to this server (Certbot uses an HTTP-01 challenge on port 80).
#
# Nginx and Certbot are installed at boot by infra/user-data.sh; this script just
# drives the certificate issuance, which needs live DNS and so can't run at boot.
#
# Usage:  sudo DOMAIN=dream-vacations.duckdns.org EMAIL=you@example.com ./deploy/setup-ssl.sh
# =============================================================================
set -euo pipefail

DOMAIN="${DOMAIN:?DOMAIN is required (e.g. dream-vacations.duckdns.org)}"
EMAIL="${EMAIL:?EMAIL is required for certificate expiry notices}"

log() { printf '\033[1;36m[ssl]\033[0m %s\n' "$*"; }

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# Make sure the reverse proxy answers for this hostname before asking for a cert.
$SUDO sed -i "s/server_name .*/server_name ${DOMAIN};/" /etc/nginx/sites-available/dream-vacations
$SUDO nginx -t && $SUDO systemctl reload nginx

log "Requesting certificate for ${DOMAIN} ..."
# --redirect makes Certbot add the HTTP->HTTPS redirect; --nginx edits the site
# in place and reloads. --keep avoids re-issuing if a valid cert already exists.
$SUDO certbot --nginx \
  -d "${DOMAIN}" \
  --non-interactive --agree-tos --redirect --keep-until-expiring \
  -m "${EMAIL}"

# certbot installs a systemd timer (certbot.timer) that renews twice daily.
log "Enabling automatic renewal timer ..."
$SUDO systemctl enable --now certbot.timer

log "Renewal dry run (does not touch the live cert):"
$SUDO certbot renew --dry-run

log "SSL is live. Visit: https://${DOMAIN}/"

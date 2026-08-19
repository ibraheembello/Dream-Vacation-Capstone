#!/usr/bin/env bash
# Runs once on first boot. Installs Docker Engine + the Compose plugin from
# Docker's official apt repo and lets the ubuntu user run docker without sudo.
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu

# App working directory the deploy job copies files into.
mkdir -p /home/ubuntu/app
chown -R ubuntu:ubuntu /home/ubuntu/app

# --- Host Nginx reverse proxy + Certbot (for Let's Encrypt SSL) ----------------
# Nginx terminates HTTP/HTTPS on 80/443 and forwards to the app containers, which
# are published on loopback only (frontend 127.0.0.1:8080, backend 127.0.0.1:3001).
# Certbot later upgrades this HTTP site to HTTPS with automatic renewal.
apt-get install -y nginx certbot python3-certbot-nginx

cat >/etc/nginx/sites-available/dream-vacations <<'NGINX'
# Dream Vacations reverse proxy. Certbot injects the SSL server block and the
# HTTP->HTTPS redirect on top of this once a certificate is issued.
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # API traffic goes to the NodeJS backend container.
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Everything else is served by the React frontend container.
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/dream-vacations /etc/nginx/sites-enabled/dream-vacations
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable --now nginx && systemctl reload nginx

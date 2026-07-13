#!/usr/bin/env bash
# Sellora.ai — fresh VPS bootstrap for the self-hosted n8n box.
# Target: a fresh Ubuntu 24.04 LTS droplet/instance (DigitalOcean or Hetzner).
# Run as root, once, right after the VPS is provisioned:
#   ssh root@<vps-ip>
#   curl -fsSL -o bootstrap.sh <raw-url-once-this-is-in-your-repo>
#   chmod +x bootstrap.sh && ./bootstrap.sh
#
# Safe to re-run; each step is idempotent.

set -euo pipefail

echo "==> Updating base packages"
apt-get update -y
apt-get upgrade -y

echo "==> Installing baseline tools"
apt-get install -y ca-certificates curl gnupg ufw fail2ban unattended-upgrades

echo "==> Enabling unattended security updates"
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "==> Configuring the firewall (SSH, HTTP, HTTPS only)"
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Enabling fail2ban against SSH brute-forcing"
systemctl enable --now fail2ban

echo "==> Installing Docker Engine + Compose plugin"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Creating a non-root deploy user (skip if it already exists)"
if ! id -u deploy >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" deploy
  usermod -aG docker deploy
  mkdir -p /home/deploy/.ssh
  cp /root/.ssh/authorized_keys /home/deploy/.ssh/ 2>/dev/null || true
  chown -R deploy:deploy /home/deploy/.ssh
  chmod 700 /home/deploy/.ssh
  chmod 600 /home/deploy/.ssh/authorized_keys 2>/dev/null || true
fi

echo "==> Done. Log back in as 'deploy' from now on:"
echo "    ssh deploy@<vps-ip>"
echo "Then copy the infra/ folder onto the box and:"
echo "    cd infra && cp .env.example .env  # fill in real values"
echo "    docker compose up -d"

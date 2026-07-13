# Sellora.ai — n8n Infrastructure

Self-hosted n8n (Community Edition), not n8n Cloud. Cloud's execution-based
billing doesn't scale here — the feed poller alone runs 8,640 executions/month
on its own, before any real seller traffic exists.

## What's in this folder

| File | Purpose |
|---|---|
| `docker-compose.yml` | n8n + its own Postgres backing store + Caddy (reverse proxy / automatic HTTPS) |
| `Caddyfile` | Reverse proxy config — HTTPS cert issuance is automatic, no certbot cron needed |
| `.env.example` | Template for the real `.env` (never commit the filled-in version) |
| `bootstrap.sh` | One-time fresh-VPS setup: firewall, fail2ban, auto security updates, Docker |

## Deploy, step by step

1. **Provision the VPS** — a DigitalOcean Droplet or Hetzner Cloud instance,
   Ubuntu 24.04 LTS, 2 vCPU / 4GB RAM is a reasonable starting size for Week 0.
2. **Point DNS** — create an A record for the subdomain n8n will live on
   (e.g. `n8n.sellora.ai`) pointing at the VPS's IP. Do this before starting
   Caddy, or Let's Encrypt issuance will fail.
3. **Bootstrap the box:**
   ```bash
   ssh root@<vps-ip>
   # copy bootstrap.sh onto the box (scp, or paste + curl once it's in your repo), then:
   chmod +x bootstrap.sh && ./bootstrap.sh
   ```
4. **Copy this `infra/` folder onto the box** (as the `deploy` user bootstrap.sh
   created), then:
   ```bash
   cp .env.example .env
   nano .env   # fill in N8N_HOST, LETSENCRYPT_EMAIL, TIMEZONE, POSTGRES_*, N8N_ENCRYPTION_KEY
   # generate the encryption key with:
   openssl rand -base64 32
   docker compose up -d
   ```
5. **Visit `https://<N8N_HOST>`** — n8n's first-run screen creates the
   instance owner account (email + password). There's no basic-auth
   environment variable in current n8n versions; this in-app setup is the
   only login path now.
6. **Import the 8 workflows** from `../workflows/` via the n8n UI
   (Workflows → Import from File) once you're in.

## Notes for later, not needed today

- Each workflow currently authenticates to Supabase with an `apikey`/
  `Authorization` header value typed directly into the node parameters
  (visible in the JSON exports), rather than stored in n8n's own Credentials
  system. The key itself is Supabase's `sb_publishable_...` tier — by
  Supabase's design that's safe to expose client-side, so this isn't a
  secret leak, but hardcoding it still makes rotation harder and sets a
  pattern worth breaking before any workflow needs a higher-privilege
  (`sb_secret_...`) key, which must never be typed into workflow JSON the
  same way. Move both into n8n Credentials once Week 1's tables exist.
- `EXECUTIONS_DATA_SAVE_ON_SUCCESS` / pruning settings aren't set here, so
  n8n's defaults apply — worth revisiting once real execution volume exists,
  not before.

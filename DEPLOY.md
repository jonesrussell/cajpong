# Deploying to pong.northcloud.biz

## Deployment methods

- **CI/CD (recommended):** Push to `main` triggers GitHub Actions: build Flutter web, build Docker image, push to GHCR, SSH to server and run `docker compose pull && docker compose up -d`. See [CI/CD and Docker](#cicd-and-docker) below.
- **Manual (legacy):** Use [deploy.sh](deploy.sh) to build and rsync, then pm2 on the server. See [Deploy from your machine (legacy)](#deploy-from-your-machine-legacy).

---

## CI/CD and Docker

### One-time setup on the server

1. **Docker** — Install Docker Engine and Docker Compose (v2 plugin). Add user `jones` to the `docker` group so compose runs without sudo.

2. **Compose-only layout** — Create `~/cajpong/` and place **only**:
   - `docker-compose.yml` (copy from this repo; CI does not overwrite it, so update it manually if the file changes in the repo).
   - `.env` is written by CI on every deploy with `IMAGE_TAG=<sha>`; you do not need to create it by hand.

3. **SSH** — GitHub Actions deploys via SSH. Add the deploy key’s public part to `~/.ssh/authorized_keys` for `jones` on the deploy host. In the repo: **Settings → Secrets and variables → Actions**, add:
   - `SSH_HOST` — e.g. `pong.northcloud.biz`
   - `SSH_USER` — e.g. `jones`
   - `SSH_PRIVATE_KEY` — private key for the deploy key.

4. **Caddy** — Reverse proxy and TLS (Let’s Encrypt) for `pong.northcloud.biz`. Caddy proxies to `127.0.0.1:3000` only (app port not exposed publicly). Run once:

   ```bash
   ssh jones@pong.northcloud.biz
   sudo apt install -y caddy
   sudo cp ~/cajpong/Caddyfile /etc/caddy/Caddyfile
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl restart caddy
   ```

   (Copy the Caddyfile to the server first, or clone the repo once to get it then remove the clone.)

5. **GHCR** — If the image `ghcr.io/jonesrussell/cajpong` is **private**, log in to ghcr.io on the server (e.g. `docker login ghcr.io` with a PAT that has `read:packages`). For a **public** image, no login.

### What CI does on push to `main`

1. Builds Flutter web with `SERVER_URL=https://pong.northcloud.biz`.
2. Builds the Docker image (Node server + Flutter static assets), tags as `:latest` and `:<sha>`.
3. Pushes the image to GitHub Container Registry (ghcr.io).
4. SSHs to the server, runs:
   - `cd ~/cajpong`
   - `echo "IMAGE_TAG=<sha>" > .env`
   - `docker compose pull`
   - `docker compose up -d`

### Rollback

On the server, set `IMAGE_TAG` to a previous commit SHA, then redeploy:

```bash
ssh jones@pong.northcloud.biz
cd ~/cajpong
# Edit .env and set IMAGE_TAG to the desired SHA (e.g. abc1234)
docker compose pull
docker compose up -d
```

---

## Deploy from your machine (legacy)

From the repo root:

```bash
./deploy.sh
```

This builds the Flutter web client with `SERVER_URL=https://pong.northcloud.biz`, then rsyncs the project to `~/cajpong` on the server.

To install dependencies and start (or restart) the app with pm2:

```bash
./deploy.sh restart
```

## Overriding defaults (legacy deploy)

- `DEPLOY_HOST` — default `jones@pong.northcloud.biz`
- `DEPLOY_PATH` — default `~/cajpong`
- `SERVER_URL` — default `https://pong.northcloud.biz` (used at Flutter build time)

Example:

```bash
SERVER_URL=https://pong.example.com DEPLOY_PATH=/var/www/cajpong ./deploy.sh restart
```

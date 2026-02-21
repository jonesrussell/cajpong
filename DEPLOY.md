# Deploying to pong.northcloud.biz

## Deployment methods

- **CI/CD (recommended):** Push to `main` triggers GitHub Actions: build Flutter web, build Docker image, push to GHCR, SSH to server and run `docker compose pull && docker compose up -d`. See [CI/CD and Docker](#cicd-and-docker) below.
- **Manual (legacy):** Use [deploy.sh](deploy.sh) to build and rsync, then pm2 on the server. See [Deploy from your machine (legacy)](#deploy-from-your-machine-legacy).

---

## CI/CD and Docker

### One-time setup on the server

Repo/CI handles: GitHub secrets (`SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`), copying `docker-compose.yml` and the deploy public key to the server (e.g. into `/tmp/` or `~/cajpong/`). You only run the following **sudo** commands on the server.

**1. Deployer SSH + Docker + /opt/cajpong** (after deploy key is on server at `/tmp/cajpong_deploy.pub` and `docker-compose.yml` at `/tmp/docker-compose.yml` — repo or automation copies them there):

```bash
sudo -u deployer mkdir -p /home/deployer/.ssh
sudo -u deployer chmod 700 /home/deployer/.ssh
sudo cat /tmp/cajpong_deploy.pub | sudo tee -a /home/deployer/.ssh/authorized_keys
sudo chown deployer:deployer /home/deployer/.ssh/authorized_keys
sudo -u deployer chmod 600 /home/deployer/.ssh/authorized_keys
sudo usermod -aG docker deployer
sudo mkdir -p /opt/cajpong
sudo chown deployer:deployer /opt/cajpong
sudo -u deployer cp /tmp/docker-compose.yml /opt/cajpong/
```

**2. Caddy** (pong.northcloud.biz; Caddyfile lives in `/opt/cajpong/Caddyfile`). After the repo Caddyfile is on the server at `/tmp/Caddyfile`:

```bash
sudo apt install -y caddy
sudo -u deployer cp /tmp/Caddyfile /opt/cajpong/Caddyfile
sudo chmod o+rx /opt/cajpong
sudo chmod o+r /opt/cajpong/Caddyfile
# Ensure main Caddyfile imports /opt/cajpong (replace old cajpong import if present):
sudo sed -i 's|import /home/jones/cajpong/Caddyfile|import /opt/cajpong/Caddyfile|g' /etc/caddy/Caddyfile
sudo sed -i 's|import /etc/caddy/cajpong.Caddyfile|import /opt/cajpong/Caddyfile|g' /etc/caddy/Caddyfile
grep -q 'import /opt/cajpong/Caddyfile' /etc/caddy/Caddyfile || echo 'import /opt/cajpong/Caddyfile' | sudo tee -a /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl restart caddy
```

**3. (Optional) Free port 3000** if something else is using it:

```bash
sudo fuser -k 3000/tcp
```

**4. (Optional) First run under deployer** if the app was under jones (replace `SHA` with latest image tag):

```bash
sudo -u jones bash -c 'cd ~/cajpong && docker compose down'
sudo -u deployer bash -c 'cd /opt/cajpong && echo "IMAGE_TAG=SHA" > .env && docker compose pull && docker compose up -d'
```

Notes: GHCR — if the image is private, log in as deployer on the server (`docker login ghcr.io`). DNS — point `pong.northcloud.biz` to the same IP as the deploy host.

### What CI does on push to `main`

1. Builds Flutter web with `SERVER_URL=https://pong.northcloud.biz`.
2. Builds the Docker image (Node server + Flutter static assets), tags as `:latest` and `:<sha>`.
3. Pushes the image to GitHub Container Registry (ghcr.io).
4. SSHs to the server, runs:
   - `cd /opt/cajpong`
   - `echo "IMAGE_TAG=<sha>" > .env`
   - `docker compose pull`
   - `docker compose up -d`

### Rollback

On the server, set `IMAGE_TAG` to a previous commit SHA, then redeploy:

```bash
ssh deployer@northcloud.biz
cd /opt/cajpong
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

This builds the Flutter web client with `SERVER_URL=https://pong.northcloud.biz`, then rsyncs the project to the server (default `~/cajpong`; set `DEPLOY_PATH` to use e.g. `/opt/cajpong`).

To install dependencies and start (or restart) the app with pm2:

```bash
./deploy.sh restart
```

## Overriding defaults (legacy deploy)

- `DEPLOY_HOST` — default `jones@pong.northcloud.biz`
- `DEPLOY_PATH` — default `~/cajpong` (legacy); CI uses `/opt/cajpong`
- `SERVER_URL` — default `https://pong.northcloud.biz` (used at Flutter build time)

Example:

```bash
SERVER_URL=https://pong.example.com DEPLOY_PATH=/var/www/cajpong ./deploy.sh restart
```

# Deploying to pong.northcloud.biz

## One-time setup on the server

1. **Node** (v18+) — for the app.
2. **Caddy** — reverse proxy and TLS (Let's Encrypt) for `pong.northcloud.biz`. The repo includes a `Caddyfile`; after deploy, install Caddy (if needed) and load the config. Run these **once on the server**:

   ```bash
   ssh jones@pong.northcloud.biz

   sudo apt install -y caddy
   sudo cp ~/cajpong/Caddyfile /etc/caddy/Caddyfile
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl restart caddy
   ```

   Caddy proxies HTTPS to the app on `localhost:3000`. Socket.IO WebSockets work through the proxy by default.

## Deploy from your machine

From the repo root:

```bash
./deploy.sh
```

This builds the **Flutter web** client with `SERVER_URL=https://pong.northcloud.biz`, then rsyncs the project (excluding `node_modules`, `.git`, `.env`, and Flutter build artifacts) to `~/cajpong` on the server.

To install dependencies and start (or restart) the app on the server:

```bash
./deploy.sh restart
```

That runs on the host: `npm install` then `pm2 restart cajpong` (or `pm2 start npm --name cajpong -- start` if not already running).

## Running the app on the server

After syncing, on the server:

```bash
cd ~/cajpong
npm install
npm start
```

The server listens on `PORT` (default 3000). It serves the static Flutter web client from `cajpong_flutter/build/web` when that directory exists (i.e. after a deploy that built Flutter web). Caddy in front handles HTTPS and proxies to this port.

## Overriding defaults

- `DEPLOY_HOST` — default `jones@pong.northcloud.biz`
- `DEPLOY_PATH` — default `~/cajpong`
- `SERVER_URL` — default `https://pong.northcloud.biz` (used at Flutter build time so the client connects to this URL)

Example:

```bash
SERVER_URL=https://pong.example.com DEPLOY_PATH=/var/www/cajpong ./deploy.sh restart
```

# Deploying to pong.northcloud.biz

## One-time setup on the server

1. **Node** (v18+) — for the app.
2. **Caddy** — reverse proxy and TLS (Let's Encrypt) for `pong.northcloud.biz`. The repo includes a `Caddyfile`; after deploy, install Caddy (if needed) and load the config. Run these **once on the server** (sudo will prompt for your password):

   ```bash
   ssh jones@pong.northcloud.biz

   # Install Caddy (Debian/Ubuntu) if not already installed
   sudo apt install -y caddy

   # Use the Caddyfile from the deployed app and restart Caddy
   sudo cp ~/cajpong/Caddyfile /etc/caddy/Caddyfile
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl restart caddy
   ```

   Caddy will obtain a certificate for `pong.northcloud.biz` and proxy HTTPS to the app on `localhost:3000`. Socket.IO WebSockets work through the proxy by default. If `reload` fails after a config change, use `restart` instead. After the first deploy that adds or changes the Caddyfile, run the `sudo cp`, `sudo caddy validate`, and `sudo systemctl restart caddy` steps again.

   **Optional — passwordless Caddy updates:** To let deploy automation update Caddy without a sudo password, install the included sudoers fragment once on the server:  
   `sudo cp ~/cajpong/deploy/sudoers.cajpong /etc/sudoers.d/cajpong && sudo chmod 440 /etc/sudoers.d/cajpong && sudo visudo -c`

## Deploy from your machine

From the repo root:

```bash
./deploy.sh
```

This builds the client with `VITE_SERVER_URL=https://pong.northcloud.biz`, then rsyncs the project (excluding `node_modules`, `.git`, `.env`) to `~/cajpong` on the server.

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

The server listens on `PORT` (default 3000). Caddy in front handles HTTPS and proxies to this port.

## Overriding defaults

- `DEPLOY_HOST` — default `jones@pong.northcloud.biz`
- `DEPLOY_PATH` — default `~/cajpong`
- `VITE_SERVER_URL` — default `https://pong.northcloud.biz` (used at build time so the client connects to this URL)

Example:

```bash
VITE_SERVER_URL=https://pong.example.com DEPLOY_PATH=/var/www/cajpong ./deploy.sh restart
```

# Deploying to pong.northcloud.biz

## One-time setup on the server

SSH to the host and install Node (v18+), then optionally [pm2](https://pm2.keymetrics.io/) to keep the app running:

```bash
ssh jones@pong.northcloud.biz
# Install Node (e.g. via nvm or system package manager)
# Optional: npm install -g pm2
```

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

The server listens on `PORT` (default 3000), serves the static client from `dist/`, and handles Socket.IO. To listen on 80 or use HTTPS, put the app behind nginx (or another reverse proxy) or set `PORT=80` and run with appropriate privileges.

## Overriding defaults

- `DEPLOY_HOST` — default `jones@pong.northcloud.biz`
- `DEPLOY_PATH` — default `~/cajpong`
- `VITE_SERVER_URL` — default `https://pong.northcloud.biz` (used at build time so the client connects to this URL)

Example:

```bash
VITE_SERVER_URL=https://pong.example.com DEPLOY_PATH=/var/www/cajpong ./deploy.sh restart
```

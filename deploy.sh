#!/usr/bin/env bash
# Deploy CajPong to jones@pong.northcloud.biz
# Usage: ./deploy.sh [restart]
#   restart - after syncing, SSH and run npm install then pm2 restart cajpong (or pm2 start)
#
# Build the client with VITE_SERVER_URL so the app connects to the deployed server.
# Set DEPLOY_HOST, DEPLOY_PATH, or VITE_SERVER_URL to override defaults.

set -e
HOST="${DEPLOY_HOST:-jones@pong.northcloud.biz}"
PATH_ON_HOST="${DEPLOY_PATH:-~/cajpong}"
PUBLIC_URL="${VITE_SERVER_URL:-https://pong.northcloud.biz}"

echo "Building client with VITE_SERVER_URL=$PUBLIC_URL"
VITE_SERVER_URL="$PUBLIC_URL" npm run build

echo "Syncing to $HOST:$PATH_ON_HOST"
rsync -avz \
  --exclude node_modules \
  --exclude .git \
  --exclude .env \
  --exclude '*.log' \
  . \
  "$HOST:$PATH_ON_HOST/"

if [[ "${1:-}" == "restart" ]]; then
  echo "Installing deps and restarting on host..."
  ssh "$HOST" "cd $PATH_ON_HOST && npm install && (pm2 restart cajpong 2>/dev/null || (pm2 delete cajpong 2>/dev/null; pm2 start npm --name cajpong -- start))"
fi

echo "Done. App URL: $PUBLIC_URL"

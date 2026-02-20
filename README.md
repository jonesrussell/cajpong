# CajPong

Two-player Pong: **Flutter + Flame** client (iOS, Android, Web) and **Node.js Socket.IO** server for online multiplayer.

## Quick start

**Client** (from `cajpong_flutter/`):

```bash
cd cajpong_flutter
flutter pub get
flutter run
```

Use `-d chrome` for web, or a device id for mobile/desktop.

**Server** (for online play, from repo root):

```bash
npm install
npm run dev:server
```

The Flutter app defaults to `http://localhost:3000` for the server URL.

## Repo layout

- **cajpong_flutter/** — Flutter + Flame game (see [cajpong_flutter/README.md](cajpong_flutter/README.md))
- **server/** — Socket.IO matchmaking and game loop (TypeScript, Node)
- **CLAUDE.md** — Project notes and commands for Claude
- **DEPLOY.md** — Deploy to pong.northcloud.biz

## Deploy

```bash
./deploy.sh          # Build Flutter web + rsync
./deploy.sh restart  # Same + npm install and pm2 restart on host
```

See [DEPLOY.md](DEPLOY.md) for server setup and overrides.

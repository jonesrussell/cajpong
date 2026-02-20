# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CajPong is a two-player Pong game built with **Flutter + Flame**. The client runs on iOS, Android, and Web. A **Node.js Socket.IO server** provides matchmaking and authoritative game state for online play.

## Commands

**Flutter client** (from `cajpong_flutter/`):

- `flutter pub get` — Resolve dependencies
- `flutter run` — Run on default device (use `-d chrome` for web, `-d linux` for desktop)
- `flutter build web` — Production web build to `cajpong_flutter/build/web/`
- `flutter build apk` / `flutter build ios` — Mobile builds

**Server** (from repo root):

- `npm run dev:server` — Run game server (Socket.IO + matchmaking) locally
- `npm start` — Run game server (production; serves static client from `cajpong_flutter/build/web` if present)
- `npm run lint` — Lint server with ESLint 9 (flat config)

**Deploy:**

- `./deploy.sh [restart]` — Build Flutter web, rsync to jones@pong.northcloud.biz; use `restart` to npm install + pm2 on host (see DEPLOY.md)

## Architecture

**Client:** `cajpong_flutter/` — Single Flame game (`PongGame`), components (paddles, ball, walls, touch zones), overlays for menu/matchmaking/game over. Local play runs pure Dart game step; online play receives `game_state` from server and sends `input` (up/down). Two-thumb touch: left half = left paddle, right half = right paddle.

**Server:** `server/index.ts` — Socket.IO matchmaking and 60 Hz room tick. Game logic in `server/game/` (gameState.ts, gameLogic.ts, constants.ts). Serves static files from `cajpong_flutter/build/web` when present.

**Protocol:** `find_match` → `matched` (side, roomId) → client sends `input` (up, down); server broadcasts `game_state` (state, tick), `opponent_left` on disconnect.

## Key paths

- `cajpong_flutter/lib/game/pong_game.dart` — Root Flame game
- `cajpong_flutter/lib/game/game_loop.dart` — Pure step/getWinner (matches server logic)
- `cajpong_flutter/lib/services/pong_socket_service.dart` — Socket.IO client
- `server/index.ts` — HTTP + Socket.IO server
- `server/game/` — Server-side game state and step

## Server URL

Flutter app uses `--dart-define=SERVER_URL=...` at build time (default `http://localhost:3000`). Deploy sets this to the production URL.

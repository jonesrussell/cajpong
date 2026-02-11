# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CajPong is a two-player Pong game built with Phaser 3 and Vite.

## Commands

- `npm run dev` — Start Vite dev server with hot reload
- `npm run build` — Production build to `dist/`
- `npm run typecheck` — Type-check with TypeScript (no emit)
- `npm run test` — Run tests in watch mode (Vitest)
- `npm run test:run` — Run tests once
- `npm run lint` — Lint with ESLint 9 (flat config)
- `npm run dev:server` — Run game server (Socket.IO + matchmaking) locally
- `npm start` — Run game server (for production; serves static client from `dist/` if present)
- `./deploy.sh [restart]` — Build and rsync to jones@pong.northcloud.biz; use `restart` to npm install + pm2 on host (see DEPLOY.md)

## Architecture

**Entry point:** `index.html` loads `src/main.ts`, which creates the Phaser game instance.

**Key files:**
- `src/main.ts` — Phaser.Game config (arcade physics, no gravity, scale-to-fit)
- `src/constants.ts` — All game tuning values (dimensions, speeds, sizes, colors)
- `src/scenes/Game.ts` — Single scene containing all gameplay logic

The project uses **TypeScript**. Run `npm run typecheck` to type-check without building.

**Tests:** Vitest in `src/**/*.test.ts`. Pure game logic lives in `src/gameLogic.ts` (e.g. `getWinner`) and is used by the Game scene so win logic can be tested without Phaser.

**Physics approach:** Paddles use static bodies moved by position (`updateFromGameObject()`) each frame to prevent ball-sticking issues. The ball uses a dynamic body with arcade physics colliders against walls and paddles.

**Controls:** Left paddle: W/S keys. Right paddle: Arrow Up/Down.

**Ball behavior:** On paddle hit, ball speed increases by `BALL_SPEED_INCREASE` multiplier. Bounce angle varies based on where the ball hits the paddle (`BALL_ANGLE_VARIATION`). A cooldown (`PADDLE_HIT_COOLDOWN_MS`) prevents double-hits.

**Textures:** Generated procedurally at runtime via `this.make.graphics()` — no external assets.

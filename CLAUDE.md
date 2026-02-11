# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CajPong is a two-player Pong game built with Phaser 3 and Vite.

## Commands

- `npm run dev` — Start Vite dev server with hot reload
- `npm run build` — Production build to `dist/`

No test framework or linter is configured.

## Architecture

**Entry point:** `index.html` loads `src/main.js`, which creates the Phaser game instance.

**Key files:**
- `src/main.js` — Phaser.Game config (arcade physics, no gravity, scale-to-fit)
- `src/constants.js` — All game tuning values (dimensions, speeds, sizes, colors)
- `src/scenes/Game.js` — Single scene containing all gameplay logic

**Physics approach:** Paddles use static bodies moved by position (`updateFromGameObject()`) each frame to prevent ball-sticking issues. The ball uses a dynamic body with arcade physics colliders against walls and paddles.

**Controls:** Left paddle: W/S keys. Right paddle: Arrow Up/Down.

**Ball behavior:** On paddle hit, ball speed increases by `BALL_SPEED_INCREASE` multiplier. Bounce angle varies based on where the ball hits the paddle (`BALL_ANGLE_VARIATION`). A cooldown (`PADDLE_HIT_COOLDOWN_MS`) prevents double-hits.

**Textures:** Generated procedurally at runtime via `this.make.graphics()` — no external assets.

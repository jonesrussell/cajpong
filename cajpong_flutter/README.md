# CajPong Flutter

Two-player Pong built with Flutter and [Flame](https://docs.flame-engine.org/). Supports local two-thumb play and online multiplayer via the Node.js Socket.IO server in the repo root (`../server`).

## Requirements

- Flutter SDK (stable channel)
- For online play: run the game server from the repo root with `npm run dev:server`

## Project structure

- `lib/game/` — Flame game, components (paddle, ball, walls, touch zones), and pure game step logic
- `lib/services/` — `PongSocketService` (Socket.IO client; find match, game state stream, send input)
- `lib/screens/` — Flutter overlay widgets (menu, matchmaking, game over)
- `lib/models/` — `GameState`, `Side`, `MatchedPayload`, `Inputs`
- `lib/utils/` — `constants.dart` (dimensions, speeds, colors)

## Run

From this directory (`cajpong_flutter/`):

```bash
flutter pub get
flutter run
```

- **Chrome (web):** `flutter run -d chrome`
- **Android:** `flutter run -d <device-id>`
- **iOS:** `flutter run -d <device-id>` (requires macOS and Xcode for device/simulator)

If the project was created manually (no `android/` or `ios/` folders), generate platform files first:

```bash
flutter create .
flutter pub get
flutter run
```

## Server URL (online play)

The app connects to the game server for matchmaking and multiplayer. Default: `http://localhost:3000`.

Override at build/run time:

```bash
flutter run --dart-define=SERVER_URL=https://pong.example.com
```

For production web builds:

```bash
flutter build web --dart-define=SERVER_URL=https://pong.northcloud.biz
```

## Build for production

- **Web:** `flutter build web` — output in `build/web/`. Can be served by the same Node server (e.g. static files from `dist/` in the parent setup).
- **Android:** `flutter build apk` or `flutter build appbundle`
- **iOS:** `flutter build ios` (then open Xcode for signing and archive)

## Controls

- **Local:** Left half of the screen moves the left paddle (drag); right half moves the right paddle.
- **Online:** Same; your side (left or right) is assigned when you are matched.

## Architecture notes

- **Single FlameGame** with overlays for menu, matchmaking, and game over (no Phaser-style scenes).
- **Manual Pong physics** in `game_loop.dart` (no Flame collision) so client and server share the same step logic.
- **Server-authoritative** online mode: client receives `game_state` and sends `input` (up/down); no client-side ball simulation in online play.
- **Networking** is isolated in `PongSocketService`; the game only calls `findMatch()`, subscribes to game state, and `sendInput()`.

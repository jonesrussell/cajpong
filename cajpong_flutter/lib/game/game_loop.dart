import 'dart:math' as math;

import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/utils/constants.dart';

/// Pure game step and win check (ported from gameState.ts / gameLogic.ts).
/// Used for local play; server uses equivalent logic.

double _clamp(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

double _movePaddleFromInput(
    double y, bool up, bool down, double dt, GameDimensions d) {
  if (up) y -= paddleSpeed * dt;
  if (down) y += paddleSpeed * dt;
  return _clamp(y, d.paddleClampMargin, d.height - d.paddleClampMargin);
}

double _randomServeAngle() {
  return (2 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 - 1) *
      ballAngleVariation;
}

/// Returns which side has won, or null if neither has reached the win threshold.
Side? getWinner(int scoreLeft, int scoreRight) {
  if (scoreLeft >= pointsToWin) return Side.left;
  if (scoreRight >= pointsToWin) return Side.right;
  return null;
}

/// Create initial state for a new game. [serveDirection] 1 or -1; if null, random.
GameState createInitialState(GameDimensions d, [int? serveDirection]) {
  final direction = serveDirection ??
      (DateTime.now().millisecondsSinceEpoch.isEven ? 1 : -1);
  return GameState(
    ballX: d.width / 2,
    ballY: d.height / 2,
    ballVx: 0,
    ballVy: 0,
    leftPaddleY: d.height / 2,
    rightPaddleY: d.height / 2,
    scoreLeft: 0,
    scoreRight: 0,
    serving: true,
    serveDirection: direction,
    serveCountdownRemaining: serveDelayMs / 1000.0,
    gameOver: false,
    winner: null,
    gameTime: 0,
    lastPaddleHitTime: -1,
  );
}

/// Pure step. [dt] in seconds. Returns new state (does not mutate).
/// [nextServeAngle] in radians makes serve launch deterministic for tests.
GameState step(GameState state, Inputs inputs, double dt, GameDimensions d,
    {double? nextServeAngle}) {
  const serveDelayS = serveDelayMs / 1000.0;
  const paddleHitCooldownS = paddleHitCooldownMs / 1000.0;

  final left = inputs.left;
  final right = inputs.right;
  GameState s = state.copyWith(
    gameTime: state.gameTime + dt,
    leftPaddleY: _movePaddleFromInput(
        state.leftPaddleY, left.up, left.down, dt, d),
    rightPaddleY: _movePaddleFromInput(
        state.rightPaddleY, right.up, right.down, dt, d),
  );

  if (s.gameOver) return s;

  if (s.serving) {
    double remaining = s.serveCountdownRemaining - dt;
    if (remaining <= 0) {
      final angle = nextServeAngle ?? _randomServeAngle();
      final dir = s.serveDirection ?? 1;
      return s.copyWith(
        ballVx: dir * ballSpeed * math.cos(angle),
        ballVy: ballSpeed * math.sin(angle),
        serving: false,
        serveDirection: null,
        serveCountdownRemaining: 0,
      );
    }
    return s.copyWith(
      ballX: d.width / 2,
      ballY: d.height / 2,
      ballVx: 0,
      ballVy: 0,
      serveCountdownRemaining: remaining,
    );
  }

  double nx = s.ballX + s.ballVx * dt;
  double ny = s.ballY + s.ballVy * dt;

  // Wall bounces (top/bottom)
  double nvy = s.ballVy;
  if (ny - d.ballSize <= d.topWall) {
    ny = d.topWall + d.ballSize;
    nvy = s.ballVy.abs();
  } else if (ny + d.ballSize >= d.bottomWall) {
    ny = d.bottomWall - d.ballSize;
    nvy = -s.ballVy.abs();
  }

  if (nx < 0) {
    int scoreRight = s.scoreRight + 1;
    Side? winner = getWinner(s.scoreLeft, scoreRight);
    return s.copyWith(
      ballX: d.width / 2,
      ballY: d.height / 2,
      ballVx: 0,
      ballVy: 0,
      scoreRight: scoreRight,
      gameOver: winner != null,
      winner: winner,
      serving: winner == null,
      serveDirection: winner == null ? -1 : null,
      serveCountdownRemaining: winner == null ? serveDelayS : 0,
    );
  }
  if (nx > d.width) {
    int scoreLeft = s.scoreLeft + 1;
    Side? winner = getWinner(scoreLeft, s.scoreRight);
    return s.copyWith(
      ballX: d.width / 2,
      ballY: d.height / 2,
      ballVx: 0,
      ballVy: 0,
      scoreLeft: scoreLeft,
      gameOver: winner != null,
      winner: winner,
      serving: winner == null,
      serveDirection: winner == null ? 1 : null,
      serveCountdownRemaining: winner == null ? serveDelayS : 0,
    );
  }

  final cooldownOk =
      s.gameTime - s.lastPaddleHitTime >= paddleHitCooldownS;
  final leftPaddleRight = d.paddlePadding + d.halfPaddle;
  final leftPaddleLeft = d.paddlePadding - d.halfPaddle;
  final rightPaddleLeft = d.width - d.paddlePadding - d.halfPaddle;
  final rightPaddleRight = d.width - d.paddlePadding + d.halfPaddle;

  final hitLeftPaddle = cooldownOk &&
      s.ballVx < 0 &&
      nx - d.ballSize <= leftPaddleRight &&
      nx + d.ballSize >= leftPaddleLeft &&
      ny >= s.leftPaddleY - d.halfPaddleH &&
      ny <= s.leftPaddleY + d.halfPaddleH;

  if (hitLeftPaddle) {
    final currentSpeed = math.sqrt(s.ballVx * s.ballVx + s.ballVy * s.ballVy);
    final actualSpeed =
        math.max(currentSpeed, ballSpeed) * ballSpeedIncrease;
    final offset = _clamp(
        (ny - s.leftPaddleY) / d.halfPaddleH, -1.0, 1.0);
    final angle = offset * ballAngleVariation;
    return s.copyWith(
      ballX: leftPaddleLeft - d.ballSize - d.ballPaddleSeparation,
      ballY: ny,
      ballVx: actualSpeed * math.cos(angle),
      ballVy: actualSpeed * math.sin(angle),
      lastPaddleHitTime: s.gameTime,
    );
  }

  final hitRightPaddle = cooldownOk &&
      s.ballVx > 0 &&
      nx - d.ballSize <= rightPaddleRight &&
      nx + d.ballSize >= rightPaddleLeft &&
      ny >= s.rightPaddleY - d.halfPaddleH &&
      ny <= s.rightPaddleY + d.halfPaddleH;

  if (hitRightPaddle) {
    final currentSpeed = math.sqrt(s.ballVx * s.ballVx + s.ballVy * s.ballVy);
    final actualSpeed =
        math.max(currentSpeed, ballSpeed) * ballSpeedIncrease;
    final offset = _clamp(
        (ny - s.rightPaddleY) / d.halfPaddleH, -1.0, 1.0);
    final angle = offset * ballAngleVariation;
    return s.copyWith(
      ballX: rightPaddleRight + d.ballSize + d.ballPaddleSeparation,
      ballY: ny,
      ballVx: -actualSpeed * math.cos(angle),
      ballVy: actualSpeed * math.sin(angle),
      lastPaddleHitTime: s.gameTime,
    );
  }

  return s.copyWith(ballX: nx, ballY: ny, ballVy: nvy);
}

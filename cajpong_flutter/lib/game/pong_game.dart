import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:cajpong_flutter/game/components/ball.dart';
import 'package:cajpong_flutter/game/components/paddle.dart';
import 'package:cajpong_flutter/game/components/touch_zone.dart';
import 'package:cajpong_flutter/game/components/wall.dart';
import 'package:cajpong_flutter/game/game_loop.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/services/pong_socket_service.dart';
import 'package:cajpong_flutter/utils/constants.dart';

enum GameMode { menu, localPlaying, onlineFinding, onlinePlaying, gameOver }

/// Root Flame game: one game instance, mode and overlays control menu/play/game over.
class PongGame extends FlameGame {
  PongGame({required PongSocketService socketService})
      : _socketService = socketService;

  final PongSocketService _socketService;
  StreamSubscription<GameState>? _gameStateSub;
  StreamSubscription<void>? _disconnectSub;

  GameMode get mode => _mode;
  GameMode _mode = GameMode.menu;
  set mode(GameMode value) {
    _mode = value;
  }

  Side? get winner => _winner;
  Side? _winner;

  bool get matchmakingError => _matchmakingError;
  bool _matchmakingError = false;

  /// For online: which side this client controls.
  Side? get mySide => _mySide;
  Side? _mySide;

  /// Last state from server (online) or from local step (local).
  GameState? get currentState => _currentState;
  GameState? _currentState;

  late Paddle leftPaddle;
  late Paddle rightPaddle;
  late Ball ball;
  late TextComponent scoreText;

  double? _leftTargetY;
  double? _rightTargetY;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(resolution: Vector2(width, height));
    leftPaddle = Paddle.left()
      ..position = Vector2(paddlePadding, height / 2)
      ..anchor = Anchor.center;
    rightPaddle = Paddle.right()
      ..position = Vector2(width - paddlePadding, height / 2)
      ..anchor = Anchor.center;
    ball = Ball()
      ..position = Vector2(width / 2, height / 2)
      ..anchor = Anchor.center;

    add(Wall(isTop: true));
    add(Wall(isTop: false));
    add(leftPaddle);
    add(rightPaddle);
    add(ball);

    scoreText = TextComponent(
      text: '0 - 0',
      position: Vector2(width / 2, scoreTextY),
      anchor: Anchor.center,
    )..textRenderer = TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: scoreFontSize,
        ),
      );
    add(scoreText);

    final halfWidth = width / 2;
    final minY = paddleClampMargin;
    final maxY = height - paddleClampMargin;
    add(TouchZone(
      isLeft: true,
      onTargetY: (y) =>
          _leftTargetY = y == null ? null : y.clamp(minY, maxY).toDouble(),
    )
      ..position = Vector2.zero()
      ..size = Vector2(halfWidth, height)
      ..anchor = Anchor.topLeft);
    add(TouchZone(
      isLeft: false,
      onTargetY: (y) =>
          _rightTargetY = y == null ? null : y.clamp(minY, maxY).toDouble(),
    )
      ..position = Vector2(halfWidth, 0)
      ..size = Vector2(halfWidth, height)
      ..anchor = Anchor.topLeft);

    overlays.add('menu');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_mode == GameMode.localPlaying && _currentState != null) {
      _updateLocal(dt);
    } else if (_mode == GameMode.onlinePlaying) {
      if (_currentState != null) _applyState(_currentState!);
      _sendOnlineInput();
    }
  }

  void _sendOnlineInput() {
    if (_mySide == null) return;
    final paddleY =
        _mySide == Side.left ? leftPaddle.position.y : rightPaddle.position.y;
    final targetY =
        _mySide == Side.left ? _leftTargetY : _rightTargetY;
    final up = targetY != null && targetY < paddleY;
    final down = targetY != null && targetY > paddleY;
    _socketService.sendInput(up: up, down: down);
  }

  void _updateLocal(double dt) {
    final state = _currentState!;
    final leftUp = _leftTargetY != null && _leftTargetY! < leftPaddle.position.y;
    final leftDown =
        _leftTargetY != null && _leftTargetY! > leftPaddle.position.y;
    final rightUp =
        _rightTargetY != null && _rightTargetY! < rightPaddle.position.y;
    final rightDown =
        _rightTargetY != null && _rightTargetY! > rightPaddle.position.y;
    final inputs = Inputs(
      left: PaddleInput(up: leftUp, down: leftDown),
      right: PaddleInput(up: rightUp, down: rightDown),
    );
    _currentState = step(state, inputs, dt);
    _applyState(_currentState!);
    if (_currentState!.gameOver && _currentState!.winner != null) {
      _winner = _currentState!.winner;
      _mode = GameMode.gameOver;
      overlays.add('game_over');
    }
  }

  void _applyState(GameState state) {
    ball.position.setValues(state.ballX, state.ballY);
    leftPaddle.position.y = state.leftPaddleY;
    rightPaddle.position.y = state.rightPaddleY;
    scoreText.text = '${state.scoreLeft} - ${state.scoreRight}';
  }

  void startLocal() {
    overlays.remove('menu');
    _mode = GameMode.localPlaying;
    _currentState = createInitialState();
    _winner = null;
  }

  void startOnline(Side side) {
    overlays.remove('matchmaking');
    _mode = GameMode.onlinePlaying;
    _mySide = side;
  }

  void showMenu() {
    overlays.remove('game_over');
    overlays.remove('matchmaking');
    overlays.add('menu');
    _mode = GameMode.menu;
    _winner = null;
    _mySide = null;
    _currentState = null;
    _matchmakingError = false;
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
  }

  void showMatchmaking() {
    _mode = GameMode.onlineFinding;
    _matchmakingError = false;
    overlays.remove('menu');
    overlays.add('matchmaking');
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
    _disconnectSub = _socketService.onDisconnect.listen((_) {
      if (_mode == GameMode.onlineFinding || _mode == GameMode.onlinePlaying) {
        onOpponentLeft();
      }
    });
    _socketService.findMatch().then((payload) {
      if (_mode != GameMode.onlineFinding) return;
      onMatched(payload.side);
      _socketService.startGameStateListener();
      _gameStateSub =
          _socketService.gameStateStream.listen(onGameState);
    }).catchError((_) {
      if (_mode == GameMode.onlineFinding) {
        _matchmakingError = true;
      }
    });
  }

  void retryMatchmaking() {
    _matchmakingError = false;
    showMatchmaking();
  }

  void onMatched(Side side) {
    startOnline(side);
  }

  void onGameState(GameState state) {
    _currentState = state;
    if (state.gameOver && state.winner != null) {
      _winner = state.winner;
      _mode = GameMode.gameOver;
      overlays.add('game_over');
    }
  }

  void onOpponentLeft() {
    _mode = GameMode.gameOver;
    overlays.add('game_over');
  }
}

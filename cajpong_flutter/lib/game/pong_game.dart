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

  /// Current game dimensions (canvas size); updated in onGameResize.
  GameDimensions get dimensions => _dimensions;
  late GameDimensions _dimensions;

  GameMode _mode = GameMode.menu;
  GameMode get mode => _mode;
  set mode(GameMode value) => _mode = value;

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
  late Wall topWall;
  late Wall bottomWall;
  late TouchZone leftTouchZone;
  late TouchZone rightTouchZone;

  double? _leftTargetY;
  double? _rightTargetY;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = MaxViewport();
    _dimensions = GameDimensions(refWidth, refHeight);
    _createComponents();
    _layoutFromDimensions(_dimensions);
    overlays.add('menu');
  }

  void _createComponents() {
    leftPaddle = Paddle.left()
      ..anchor = Anchor.center;
    rightPaddle = Paddle.right()
      ..anchor = Anchor.center;
    ball = Ball()
      ..anchor = Anchor.center;

    topWall = Wall(isTop: true);
    bottomWall = Wall(isTop: false);

    add(topWall);
    add(bottomWall);
    add(leftPaddle);
    add(rightPaddle);
    add(ball);

    scoreText = TextComponent(
      text: '0 - 0',
      anchor: Anchor.center,
    )..textRenderer = TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: _dimensions.scoreFontSize,
        ),
      );
    add(scoreText);

    final d = _dimensions;
    final minY = d.paddleClampMargin;
    final maxY = d.height - d.paddleClampMargin;
    leftTouchZone = TouchZone(
      isLeft: true,
      onTargetY: (y) =>
          _leftTargetY = y == null ? null : y.clamp(minY, maxY).toDouble(),
    )
      ..anchor = Anchor.topLeft;
    rightTouchZone = TouchZone(
      isLeft: false,
      onTargetY: (y) =>
          _rightTargetY = y == null ? null : y.clamp(minY, maxY).toDouble(),
    )
      ..anchor = Anchor.topLeft;
    add(leftTouchZone);
    add(rightTouchZone);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _dimensions = GameDimensions(size.x, size.y);
    _layoutFromDimensions(_dimensions);
  }

  void _layoutFromDimensions(GameDimensions d) {
    leftPaddle.size.setValues(d.paddleWidth, d.paddleHeight);
    leftPaddle.position.setValues(d.paddlePadding, d.height / 2);

    rightPaddle.size.setValues(d.paddleWidth, d.paddleHeight);
    rightPaddle.position.setValues(d.width - d.paddlePadding, d.height / 2);

    ball.size.setValues(d.ballSize * 2, d.ballSize * 2);
    ball.position.setValues(d.width / 2, d.height / 2);

    topWall.size.setValues(d.width, d.wallHeight);
    topWall.position.setValues(0, 0);
    bottomWall.size.setValues(d.width, d.wallHeight);
    bottomWall.position.setValues(0, d.height - d.wallHeight);

    scoreText.position.setValues(d.width / 2, d.scoreTextY);
    scoreText.textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: d.scoreFontSize,
      ),
    );

    leftTouchZone.position.setValues(0, 0);
    leftTouchZone.size.setValues(d.width / 2, d.height);
    rightTouchZone.position.setValues(d.width / 2, 0);
    rightTouchZone.size.setValues(d.width / 2, d.height);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_mode == GameMode.localPlaying && _currentState != null) {
      _updateLocal(dt);
    } else if (_mode == GameMode.onlinePlaying) {
      if (_currentState != null) _applyState(_currentState!, fromServer: true);
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
    final leftUp = _leftTargetY?.compareTo(leftPaddle.position.y) == -1;
    final leftDown = _leftTargetY?.compareTo(leftPaddle.position.y) == 1;
    final rightUp = _rightTargetY?.compareTo(rightPaddle.position.y) == -1;
    final rightDown = _rightTargetY?.compareTo(rightPaddle.position.y) == 1;
    final inputs = Inputs(
      left: PaddleInput(up: leftUp, down: leftDown),
      right: PaddleInput(up: rightUp, down: rightDown),
    );
    _currentState = step(state, inputs, dt, _dimensions);
    _applyState(_currentState!, fromServer: false);
    if (_currentState!.gameOver && _currentState!.winner != null) {
      _winner = _currentState!.winner;
      _mode = GameMode.gameOver;
      overlays.add('game_over');
    }
  }

  void _applyState(GameState state, {required bool fromServer}) {
    if (fromServer) {
      ball.position.setValues(
        _dimensions.serverXToClient(state.ballX),
        _dimensions.serverYToClient(state.ballY),
      );
      leftPaddle.position.y = _dimensions.serverYToClient(state.leftPaddleY);
      rightPaddle.position.y = _dimensions.serverYToClient(state.rightPaddleY);
    } else {
      ball.position.setValues(state.ballX, state.ballY);
      leftPaddle.position.y = state.leftPaddleY;
      rightPaddle.position.y = state.rightPaddleY;
    }
    scoreText.text = '${state.scoreLeft} - ${state.scoreRight}';
  }

  void startLocal() {
    overlays.remove('menu');
    _mode = GameMode.localPlaying;
    _lastGameWasOnline = false;
    _currentState = createInitialState(_dimensions);
    _winner = null;
  }

  /// True if the current or most recent game was online (for game-over UI).
  bool get lastGameWasOnline => _lastGameWasOnline;
  bool _lastGameWasOnline = false;

  void startOnline(Side side) {
    overlays.remove('matchmaking');
    _mode = GameMode.onlinePlaying;
    _mySide = side;
    _lastGameWasOnline = true;
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
    overlays.remove('game_over');
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

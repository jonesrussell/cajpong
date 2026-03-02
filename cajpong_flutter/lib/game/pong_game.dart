import 'dart:async';
import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show KeyEventResult;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:cajpong_flutter/game/components/ball.dart';
import 'package:cajpong_flutter/game/campaign_stages.dart';
import 'package:cajpong_flutter/game/components/paddle.dart';
import 'package:cajpong_flutter/game/components/smash_pickup.dart';
import 'package:cajpong_flutter/game/components/touch_zone.dart';
import 'package:cajpong_flutter/game/components/wall.dart';
import 'package:cajpong_flutter/game/game_loop.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/services/pong_socket_service.dart';
import 'package:cajpong_flutter/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum GameMode { menu, localPlaying, onlineFinding, onlinePlaying, gameOver }

/// Root Flame game: one game instance, mode and overlays control menu/play/game over.
class PongGame extends FlameGame with KeyboardEvents {
  PongGame({required PongSocketService socketService})
      : _socketService = socketService;

  final PongSocketService _socketService;
  StreamSubscription<GameState>? _gameStateSub;
  StreamSubscription<void>? _disconnectSub;
  bool _matchmakingWakeLockEnabled = false;

  /// Current game dimensions (canvas size); updated in onGameResize.
  GameDimensions get dimensions => _dimensions;
  late GameDimensions _dimensions;

  GameMode mode = GameMode.menu;

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
  late TextComponent hudText;
  late Wall topWall;
  late Wall bottomWall;
  late TouchZone leftTouchZone;
  late TouchZone rightTouchZone;
  final List<SmashPickup> _pickups = [];
  final _rng = math.Random();

  double? _leftTargetY;
  double? _rightTargetY;

  final Set<LogicalKeyboardKey> _keysHeld = {};

  bool _componentsReady = false;

  static const int _maxDurability = 8;
  static const double _onlineSmoothing = 14.0;
  static const double _onlinePredictionSeconds = 0.04;
  static const double _onlineBallSnapDistance = 140.0;
  static const double _onlinePaddleSnapDistance = 90.0;
  static int _bestCampaignScore = 0;
  int _campaignScore = 0;
  int _campaignLevel = 1;
  int _rallyCount = 0;
  int _leftDurability = _maxDurability;
  int _rightDurability = _maxDurability;
  double _pickupSpawnCooldown = 3.5;
  CampaignStage _campaignStage = campaignStages.first;

  int get campaignScore => _campaignScore;
  int get campaignLevel => _campaignLevel;
  int get campaignBestScore => _bestCampaignScore;
  int get rallyCount => _rallyCount;
  int get leftDurability => _leftDurability;
  int get rightDurability => _rightDurability;
  String get campaignStageName => _campaignStage.name;
  bool get inCampaign => !_lastGameWasOnline;

  PaddleSkin _paddleSkin = PaddleSkin.classic;
  BallSkin _ballSkin = BallSkin.classic;
  PaddleSkin get paddleSkin => _paddleSkin;
  BallSkin get ballSkin => _ballSkin;
  static const _bestScorePrefKey = 'cajpong_campaign_best_score';

  Future<void> _loadBestCampaignScore() async {
    final prefs = await SharedPreferences.getInstance();
    _bestCampaignScore = prefs.getInt(_bestScorePrefKey) ?? 0;
  }

  Future<void> _saveBestCampaignScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScorePrefKey, _bestCampaignScore);
  }

  Future<void> _setMatchmakingWakeLock(bool enabled) async {
    if (_matchmakingWakeLockEnabled == enabled) return;
    _matchmakingWakeLockEnabled = enabled;
    await WakelockPlus.toggle(enable: enabled);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = MaxViewport();
    _dimensions = GameDimensions(refWidth, refHeight);
    await _loadBestCampaignScore();
    _createComponents();
    _layoutFromDimensions(_dimensions);
    _componentsReady = true;
    overlays.add('menu');
  }

  void _createComponents() {
    leftPaddle = Paddle.left()..anchor = Anchor.center;
    rightPaddle = Paddle.right()..anchor = Anchor.center;
    ball = Ball()..anchor = Anchor.center;
    _applySkins();

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
    hudText = TextComponent(
      text: '',
      anchor: Anchor.center,
    )..textRenderer = TextPaint(
        style: TextStyle(
          color: const Color(0xFFBBC7D9),
          fontSize: _dimensions.scoreFontSize * 0.45,
        ),
      );
    add(hudText);

    final d = _dimensions;
    final minY = d.paddleClampMargin;
    final maxY = d.height - d.paddleClampMargin;
    leftTouchZone = TouchZone(
      isLeft: true,
      onTargetY: (y) => _leftTargetY = y?.clamp(minY, maxY).toDouble(),
    )..anchor = Anchor.topLeft;
    rightTouchZone = TouchZone(
      isLeft: false,
      onTargetY: (y) => _rightTargetY = y?.clamp(minY, maxY).toDouble(),
    )..anchor = Anchor.topLeft;
    add(leftTouchZone);
    add(rightTouchZone);
  }

  void _applySkins() {
    leftPaddle.skin = _paddleSkin;
    rightPaddle.skin = _paddleSkin;
    ball.skin = _ballSkin;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _dimensions = GameDimensions(size.x, size.y);
    if (_componentsReady) {
      _layoutFromDimensions(_dimensions);
      if (mode == GameMode.localPlaying) _applyDurabilityVisuals();
    }
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
    hudText.position.setValues(d.width / 2, d.scoreTextY + d.scale * 40);
    hudText.textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFBBC7D9),
        fontSize: d.scoreFontSize * 0.45,
      ),
    );

    leftTouchZone.position.setValues(0, 0);
    leftTouchZone.size.setValues(d.width / 2, d.height);
    rightTouchZone.position.setValues(d.width / 2, 0);
    rightTouchZone.size.setValues(d.width / 2, d.height);
  }

  static const _keyLeftUp = LogicalKeyboardKey.keyW;
  static const _keyLeftDown = LogicalKeyboardKey.keyS;
  static const _keyRightUp = LogicalKeyboardKey.arrowUp;
  static const _keyRightDown = LogicalKeyboardKey.arrowDown;

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == _keyLeftUp ||
          event.logicalKey == _keyLeftDown ||
          event.logicalKey == _keyRightUp ||
          event.logicalKey == _keyRightDown) {
        _keysHeld.add(event.logicalKey);
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      _keysHeld.remove(event.logicalKey);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (mode == GameMode.localPlaying && _currentState != null) {
      _updateLocal(dt);
    } else if (mode == GameMode.onlinePlaying) {
      _updateOnlineVisuals(dt);
      _sendOnlineInput();
    }
  }

  void _updateOnlineVisuals(double dt) {
    final state = _currentState;
    if (state == null) return;

    final renderAlpha = 1 - math.exp(-_onlineSmoothing * dt);
    final predictedBallX = state.serving
        ? state.ballX
        : (state.ballX + (state.ballVx * _onlinePredictionSeconds));
    final predictedBallY = state.serving
        ? state.ballY
        : (state.ballY + (state.ballVy * _onlinePredictionSeconds));

    final targetBallX = _dimensions.serverXToClient(predictedBallX);
    final targetBallY = _dimensions.serverYToClient(predictedBallY);
    final targetLeftY = _dimensions.serverYToClient(state.leftPaddleY);
    final targetRightY = _dimensions.serverYToClient(state.rightPaddleY);

    final ballDx = targetBallX - ball.position.x;
    final ballDy = targetBallY - ball.position.y;
    final ballDist = math.sqrt((ballDx * ballDx) + (ballDy * ballDy));
    if (ballDist > _onlineBallSnapDistance) {
      ball.position.setValues(targetBallX, targetBallY);
    } else {
      ball.position.setValues(
        ball.position.x + (ballDx * renderAlpha),
        ball.position.y + (ballDy * renderAlpha),
      );
    }

    final leftDy = targetLeftY - leftPaddle.position.y;
    if (leftDy.abs() > _onlinePaddleSnapDistance) {
      leftPaddle.position.y = targetLeftY;
    } else {
      leftPaddle.position.y += leftDy * renderAlpha;
    }

    final rightDy = targetRightY - rightPaddle.position.y;
    if (rightDy.abs() > _onlinePaddleSnapDistance) {
      rightPaddle.position.y = targetRightY;
    } else {
      rightPaddle.position.y += rightDy * renderAlpha;
    }

    scoreText.text = '${state.scoreLeft} - ${state.scoreRight}';
    hudText.text = _mySide == null ? '' : 'Online duel';
  }

  void _sendOnlineInput() {
    if (_mySide == null) return;
    final paddleY =
        _mySide == Side.left ? leftPaddle.position.y : rightPaddle.position.y;
    final targetY = _mySide == Side.left ? _leftTargetY : _rightTargetY;
    final keyUp = _mySide == Side.left
        ? _keysHeld.contains(_keyLeftUp)
        : _keysHeld.contains(_keyRightUp);
    final keyDown = _mySide == Side.left
        ? _keysHeld.contains(_keyLeftDown)
        : _keysHeld.contains(_keyRightDown);
    final up = keyUp || targetY?.compareTo(paddleY) == -1;
    final down = keyDown || targetY?.compareTo(paddleY) == 1;
    _socketService.sendInput(up: up, down: down);
  }

  void _updateLocal(double dt) {
    final previous = _currentState!;
    final leftPaddleY = leftPaddle.position.y;
    final rightPaddleY = rightPaddle.position.y;
    final leftUp = _keysHeld.contains(_keyLeftUp) ||
        _leftTargetY?.compareTo(leftPaddleY) == -1;
    final leftDown = _keysHeld.contains(_keyLeftDown) ||
        _leftTargetY?.compareTo(leftPaddleY) == 1;
    final rightUp = _keysHeld.contains(_keyRightUp) ||
        _rightTargetY?.compareTo(rightPaddleY) == -1;
    final rightDown = _keysHeld.contains(_keyRightDown) ||
        _rightTargetY?.compareTo(rightPaddleY) == 1;
    final inputs = Inputs(
      left: PaddleInput(up: leftUp, down: leftDown),
      right: PaddleInput(up: rightUp, down: rightDown),
    );

    _currentState = step(previous, inputs, dt, _dimensions);
    final next = _currentState!;

    if (next.lastPaddleHitTime > previous.lastPaddleHitTime) {
      _rallyCount++;
      _campaignScore += _campaignStage.savePoints;

      if (next.ballVx > 0) {
        _leftDurability =
            (_leftDurability - _campaignStage.durabilityDamagePerSave)
                .clamp(0, _maxDurability);
      } else {
        _rightDurability =
            (_rightDurability - _campaignStage.durabilityDamagePerSave)
                .clamp(0, _maxDurability);
      }

      _updateCampaignStage();
      _applyDurabilityVisuals();
      _applyLevelBallTuning();
    }

    _pickupSpawnCooldown -= dt;
    if (_pickupSpawnCooldown <= 0 && _pickups.length < 3) {
      _spawnPickup();
    }
    _checkPickupCollision();

    final conceded = (next.scoreLeft != previous.scoreLeft) ||
        (next.scoreRight != previous.scoreRight) ||
        _leftDurability == 0 ||
        _rightDurability == 0;
    if (conceded) {
      _endCampaign();
      return;
    }

    _applyState(_currentState!, fromServer: false);
  }

  void _spawnPickup() {
    const types = SmashPickupType.values;
    final stageIndexBoost = _campaignStage.level.clamp(1, 12);
    final preferPoints =
        _rng.nextDouble() < (0.55 + (stageIndexBoost * 0.015)).clamp(0.55, 0.8);
    final type = preferPoints
        ? SmashPickupType.points
        : types[_rng.nextInt(types.length)];
    final laneCount = _campaignStage.bossWave ? 5 : 3;
    final lane = _rng.nextInt(laneCount);
    final laneY = _dimensions.height * (0.2 + (lane * (0.6 / (laneCount - 1))));
    final x = _dimensions.width * (0.28 + (_rng.nextDouble() * 0.44));
    final y = laneY + ((_rng.nextDouble() - 0.5) * _dimensions.height * 0.06);
    final pickup = SmashPickup(
      type: type,
      position: Vector2(x, y),
      radius: _dimensions.ballSize * 0.95,
    );
    _pickups.add(pickup);
    add(pickup);
    _scheduleNextPickup();
  }

  void _checkPickupCollision() {
    final state = _currentState;
    if (state == null || _pickups.isEmpty) return;
    final collected = <SmashPickup>[];
    for (final pickup in _pickups) {
      final dx = state.ballX - pickup.position.x;
      final dy = state.ballY - pickup.position.y;
      final hitDistance = _dimensions.ballSize + pickup.radius;
      if ((dx * dx) + (dy * dy) > hitDistance * hitDistance) continue;

      switch (pickup.type) {
        case SmashPickupType.points:
          _campaignScore += 80 + (_campaignLevel * 14);
          _updateCampaignStage();
          break;
        case SmashPickupType.repair:
          _leftDurability = (_leftDurability + 3).clamp(0, _maxDurability);
          _rightDurability = (_rightDurability + 3).clamp(0, _maxDurability);
          _applyDurabilityVisuals();
          break;
        case SmashPickupType.slow:
          _currentState = state.copyWith(
            ballVx: state.ballVx * 0.84,
            ballVy: state.ballVy * 0.84,
          );
          break;
      }
      collected.add(pickup);
    }
    if (collected.isEmpty) return;
    for (final pickup in collected) {
      pickup.removeFromParent();
      _pickups.remove(pickup);
    }
    if (_pickups.length < 2) {
      _pickupSpawnCooldown = _pickupSpawnCooldown.clamp(0.7, 99);
    }
  }

  void _clearPickups() {
    for (final pickup in _pickups) {
      pickup.removeFromParent();
    }
    _pickups.clear();
  }

  void _scheduleNextPickup() {
    final spread = _campaignStage.bossWave ? 0.55 : 1.2;
    _pickupSpawnCooldown =
        _campaignStage.pickupCooldown + (_rng.nextDouble() * spread);
  }

  void _spawnBossWave() {
    final burst = _campaignStage.pickupBurst;
    if (burst <= 0) return;
    for (int i = 0; i < burst; i++) {
      if (_pickups.length >= 6) break;
      _spawnPickup();
    }
    _pickupSpawnCooldown = 0.5;
  }

  void _updateCampaignStage() {
    final nextStage = campaignStageForScore(_campaignScore);
    if (nextStage.level == _campaignStage.level &&
        nextStage.name == _campaignStage.name) {
      _campaignLevel = _campaignStage.level;
      return;
    }
    _campaignStage = nextStage;
    _campaignLevel = _campaignStage.level;
    if (_campaignStage.bossWave) {
      _spawnBossWave();
    } else {
      _pickupSpawnCooldown =
          _pickupSpawnCooldown.clamp(0.8, _campaignStage.pickupCooldown);
    }
  }

  void _endCampaign() {
    if (_campaignScore > _bestCampaignScore) {
      _bestCampaignScore = _campaignScore;
      unawaited(_saveBestCampaignScore());
    }
    _clearPickups();
    mode = GameMode.gameOver;
    _winner = null;
    overlays.add('game_over');
  }

  void _applyLevelBallTuning() {
    final state = _currentState;
    if (state == null) return;
    if (state.serving || state.ballVx == 0) return;
    final speed = math
        .sqrt((state.ballVx * state.ballVx) + (state.ballVy * state.ballVy));
    final target = ballSpeed * _campaignStage.speedMultiplier;
    if (speed >= target) return;
    final ratio = target / speed;
    _currentState = state.copyWith(
      ballVx: state.ballVx * ratio,
      ballVy: state.ballVy * ratio,
    );
  }

  void _applyDurabilityVisuals() {
    leftPaddle.integrity = _leftDurability / _maxDurability;
    rightPaddle.integrity = _rightDurability / _maxDurability;
    const minScale = 0.62;
    final leftScale = minScale + (leftPaddle.integrity * (1 - minScale));
    final rightScale = minScale + (rightPaddle.integrity * (1 - minScale));
    leftPaddle.size.y = _dimensions.paddleHeight * leftScale;
    rightPaddle.size.y = _dimensions.paddleHeight * rightScale;
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
    if (mode == GameMode.onlinePlaying || _lastGameWasOnline) {
      scoreText.text = '${state.scoreLeft} - ${state.scoreRight}';
      hudText.text = _mySide == null ? '' : 'Online duel';
    } else {
      scoreText.text = 'Score ${_campaignScore.toString().padLeft(4, '0')}';
      hudText.text =
          '$campaignStageName  Lvl $_campaignLevel  Rally $_rallyCount  Hull L$_leftDurability R$_rightDurability  Best $_bestCampaignScore';
    }
  }

  void startLocal() {
    unawaited(_setMatchmakingWakeLock(false));
    overlays.remove('menu');
    overlays.remove('game_over');
    mode = GameMode.localPlaying;
    _lastGameWasOnline = false;
    _currentState = createInitialState(_dimensions);
    _winner = null;
    _mySide = null;
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
    _clearPickups();
    _campaignScore = 0;
    _rallyCount = 0;
    _leftDurability = _maxDurability;
    _rightDurability = _maxDurability;
    _campaignStage = campaignStageForScore(0);
    _campaignLevel = _campaignStage.level;
    _pickupSpawnCooldown = _campaignStage.pickupCooldown;
    _applyDurabilityVisuals();
    _applyState(_currentState!, fromServer: false);
  }

  /// True if the current or most recent game was online (for game-over UI).
  bool get lastGameWasOnline => _lastGameWasOnline;
  bool _lastGameWasOnline = false;

  void startOnline(Side side) {
    unawaited(_setMatchmakingWakeLock(false));
    overlays.remove('matchmaking');
    mode = GameMode.onlinePlaying;
    _mySide = side;
    _lastGameWasOnline = true;
    _clearPickups();
    leftPaddle.size.y = _dimensions.paddleHeight;
    rightPaddle.size.y = _dimensions.paddleHeight;
    leftPaddle.integrity = 1;
    rightPaddle.integrity = 1;
  }

  void showMenu() {
    unawaited(_setMatchmakingWakeLock(false));
    overlays.remove('game_over');
    overlays.remove('matchmaking');
    overlays.add('menu');
    mode = GameMode.menu;
    _winner = null;
    _mySide = null;
    _currentState = null;
    _matchmakingError = false;
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
    _clearPickups();
    hudText.text = '';
  }

  void cyclePaddleSkin() {
    const list = PaddleSkin.values;
    final next = (list.indexOf(_paddleSkin) + 1) % list.length;
    _paddleSkin = list[next];
    _applySkins();
  }

  void cycleBallSkin() {
    const list = BallSkin.values;
    final next = (list.indexOf(_ballSkin) + 1) % list.length;
    _ballSkin = list[next];
    _applySkins();
  }

  void showMatchmaking() {
    unawaited(_setMatchmakingWakeLock(true));
    mode = GameMode.onlineFinding;
    _matchmakingError = false;
    _lastGameWasOnline = true;
    overlays.remove('menu');
    overlays.remove('game_over');
    overlays.add('matchmaking');
    _clearPickups();
    leftPaddle.size.y = _dimensions.paddleHeight;
    rightPaddle.size.y = _dimensions.paddleHeight;
    leftPaddle.integrity = 1;
    rightPaddle.integrity = 1;
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
    _disconnectSub = _socketService.onDisconnect.listen((_) {
      if (mode == GameMode.onlineFinding || mode == GameMode.onlinePlaying) {
        onOpponentLeft();
      }
    });
    _socketService.findMatch().then((payload) {
      if (mode != GameMode.onlineFinding) return;
      onMatched(payload.side);
      _socketService.startGameStateListener();
      _gameStateSub = _socketService.gameStateStream.listen(onGameState);
    }).catchError((_) {
      if (mode == GameMode.onlineFinding) {
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
    final wasNull = _currentState == null;
    _currentState = state;
    if (mode == GameMode.onlinePlaying && wasNull) {
      _applyState(_currentState!, fromServer: true);
    }
    if (state.gameOver && state.winner != null) {
      _winner = state.winner;
      mode = GameMode.gameOver;
      overlays.add('game_over');
    }
  }

  void onOpponentLeft() {
    unawaited(_setMatchmakingWakeLock(false));
    mode = GameMode.gameOver;
    _winner = null;
    overlays.add('game_over');
  }

  @override
  void onRemove() {
    _gameStateSub?.cancel();
    _disconnectSub?.cancel();
    unawaited(_setMatchmakingWakeLock(false));
    super.onRemove();
  }
}

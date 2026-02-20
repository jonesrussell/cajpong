/// Shared game state and message types for local and online play.
library;

/// Which side scored or won.
enum Side { left, right }

/// Full game state (matches server and local step).
class GameState {
  GameState({
    required this.ballX,
    required this.ballY,
    required this.ballVx,
    required this.ballVy,
    required this.leftPaddleY,
    required this.rightPaddleY,
    required this.scoreLeft,
    required this.scoreRight,
    required this.serving,
    this.serveDirection,
    required this.serveCountdownRemaining,
    required this.gameOver,
    this.winner,
    required this.gameTime,
    required this.lastPaddleHitTime,
  });

  final double ballX;
  final double ballY;
  final double ballVx;
  final double ballVy;
  final double leftPaddleY;
  final double rightPaddleY;
  final int scoreLeft;
  final int scoreRight;
  final bool serving;
  final int? serveDirection;
  final double serveCountdownRemaining;
  final bool gameOver;
  final Side? winner;
  final double gameTime;
  final double lastPaddleHitTime;

  GameState copyWith({
    double? ballX,
    double? ballY,
    double? ballVx,
    double? ballVy,
    double? leftPaddleY,
    double? rightPaddleY,
    int? scoreLeft,
    int? scoreRight,
    bool? serving,
    int? serveDirection,
    double? serveCountdownRemaining,
    bool? gameOver,
    Side? winner,
    double? gameTime,
    double? lastPaddleHitTime,
  }) {
    return GameState(
      ballX: ballX ?? this.ballX,
      ballY: ballY ?? this.ballY,
      ballVx: ballVx ?? this.ballVx,
      ballVy: ballVy ?? this.ballVy,
      leftPaddleY: leftPaddleY ?? this.leftPaddleY,
      rightPaddleY: rightPaddleY ?? this.rightPaddleY,
      scoreLeft: scoreLeft ?? this.scoreLeft,
      scoreRight: scoreRight ?? this.scoreRight,
      serving: serving ?? this.serving,
      serveDirection: serveDirection ?? this.serveDirection,
      serveCountdownRemaining:
          serveCountdownRemaining ?? this.serveCountdownRemaining,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      gameTime: gameTime ?? this.gameTime,
      lastPaddleHitTime: lastPaddleHitTime ?? this.lastPaddleHitTime,
    );
  }

  /// Parse from server JSON (numbers may be int or double).
  static GameState fromJson(Map<String, dynamic> json) {
    return GameState(
      ballX: (json['ballX'] as num).toDouble(),
      ballY: (json['ballY'] as num).toDouble(),
      ballVx: (json['ballVx'] as num).toDouble(),
      ballVy: (json['ballVy'] as num).toDouble(),
      leftPaddleY: (json['leftPaddleY'] as num).toDouble(),
      rightPaddleY: (json['rightPaddleY'] as num).toDouble(),
      scoreLeft: json['scoreLeft'] as int,
      scoreRight: json['scoreRight'] as int,
      serving: json['serving'] as bool,
      serveDirection: json['serveDirection'] as int?,
      serveCountdownRemaining:
          (json['serveCountdownRemaining'] as num).toDouble(),
      gameOver: json['gameOver'] as bool,
      winner: json['winner'] == null
          ? null
          : (json['winner'] as String == 'left' ? Side.left : Side.right),
      gameTime: (json['gameTime'] as num).toDouble(),
      lastPaddleHitTime: (json['lastPaddleHitTime'] as num).toDouble(),
    );
  }
}

/// One paddle's input (up/down).
class PaddleInput {
  const PaddleInput({this.up = false, this.down = false});
  final bool up;
  final bool down;
}

/// Paddle inputs per side (for game step).
class Inputs {
  const Inputs({PaddleInput? left, PaddleInput? right})
      : left = left ?? const PaddleInput(),
        right = right ?? const PaddleInput();

  final PaddleInput left;
  final PaddleInput right;
}

/// Payload when server matches two players.
class MatchedPayload {
  const MatchedPayload({required this.side, required this.roomId});
  final Side side;
  final String roomId;

  static MatchedPayload fromJson(Map<String, dynamic> json) {
    return MatchedPayload(
      side: json['side'] as String == 'left' ? Side.left : Side.right,
      roomId: json['roomId'] as String,
    );
  }
}

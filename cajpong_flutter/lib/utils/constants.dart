// Game tuning values (ported from Phaser constants).
// Reference size 800x600; runtime dimensions scale from [GameDimensions].

/// Reference size used by server and for scaling (server space).
const double refWidth = 800;
const double refHeight = 600;

const double paddleWidthRef = 20;
const double paddleHeightRef = 100;
const double paddlePaddingRef = 40;
const double paddleSpeed = 700;
const double paddleClampMarginRef = 70;

const double ballSizeRef = 16;
const double ballSpeed = 500;
const double ballSpeedIncrease = 1.1;
const int paddleHitCooldownMs = 100;
const double ballAngleVariation = 0.3;

const double wallHeightRef = 20;

const double scoreTextYRef = 50;
const double scoreFontSizeRef = 48;

const int serveDelayMs = 500;

const int pointsToWin = 11;
const double ballPaddleSeparationRef = 2;
const int winDisplayDelayMs = 2500;

const double buttonWidthRef = 180;
const double buttonHeightRef = 50;

/// Scaled dimensions for the current game canvas (responsive layout).
class GameDimensions {
  GameDimensions(this.width, this.height)
      : scaleX = width / refWidth,
        scaleY = height / refHeight,
        scale = (width / refWidth) < (height / refHeight)
            ? (width / refWidth)
            : (height / refHeight) {
    paddleWidth = paddleWidthRef * scaleX;
    paddleHeight = paddleHeightRef * scaleY;
    paddlePadding = paddlePaddingRef * scaleX;
    paddleClampMargin = paddleClampMarginRef * scaleY;
    ballSize = ballSizeRef * scale;
    wallHeight = wallHeightRef * scaleY;
    scoreTextY = scoreTextYRef * scaleY;
    scoreFontSize = scoreFontSizeRef * scale;
    ballPaddleSeparation = ballPaddleSeparationRef * scaleX;
    halfPaddle = paddleWidth / 2;
    halfPaddleH = paddleHeight / 2;
    topWall = wallHeight / 2;
    bottomWall = height - wallHeight / 2;
    buttonWidth = buttonWidthRef * scale;
    buttonHeight = buttonHeightRef * scale;
  }

  final double width;
  final double height;
  final double scaleX;
  final double scaleY;
  final double scale;

  late final double paddleWidth;
  late final double paddleHeight;
  late final double paddlePadding;
  late final double paddleClampMargin;
  late final double ballSize;
  late final double wallHeight;
  late final double scoreTextY;
  late final double scoreFontSize;
  late final double ballPaddleSeparation;
  late final double halfPaddle;
  late final double halfPaddleH;
  late final double topWall;
  late final double bottomWall;
  late final double buttonWidth;
  late final double buttonHeight;

  /// Scale server state (800x600) to client coordinates.
  double serverXToClient(double x) => x * scaleX;
  double serverYToClient(double y) => y * scaleY;

  /// Scale client-space coordinates back to server space (800x600).
  double clientYToServer(double y) => y / scaleY;
}

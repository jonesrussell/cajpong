import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum BallSkin { classic, plasma, ember }

/// Ball. Position and size are set by the game from [GameDimensions].
class Ball extends PositionComponent {
  Ball() : super(size: Vector2.zero());
  BallSkin skin = BallSkin.classic;

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..shader = _shaderForSkin(rect);
    canvas.drawCircle(
      center,
      radius,
      paint,
    );

    if (skin != BallSkin.classic) {
      canvas.drawCircle(
        center,
        radius * 0.5,
        Paint()..color = const Color(0x77FFFFFF),
      );
    }
  }

  Shader _shaderForSkin(Rect rect) {
    switch (skin) {
      case BallSkin.classic:
        return const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFDADFE7)],
        ).createShader(rect);
      case BallSkin.plasma:
        return const RadialGradient(
          colors: [Color(0xFF9EFFF6), Color(0xFF24A8F5), Color(0xFF10426A)],
        ).createShader(rect);
      case BallSkin.ember:
        return const RadialGradient(
          colors: [Color(0xFFFFF0BE), Color(0xFFFF8A3D), Color(0xFF9A2E13)],
        ).createShader(rect);
    }
  }
}

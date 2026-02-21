import 'dart:ui';

import 'package:flame/components.dart';

/// Ball. Position and size are set by the game from [GameDimensions].
class Ball extends PositionComponent {
  Ball() : super(size: Vector2.zero());

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}

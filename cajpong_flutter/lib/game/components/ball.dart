import 'dart:ui';

import 'package:flame/components.dart';
import 'package:cajpong_flutter/utils/constants.dart';

/// Ball. Position and velocity are updated by the game each frame.
class Ball extends PositionComponent {
  Ball() : super(size: Vector2(ballSize * 2, ballSize * 2));

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      ballSize,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}

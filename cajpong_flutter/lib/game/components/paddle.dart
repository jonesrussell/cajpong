import 'dart:ui';

import 'package:flame/components.dart';
import 'package:cajpong_flutter/utils/constants.dart';

/// Left or right paddle. Position.y is updated by the game; x is fixed.
class Paddle extends PositionComponent {
  Paddle({required this.isLeft}) : super(size: Vector2(paddleWidth, paddleHeight));

  final bool isLeft;

  factory Paddle.left() => Paddle(isLeft: true);
  factory Paddle.right() => Paddle(isLeft: false);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
  }
}

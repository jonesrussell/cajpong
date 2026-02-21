import 'dart:ui';

import 'package:flame/components.dart';

/// Left or right paddle. Position and size are set by the game from [GameDimensions].
class Paddle extends PositionComponent {
  Paddle({required this.isLeft}) : super(size: Vector2.zero());

  final bool isLeft;

  factory Paddle.left() => Paddle(isLeft: true);
  factory Paddle.right() => Paddle(isLeft: false);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
  }
}

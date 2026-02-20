import 'dart:ui';

import 'package:flame/components.dart';
import 'package:cajpong_flutter/utils/constants.dart';

/// Top or bottom wall (visual only; collision is in game_loop).
class Wall extends PositionComponent {
  Wall({required this.isTop})
      : super(
          size: Vector2(width, wallHeight),
          position: Vector2(0, isTop ? 0 : height - wallHeight),
        );

  final bool isTop;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF444444),
    );
  }
}

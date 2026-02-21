import 'dart:ui';

import 'package:flame/components.dart';

/// Top or bottom wall (visual only; collision is in game_loop).
/// Size and position are set by the game from [GameDimensions].
class Wall extends PositionComponent {
  Wall({required this.isTop}) : super(size: Vector2.zero(), position: Vector2.zero());

  final bool isTop;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF444444),
    );
  }
}

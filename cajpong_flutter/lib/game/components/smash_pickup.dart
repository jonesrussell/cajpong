import 'dart:ui';

import 'package:flame/components.dart';

enum SmashPickupType { points, repair, slow }

class SmashPickup extends PositionComponent {
  SmashPickup({
    required this.type,
    required Vector2 position,
    required this.radius,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  final SmashPickupType type;
  final double radius;

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final paint = Paint()..shader = _shaderForType();
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  Shader _shaderForType() {
    switch (type) {
      case SmashPickupType.points:
        return Gradient.radial(
          Offset(radius, radius),
          radius,
          const [Color(0xFFFFF0A8), Color(0xFFFFA82E), Color(0xFF9A5B00)],
        );
      case SmashPickupType.repair:
        return Gradient.radial(
          Offset(radius, radius),
          radius,
          const [Color(0xFFC8FFD5), Color(0xFF37C463), Color(0xFF0F5A2D)],
        );
      case SmashPickupType.slow:
        return Gradient.radial(
          Offset(radius, radius),
          radius,
          const [Color(0xFFC8E9FF), Color(0xFF2C8CE2), Color(0xFF0C3A78)],
        );
    }
  }
}

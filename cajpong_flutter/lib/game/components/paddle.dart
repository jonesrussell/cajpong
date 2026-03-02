import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum PaddleSkin { classic, neon, steel }

/// Left or right paddle. Position and size are set by the game from [GameDimensions].
class Paddle extends PositionComponent {
  Paddle({required this.isLeft}) : super(size: Vector2.zero());

  final bool isLeft;
  PaddleSkin skin = PaddleSkin.classic;
  double integrity = 1.0;

  factory Paddle.left() => Paddle(isLeft: true);
  factory Paddle.right() => Paddle(isLeft: false);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final crack = integrity < 0.35;
    final damage = (1.0 - integrity).clamp(0.0, 1.0);
    final basePaint = Paint()
      ..shader = _shaderForSkin(rect)
      ..colorFilter = damage > 0.01
          ? ColorFilter.mode(
              Color.lerp(
                  const Color(0x00000000), const Color(0xFF9B2C2C), damage)!,
              BlendMode.modulate,
            )
          : null;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.3)),
      basePaint,
    );

    if (crack) {
      final crackPaint = Paint()
        ..color = const Color(0xFFE6EEF8)
        ..strokeWidth = size.x * 0.08
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(size.x * 0.2, size.y * 0.18)
        ..lineTo(size.x * 0.7, size.y * 0.42)
        ..lineTo(size.x * 0.35, size.y * 0.68)
        ..lineTo(size.x * 0.75, size.y * 0.88);
      canvas.drawPath(path, crackPaint);
    }
  }

  Shader _shaderForSkin(Rect rect) {
    switch (skin) {
      case PaddleSkin.classic:
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFD7D9DD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      case PaddleSkin.neon:
        return const LinearGradient(
          colors: [Color(0xFF2EE6A6), Color(0xFF11856F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      case PaddleSkin.steel:
        return const LinearGradient(
          colors: [Color(0xFFCAD3DB), Color(0xFF6D7784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
    }
  }
}

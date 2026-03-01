import 'package:flutter/material.dart';

/// Reusable button used in menu and game-over overlays.
class PongButton extends StatelessWidget {
  const PongButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.width,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF333333),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

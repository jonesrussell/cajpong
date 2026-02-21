import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';

Widget buildMenuOverlay(BuildContext context, PongGame game) {
  final d = game.dimensions;
  return Container(
    color: const Color(0xFF111111),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CajPong',
            style: TextStyle(
              color: Colors.white,
              fontSize: d.scale * 64,
            ),
          ),
          SizedBox(height: d.scale * 24),
          Text(
            'Local  |  Online',
            style: TextStyle(color: Colors.white, fontSize: d.scale * 24),
          ),
          SizedBox(height: d.scale * 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                label: 'Local',
                onTap: () => game.startLocal(),
                width: d.buttonWidth,
                height: d.buttonHeight,
              ),
              SizedBox(width: d.scale * 40),
              _MenuButton(
                label: 'Online',
                onTap: () => game.showMatchmaking(),
                width: d.buttonWidth,
                height: d.buttonHeight,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
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

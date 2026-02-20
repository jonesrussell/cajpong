import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/utils/constants.dart';

Widget buildMenuOverlay(BuildContext context, PongGame game) {
  return Container(
    color: const Color(0xFF111111),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CajPong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Local  |  Online',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                label: 'Local',
                onTap: () => game.startLocal(),
              ),
              const SizedBox(width: 40),
              _MenuButton(
                label: 'Online',
                onTap: () => game.showMatchmaking(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF333333),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}

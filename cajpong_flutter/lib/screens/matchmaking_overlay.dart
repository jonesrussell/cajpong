import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';

Widget buildMatchmakingOverlay(BuildContext context, PongGame game) {
  if (game.matchmakingError) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connection failed',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => game.retryMatchmaking(),
              child: const Text('Tap to retry'),
            ),
          ],
        ),
      ),
    );
  }
  return Container(
    color: const Color(0xFF111111),
    child: const Center(
      child: Text(
        'Finding opponent…',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    ),
  );
}

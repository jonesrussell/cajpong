import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';

Widget buildMatchmakingOverlay(BuildContext context, PongGame game) {
  final d = game.dimensions;
  if (game.matchmakingError) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connection failed',
              style: TextStyle(color: Colors.white, fontSize: d.scale * 24),
            ),
            SizedBox(height: d.scale * 16),
            TextButton(
              onPressed: () => game.retryMatchmaking(),
              child: Text(
                'Tap to retry',
                style: TextStyle(fontSize: d.scale * 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return Container(
    color: const Color(0xFF111111),
    child: Center(
      child: Text(
        'Finding opponent…',
        style: TextStyle(color: Colors.white, fontSize: d.scale * 24),
      ),
    ),
  );
}
